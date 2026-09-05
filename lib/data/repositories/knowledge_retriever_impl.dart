import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/core/utils/fingerprints.dart';
import 'package:studee_pc/core/utils/text_normalizer.dart';
import 'package:studee_pc/data/subject_database/subject_database.dart';
import 'package:studee_pc/data/subject_database/subject_database_manager.dart';
import 'package:studee_pc/domain/entities/parsed_question.dart';
import 'package:studee_pc/domain/entities/question_choice.dart';
import 'package:studee_pc/domain/entities/ranked_candidate.dart';
import 'package:studee_pc/domain/entities/retrieval_result.dart';
import 'package:studee_pc/domain/enums/knowledge_unit_type.dart';
import 'package:studee_pc/domain/enums/question_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';
import 'package:studee_pc/domain/repositories/deepseek_client.dart';
import 'package:studee_pc/domain/repositories/knowledge_retriever.dart';
import 'package:studee_pc/domain/services/candidate_scorer.dart';
import 'package:studee_pc/domain/services/choice_mapper.dart';

/// Retrieval pipeline:
/// exact fingerprint → reordered choices → semantic key → lexical → FTS →
/// LLM meaning match → empty.
class KnowledgeRetrieverImpl implements KnowledgeRetriever {
  KnowledgeRetrieverImpl({
    required SubjectDatabaseManager databaseManager,
    DeepSeekClient? deepSeek,
    CandidateScorer scorer = const CandidateScorer(),
    ChoiceMapper choiceMapper = const ChoiceMapper(),
  })  : _dbManager = databaseManager,
        _deepSeek = deepSeek,
        _scorer = scorer,
        _choiceMapper = choiceMapper;

  final SubjectDatabaseManager _dbManager;
  final DeepSeekClient? _deepSeek;
  final CandidateScorer _scorer;
  final ChoiceMapper _choiceMapper;
  final AppLogger _log = AppLogger('KnowledgeRetriever');

  /// Caps lazy semantic-key backfill per retrieve call.
  static const int _backfillBatch = 15;

  @override
  Future<RetrievalResult> retrieve({
    required String subjectId,
    required ParsedQuestion question,
    required int limit,
  }) async {
    final cappedLimit = limit.clamp(1, 50);
    final db = await _ensureOpen(subjectId);

    final fingerprint = Fingerprints.questionFingerprint(
      questionText: question.content,
      choiceContents: question.choiceContents,
    );
    final choiceSetFp = Fingerprints.choiceSetFingerprint(question.choiceContents);
    final normalizedQuestion =
        TextNormalizer.normalizeQuestionText(question.content);

    // 1) Exact fingerprint
    final exactRows = await (db.select(db.questions)
          ..where(
            (q) =>
                q.questionFingerprint.equals(fingerprint) &
                q.verificationStatus.isNotValue(
                  VerificationStatus.rejected.wireName,
                ),
          ))
        .get();

    if (exactRows.isNotEmpty) {
      final candidates = await _questionsToCandidates(db, exactRows);
      final scored = _scorer.scoreAndFilter(
        question: question,
        candidates: candidates,
      );
      final exact = scored
          .map((c) => c.copyWith(exactFingerprintMatch: true, score: 1.0))
          .toList();
      final expanded = await _expandWithRelatedKnowledge(
        db,
        exact.take(cappedLimit).toList(),
        cappedLimit,
      );
      _log.info(
        'Retrieve exact fingerprint hits=${exact.length} '
        'expanded=${expanded.length}',
      );
      return RetrievalResult(
        candidates: expanded,
        exactMatches: exact,
        hasTrustedConflict: _hasTrustedConflict(exact),
      );
    }

    // 2) Reordered choices: same normalized stem + same choice-set fingerprint
    // Compare against raw question content (normalizedContent may include aliases).
    final stemCandidates = await (db.select(db.questions)
          ..where(
            (q) => q.verificationStatus.isNotValue(
              VerificationStatus.rejected.wireName,
            ),
          ))
        .get();

    final reordered = <RankedCandidate>[];
    for (final row in stemCandidates) {
      final rowStem = TextNormalizer.normalizeQuestionText(row.content);
      if (rowStem != normalizedQuestion) continue;

      final choices = await _loadChoices(db, row.id);
      final storedSetFp = Fingerprints.choiceSetFingerprint(
        choices.map((c) => c.content),
      );
      if (storedSetFp != choiceSetFp) continue;

      // Map stored answer onto current labels (never copy stored label).
      final mapped = _choiceMapper.mapStoredAnswer(
        storedAnswerContent: row.answerContent,
        storedAnswerLabel: row.answerLabel,
        currentQuestion: question,
      );

      reordered.add(
        await _questionToCandidate(
          db,
          row,
          choices,
          overrideAnswerLabel: mapped?.label,
          overrideAnswerContent: mapped?.content ?? row.answerContent,
          scoreHint: 0.95,
          highLexical: true,
        ),
      );
    }

    if (reordered.isNotEmpty) {
      final scored = _scorer.scoreAndFilter(
        question: question,
        candidates: reordered,
      );
      final expanded = await _expandWithRelatedKnowledge(
        db,
        scored.take(cappedLimit).toList(),
        cappedLimit,
      );
      _log.info(
        'Retrieve reordered-choice hits=${scored.length} '
        'expanded=${expanded.length}',
      );
      return RetrievalResult(
        candidates: expanded,
        exactMatches: const [],
        hasTrustedConflict: _hasTrustedConflict(scored),
      );
    }

    // 3) Semantic key equality (canonical meaning)
    final semanticHit = await _retrieveBySemanticKey(
      db,
      question: question,
      cappedLimit: cappedLimit,
    );
    if (semanticHit != null) return semanticHit;

    // 4) High lexical similarity among non-rejected questions
    final lexicalRows = await (db.select(db.questions)
          ..where(
            (q) => q.verificationStatus.isNotValue(
              VerificationStatus.rejected.wireName,
            ),
          ))
        .get();

    final lexicalPool = await _questionsToCandidates(db, lexicalRows);
    final lexicalScored = _scorer.scoreAndFilter(
      question: question,
      candidates: lexicalPool,
    );
    final strongLexical =
        lexicalScored.where((c) => c.highLexicalMatch).toList();

    if (strongLexical.isNotEmpty) {
      final expanded = await _expandWithRelatedKnowledge(
        db,
        strongLexical.take(cappedLimit).toList(),
        cappedLimit,
      );
      _log.info(
        'Retrieve high-lexical hits=${strongLexical.length} '
        'expanded=${expanded.length}',
      );
      return RetrievalResult(
        candidates: expanded,
        exactMatches: const [],
        hasTrustedConflict: _hasTrustedConflict(strongLexical),
      );
    }

    // 4b) Softer lexical pass (accent-folded) when OCR/diacritics drift.
    final softLexical = <RankedCandidate>[];
    for (final candidate in lexicalPool) {
      if (!candidate.verificationStatus.isRetrievable) continue;
      final folded = _scorer.accentFoldedSimilarity(
        question.content,
        candidate.content,
      );
      if (folded < 0.72) continue;
      final scored = _scorer.score(question: question, candidate: candidate);
      if (scored.score < _scorer.rejectThreshold && folded < 0.88) continue;
      softLexical.add(
        scored.copyWith(
          score: math.max(scored.score, folded * 0.85),
          highLexicalMatch: false,
        ),
      );
    }
    softLexical.sort((a, b) => b.score.compareTo(a.score));

    // 5) FTS5 over questions + knowledge units
    final ftsQuestions = await db.searchQuestionsFts(
      question.content,
      limit: cappedLimit * 2,
    );
    final ftsUnits = await db.searchKnowledgeFts(
      question.content,
      limit: cappedLimit * 2,
    );

    final ftsCandidates = <RankedCandidate>[
      ...await _questionsToCandidates(db, ftsQuestions),
      ...ftsUnits.map(_unitToCandidate),
    ];

    final ftsScored = _scorer.scoreAndFilter(
      question: question,
      candidates: ftsCandidates,
    );

    // 6) LLM same-meaning match against soft + FTS question candidates
    final weakPool = _dedupeCandidates([
      ...softLexical,
      ...ftsScored.where((c) => c.questionId != null),
    ]);
    final meaningHit = await _retrieveByMeaningMatch(
      db,
      question: question,
      weakPool: weakPool,
      cappedLimit: cappedLimit,
    );
    if (meaningHit != null) return meaningHit;

    if (softLexical.isNotEmpty) {
      final expanded = await _expandWithRelatedKnowledge(
        db,
        softLexical.take(cappedLimit).toList(),
        cappedLimit,
      );
      _log.info(
        'Retrieve soft-lexical hits=${softLexical.length} '
        'expanded=${expanded.length}',
      );
      return RetrievalResult(
        candidates: expanded,
        exactMatches: const [],
        hasTrustedConflict: _hasTrustedConflict(expanded),
      );
    }

    if (ftsScored.isNotEmpty) {
      _log.info('Retrieve FTS hits=${ftsScored.length}');
      return RetrievalResult(
        candidates: ftsScored.take(cappedLimit).toList(),
        exactMatches: const [],
        hasTrustedConflict: _hasTrustedConflict(ftsScored),
      );
    }

    // 7) Empty — caller may fall back to model-only solve.
    _log.info('Retrieve empty for subjectId=$subjectId');
    return const RetrievalResult(candidates: []);
  }

  Future<RetrievalResult?> _retrieveBySemanticKey(
    SubjectDatabase db, {
    required ParsedQuestion question,
    required int cappedLimit,
  }) async {
    final deepSeek = _deepSeek;
    if (deepSeek == null) return null;

    try {
      await _lazyBackfillSemanticKeys(db, deepSeek);

      final canon = await deepSeek.canonicalizeQuestions([
        CanonicalizeItem(
          id: 'live',
          questionText: question.content,
          choiceContents: question.choiceContents.toList(),
        ),
      ]);
      final key = canon['live']?.semanticKey.trim();
      if (key == null || key.isEmpty) return null;

      final fp = Fingerprints.semanticFingerprint(key);
      final rows = await (db.select(db.questions)
            ..where(
              (q) =>
                  q.semanticFingerprint.equals(fp) &
                  q.verificationStatus.isNotValue(
                    VerificationStatus.rejected.wireName,
                  ),
            ))
          .get();
      if (rows.isEmpty) return null;

      final promoted = <RankedCandidate>[];
      for (final row in rows) {
        if (!_scorer.numericSignaturesCompatible(question.content, row.content)) {
          continue;
        }
        final choices = await _loadChoices(db, row.id);
        final mapped = _choiceMapper.mapStoredAnswer(
          storedAnswerContent: row.answerContent,
          storedAnswerLabel: row.answerLabel,
          currentQuestion: question,
        );
        promoted.add(
          await _questionToCandidate(
            db,
            row,
            choices,
            overrideAnswerLabel: mapped?.label,
            overrideAnswerContent: mapped?.content ?? row.answerContent,
            scoreHint: 0.97,
            highLexical: true,
          ),
        );
      }
      if (promoted.isEmpty) return null;

      final expanded = await _expandWithRelatedKnowledge(
        db,
        promoted.take(cappedLimit).toList(),
        cappedLimit,
      );
      _log.info(
        'Retrieve semantic-key hits=${promoted.length} '
        'expanded=${expanded.length}',
      );
      return RetrievalResult(
        candidates: expanded,
        exactMatches: const [],
        hasTrustedConflict: _hasTrustedConflict(promoted),
      );
    } on Object catch (e) {
      _log.warning('Semantic-key retrieve failed: ${e.runtimeType}');
      return null;
    }
  }

  Future<void> _lazyBackfillSemanticKeys(
    SubjectDatabase db,
    DeepSeekClient deepSeek,
  ) async {
    final missing = await (db.select(db.questions)
          ..where(
            (q) =>
                q.semanticFingerprint.isNull() &
                q.verificationStatus.isNotValue(
                  VerificationStatus.rejected.wireName,
                ),
          )
          ..limit(_backfillBatch))
        .get();
    if (missing.isEmpty) return;

    try {
      final items = <CanonicalizeItem>[];
      for (final row in missing) {
        final choices = await _loadChoices(db, row.id);
        items.add(
          CanonicalizeItem(
            id: row.id,
            questionText: row.content,
            choiceContents: choices.map((c) => c.content).toList(),
          ),
        );
      }
      final keys = await deepSeek.canonicalizeQuestions(items);
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      for (final row in missing) {
        final sem = keys[row.id];
        if (sem == null || sem.semanticKey.trim().isEmpty) continue;
        final stemNorm = TextNormalizer.normalizeQuestionText(row.content);
        final aliasBlob = sem.aliases
            .map(TextNormalizer.normalizeQuestionText)
            .where((s) => s.isNotEmpty && s != stemNorm)
            .join(' ');
        final normalized = aliasBlob.isEmpty ? stemNorm : '$stemNorm $aliasBlob';
        await (db.update(db.questions)..where((q) => q.id.equals(row.id))).write(
          QuestionsCompanion(
            semanticKey: Value(sem.semanticKey),
            semanticFingerprint: Value(
              Fingerprints.semanticFingerprint(sem.semanticKey),
            ),
            normalizedContent: Value(normalized),
            updatedAt: Value(now),
          ),
        );
      }
      _log.info('Lazy semantic-key backfill count=${keys.length}');
    } on Object catch (e) {
      _log.warning('Lazy semantic backfill failed: ${e.runtimeType}');
    }
  }

  Future<RetrievalResult?> _retrieveByMeaningMatch(
    SubjectDatabase db, {
    required ParsedQuestion question,
    required List<RankedCandidate> weakPool,
    required int cappedLimit,
  }) async {
    final deepSeek = _deepSeek;
    if (deepSeek == null) return null;

    final questionCandidates = weakPool
        .where((c) => c.questionId != null && c.verificationStatus.isRetrievable)
        .take(8)
        .toList();
    if (questionCandidates.isEmpty) return null;

    try {
      final match = await deepSeek.matchQuestionMeaning(
        liveQuestion: question.content,
        candidates: [
          for (final c in questionCandidates)
            MeaningMatchCandidate(
              id: c.questionId!,
              questionText: c.content,
            ),
        ],
      );
      if (!match.sameMeaning || match.id == null) return null;

      final hit = questionCandidates.where((c) => c.questionId == match.id).firstOrNull;
      if (hit == null) return null;
      if (!_scorer.numericSignaturesCompatible(question.content, hit.content)) {
        _log.info('Meaning match rejected by numeric guard id=${match.id}');
        return null;
      }

      final row = await (db.select(db.questions)
            ..where((q) => q.id.equals(match.id!)))
          .getSingleOrNull();
      if (row == null) return null;

      final choices = await _loadChoices(db, row.id);
      final mapped = _choiceMapper.mapStoredAnswer(
        storedAnswerContent: row.answerContent,
        storedAnswerLabel: row.answerLabel,
        currentQuestion: question,
      );
      final promoted = await _questionToCandidate(
        db,
        row,
        choices,
        overrideAnswerLabel: mapped?.label,
        overrideAnswerContent: mapped?.content ?? row.answerContent,
        scoreHint: math.max(0.9, hit.score),
        highLexical: true,
      );

      final expanded = await _expandWithRelatedKnowledge(
        db,
        [promoted],
        cappedLimit,
      );
      _log.info('Retrieve meaning-match hit id=${match.id}');
      return RetrievalResult(
        candidates: expanded,
        exactMatches: const [],
        hasTrustedConflict: false,
      );
    } on Object catch (e) {
      _log.warning('Meaning-match retrieve failed: ${e.runtimeType}');
      return null;
    }
  }

  List<RankedCandidate> _dedupeCandidates(List<RankedCandidate> input) {
    final seen = <String>{};
    final out = <RankedCandidate>[];
    for (final c in input) {
      if (!seen.add(c.localId)) continue;
      out.add(c);
    }
    out.sort((a, b) => b.score.compareTo(a.score));
    return out;
  }

  Future<SubjectDatabase> _ensureOpen(String subjectId) async {
    if (_dbManager.activeSubjectId == subjectId &&
        _dbManager.activeDatabase != null) {
      return _dbManager.activeDatabase!;
    }
    try {
      return await _dbManager.open(subjectId);
    } on AppFailure {
      rethrow;
    } on Object catch (e) {
      throw DatabaseFailure(
        code: 'retriever_open_failed',
        details: e.runtimeType.toString(),
      );
    }
  }

  Future<List<RankedCandidate>> _questionsToCandidates(
    SubjectDatabase db,
    List<QuestionRow> rows,
  ) async {
    final out = <RankedCandidate>[];
    for (final row in rows) {
      final choices = await _loadChoices(db, row.id);
      out.add(await _questionToCandidate(db, row, choices));
    }
    return out;
  }

  Future<List<QuestionChoice>> _loadChoices(
    SubjectDatabase db,
    String questionId,
  ) async {
    final rows = await (db.select(db.questionChoices)
          ..where((c) => c.questionId.equals(questionId))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
    return rows
        .map(
          (r) => QuestionChoice(
            id: r.id,
            questionId: r.questionId,
            label: r.label,
            content: r.content,
            normalizedContent: r.normalizedContent,
            sortOrder: r.sortOrder,
          ),
        )
        .toList();
  }

  Future<RankedCandidate> _questionToCandidate(
    SubjectDatabase db,
    QuestionRow row,
    List<QuestionChoice> choices, {
    String? overrideAnswerLabel,
    String? overrideAnswerContent,
    double scoreHint = 0,
    bool highLexical = false,
  }) async {
    int sourcePriority = 0;
    String? sourceTitle;
    int? page;

    final unit = await (db.select(db.knowledgeUnits)
          ..where((u) => u.id.equals(row.knowledgeUnitId)))
        .getSingleOrNull();
    if (unit != null) {
      sourcePriority = unit.sourcePriority;
      final source = await (db.select(db.sources)
            ..where((s) => s.id.equals(unit.sourceId)))
          .getSingleOrNull();
      sourceTitle = source?.title;
      if (unit.sourcePageId != null) {
        final pageRow = await (db.select(db.sourcePages)
              ..where((p) => p.id.equals(unit.sourcePageId!)))
            .getSingleOrNull();
        page = pageRow?.pageNumber;
      }
    }

    return RankedCandidate(
      localId: row.id,
      questionId: row.id,
      unitType: KnowledgeUnitType.question,
      questionType: QuestionType.fromWire(row.questionType),
      content: row.content,
      normalizedContent: row.normalizedContent,
      answerLabel: overrideAnswerLabel ?? row.answerLabel,
      answerContent: overrideAnswerContent ?? row.answerContent,
      explanation: row.explanation,
      choices: choices,
      verificationStatus: VerificationStatus.fromWire(row.verificationStatus),
      sourcePriority: sourcePriority,
      score: scoreHint,
      exactFingerprintMatch: false,
      highLexicalMatch: highLexical,
      sourceTitle: sourceTitle,
      page: page,
      choiceSetFingerprint: Fingerprints.choiceSetFingerprint(
        choices.map((c) => c.content),
      ),
    );
  }

  RankedCandidate _unitToCandidate(KnowledgeUnitRow row) {
    return RankedCandidate(
      localId: row.id,
      unitType: KnowledgeUnitType.fromWire(row.type),
      content: row.content,
      normalizedContent: row.normalizedContent,
      verificationStatus: VerificationStatus.fromWire(row.verificationStatus),
      sourcePriority: row.sourcePriority,
      score: 0,
    );
  }

  /// Pull related theory/solution units so DeepSeek sees more than the stem.
  Future<List<RankedCandidate>> _expandWithRelatedKnowledge(
    SubjectDatabase db,
    List<RankedCandidate> seeds,
    int limit,
  ) async {
    if (seeds.isEmpty) return seeds;

    final out = <RankedCandidate>[...seeds];
    final seen = out.map((c) => c.localId).toSet();
    final parentUnitIds = <String>{};

    for (final seed in seeds) {
      if (seed.questionId == null) continue;
      final q = await (db.select(db.questions)
            ..where((t) => t.id.equals(seed.questionId!)))
          .getSingleOrNull();
      if (q == null) continue;
      parentUnitIds.add(q.knowledgeUnitId);
    }

    if (parentUnitIds.isEmpty) return out.take(limit).toList();

    final relatedIds = <String>{};
    for (final parentId in parentUnitIds) {
      final outgoing = await (db.select(db.knowledgeRelations)
            ..where((r) => r.fromUnitId.equals(parentId)))
          .get();
      for (final rel in outgoing) {
        relatedIds.add(rel.toUnitId);
      }
      final incoming = await (db.select(db.knowledgeRelations)
            ..where((r) => r.toUnitId.equals(parentId)))
          .get();
      for (final rel in incoming) {
        relatedIds.add(rel.fromUnitId);
      }

      // Sibling units from the same source (answer_key / solution / theory).
      final parent = await (db.select(db.knowledgeUnits)
            ..where((u) => u.id.equals(parentId)))
          .getSingleOrNull();
      if (parent != null) {
        final siblings = await (db.select(db.knowledgeUnits)
              ..where(
                (u) =>
                    u.sourceId.equals(parent.sourceId) &
                    u.id.isNotValue(parentId) &
                    u.verificationStatus.isNotValue(
                      VerificationStatus.rejected.wireName,
                    ),
              ))
            .get();
        for (final sib in siblings) {
          final type = KnowledgeUnitType.fromWire(sib.type);
          if (type == KnowledgeUnitType.question) continue;
          relatedIds.add(sib.id);
        }
      }
    }

    relatedIds.removeAll(parentUnitIds);

    for (final id in relatedIds) {
      if (out.length >= limit) break;
      if (seen.contains(id)) continue;
      final unit = await (db.select(db.knowledgeUnits)
            ..where((u) => u.id.equals(id)))
          .getSingleOrNull();
      if (unit == null) continue;
      if (unit.verificationStatus == VerificationStatus.rejected.wireName) {
        continue;
      }
      final candidate = _unitToCandidate(unit).copyWith(
        score: math.max(0.4, seeds.first.score * 0.85),
        highLexicalMatch: false,
        exactFingerprintMatch: false,
      );
      out.add(candidate);
      seen.add(id);
    }

    return out.take(limit).toList();
  }

  bool _hasTrustedConflict(List<RankedCandidate> candidates) {
    final trusted = candidates
        .where((c) => c.verificationStatus.isTrusted && c.hasAnswer)
        .toList();
    if (trusted.length < 2) return false;

    final contents = trusted
        .map(
          (c) {
            final body = TextNormalizer.normalizeAnswerForCompare(
              c.answerContent ?? '',
            );
            if (body.isNotEmpty && !TextNormalizer.isBareChoiceLabel(body)) {
              return body;
            }
            final label = (c.answerLabel ?? '').trim().toLowerCase();
            if (label.isNotEmpty) return 'label:$label';
            return body;
          },
        )
        .where((s) => s.isNotEmpty)
        .toSet();
    return contents.length > 1;
  }
}

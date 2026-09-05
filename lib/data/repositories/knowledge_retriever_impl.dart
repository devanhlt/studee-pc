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
import 'package:studee_pc/domain/repositories/knowledge_retriever.dart';
import 'package:studee_pc/domain/services/candidate_scorer.dart';
import 'package:studee_pc/domain/services/choice_mapper.dart';

/// Retrieval pipeline:
/// exact fingerprint → reordered choices → lexical similarity → FTS5 → empty.
class KnowledgeRetrieverImpl implements KnowledgeRetriever {
  KnowledgeRetrieverImpl({
    required SubjectDatabaseManager databaseManager,
    CandidateScorer scorer = const CandidateScorer(),
    ChoiceMapper choiceMapper = const ChoiceMapper(),
  })  : _dbManager = databaseManager,
        _scorer = scorer,
        _choiceMapper = choiceMapper;

  final SubjectDatabaseManager _dbManager;
  final CandidateScorer _scorer;
  final ChoiceMapper _choiceMapper;
  final AppLogger _log = AppLogger('KnowledgeRetriever');

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
    final stemRows = await (db.select(db.questions)
          ..where(
            (q) =>
                q.normalizedContent.equals(normalizedQuestion) &
                q.verificationStatus.isNotValue(
                  VerificationStatus.rejected.wireName,
                ),
          ))
        .get();

    final reordered = <RankedCandidate>[];
    for (final row in stemRows) {
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

    // 3) High lexical similarity among non-rejected questions (includes
    // user-imported / unreviewed — previously only official+reviewed, which
    // made freshly imported Q&A invisible to the solver).
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
    // Keep true high-lexical only — score alone is not enough (FTS siblings).
    final strongLexical = lexicalScored.where((c) => c.highLexicalMatch).toList();

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

    // 3b) Softer lexical pass (accent-folded) when OCR/diacritics drift.
    final softLexical = <RankedCandidate>[];
    for (final candidate in lexicalPool) {
      if (!candidate.verificationStatus.isRetrievable) continue;
      final folded = _scorer.accentFoldedSimilarity(
        question.content,
        candidate.content,
      );
      if (folded < 0.72) continue;
      final scored = _scorer.score(question: question, candidate: candidate);
      // Keep if base score is near threshold or accent overlap is strong.
      if (scored.score < _scorer.rejectThreshold && folded < 0.88) continue;
      softLexical.add(
        scored.copyWith(
          score: math.max(scored.score, folded * 0.85),
          // Soft pass is for context / OCR diacritics only — never claim
          // high-lexical identity (that would lock a sibling question's answer).
          highLexicalMatch: false,
        ),
      );
    }
    softLexical.sort((a, b) => b.score.compareTo(a.score));
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

    // 4) FTS5 over questions + knowledge units (OR query — tolerant of OCR drift)
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

    if (ftsScored.isNotEmpty) {
      _log.info('Retrieve FTS hits=${ftsScored.length}');
      return RetrievalResult(
        candidates: ftsScored.take(cappedLimit).toList(),
        exactMatches: const [],
        hasTrustedConflict: _hasTrustedConflict(ftsScored),
      );
    }

    // 5) Empty — caller may fall back to model-only solve.
    _log.info('Retrieve empty for subjectId=$subjectId');
    return const RetrievalResult(candidates: []);
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
        // Related theory/answer units are context only — never inherit
        // identity flags from the matched question (would lock wrong answers).
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

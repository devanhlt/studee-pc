import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/core/utils/fingerprints.dart';
import 'package:studee_pc/core/utils/text_normalizer.dart';
import 'package:studee_pc/data/repositories/knowledge_retriever_impl.dart';
import 'package:studee_pc/data/subject_database/subject_database.dart';
import 'package:studee_pc/data/subject_database/subject_database_manager.dart';
import 'package:studee_pc/domain/entities/deepseek_answer_response.dart';
import 'package:studee_pc/domain/entities/parsed_question.dart';
import 'package:studee_pc/domain/entities/practice_turn.dart';
import 'package:studee_pc/domain/enums/question_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';
import 'package:studee_pc/domain/repositories/deepseek_client.dart';
import 'package:studee_pc/domain/services/answer_precedence.dart';

class _MemoryDbManager extends SubjectDatabaseManager {
  _MemoryDbManager(this._db);

  final SubjectDatabase _db;

  @override
  String? get activeSubjectId => 'sub1';

  @override
  SubjectDatabase? get activeDatabase => _db;

  @override
  Future<SubjectDatabase> open(String subjectId) async => _db;
}

class _FakeDeepSeek implements DeepSeekClient {
  _FakeDeepSeek({
    this.liveSemanticKey = '1+1',
    this.storedSemanticKey,
    this.matchId,
    this.sameMeaning = false,
  });

  final String liveSemanticKey;
  /// When set, non-live items get this key (for meaning-match path tests).
  final String? storedSemanticKey;
  final String? matchId;
  final bool sameMeaning;

  @override
  Future<Map<String, SemanticCanonicalization>> canonicalizeQuestions(
    List<CanonicalizeItem> items,
  ) async {
    final out = <String, SemanticCanonicalization>{};
    for (final item in items) {
      final String key;
      if (item.id == 'live') {
        key = liveSemanticKey;
      } else if (storedSemanticKey != null) {
        key = storedSemanticKey!;
      } else {
        key = liveSemanticKey;
      }
      out[item.id] = SemanticCanonicalization(
        semanticKey: key,
        aliases: const ['one plus one', 'một cộng một'],
      );
    }
    return out;
  }

  @override
  Future<MeaningMatchResult> matchQuestionMeaning({
    required String liveQuestion,
    required List<MeaningMatchCandidate> candidates,
  }) async {
    if (!sameMeaning || matchId == null) {
      return const MeaningMatchResult(sameMeaning: false);
    }
    return MeaningMatchResult(id: matchId, sameMeaning: true);
  }

  @override
  Future<StructureSourceResponse> structureSource(
    StructureSourceRequest request,
  ) async =>
      throw UnimplementedError();

  @override
  Future<ParsedQuestion> parseQuestion(ParseQuestionRequest request) async =>
      throw UnimplementedError();

  @override
  Future<DeepSeekAnswerResponse> generateAnswer(
    GenerateAnswerRequest request,
  ) async =>
      throw UnimplementedError();

  @override
  Future<DeepSeekAnswerResponse> repairResponse(
    RepairResponseRequest request,
  ) async =>
      throw UnimplementedError();

  @override
  Future<void> testConnection() async {}

  @override
  Future<Map<String, String>> generateMemorizationTips(
    List<StudyTipItem> items,
  ) async =>
      {};

  @override
  Future<String> generateMcqStrategyTip({
    required String question,
    required List<String> choices,
    String? correctAnswer,
  }) async =>
      'Mẹo: tip giả lập.';

  @override
  Future<QuizAnswerResolution> resolveQuizAnswer({
    required String question,
    required List<({String label, String content})> choices,
  }) async {
    if (choices.isEmpty) {
      return const QuizAnswerResolution(label: '', content: '');
    }
    final first = choices.first;
    return QuizAnswerResolution(
      label: first.label,
      content: first.content,
      briefReason: 'Giả lập',
    );
  }

  @override
  Future<MathLatexFormatResult> formatMathLatex({
    required String content,
    List<({String label, String content})> choices = const [],
    String? answerContent,
    String? subjectName,
    String? formatKind,
  }) async =>
      MathLatexFormatResult(
        content: content,
        choices: choices,
        answerContent: answerContent,
      );

  @override
  Future<String> generateKnowledgeSummary({
    required String subjectName,
    required List<KnowledgeSummaryUnit> units,
    required List<KnowledgeSummaryQa> questions,
  }) async =>
      '- Tóm tắt giả lập cho $subjectName';

  @override
  Future<String> polishOcrText({
    required String raw,
    required String heuristic,
  }) async =>
      heuristic;

  @override
  Future<PracticeTurnResponse> startPracticeTurn({
    required String questionText,
    ParsedQuestion? parsed,
    int maxCheckSteps = 6,
    bool reviewMode = false,
    String? knownAnswerContent,
  }) async =>
      throw UnimplementedError();

  @override
  Future<PracticeTurnResponse> continuePracticeTurn({
    required List<PracticeLlmMessage> history,
    required String userAnswer,
    required int attemptsOnStep,
    int checkStepsSoFar = 0,
    int maxCheckSteps = 6,
    bool reviewMode = false,
  }) async =>
      throw UnimplementedError();

  @override
  void beginCancellableSession() {}

  @override
  void cancelActiveSession() {}
}

Future<void> _seedEquation({
  required SubjectDatabase db,
  required String questionId,
  required String content,
  required String answer,
  String? semanticKey,
  List<String> aliases = const [],
}) async {
  final now = DateTime.now().toUtc().millisecondsSinceEpoch;
  final stemNorm = TextNormalizer.normalizeQuestionText(content);
  final aliasBlob = aliases
      .map(TextNormalizer.normalizeQuestionText)
      .where((s) => s.isNotEmpty && s != stemNorm)
      .join(' ');
  final normalized = aliasBlob.isEmpty ? stemNorm : '$stemNorm $aliasBlob';

  await db.into(db.sources).insert(
        SourcesCompanion.insert(
          id: 'src1',
          type: 'paste',
          title: 'Paste',
          contentSha256: 'x',
          processingStatus: 'done',
          createdAt: now,
          updatedAt: now,
        ),
      );
  await db.into(db.knowledgeUnits).insert(
        KnowledgeUnitsCompanion.insert(
          id: 'ku1',
          sourceId: 'src1',
          type: 'question',
          content: content,
          normalizedContent: stemNorm,
          verificationStatus: VerificationStatus.reviewed.wireName,
          contentHash: Fingerprints.contentHash(content),
          createdAt: now,
          updatedAt: now,
        ),
      );
  await db.into(db.questions).insert(
        QuestionsCompanion.insert(
          id: questionId,
          knowledgeUnitId: 'ku1',
          questionType: QuestionType.textResponse.wireName,
          content: content,
          normalizedContent: normalized,
          questionFingerprint: Fingerprints.questionFingerprint(
            questionText: content,
            choiceContents: const [],
          ),
          semanticKey:
              semanticKey == null ? const Value.absent() : Value(semanticKey),
          semanticFingerprint: semanticKey == null
              ? const Value.absent()
              : Value(Fingerprints.semanticFingerprint(semanticKey)),
          answerContent: Value(answer),
          verificationStatus: VerificationStatus.reviewed.wireName,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

void main() {
  group('semantic fingerprint helper', () {
    test('same canonical key → same semantic fingerprint', () {
      expect(
        Fingerprints.semanticFingerprint('1+1'),
        Fingerprints.semanticFingerprint(' 1 + 1 '),
      );
    });

    test('different keys → different fingerprints', () {
      expect(
        Fingerprints.semanticFingerprint('1+1'),
        isNot(Fingerprints.semanticFingerprint('1+2')),
      );
    });
  });

  group('KnowledgeRetriever semantic path', () {
    late SubjectDatabase db;
    late KnowledgeRetrieverImpl retriever;

    setUp(() {
      db = SubjectDatabase.memory();
    });

    tearDown(() async {
      await db.close();
    });

    test('paraphrase matches via semantic key and locks stored answer', () async {
      await _seedEquation(
        db: db,
        questionId: 'q1',
        content: '1 + 1',
        answer: '1000',
        semanticKey: '1+1',
        aliases: const ['one plus one'],
      );

      retriever = KnowledgeRetrieverImpl(
        databaseManager: _MemoryDbManager(db),
        deepSeek: _FakeDeepSeek(liveSemanticKey: '1+1'),
      );

      final result = await retriever.retrieve(
        subjectId: 'sub1',
        question: const ParsedQuestion(
          questionType: QuestionType.textResponse,
          content: 'one plus one',
        ),
        limit: 10,
      );

      expect(result.candidates, isNotEmpty);
      final top = result.candidates.first;
      expect(top.questionId, 'q1');
      expect(top.highLexicalMatch, isTrue);
      expect(top.answerContent, '1000');

      final decision = const AnswerPrecedence().resolve(
        currentQuestion: const ParsedQuestion(
          questionType: QuestionType.textResponse,
          content: 'one plus one',
        ),
        candidates: result.candidates,
      );
      expect(decision.constraint?.fixed, isTrue);
      expect(decision.constraint?.answerContent, '1000');
    });

    test('meaning-match fallback promotes soft/FTS candidate', () async {
      await _seedEquation(
        db: db,
        questionId: 'q1',
        content: '1 + 1',
        answer: '1000',
        // No semantic key — FTS finds via aliases; meaning match promotes.
        aliases: const ['one plus one'],
      );

      retriever = KnowledgeRetrieverImpl(
        databaseManager: _MemoryDbManager(db),
        deepSeek: _FakeDeepSeek(
          liveSemanticKey: 'ADD(1,1)',
          storedSemanticKey: 'PLUS(1,1)', // backfill ≠ live → stage-3 miss
          matchId: 'q1',
          sameMeaning: true,
        ),
      );

      final result = await retriever.retrieve(
        subjectId: 'sub1',
        question: const ParsedQuestion(
          questionType: QuestionType.textResponse,
          content: 'one plus one',
        ),
        limit: 10,
      );

      expect(result.candidates, isNotEmpty);
      final top = result.candidates.firstWhere((c) => c.questionId == 'q1');
      expect(top.highLexicalMatch, isTrue);
      expect(top.answerContent, '1000');
    });
  });

  group('schema columns', () {
    test('memory database includes semantic columns', () async {
      final db = SubjectDatabase.memory();
      addTearDown(db.close);

      final rows = await db.customSelect("PRAGMA table_info('questions')").get();
      final names = rows.map((r) => r.read<String>('name')).toSet();
      expect(names.contains('semantic_key'), isTrue);
      expect(names.contains('semantic_fingerprint'), isTrue);
      expect(db.schemaVersion, 4);
    });
  });
}

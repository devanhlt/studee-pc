import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/core/utils/fingerprints.dart';
import 'package:studee_pc/core/utils/text_normalizer.dart';
import 'package:studee_pc/data/subject_database/subject_database.dart';
import 'package:studee_pc/domain/entities/parsed_choice.dart';
import 'package:studee_pc/domain/entities/parsed_question.dart';
import 'package:studee_pc/domain/entities/question_choice.dart';
import 'package:studee_pc/domain/entities/ranked_candidate.dart';
import 'package:studee_pc/domain/enums/question_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';
import 'package:studee_pc/domain/services/candidate_scorer.dart';
import 'package:studee_pc/domain/services/choice_mapper.dart';

/// Exercises fingerprint + choice remapping + scorer without opening the
/// full KnowledgeRetrieverImpl / SubjectDatabaseManager stack.
void main() {
  group('FTS and fingerprint retrieval path', () {
    late SubjectDatabase db;

    setUp(() {
      db = SubjectDatabase.memory();
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'reviewed Vietnamese question remaps label after choice reorder',
      () async {
        const questionText = 'Ma trận A khả nghịch khi nào?';
        const storedChoices = [
          ('A', 'định thức khác không'),
          ('B', 'det(A) = 0'),
          ('C', 'rank(A) < n'),
          ('D', 'A = 0'),
        ];
        // Current OCR presents same contents reordered — correct answer is C.
        const currentChoices = [
          ParsedChoice(label: 'A', content: 'det(A) = 0'),
          ParsedChoice(label: 'B', content: 'rank(A) < n'),
          ParsedChoice(label: 'C', content: 'định thức khác không'),
          ParsedChoice(label: 'D', content: 'A = 0'),
        ];

        final storedContents = storedChoices.map((c) => c.$2);
        final fingerprint = Fingerprints.questionFingerprint(
          questionText: questionText,
          choiceContents: storedContents,
        );
        final choiceSetFp = Fingerprints.choiceSetFingerprint(storedContents);
        final normalized = TextNormalizer.normalizeQuestionText(questionText);
        final now = DateTime.now().toUtc().millisecondsSinceEpoch;

        await db.into(db.sources).insert(
              SourcesCompanion.insert(
                id: 'src1',
                type: 'pdf',
                title: 'Đề thi mẫu',
                contentSha256: 'abc',
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
                content: questionText,
                normalizedContent: normalized,
                verificationStatus: VerificationStatus.reviewed.wireName,
                contentHash: Fingerprints.contentHash(questionText),
                createdAt: now,
                updatedAt: now,
              ),
            );
        await db.into(db.questions).insert(
              QuestionsCompanion.insert(
                id: 'q1',
                knowledgeUnitId: 'ku1',
                questionType: QuestionType.multipleChoice.wireName,
                content: questionText,
                normalizedContent: normalized,
                questionFingerprint: fingerprint,
                answerLabel: const Value('A'),
                answerContent: const Value('định thức khác không'),
                verificationStatus: VerificationStatus.reviewed.wireName,
                createdAt: now,
                updatedAt: now,
              ),
            );
        for (var i = 0; i < storedChoices.length; i++) {
          final (label, content) = storedChoices[i];
          await db.into(db.questionChoices).insert(
                QuestionChoicesCompanion.insert(
                  id: 'qc$i',
                  questionId: 'q1',
                  label: label,
                  content: content,
                  normalizedContent:
                      TextNormalizer.normalizeChoiceContent(content),
                  sortOrder: i,
                ),
              );
        }

        // Same stem + same choice-set FP despite label reorder.
        final currentFp = Fingerprints.choiceSetFingerprint(
          currentChoices.map((c) => c.content),
        );
        expect(currentFp, choiceSetFp);

        final currentQuestion = ParsedQuestion(
          questionType: QuestionType.multipleChoice,
          content: questionText,
          choices: currentChoices,
        );

        // Simulate retriever remapping step.
        const mapper = ChoiceMapper();
        final mapped = mapper.mapStoredAnswer(
          storedAnswerContent: 'định thức khác không',
          storedAnswerLabel: 'A',
          currentQuestion: currentQuestion,
        );
        expect(mapped, isNotNull);
        expect(mapped!.label, 'C');
        expect(mapped.label, isNot('A'));

        final choiceRows = await (db.select(db.questionChoices)
              ..where((c) => c.questionId.equals('q1')))
            .get();
        final storedAsDomain = choiceRows
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

        final candidate = RankedCandidate(
          localId: 'q1',
          questionId: 'q1',
          content: questionText,
          normalizedContent: normalized,
          answerLabel: mapped.label,
          answerContent: mapped.content,
          choices: storedAsDomain,
          verificationStatus: VerificationStatus.reviewed,
          score: 0,
          choiceSetFingerprint: choiceSetFp,
        );

        const scorer = CandidateScorer();
        final scored = scorer.scoreAndFilter(
          question: currentQuestion,
          candidates: [candidate],
        );
        expect(scored, isNotEmpty);
        expect(scored.first.exactFingerprintMatch, isTrue);
        expect(scored.first.answerLabel, 'C');

        // FTS can find the Vietnamese stem when present.
        final fts = await db.searchQuestionsFts('khả nghịch', limit: 5);
        expect(fts, isNotEmpty);
        expect(fts.first.id, 'q1');
        expect(fts.first.verificationStatus, 'reviewed');
      },
    );

    test('scorer rejects rejected verification status', () {
      const scorer = CandidateScorer();
      final question = ParsedQuestion(
        questionType: QuestionType.multipleChoice,
        content: 'Câu hỏi?',
        choices: const [
          ParsedChoice(label: 'A', content: 'một'),
          ParsedChoice(label: 'B', content: 'hai'),
        ],
      );
      final rejected = RankedCandidate(
        localId: 'r1',
        questionId: 'r1',
        content: 'Câu hỏi?',
        verificationStatus: VerificationStatus.rejected,
        score: 1.0,
        answerContent: 'một',
        choices: const [
          QuestionChoice(
            id: '1',
            questionId: 'r1',
            label: 'A',
            content: 'một',
            normalizedContent: 'một',
            sortOrder: 0,
          ),
          QuestionChoice(
            id: '2',
            questionId: 'r1',
            label: 'B',
            content: 'hai',
            normalizedContent: 'hai',
            sortOrder: 1,
          ),
        ],
      );
      expect(
        scorer.scoreAndFilter(question: question, candidates: [rejected]),
        isEmpty,
      );
    });
  });
}

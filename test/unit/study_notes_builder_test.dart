import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/domain/entities/question.dart';
import 'package:studee_pc/domain/entities/question_choice.dart';
import 'package:studee_pc/domain/enums/question_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';
import 'package:studee_pc/features/subjects/application/study_notes_builder.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1);

  Question q({
    required String id,
    String? number,
    required QuestionType type,
    required String content,
    String? answerLabel,
    String? answerContent,
    String? explanation,
    List<QuestionChoice> choices = const [],
  }) {
    return Question(
      id: id,
      knowledgeUnitId: 'ku',
      questionNumber: number,
      questionType: type,
      content: content,
      normalizedContent: content.toLowerCase(),
      questionFingerprint: id,
      answerLabel: answerLabel,
      answerContent: answerContent,
      explanation: explanation,
      verificationStatus: VerificationStatus.unreviewed,
      createdAt: t0,
      updatedAt: t0,
      choices: choices,
    );
  }

  test('uses answer meaning not letter; includes tip; no choice list', () {
    final md = buildStudyNotesMarkdown(
      subjectName: 'Toán',
      tipsByQuestionId: const {'1': 'Nhớ: 2 cặp 2 thành 4'},
      questions: [
        q(
          id: '1',
          number: '2',
          type: QuestionType.multipleChoice,
          content: '2 + 2 = ?',
          answerLabel: 'B',
          answerContent: 'B',
          explanation: 'dài — không xuất',
          choices: const [
            QuestionChoice(
              id: 'c1',
              questionId: '1',
              label: 'A',
              content: '3',
              normalizedContent: '3',
              sortOrder: 0,
            ),
            QuestionChoice(
              id: 'c2',
              questionId: '1',
              label: 'B',
              content: '4',
              normalizedContent: '4',
              sortOrder: 1,
            ),
          ],
        ),
      ],
    );

    expect(md, contains('# Toán — nhớ đáp án'));
    expect(md, contains('**TUYÊN BỐ MIỄN TRỪ TRÁCH NHIỆM**'));
    expect(
      md.indexOf('**TUYÊN BỐ MIỄN TRỪ TRÁCH NHIỆM**'),
      lessThan(md.indexOf('**Hỏi:**')),
    );
    expect(md, contains('**Hỏi:** 2 + 2 = ?'));
    expect(md, contains('**Đáp:** 4'));
    expect(md, contains('**Mẹo:** Nhớ: 2 cặp 2 thành 4'));
    expect(md, isNot(contains('A. 3')));
    expect(md, isNot(contains('**Đáp:** B')));
    expect(md, isNot(contains('Loại')));
    expect(md, isNot(contains('không xuất')));
  });

  test('text response uses answer content + tip', () {
    final md = buildStudyNotesMarkdown(
      subjectName: 'Văn',
      tipsByQuestionId: const {'t': 'Hà Nội — thủ đô từ lâu'},
      questions: [
        q(
          id: 't',
          type: QuestionType.textResponse,
          content: 'Thủ đô Việt Nam?',
          answerContent: 'Hà Nội',
        ),
      ],
    );

    expect(md, contains('**Đáp:** Hà Nội'));
    expect(md, contains('**Mẹo:** Hà Nội — thủ đô từ lâu'));
  });

  test('missing answer shows (chưa có)', () {
    final md = buildStudyNotesMarkdown(
      subjectName: 'X',
      questions: [
        q(
          id: 'm',
          type: QuestionType.textResponse,
          content: 'Câu hỏi chưa có đáp án',
        ),
      ],
    );
    expect(md, contains('**Đáp:** (chưa có)'));
  });

  test('answerMeaning resolves label via choices', () {
    final question = q(
      id: '1',
      type: QuestionType.multipleChoice,
      content: 'Q',
      answerLabel: 'C',
      choices: const [
        QuestionChoice(
          id: 'c',
          questionId: '1',
          label: 'C',
          content: 'Đáp án đúng chi tiết',
          normalizedContent: 'dap an dung chi tiet',
          sortOrder: 2,
        ),
      ],
    );
    expect(
      StudyNotesBuilder.answerMeaning(question),
      'Đáp án đúng chi tiết',
    );
  });
}

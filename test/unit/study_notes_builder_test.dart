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
      knowledgeSummaryMarkdown: '- Cộng hai số cùng dấu',
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
    expect(md, contains('## Lý thuyết'));
    expect(md, contains('- Cộng hai số cùng dấu'));
    expect(md, contains('## Danh sách câu hỏi'));
    expect(
      md.indexOf('## Lý thuyết'),
      lessThan(md.indexOf('## Danh sách câu hỏi')),
    );
    expect(
      md.indexOf('## Danh sách câu hỏi'),
      lessThan(md.indexOf('**Hỏi:**')),
    );
    expect(md, contains('### 2'));
    expect(md, contains('**Hỏi:**'));
    expect(md, contains('2 + 2 = ?'));
    expect(md, contains('**Đáp:**'));
    expect(md, contains('4'));
    expect(md, contains('**Mẹo:** Nhớ: 2 cặp 2 thành 4'));
    expect(md, isNot(contains('A. 3')));
    expect(md, isNot(contains('**Đáp:** B')));
    expect(md, isNot(contains('Loại')));
    expect(md, isNot(contains('không xuất')));
  });

  test('wraps C program questions in fenced code blocks', () {
    final md = buildStudyNotesMarkdown(
      subjectName: 'KTLT',
      questions: [
        q(
          id: '1',
          type: QuestionType.textResponse,
          content:
              'Khi chạy chương trình sau thì kết quả là gì? #include<stdio.h> int main() { int a[] = {2,1}; printf("%d", *a); return 0; }',
          answerContent: '2',
        ),
      ],
    );

    expect(md, contains('```c'));
    expect(md, contains('#include'));
    expect(md, contains('int main()'));
    expect(md, contains('```'));
    expect(md, contains('Khi chạy chương trình sau'));
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

    expect(md, contains('**Đáp:**'));
    expect(md, contains('Hà Nội'));
    expect(md, contains('**Mẹo:** Hà Nội — thủ đô từ lâu'));
  });

  test('omits summary section when markdown empty; still has question list title',
      () {
    final md = buildStudyNotesMarkdown(
      subjectName: 'X',
      knowledgeSummaryMarkdown: '  ',
      questions: [
        q(
          id: 'm',
          type: QuestionType.textResponse,
          content: 'Câu hỏi chưa có đáp án',
        ),
      ],
    );
    expect(md, isNot(contains('## Lý thuyết')));
    expect(md, contains('## Danh sách câu hỏi'));
    expect(md, contains('**Đáp:**'));
    expect(md, contains('(chưa có)'));
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

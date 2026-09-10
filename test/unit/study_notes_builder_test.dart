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

  test('document is title + disclaimer + insights only', () {
    final md = buildStudyNotesMarkdown(
      subjectName: 'Toán',
      insightsMarkdown: '''
### Tổng quan
Có 12 câu về cộng trừ.

### Nhóm: Cộng hai số
**Thống kê:** 5 câu.
**Nhận xét:** Cộng cùng dấu giữ dấu.
**Ví dụ:** 2 + 2 → 4
''',
    );

    expect(md, contains('# Toán — thống kê & nhận xét'));
    expect(md, contains('**TUYÊN BỐ MIỄN TRỪ TRÁCH NHIỆM**'));
    expect(md, contains('### Tổng quan'));
    expect(md, contains('Có 12 câu về cộng trừ.'));
    expect(md, contains('**Ví dụ:** 2 + 2 → 4'));
    expect(md, isNot(contains('## Lý thuyết')));
    expect(md, isNot(contains('## Danh sách câu hỏi')));
    expect(md, isNot(contains('**Hỏi:**')));
    expect(md, isNot(contains('**Đáp:**')));
    expect(md, isNot(contains('**Mẹo:**')));
  });

  test('omits body when insights empty; keeps disclaimer', () {
    final md = buildStudyNotesMarkdown(
      subjectName: 'X',
      insightsMarkdown: '  ',
    );
    expect(md, contains('# X — thống kê & nhận xét'));
    expect(md, contains('**TUYÊN BỐ MIỄN TRỪ TRÁCH NHIỆM**'));
    expect(md, isNot(contains('## Lý thuyết')));
    expect(md, isNot(contains('## Danh sách câu hỏi')));
  });

  test('strips duplicate outer section headings from insights', () {
    final md = buildStudyNotesMarkdown(
      subjectName: 'KTLT',
      insightsMarkdown: '''
## Lý thuyết
### Con trỏ
Insight về *a.
''',
    );
    expect(md, isNot(contains('## Lý thuyết')));
    expect(md, contains('### Con trỏ'));
    expect(md, contains('Insight về *a.'));
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

  test('countExportable ignores empty stems', () {
    expect(
      StudyNotesBuilder.countExportable([
        q(id: '1', type: QuestionType.textResponse, content: 'Có nội dung'),
        q(id: '2', type: QuestionType.textResponse, content: '   '),
      ]),
      1,
    );
  });
}

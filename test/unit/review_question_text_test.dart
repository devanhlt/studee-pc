import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/domain/entities/question.dart';
import 'package:studee_pc/domain/entities/question_choice.dart';
import 'package:studee_pc/domain/enums/question_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';
import 'package:studee_pc/features/review/application/review_question_text.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1);

  Question q({
    String? number,
    required String content,
    List<QuestionChoice> choices = const [],
    String? answerLabel,
    String? answerContent,
  }) {
    return Question(
      id: 'q1',
      knowledgeUnitId: 'ku',
      questionNumber: number,
      questionType: QuestionType.multipleChoice,
      content: content,
      normalizedContent: content.toLowerCase(),
      questionFingerprint: 'fp',
      answerLabel: answerLabel,
      answerContent: answerContent,
      verificationStatus: VerificationStatus.unreviewed,
      createdAt: t0,
      updatedAt: t0,
      choices: choices,
    );
  }

  test('formats stem, number, and choices without leaking the answer', () {
    final text = formatReviewQuestion(
      q(
        number: '2',
        content: 'Tính 2 + 2',
        answerLabel: 'B',
        answerContent: '4',
        choices: const [
          QuestionChoice(
            id: 'c1',
            questionId: 'q1',
            label: 'A',
            content: '3',
            normalizedContent: '3',
            sortOrder: 0,
          ),
          QuestionChoice(
            id: 'c2',
            questionId: 'q1',
            label: 'B',
            content: '4',
            normalizedContent: '4',
            sortOrder: 1,
          ),
        ],
      ),
    );

    expect(text, startsWith('Câu 2\nTính 2 + 2'));
    expect(text, contains('A. 3'));
    expect(text, contains('B. 4'));
    expect(text, isNot(contains('Đáp án')));
    expect(text.split('\n').first, 'Câu 2');
  });

  test('falls back to 1-based index when the question has no number', () {
    final text = formatReviewQuestion(
      q(content: 'Khai triển (x+1)^2'),
      number: 3,
    );
    expect(text, 'Câu 3\nKhai triển (x+1)^2');
  });
}

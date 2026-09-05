import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/domain/entities/parsed_choice.dart';
import 'package:studee_pc/domain/entities/parsed_question.dart';
import 'package:studee_pc/domain/enums/question_type.dart';
import 'package:studee_pc/domain/services/choice_mapper.dart';

void main() {
  const mapper = ChoiceMapper();

  group('ChoiceMapper Vietnamese MC', () {
    const storedAnswerA = 'định thức khác không';

    final currentChoices = const [
      ParsedChoice(label: 'A', content: 'det(A) = 0'),
      ParsedChoice(label: 'B', content: 'rank(A) < n'),
      ParsedChoice(label: 'C', content: 'định thức khác không'),
      ParsedChoice(label: 'D', content: 'A = 0'),
    ];

    final currentQuestion = ParsedQuestion(
      questionType: QuestionType.multipleChoice,
      content: 'Ma trận A khả nghịch khi nào?',
      choices: currentChoices,
    );

    test('maps stored answer content to current label C, never A', () {
      final label = mapper.mapAnswerContentToCurrentLabel(
        storedAnswerContent: storedAnswerA,
        currentChoices: currentChoices,
      );
      expect(label, 'C');
      expect(label, isNot('A'));

      final mapped = mapper.mapStoredAnswer(
        storedAnswerContent: storedAnswerA,
        storedAnswerLabel: 'A', // stored as A — must be ignored
        currentQuestion: currentQuestion,
      );
      expect(mapped, isNotNull);
      expect(mapped!.label, 'C');
      expect(mapped.content, 'định thức khác không');
      expect(mapped.ignoredStoredLabel, 'A');
      expect(mapped.matchedByContent, isTrue);
    });

    test('ignores A./B) prefix when matching answer content', () {
      final label = mapper.mapAnswerContentToCurrentLabel(
        storedAnswerContent: 'A. định thức khác không',
        currentChoices: currentChoices,
      );
      expect(label, 'C');
    });

    test('also maps det(A) khác không style content to current label', () {
      final reordered = const [
        ParsedChoice(label: 'A', content: 'A = 0'),
        ParsedChoice(label: 'B', content: 'det(A) = 0'),
        ParsedChoice(label: 'C', content: 'det(A) khác không'),
        ParsedChoice(label: 'D', content: 'rank(A) < n'),
      ];
      final label = mapper.mapAnswerContentToCurrentLabel(
        storedAnswerContent: 'det(A) khác không',
        currentChoices: reordered,
      );
      expect(label, 'C');
    });

    test('maps LaTeX-drifted choice content', () {
      final choices = const [
        ParsedChoice(label: 'A', content: r'$x_1=3; x_2=-3; x_3=-2$'),
        ParsedChoice(label: 'B', content: r'$x_1=1; x_2=2; x_3=3$'),
      ];
      final label = mapper.mapAnswerContentToCurrentLabel(
        storedAnswerContent: 'x1=3; x2=-3; x3=-2',
        currentChoices: choices,
      );
      expect(label, 'A');
    });

    test('content label lookup null when unmatched; map keeps stored text', () {
      expect(
        mapper.mapAnswerContentToCurrentLabel(
          storedAnswerContent: 'không có trong danh sách',
          currentChoices: currentChoices,
        ),
        isNull,
      );
      final mapped = mapper.mapStoredAnswer(
        storedAnswerContent: 'không có trong danh sách',
        storedAnswerLabel: 'A',
        currentQuestion: currentQuestion,
      );
      expect(mapped, isNotNull);
      expect(mapped!.content, 'không có trong danh sách');
      expect(mapped.label, 'A');
      expect(mapped.matchedByContent, isFalse);
    });

    test('does not remap by stored letter onto current choice body alone', () {
      final mapped = mapper.mapStoredAnswer(
        storedAnswerContent: 'nội dung sai lệch hoàn toàn',
        storedAnswerLabel: 'C',
        currentQuestion: currentQuestion,
      );
      // Keep stored text; do not replace with current C body (reorder-safe).
      expect(mapped, isNotNull);
      expect(mapped!.content, 'nội dung sai lệch hoàn toàn');
      expect(mapped.label, 'C');
      expect(mapped.matchedByContent, isFalse);
    });

    test('null/empty stored content → null', () {
      expect(
        mapper.mapAnswerContentToCurrentLabel(
          storedAnswerContent: null,
          currentChoices: currentChoices,
        ),
        isNull,
      );
      expect(
        mapper.mapAnswerContentToCurrentLabel(
          storedAnswerContent: '   ',
          currentChoices: currentChoices,
        ),
        isNull,
      );
    });
  });
}

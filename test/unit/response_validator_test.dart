import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/domain/entities/answer_constraint.dart';
import 'package:studee_pc/domain/entities/deepseek_answer_response.dart';
import 'package:studee_pc/domain/entities/evidence_item.dart';
import 'package:studee_pc/domain/entities/evidence_package.dart';
import 'package:studee_pc/domain/entities/parsed_choice.dart';
import 'package:studee_pc/domain/entities/parsed_question.dart';
import 'package:studee_pc/domain/enums/knowledge_unit_type.dart';
import 'package:studee_pc/domain/enums/question_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';
import 'package:studee_pc/data/deepseek/response_validator.dart';

EvidencePackage _package({
  AnswerConstraint constraint = AnswerConstraint.none,
  List<String> evidenceIds = const ['ev_001', 'ev_002'],
  List<ParsedChoice> choices = const [
    ParsedChoice(label: 'A', content: 'det(A) = 0'),
    ParsedChoice(label: 'B', content: 'rank(A) < n'),
    ParsedChoice(label: 'C', content: 'định thức khác không'),
    ParsedChoice(label: 'D', content: 'A = 0'),
  ],
  QuestionType questionType = QuestionType.multipleChoice,
}) {
  return EvidencePackage(
    currentQuestion: ParsedQuestion(
      questionType: questionType,
      content: 'Ma trận A khả nghịch khi nào?',
      choices: choices,
    ),
    answerConstraint: constraint,
    evidence: [
      for (final id in evidenceIds)
        EvidenceItem(
          evidenceId: id,
          localId: 'local_$id',
          type: KnowledgeUnitType.question,
          content: 'bằng chứng $id',
          verificationStatus: VerificationStatus.reviewed,
        ),
    ],
  );
}

DeepSeekAnswerResponse _response({
  String? label = 'C',
  String? content = 'định thức khác không',
  List<String> used = const ['ev_001'],
  QuestionType type = QuestionType.multipleChoice,
}) {
  return DeepSeekAnswerResponse(
    questionType: type,
    finalAnswerLabel: label,
    finalAnswerContent: content,
    shortAnswer: label,
    explanationMarkdown: 'Giải thích ngắn.',
    usedEvidenceIds: used,
  );
}

void main() {
  const validator = ResponseValidator();

  group('ResponseValidator', () {
    test('strips invented evidence ids instead of failing', () {
      final result = validator.validate(
        response: _response(used: const ['ev_001', 'ev_999']),
        package: _package(),
      );
      expect(result, isA<Success<DeepSeekAnswerResponse>>());
      final value = (result as Success<DeepSeekAnswerResponse>).value;
      expect(value.usedEvidenceIds, ['ev_001']);
      expect(value.warnings.any((w) => w.contains('ev_999')), isTrue);
    });

    test('rejects wrong MC label when choices exist', () {
      final result = validator.validate(
        response: _response(label: 'Z', content: 'không tồn tại'),
        package: _package(),
      );
      expect(result, isA<Failure<DeepSeekAnswerResponse>>());
      final errors = validator.collectErrors(
        response: _response(label: 'Z', content: 'không tồn tại'),
        package: _package(),
      );
      expect(errors.any((e) => e.startsWith('mc_label_not_found')), isTrue);
    });

    test('fixed constraint coerces wrong label/content instead of failing', () {
      final package = _package(
        constraint: const AnswerConstraint(
          fixed: true,
          answerLabel: 'C',
          answerContent: 'định thức khác không',
        ),
      );

      final coerced = validator.validate(
        response: _response(label: 'A', content: 'det(A) = 0'),
        package: package,
      );
      expect(coerced, isA<Success<DeepSeekAnswerResponse>>());
      final value = (coerced as Success<DeepSeekAnswerResponse>).value;
      expect(value.finalAnswerLabel, 'C');
      expect(value.finalAnswerContent, 'định thức khác không');
      expect(value.modelKnowledgeUsed, isFalse);
    });

    test('accepts valid response', () {
      final package = _package(
        constraint: const AnswerConstraint(
          fixed: true,
          answerLabel: 'C',
          answerContent: 'định thức khác không',
        ),
      );
      final result = validator.validate(
        response: _response(),
        package: package,
      );
      expect(result, isA<Success<DeepSeekAnswerResponse>>());
      final value = (result as Success<DeepSeekAnswerResponse>).value;
      expect(value.finalAnswerLabel, 'C');
      expect(value.finalAnswerContent, 'định thức khác không');
    });

    test('coerces label/content mismatch instead of rejecting', () {
      final result = validator.validate(
        response: _response(label: 'C', content: 'A. định thức khác không'),
        package: _package(),
      );
      expect(result, isA<Success<DeepSeekAnswerResponse>>());
      final value = (result as Success<DeepSeekAnswerResponse>).value;
      expect(value.finalAnswerLabel, 'C');
      expect(value.finalAnswerContent, 'định thức khác không');
    });

    test('remaps by content when label and body disagree', () {
      final result = validator.validate(
        response: _response(label: 'C', content: 'det(A) = 0'),
        package: _package(),
      );
      expect(result, isA<Success<DeepSeekAnswerResponse>>());
      final value = (result as Success<DeepSeekAnswerResponse>).value;
      expect(value.finalAnswerLabel, 'A');
      expect(value.finalAnswerContent, 'det(A) = 0');
    });

    test('collectErrors empty when mismatch is coercible', () {
      final errors = validator.collectErrors(
        response: _response(label: 'C', content: 'det(A) = 0'),
        package: _package(),
      );
      expect(errors, isEmpty);
    });

    test('text question without choices accepts answer without MC label', () {
      final package = _package(
        choices: const [],
        questionType: QuestionType.textResponse,
      );
      final result = validator.validate(
        response: _response(
          label: null,
          content: 'x1=3; x2=-3; x3=-2',
          type: QuestionType.multipleChoice, // model mis-types — still OK
        ),
        package: package,
      );
      expect(result, isA<Success<DeepSeekAnswerResponse>>());
    });
  });
}

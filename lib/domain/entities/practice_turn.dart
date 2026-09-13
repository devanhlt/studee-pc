import 'package:equatable/equatable.dart';

/// One OpenAI-style chat message for multi-turn practice.
class PracticeLlmMessage extends Equatable {
  const PracticeLlmMessage({
    required this.role,
    required this.content,
  });

  final String role; // system | user | assistant
  final String content;

  Map<String, String> toApiMap() => {'role': role, 'content': content};

  @override
  List<Object?> get props => [role, content];
}

/// A/B choice for a practice check question.
class PracticeChoice extends Equatable {
  const PracticeChoice({
    required this.label,
    required this.content,
  });

  final String label;
  final String content;

  String get display => '$label. $content';

  Map<String, dynamic> toJson() => {
        'label': label,
        'content': content,
      };

  factory PracticeChoice.fromJson(Map<String, dynamic> json) {
    return PracticeChoice(
      label: (json['label'] ?? '').toString().trim().toUpperCase(),
      content: (json['content'] ?? '').toString().trim(),
    );
  }

  @override
  List<Object?> get props => [label, content];
}

/// Evaluation of the user's answer to a check question.
class PracticeEvaluation extends Equatable {
  const PracticeEvaluation({
    required this.correct,
    required this.feedback,
  });

  final bool correct;
  final String feedback;

  factory PracticeEvaluation.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PracticeEvaluation(correct: false, feedback: '');
    }
    return PracticeEvaluation(
      correct: json['correct'] == true,
      feedback: (json['feedback'] ?? '').toString().trim(),
    );
  }

  @override
  List<Object?> get props => [correct, feedback];
}

/// Structured practice turn from DeepSeek.
class PracticeTurnResponse extends Equatable {
  const PracticeTurnResponse({
    required this.coachMessage,
    this.checkQuestion,
    this.checkChoices = const [],
    this.correctLabel,
    this.evaluation,
    this.reveal,
    required this.isComplete,
    this.finalSummary,
    this.mcqTip,
    this.rawJson,
  });

  final String coachMessage;
  final String? checkQuestion;
  /// Exactly two choices (A/B) when a check question is active.
  final List<PracticeChoice> checkChoices;
  /// "A" or "B" when [checkChoices] are present.
  final String? correctLabel;
  final PracticeEvaluation? evaluation;
  final String? reveal;
  final bool isComplete;
  final String? finalSummary;
  /// LLM tip for quick MCQ selection (usually on complete).
  final String? mcqTip;
  final String? rawJson;

  factory PracticeTurnResponse.fromJson(
    Map<String, dynamic> json, {
    String? rawJson,
  }) {
    final check = json['check_question'];
    final summary = json['final_summary'];
    final tip = json['mcq_tip'] ?? json['tip'];
    final reveal = json['reveal'];
    final evalRaw = json['evaluation'];
    final choicesRaw = json['check_choices'] ?? json['choices'];
    final choices = <PracticeChoice>[];
    if (choicesRaw is List) {
      for (final item in choicesRaw) {
        if (item is Map) {
          final c = PracticeChoice.fromJson(Map<String, dynamic>.from(item));
          if (c.label.isNotEmpty && c.content.isNotEmpty) {
            choices.add(c);
          }
        }
      }
    }
    // Prefer first two; normalize labels to A/B when missing.
    final normalized = <PracticeChoice>[];
    for (var i = 0; i < choices.length && normalized.length < 2; i++) {
      final c = choices[i];
      final label = c.label.isEmpty
          ? (i == 0 ? 'A' : 'B')
          : (c.label == 'A' || c.label == 'B' ? c.label : (i == 0 ? 'A' : 'B'));
      normalized.add(PracticeChoice(label: label, content: c.content));
    }

    String? nullableTrim(Object? v) {
      if (v == null || '$v' == 'null') return null;
      final t = '$v'.trim();
      return t.isEmpty ? null : t;
    }

    var correctLabel = nullableTrim(
      json['correct_label'] ?? json['answer_label'],
    )?.toUpperCase();
    if (correctLabel != 'A' && correctLabel != 'B') {
      correctLabel = null;
    }
    // If missing, infer from answer_content match against choices.
    if (correctLabel == null) {
      final answerContent = nullableTrim(
        json['answer_content'] ?? json['correct_content'],
      );
      if (answerContent != null) {
        for (final c in normalized) {
          if (c.content == answerContent ||
              answerContent.contains(c.content) ||
              c.content.contains(answerContent)) {
            correctLabel = c.label;
            break;
          }
        }
      }
    }

    return PracticeTurnResponse(
      coachMessage: (json['coach_message'] ?? '').toString().trim(),
      checkQuestion: nullableTrim(check),
      checkChoices: normalized,
      correctLabel: correctLabel,
      evaluation: evalRaw is Map
          ? PracticeEvaluation.fromJson(Map<String, dynamic>.from(evalRaw))
          : null,
      reveal: nullableTrim(reveal),
      isComplete: json['is_complete'] == true,
      finalSummary: nullableTrim(summary),
      mcqTip: nullableTrim(tip),
      rawJson: rawJson,
    );
  }

  @override
  List<Object?> get props => [
        coachMessage,
        checkQuestion,
        checkChoices,
        correctLabel,
        evaluation,
        reveal,
        isComplete,
        finalSummary,
        mcqTip,
      ];
}

/// UI-facing bubble in the practice transcript.
enum PracticeMessageRole { coach, user, feedback, system }

class PracticeUiMessage extends Equatable {
  const PracticeUiMessage({
    required this.id,
    required this.role,
    required this.text,
  });

  final String id;
  final PracticeMessageRole role;
  final String text;

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'text': text,
      };

  factory PracticeUiMessage.fromJson(Map<String, dynamic> json) {
    final roleName = (json['role'] ?? 'coach').toString();
    final role = PracticeMessageRole.values.firstWhere(
      (r) => r.name == roleName,
      orElse: () => PracticeMessageRole.coach,
    );
    return PracticeUiMessage(
      id: (json['id'] ?? '').toString(),
      role: role,
      text: (json['text'] ?? '').toString(),
    );
  }

  @override
  List<Object?> get props => [id, role, text];
}

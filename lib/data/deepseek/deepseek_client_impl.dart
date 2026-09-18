import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/data/deepseek/cancel_token.dart';
import 'package:studee_pc/data/deepseek/deepseek_config.dart';
import 'package:studee_pc/data/deepseek/prompts.dart';
import 'package:studee_pc/domain/entities/deepseek_answer_response.dart';
import 'package:studee_pc/domain/entities/evidence_item.dart';
import 'package:studee_pc/domain/entities/evidence_package.dart';
import 'package:studee_pc/domain/entities/parsed_choice.dart';
import 'package:studee_pc/domain/entities/parsed_question.dart';
import 'package:studee_pc/domain/entities/practice_turn.dart';
import 'package:studee_pc/domain/enums/question_type.dart';
import 'package:studee_pc/domain/repositories/credentials_repository.dart';
import 'package:studee_pc/domain/repositories/deepseek_client.dart';

/// HTTP DeepSeek client with exponential backoff and structured JSON validation.
///
/// Never logs API keys, full prompts, or study content.
class DeepSeekClientImpl implements DeepSeekClient {
  DeepSeekClientImpl({
    required CredentialsRepository credentials,
    http.Client? httpClient,
    String? baseUrl,
    this.model = DeepSeekConfig.model,
  })  : _credentials = credentials,
        _http = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? DeepSeekConfig.baseUrl;

  final CredentialsRepository _credentials;
  final http.Client _http;
  final String baseUrl;
  final String model;
  final AppLogger _log = AppLogger('DeepSeekClient');

  /// Optional token checked during in-flight requests.
  CancelToken? activeCancelToken;

  Uri get _chatUri => Uri.parse('$baseUrl${DeepSeekConfig.chatCompletionsPath}');

  @override
  Future<StructureSourceResponse> structureSource(
    StructureSourceRequest request,
  ) async {
    final version =
        request.promptVersion ?? DeepSeekPrompts.sourceStructuringVersion;
    final userPayload = {
      'source_id': request.sourceId,
      'language': request.language,
      if (request.subjectName != null &&
          request.subjectName!.trim().isNotEmpty)
        'subject_name': request.subjectName!.trim(),
      if (request.formatKind != null && request.formatKind!.trim().isNotEmpty)
        'format_kind': request.formatKind!.trim(),
      'pages': request.pageTexts
          .map((p) => {'page_number': p.pageNumber, 'text': p.text})
          .toList(),
    };

    final raw = await _chatJson(
      systemPrompt: DeepSeekPrompts.sourceStructuringSystem(
        subjectName: request.subjectName,
        formatKind: request.formatKind,
      ),
      userContent: jsonEncode(userPayload),
      promptVersion: version,
      maxTokensOverride: DeepSeekConfig.structuringMaxTokens,
    );

    final map = _requireJsonObject(raw);
    final units = (map['knowledge_units'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final questions = (map['questions'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final relations = (map['relations'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return StructureSourceResponse(
      knowledgeUnits: units,
      questions: questions,
      relations: relations,
      promptVersion: version,
      rawJson: raw,
    );
  }

  @override
  Future<ParsedQuestion> parseQuestion(ParseQuestionRequest request) async {
    final version =
        request.promptVersion ?? DeepSeekPrompts.questionParsingVersion;
    final raw = await _chatJson(
      systemPrompt: DeepSeekPrompts.questionParsingSystem(),
      userContent: jsonEncode({
        'language': request.language,
        'raw_text': request.rawText,
      }),
      promptVersion: version,
    );

    final map = _requireJsonObject(raw);
    final choices = (map['choices'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (c) => ParsedChoice(
            label: (c['label'] ?? '').toString(),
            content: (c['content'] ?? '').toString(),
          ),
        )
        .where((c) => c.label.isNotEmpty || c.content.isNotEmpty)
        .toList();

    return ParsedQuestion(
      questionType: QuestionType.fromWire(
        map['question_type'] as String? ??
            (choices.isEmpty ? 'text_response' : 'multiple_choice'),
      ),
      content: (map['content'] as String? ?? request.rawText).trim(),
      choices: choices,
      missingInformation: map['missing_information'] as bool? ?? false,
      warnings: (map['warnings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  @override
  Future<DeepSeekAnswerResponse> generateAnswer(
    GenerateAnswerRequest request,
  ) async {
    final version =
        request.promptVersion ?? DeepSeekPrompts.groundedAnswerVersion;
    final raw = await _chatJson(
      systemPrompt: DeepSeekPrompts.groundedAnswerSystem(),
      userContent: jsonEncode(_evidencePackagePayload(request.evidencePackage)),
      promptVersion: version,
    );

    final parsed = _parseAnswer(raw);
    // Leave validation to SolveService so it can attempt one repair pass.
    return parsed;
  }

  @override
  Future<DeepSeekAnswerResponse> repairResponse(
    RepairResponseRequest request,
  ) async {
    final version = request.promptVersion ?? DeepSeekPrompts.repairVersion;
    final raw = await _chatJson(
      systemPrompt: DeepSeekPrompts.repairSystem(),
      userContent: jsonEncode({
        'validation_errors': request.validationErrors,
        'invalid_response': request.invalidResponse,
        'evidence_package':
            _evidencePackagePayload(request.evidencePackage),
      }),
      promptVersion: version,
    );

    return _parseAnswer(raw);
  }

  @override
  Future<Map<String, String>> generateMemorizationTips(
    List<StudyTipItem> items,
  ) async {
    if (items.isEmpty) return {};

    const batchSize = 12;
    final out = <String, String>{};
    for (var i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      final batch = items.sublist(i, end);
      final version = DeepSeekPrompts.memorizationTipsVersion;
      final userPayload = {
        'items': [
          for (final item in batch)
            {
              'id': item.id,
              'question': item.question,
              'answer': item.answer,
            },
        ],
      };
      final raw = await _chatJson(
        systemPrompt: DeepSeekPrompts.memorizationTipsSystem(),
        userContent: jsonEncode(userPayload),
        promptVersion: version,
        maxTokensOverride: DeepSeekConfig.structuringMaxTokens,
      );
      out.addAll(_parseTips(raw, expectedIds: batch.map((e) => e.id).toSet()));
    }
    return out;
  }

  Map<String, String> _parseTips(
    String raw, {
    required Set<String> expectedIds,
  }) {
    final map = _requireJsonObject(raw);
    final tips = map['tips'];
    final out = <String, String>{};
    if (tips is! List) {
      throw const UnknownFailure(
        userMessage: 'Phản hồi mẹo nhớ không đúng định dạng JSON.',
        code: 'memorization_tips_schema',
      );
    }
    for (final entry in tips) {
      if (entry is! Map) continue;
      final id = entry['id']?.toString();
      final tip = '${entry['tip'] ?? ''}'.trim();
      if (id == null || tip.isEmpty) continue;
      if (!expectedIds.contains(id)) continue;
      // Drop letter-only tips if the model slips.
      if (RegExp(r'^(đáp án\s*(là|=)\s*)?[A-Da-d]\.?$', caseSensitive: false)
          .hasMatch(tip)) {
        continue;
      }
      out[id] = tip;
    }
    return out;
  }

  @override
  Future<String> generateMcqStrategyTip({
    required String question,
    required List<String> choices,
    String? correctAnswer,
  }) async {
    final userPayload = {
      'question': question,
      'choices': choices,
      if (correctAnswer != null && correctAnswer.trim().isNotEmpty)
        'correct_answer_content': correctAnswer.trim(),
    };
    final raw = await _chatJson(
      systemPrompt: DeepSeekPrompts.mcqStrategyTipSystem(),
      userContent: jsonEncode(userPayload),
      promptVersion: DeepSeekPrompts.mcqStrategyTipVersion,
      maxTokensOverride: 512,
    );
    final map = _requireJsonObject(raw);
    var tip = '${map['tip'] ?? map['mcq_tip'] ?? ''}'.trim();
    if (tip.isEmpty) {
      throw const UnknownFailure(
        userMessage: 'Phản hồi mẹo không có nội dung.',
        code: 'mcq_strategy_tip_empty',
      );
    }
    if (!tip.startsWith('Mẹo:') && !tip.startsWith('Mẹo :')) {
      tip = 'Mẹo: $tip';
    }
    return tip;
  }

  @override
  Future<QuizAnswerResolution> resolveQuizAnswer({
    required String question,
    required List<({String label, String content})> choices,
  }) async {
    final userPayload = {
      'question': question,
      'choices': [
        for (final c in choices)
          {
            'label': c.label,
            'content': c.content,
          },
      ],
    };
    final raw = await _chatJson(
      systemPrompt: DeepSeekPrompts.quizAnswerResolveSystem(),
      userContent: jsonEncode(userPayload),
      promptVersion: DeepSeekPrompts.quizAnswerResolveVersion,
      maxTokensOverride: 512,
    );
    final map = _requireJsonObject(raw);
    var label = '${map['correct_label'] ?? ''}'.trim().toUpperCase();
    var content = '${map['correct_content'] ?? ''}'.trim();
    final reason = '${map['brief_reason'] ?? ''}'.trim();

    // Prefer matching an offered choice by label, then by content.
    ({String label, String content})? matched;
    for (final c in choices) {
      if (c.label.trim().toUpperCase() == label) {
        matched = c;
        break;
      }
    }
    if (matched == null && content.isNotEmpty) {
      for (final c in choices) {
        final cc = c.content.trim().toLowerCase();
        final got = content.toLowerCase();
        if (cc == got || cc.contains(got) || got.contains(cc)) {
          matched = c;
          break;
        }
      }
    }
    if (matched != null) {
      label = matched.label.trim().toUpperCase();
      if (matched.content.trim().isNotEmpty) {
        content = matched.content.trim();
      }
    }
    if (label.isEmpty && content.isEmpty) {
      throw const UnknownFailure(
        userMessage: 'Không suy ra được đáp án từ mô hình.',
        code: 'quiz_answer_resolve_empty',
      );
    }
    return QuizAnswerResolution(
      label: label,
      content: content,
      briefReason: reason.isEmpty ? null : reason,
    );
  }

  @override
  Future<MathLatexFormatResult> formatMathLatex({
    required String content,
    List<({String label, String content})> choices = const [],
    String? answerContent,
    String? subjectName,
    String? formatKind,
  }) async {
    final userPayload = {
      'content': content,
      if (subjectName != null && subjectName.trim().isNotEmpty)
        'subject_name': subjectName.trim(),
      if (formatKind != null && formatKind.trim().isNotEmpty)
        'format_kind': formatKind.trim(),
      'choices': [
        for (final c in choices)
          {
            'label': c.label,
            'content': c.content,
          },
      ],
      if (answerContent != null && answerContent.trim().isNotEmpty)
        'answer_content': answerContent.trim(),
    };
    final raw = await _chatJson(
      systemPrompt: DeepSeekPrompts.mathLatexFormatSystem(
        subjectName: subjectName,
        formatKind: formatKind,
      ),
      userContent: jsonEncode(userPayload),
      promptVersion: DeepSeekPrompts.mathLatexFormatVersion,
      maxTokensOverride: 2048,
    );
    final map = _requireJsonObject(raw);
    final outContent = '${map['content'] ?? content}'.trim();
    if (outContent.isEmpty) {
      throw const UnknownFailure(
        userMessage: 'Phản hồi chuẩn hóa LaTeX trống.',
        code: 'math_latex_format_empty',
      );
    }
    final outChoices = <({String label, String content})>[];
    final rawChoices = map['choices'];
    if (rawChoices is List) {
      for (final entry in rawChoices) {
        if (entry is! Map) continue;
        final label = '${entry['label'] ?? ''}'.trim();
        final body = '${entry['content'] ?? ''}'.trim();
        if (label.isEmpty && body.isEmpty) continue;
        outChoices.add((label: label, content: body));
      }
    }
    if (outChoices.isEmpty && choices.isNotEmpty) {
      outChoices.addAll(choices);
    }
    final outAnswer = map.containsKey('answer_content')
        ? '${map['answer_content'] ?? ''}'.trim()
        : answerContent?.trim();
    return MathLatexFormatResult(
      content: outContent,
      choices: outChoices,
      answerContent:
          (outAnswer == null || outAnswer.isEmpty) ? null : outAnswer,
    );
  }

  @override
  Future<String> generateKnowledgeSummary({
    required String subjectName,
    required List<KnowledgeSummaryUnit> units,
    required List<KnowledgeSummaryQa> questions,
  }) async {
    if (units.isEmpty && questions.isEmpty) return '';

    final version = DeepSeekPrompts.studyInsightsVersion;
    final userPayload = {
      'subject_name': subjectName,
      'knowledge_units': [
        for (final u in units)
          {
            'type': u.type,
            'content': u.content,
          },
      ],
      'questions': [
        for (final q in questions)
          {
            'question': q.question,
            if (q.answer != null && q.answer!.trim().isNotEmpty)
              'answer': q.answer,
            if (q.explanation != null && q.explanation!.trim().isNotEmpty)
              'explanation': q.explanation,
          },
      ],
    };
    final raw = await _chatJson(
      systemPrompt: DeepSeekPrompts.studyInsightsSystem(),
      userContent: jsonEncode(userPayload),
      promptVersion: version,
      maxTokensOverride: DeepSeekConfig.structuringMaxTokens,
    );
    return _parseKnowledgeSummary(raw);
  }

  String _parseKnowledgeSummary(String raw) {
    final map = _requireJsonObject(raw);
    final md = '${map['insights_markdown'] ?? map['insightsMarkdown'] ?? map['summary_markdown'] ?? map['summaryMarkdown'] ?? ''}'
        .trim();
    if (md.isEmpty) {
      throw const UnknownFailure(
        userMessage: 'Phản hồi phân tích ôn tập trống hoặc không hợp lệ.',
        code: 'study_insights_schema',
      );
    }
    return md;
  }

  @override
  Future<String> generateProgressAdvice({
    required String subjectName,
    required int totalQuestions,
    required int practicedQuestions,
    required int neverPracticedQuestions,
    required int weakQuestions,
    double? averageScore,
    required int totalPracticeAttempts,
    required int totalIncorrectAttempts,
    List<ProgressAdviceWeakSample> weakSamples = const [],
  }) async {
    final version = DeepSeekPrompts.progressAdviceVersion;
    final userPayload = {
      'subject_name': subjectName,
      'total_questions': totalQuestions,
      'practiced_questions': practicedQuestions,
      'never_practiced_questions': neverPracticedQuestions,
      'weak_questions': weakQuestions,
      if (averageScore != null)
        'average_score_out_of_10':
            double.parse(averageScore.toStringAsFixed(2)),
      'total_practice_attempts': totalPracticeAttempts,
      'total_incorrect_attempts': totalIncorrectAttempts,
      'weak_samples': [
        for (final s in weakSamples)
          {
            'stem': s.stem,
            'practice_count': s.practiceCount,
            'incorrect_count': s.incorrectCount,
          },
      ],
    };
    final raw = await _chatJson(
      systemPrompt: DeepSeekPrompts.progressAdviceSystem(),
      userContent: jsonEncode(userPayload),
      promptVersion: version,
      maxTokensOverride: DeepSeekConfig.structuringMaxTokens,
    );
    return _parseProgressAdvice(raw);
  }

  String _parseProgressAdvice(String raw) {
    final map = _requireJsonObject(raw);
    final md =
        '${map['advice_markdown'] ?? map['adviceMarkdown'] ?? map['insights_markdown'] ?? ''}'
            .trim();
    if (md.isEmpty) {
      throw const UnknownFailure(
        userMessage: 'Phản hồi báo cáo trống hoặc không hợp lệ.',
        code: 'progress_advice_schema',
      );
    }
    return md;
  }

  @override
  Future<List<Map<String, dynamic>>> generateQuestionsFromKnowledge({
    required List<KnowledgeSummaryUnit> units,
    String? subjectName,
    String? formatKind,
  }) async {
    if (units.isEmpty) return const [];

    final version = DeepSeekPrompts.generateQuestionsFromKnowledgeVersion;
    final userPayload = {
      'knowledge_units': [
        for (final u in units)
          {
            'type': u.type,
            'content': u.content,
          },
      ],
    };
    final raw = await _chatJson(
      systemPrompt: DeepSeekPrompts.generateQuestionsFromKnowledgeSystem(
        subjectName: subjectName,
        formatKind: formatKind,
      ),
      userContent: jsonEncode(userPayload),
      promptVersion: version,
      maxTokensOverride: DeepSeekConfig.structuringMaxTokens,
    );
    return _parseGeneratedQuestions(raw);
  }

  List<Map<String, dynamic>> _parseGeneratedQuestions(String raw) {
    final map = _requireJsonObject(raw);
    final list = map['questions'];
    if (list is! List) {
      throw const UnknownFailure(
        userMessage: 'Phản hồi tạo câu hỏi không hợp lệ.',
        code: 'generate_questions_schema',
      );
    }
    return [
      for (final item in list)
        if (item is Map)
          Map<String, dynamic>.from(item),
    ];
  }

  @override
  Future<Map<String, SemanticCanonicalization>> canonicalizeQuestions(
    List<CanonicalizeItem> items,
  ) async {
    if (items.isEmpty) return {};

    const batchSize = 15;
    final out = <String, SemanticCanonicalization>{};
    for (var i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      final batch = items.sublist(i, end);
      final version = DeepSeekPrompts.canonicalizeVersion;
      final userPayload = {
        'items': [
          for (final item in batch)
            {
              'id': item.id,
              'question': item.questionText,
              if (item.choiceContents.isNotEmpty)
                'choices': item.choiceContents,
            },
        ],
      };
      final raw = await _chatJson(
        systemPrompt: DeepSeekPrompts.canonicalizeQuestionsSystem(),
        userContent: jsonEncode(userPayload),
        promptVersion: version,
        maxTokensOverride: DeepSeekConfig.structuringMaxTokens,
      );
      out.addAll(
        _parseCanonicalizations(raw, expectedIds: batch.map((e) => e.id).toSet()),
      );
    }
    return out;
  }

  Map<String, SemanticCanonicalization> _parseCanonicalizations(
    String raw, {
    required Set<String> expectedIds,
  }) {
    final map = _requireJsonObject(raw);
    final keys = map['keys'];
    final out = <String, SemanticCanonicalization>{};
    if (keys is! List) {
      throw const UnknownFailure(
        userMessage: 'Phản hồi khóa ngữ nghĩa không đúng định dạng JSON.',
        code: 'canonicalize_schema',
      );
    }
    for (final entry in keys) {
      if (entry is! Map) continue;
      final id = entry['id']?.toString();
      final key = '${entry['semantic_key'] ?? entry['semanticKey'] ?? ''}'.trim();
      if (id == null || key.isEmpty) continue;
      if (!expectedIds.contains(id)) continue;
      final aliasesRaw = entry['aliases'];
      final aliases = <String>[];
      if (aliasesRaw is List) {
        for (final a in aliasesRaw) {
          final s = '$a'.trim();
          if (s.isNotEmpty) aliases.add(s);
        }
      }
      out[id] = SemanticCanonicalization(semanticKey: key, aliases: aliases);
    }
    return out;
  }

  @override
  Future<MeaningMatchResult> matchQuestionMeaning({
    required String liveQuestion,
    required List<MeaningMatchCandidate> candidates,
  }) async {
    if (candidates.isEmpty) {
      return const MeaningMatchResult(sameMeaning: false);
    }

    final capped = candidates.take(8).toList();
    final version = DeepSeekPrompts.matchMeaningVersion;
    final userPayload = {
      'live_question': liveQuestion,
      'candidates': [
        for (final c in capped) {'id': c.id, 'question': c.questionText},
      ],
    };
    final raw = await _chatJson(
      systemPrompt: DeepSeekPrompts.matchQuestionMeaningSystem(),
      userContent: jsonEncode(userPayload),
      promptVersion: version,
      maxTokensOverride: 256,
    );
    return _parseMeaningMatch(raw, expectedIds: capped.map((e) => e.id).toSet());
  }

  @override
  Future<String> polishOcrText({
    required String raw,
    required String heuristic,
  }) async {
    final version = DeepSeekPrompts.ocrPolishVersion;
    final userPayload = {
      'raw': raw,
      'heuristic': heuristic,
    };
    final response = await _chatJson(
      systemPrompt: DeepSeekPrompts.ocrPolishSystem(),
      userContent: jsonEncode(userPayload),
      promptVersion: version,
      maxTokensOverride: 2048,
    );
    final map = _requireJsonObject(response);
    final text = (map['text'] ?? map['polished'] ?? '').toString().trim();
    if (text.isEmpty) {
      _log.warning('OCR polish returned empty text; keeping heuristic');
      return heuristic;
    }
    _log.info(
      'OCR polish ok in=${raw.length}c heuristic=${heuristic.length}c '
      'out=${text.length}c',
    );
    return text;
  }

  @override
  Future<PracticeTurnResponse> startPracticeTurn({
    required String questionText,
    ParsedQuestion? parsed,
    int maxCheckSteps = 6,
    bool reviewMode = false,
    String? knownAnswerContent,
  }) async {
    final version = reviewMode
        ? DeepSeekPrompts.practiceReviewVersion
        : DeepSeekPrompts.practiceVersion;
    final userPayload = <String, dynamic>{
      'action': 'start',
      'question_text': questionText,
      'max_check_steps': maxCheckSteps,
      'check_steps_so_far': 0,
      if (reviewMode) 'review_mode': true,
      if (knownAnswerContent != null && knownAnswerContent.trim().isNotEmpty)
        'known_answer_content': knownAnswerContent.trim(),
      if (parsed != null)
        'parsed': {
          'question_type': parsed.questionType.wireName,
          'content': parsed.content,
          'choices': [
            for (final c in parsed.choices)
              {'label': c.label, 'content': c.content},
          ],
        },
    };
    final raw = await _chatJson(
      systemPrompt: DeepSeekPrompts.practiceSystem(reviewMode: reviewMode),
      userContent: jsonEncode(userPayload),
      promptVersion: version,
      maxTokensOverride: 2048,
    );
    return _parsePracticeTurn(raw);
  }

  @override
  Future<PracticeTurnResponse> continuePracticeTurn({
    required List<PracticeLlmMessage> history,
    required String userAnswer,
    required int attemptsOnStep,
    int checkStepsSoFar = 0,
    int maxCheckSteps = 6,
    bool reviewMode = false,
  }) async {
    final version = reviewMode
        ? DeepSeekPrompts.practiceReviewVersion
        : DeepSeekPrompts.practiceVersion;
    final messages = <Map<String, String>>[
      for (final m in history) m.toApiMap(),
      {
        'role': 'user',
        'content': jsonEncode({
          'action': 'answer',
          'user_answer': userAnswer,
          'attempts_on_step': attemptsOnStep,
          'check_steps_so_far': checkStepsSoFar,
          'max_check_steps': maxCheckSteps,
          if (reviewMode) 'review_mode': true,
        }),
      },
    ];
    final raw = await _chatJsonMessages(
      systemPrompt: DeepSeekPrompts.practiceSystem(reviewMode: reviewMode),
      messages: messages,
      promptVersion: version,
      maxTokensOverride: 2048,
    );
    return _parsePracticeTurn(raw);
  }

  PracticeTurnResponse _parsePracticeTurn(String raw) {
    final map = _requireJsonObject(raw);
    final turn = PracticeTurnResponse.fromJson(map, rawJson: raw);
    if (turn.coachMessage.isEmpty && !turn.isComplete) {
      throw const UnknownFailure(
        userMessage: 'Phản hồi luyện tập không hợp lệ. Thử lại.',
        code: 'practice_turn_invalid',
      );
    }
    return turn;
  }

  MeaningMatchResult _parseMeaningMatch(
    String raw, {
    required Set<String> expectedIds,
  }) {
    final map = _requireJsonObject(raw);
    final same = map['same_meaning'] == true || map['sameMeaning'] == true;
    final idRaw = map['id'];
    final id = idRaw == null ? null : '$idRaw'.trim();
    if (!same || id == null || id.isEmpty || id == 'null') {
      return const MeaningMatchResult(sameMeaning: false);
    }
    if (!expectedIds.contains(id)) {
      return const MeaningMatchResult(sameMeaning: false);
    }
    return MeaningMatchResult(id: id, sameMeaning: true);
  }

  @override
  Future<void> testConnection() async {
    // Tiny no-content probe — never includes questions, OCR, PDFs, or evidence.
    await _chatJson(
      systemPrompt:
          'Reply with a minimal JSON object: {"ok":true}. Do not include other fields.',
      userContent: '{"ping":true}',
      promptVersion: 'connectionTest.v1',
      maxTokensOverride: 32,
    );
  }

  @override
  void beginCancellableSession() {
    activeCancelToken?.cancel('replaced');
    activeCancelToken = CancelToken();
  }

  @override
  void cancelActiveSession() {
    activeCancelToken?.cancel('user_cancelled');
    activeCancelToken = null;
  }

  // ---------------------------------------------------------------------------
  // HTTP + backoff
  // ---------------------------------------------------------------------------

  Future<String> _chatJson({
    required String systemPrompt,
    required String userContent,
    required String promptVersion,
    int? maxTokensOverride,
  }) {
    return _chatJsonMessages(
      systemPrompt: systemPrompt,
      messages: [
        {'role': 'user', 'content': userContent},
      ],
      promptVersion: promptVersion,
      maxTokensOverride: maxTokensOverride,
    );
  }

  Future<String> _chatJsonMessages({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    required String promptVersion,
    int? maxTokensOverride,
  }) async {
    final apiKey = await _credentials.getDeepSeekApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw const MissingApiKeyFailure();
    }

    final body = jsonEncode({
      'model': model,
      'temperature': DeepSeekConfig.temperature,
      'max_tokens': maxTokensOverride ?? DeepSeekConfig.maxTokens,
      'response_format': {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        ...messages,
      ],
    });

    _log.info('DeepSeek request promptVersion=$promptVersion');

    var attempt = 0;
    var delay = DeepSeekConfig.initialBackoff;

    while (true) {
      activeCancelToken?.throwIfCancelled();
      attempt++;
      try {
        final response = await _send(apiKey.trim(), body);
        return _extractContent(response);
      } on CancelledException {
        throw const CancelledFailure(code: 'deepseek_cancelled');
      } on AppFailure catch (failure) {
        final retryable = failure is NetworkFailure ||
            failure is RateLimitFailure ||
            (failure is UnknownFailure && failure.code == 'http_5xx');
        if (!retryable || attempt > DeepSeekConfig.maxRetries) {
          rethrow;
        }
        _log.warning(
          'DeepSeek transient failure code=${failure.code}; retry=$attempt',
        );
        await _sleep(delay);
        final nextMs = (delay.inMilliseconds * 2)
            .clamp(0, DeepSeekConfig.maxBackoff.inMilliseconds);
        delay = Duration(milliseconds: nextMs);
      }
    }
  }

  Future<http.Response> _send(String apiKey, String body) async {
    final token = activeCancelToken;
    token?.throwIfCancelled();

    final client = _http;
    late http.Response response;
    try {
      response = await client
          .post(
            _chatUri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: body,
          )
          .timeout(
            DeepSeekConfig.readTimeout,
            onTimeout: () {
              throw const NetworkFailure(
                userMessage: 'Hết thời gian chờ phản hồi từ Trợ lý Stud.',
                code: 'deepseek_timeout',
              );
            },
          );
    } on TimeoutException {
      throw const NetworkFailure(
        userMessage: 'Hết thời gian chờ phản hồi từ Trợ lý Stud.',
        code: 'deepseek_timeout',
      );
    } on CancelledException {
      rethrow;
    } on AppFailure {
      rethrow;
    } on http.ClientException catch (e) {
      throw NetworkFailure(
        code: 'deepseek_network',
        details: e.runtimeType.toString(),
      );
    } on Object catch (e) {
      if (e is CancelledException) rethrow;
      throw NetworkFailure(
        code: 'deepseek_network',
        details: e.runtimeType.toString(),
      );
    }

    token?.throwIfCancelled();
    _mapHttpError(response);
    return response;
  }

  void _mapHttpError(http.Response response) {
    final code = response.statusCode;
    if (code >= 200 && code < 300) return;

    // Never log response bodies that may echo prompts.
    _log.warning('DeepSeek HTTP status=$code');

    if (code == 401 || code == 403) {
      throw AuthFailure(code: 'deepseek_http_$code');
    }
    if (code == 429) {
      throw RateLimitFailure(code: 'deepseek_http_429');
    }
    if (code == 402) {
      throw QuotaFailure(code: 'deepseek_http_402');
    }
    if (code >= 500) {
      throw UnknownFailure(
        userMessage: 'Máy chủ Trợ lý Stud tạm thời lỗi. Thử lại sau.',
        code: 'http_5xx',
        details: 'status=$code',
      );
    }
    throw UnknownFailure(
      userMessage: 'Yêu cầu Trợ lý Stud thất bại.',
      code: 'deepseek_http_$code',
      details: 'status=$code',
    );
  }

  String _extractContent(http.Response response) {
    if (response.body.isEmpty) {
      throw const ValidationFailure(
        userMessage: 'Phản hồi của Trợ lý Stud trống.',
        code: 'deepseek_empty',
      );
    }

    late final Map<String, dynamic> envelope;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('root not object');
      }
      envelope = decoded;
    } on Object {
      throw const ValidationFailure(
        userMessage: 'Phản hồi của Trợ lý Stud chưa đúng định dạng.',
        code: 'deepseek_malformed_envelope',
      );
    }

    final choices = envelope['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const ValidationFailure(
        userMessage: 'Phản hồi của Trợ lý Stud thiếu nội dung.',
        code: 'deepseek_empty_choices',
      );
    }

    final message = choices.first is Map
        ? (choices.first as Map)['message']
        : null;
    final content = message is Map ? message['content'] : null;
    if (content is! String || content.trim().isEmpty) {
      throw const ValidationFailure(
        userMessage: 'Phản hồi của Trợ lý Stud trống.',
        code: 'deepseek_empty_content',
      );
    }

    // Ensure content is parseable JSON (may be fenced).
    final cleaned = _stripCodeFence(content.trim());
    try {
      jsonDecode(cleaned);
    } on Object {
      throw const ValidationFailure(
        userMessage: 'Nội dung phản hồi của Trợ lý Stud chưa đúng định dạng.',
        code: 'deepseek_malformed_json',
      );
    }
    return cleaned;
  }

  DeepSeekAnswerResponse _parseAnswer(String raw) {
    final map = _requireJsonObject(raw);
    return DeepSeekAnswerResponse.fromJson(map).copyWithRaw(raw);
  }

  Map<String, dynamic> _requireJsonObject(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on Object {
      // fall through
    }
    throw const ValidationFailure(
      userMessage: 'Không đọc được phản hồi từ Trợ lý Stud.',
      code: 'deepseek_json_object_required',
    );
  }

  Map<String, dynamic> _evidencePackagePayload(EvidencePackage package) {
    return {
      'current_question': {
        'content': package.currentQuestion.content,
        'question_type': package.currentQuestion.questionType.wireName,
        'choices': package.currentQuestion.choices
            .map((c) => {'label': c.label, 'content': c.content})
            .toList(),
      },
      'answer_constraint': {
        'fixed': package.answerConstraint.fixed,
        'answer_label': package.answerConstraint.answerLabel,
        'answer_content': package.answerConstraint.answerContent,
      },
      'evidence': package.evidence.map(_evidenceItemPayload).toList(),
      'warnings': package.warnings,
    };
  }

  Map<String, dynamic> _evidenceItemPayload(EvidenceItem item) => {
        'evidence_id': item.evidenceId,
        'local_id': item.localId,
        'type': item.type.wireName,
        'content': item.content,
        'verification_status': item.verificationStatus.wireName,
        'source_title': item.sourceTitle,
        'page': item.page,
      };

  static String _stripCodeFence(String input) {
    final fence = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$', multiLine: true);
    final match = fence.firstMatch(input);
    if (match != null) return match.group(1)!.trim();
    return input;
  }

  Future<void> _sleep(Duration delay) async {
    final token = activeCancelToken;
    if (token == null) {
      await Future<void>.delayed(delay);
      return;
    }
    token.throwIfCancelled();
    final completer = Completer<void>();
    Timer? timer;
    void onCancel() {
      timer?.cancel();
      if (!completer.isCompleted) {
        completer.completeError(CancelledException(token.reason));
      }
    }

    token.addListener(onCancel);
    timer = Timer(delay, () {
      token.removeListener(onCancel);
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
  }

  /// Closes the underlying HTTP client when owned by this impl.
  void dispose() {
    _http.close();
  }
}

extension on DeepSeekAnswerResponse {
  DeepSeekAnswerResponse copyWithRaw(String raw) {
    return DeepSeekAnswerResponse(
      questionType: questionType,
      finalAnswerLabel: finalAnswerLabel,
      finalAnswerContent: finalAnswerContent,
      shortAnswer: shortAnswer,
      explanationMarkdown: explanationMarkdown,
      usedEvidenceIds: usedEvidenceIds,
      modelKnowledgeUsed: modelKnowledgeUsed,
      missingInformation: missingInformation,
      warnings: warnings,
      rawJson: raw,
    );
  }
}

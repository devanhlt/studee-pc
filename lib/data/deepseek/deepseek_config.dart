import 'package:studee_pc/data/backend/backend_config.dart';

/// DeepSeek-compatible client configuration (via Studee middleware).
///
/// Users configure an activation code in Settings. Requests go to
/// [BackendConfig.baseUrl] which proxies DeepSeek with server keys.
abstract final class DeepSeekConfig {
  static String get baseUrl => BackendConfig.baseUrl;
  static const String model = 'deepseek-chat';
  static const String chatCompletionsPath = '/v1/chat/completions';

  /// Connect timeout for establishing the HTTP connection.
  static const Duration connectTimeout = Duration(seconds: 20);

  /// Read timeout for receiving the full response body.
  static const Duration readTimeout = Duration(seconds: 120);

  /// Max completion tokens — keep high enough to avoid truncated JSON.
  static const int maxTokens = 4096;

  /// Higher budget for source structuring (multi-question batches).
  static const int structuringMaxTokens = 8192;

  /// Temperature for structured JSON tasks.
  static const double temperature = 0.2;

  /// Exponential backoff: initial delay and cap.
  static const Duration initialBackoff = Duration(milliseconds: 500);
  static const Duration maxBackoff = Duration(seconds: 8);
  static const int maxRetries = 3;

  /// Shared Vietnamese system instruction appended by prompt builders.
  static const String vietnameseOutputInstruction =
      'Luôn trả lời và giải thích bằng tiếng Việt trừ khi câu hỏi rõ ràng '
      'thuộc ngôn ngữ khác. Giữ nguyên thuật ngữ kỹ thuật và công thức Toán '
      'khi cần. Xuất đúng định dạng JSON theo schema được cung cấp.';
}

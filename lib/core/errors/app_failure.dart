/// Application-level failures with Vietnamese user-facing messages.
///
/// [details] and [code] must never contain secrets (API keys, prompts,
/// full question text, file contents, or credentials).
sealed class AppFailure {
  const AppFailure({
    required this.userMessage,
    this.code,
    this.details,
  });

  /// Short Vietnamese message safe to show in the UI.
  final String userMessage;

  /// Machine-readable error code (no secrets).
  final String? code;

  /// Optional non-sensitive diagnostic context.
  final String? details;

  @override
  String toString() =>
      '$runtimeType(code: $code, userMessage: $userMessage, details: $details)';
}

final class DatabaseFailure extends AppFailure {
  const DatabaseFailure({
    super.userMessage =
        'Lỗi cơ sở dữ liệu. Thao tác đã được hoàn tác nếu có thể.',
    super.code,
    super.details,
  });
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure({
    super.userMessage =
        'Không thể kết nối mạng. Kiểm tra kết nối và thử lại.',
    super.code,
    super.details,
  });
}

final class AuthFailure extends AppFailure {
  const AuthFailure({
    super.userMessage =
        'Xác thực API thất bại. Kiểm tra khóa DeepSeek trong Cài đặt.',
    super.code,
    super.details,
  });
}

final class RateLimitFailure extends AppFailure {
  const RateLimitFailure({
    super.userMessage =
        'Đã vượt giới hạn tốc độ API. Vui lòng đợi rồi thử lại.',
    super.code,
    super.details,
  });
}

final class QuotaFailure extends AppFailure {
  const QuotaFailure({
    super.userMessage =
        'Đã hết hạn mức API. Kiểm tra tài khoản DeepSeek của bạn.',
    super.code,
    super.details,
  });
}

final class OcrFailure extends AppFailure {
  const OcrFailure({
    super.userMessage =
        'Nhận dạng văn bản (OCR) thất bại. Bạn có thể thử lại trang này.',
    super.code,
    super.details,
  });
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure({
    super.userMessage = 'Dữ liệu không hợp lệ. Vui lòng kiểm tra và sửa.',
    super.code,
    super.details,
  });
}

final class CancelledFailure extends AppFailure {
  const CancelledFailure({
    super.userMessage = 'Thao tác đã bị hủy.',
    super.code,
    super.details,
  });
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({
    super.userMessage = 'Không tìm thấy dữ liệu yêu cầu.',
    super.code,
    super.details,
  });
}

final class ConflictFailure extends AppFailure {
  const ConflictFailure({
    super.userMessage =
        'Nguồn đáng tin cậy mâu thuẫn. Không tự chọn đáp án.',
    super.code,
    super.details,
  });
}

final class MissingApiKeyFailure extends AppFailure {
  const MissingApiKeyFailure({
    super.userMessage =
        'Chưa có khóa API DeepSeek. Thêm khóa trong Cài đặt để tiếp tục.',
    super.code = 'missing_api_key',
    super.details,
  });
}

final class ScreenCaptureFailure extends AppFailure {
  const ScreenCaptureFailure({
    super.userMessage =
        'Không chụp được màn hình. Cấp quyền Ghi màn hình cho đúng bản '
        '(Studee hoặc Studee (Debug)), rồi thoát hẳn app và mở lại.',
    super.code = 'screen_capture_denied',
    super.details,
  });
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure({
    super.userMessage = 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.',
    super.code,
    super.details,
  });
}

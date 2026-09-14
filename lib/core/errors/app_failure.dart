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
        'Không lưu được dữ liệu. Thao tác đã được hoàn tác.',
    super.code,
    super.details,
  });
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure({
    super.userMessage =
        'Không có kết nối mạng. Kiểm tra internet rồi thử lại nhé.',
    super.code,
    super.details,
  });
}

final class AuthFailure extends AppFailure {
  const AuthFailure({
    super.userMessage =
        'Mã kích hoạt chưa được chấp nhận. Kiểm tra lại trong Cài đặt.',
    super.code,
    super.details,
  });
}

final class RateLimitFailure extends AppFailure {
  const RateLimitFailure({
    super.userMessage =
        'Bạn gửi yêu cầu hơi nhanh. Chờ một chút rồi thử lại nhé.',
    super.code,
    super.details,
  });
}

final class QuotaFailure extends AppFailure {
  const QuotaFailure({
    super.userMessage =
        'Đã hết token. Mua thêm mã để tiếp tục nhé.',
    super.code,
    super.details,
  });
}

final class OcrFailure extends AppFailure {
  const OcrFailure({
    super.userMessage =
        'Không đọc được chữ trong ảnh. Thử lại trang này hoặc nhập tay.',
    super.code,
    super.details,
  });
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure({
    super.userMessage = 'Thông tin chưa hợp lệ. Kiểm tra lại rồi thử lần nữa.',
    super.code,
    super.details,
  });
}

final class CancelledFailure extends AppFailure {
  const CancelledFailure({
    super.userMessage = 'Đã hủy.',
    super.code,
    super.details,
  });
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({
    super.userMessage = 'Không tìm thấy dữ liệu bạn cần.',
    super.code,
    super.details,
  });
}

final class ConflictFailure extends AppFailure {
  const ConflictFailure({
    super.userMessage =
        'Các nguồn đang không khớp nhau nên chưa thể chọn đáp án.',
    super.code,
    super.details,
  });
}

final class MissingApiKeyFailure extends AppFailure {
  const MissingApiKeyFailure({
    super.userMessage =
        'Chưa có mã kích hoạt. Vào Cài đặt để nhập mã nhé.',
    super.code = 'missing_api_key',
    super.details,
  });
}

final class ScreenCaptureFailure extends AppFailure {
  const ScreenCaptureFailure({
    super.userMessage =
        'Không chụp được màn hình. Hãy cấp quyền Ghi màn hình cho đúng bản '
        '(Studee hoặc Studee (Debug)), thoát hẳn app rồi mở lại.',
    super.code = 'screen_capture_denied',
    super.details,
  });
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure({
    super.userMessage = 'Đã có lỗi xảy ra. Thử lại giúp mình nhé.',
    super.code,
    super.details,
  });
}

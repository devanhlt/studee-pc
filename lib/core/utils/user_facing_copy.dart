/// Plain-language helpers for student-facing UI copy.
abstract final class UserFacingCopy {
  /// Soften or drop technical solver warnings.
  static List<String> friendlyWarnings(Iterable<String> raw) {
    final out = <String>[];
    final seen = <String>{};
    for (final w in raw) {
      final mapped = _mapWarning(w.trim());
      if (mapped == null || mapped.isEmpty) continue;
      if (!seen.add(mapped)) continue;
      out.add(mapped);
    }
    return out;
  }

  static String? _mapWarning(String w) {
    if (w.isEmpty) return null;
    final lower = w.toLowerCase();
    // Already shown as a chip / duplicate of model-knowledge state.
    if (lower.contains('kiến thức của mô hình')) return null;
    if (lower.contains('evidence') || lower.contains('evidence_id')) {
      return null;
    }
    if (lower.contains('remap') || lower.contains('schema')) return null;
    if (lower.contains('hiển thị đáp án mô hình') ||
        lower.contains('hiển thị câu trả lời mô hình')) {
      return 'Đây là gợi ý từ AI, bạn nên đối chiếu lại với đề.';
    }
    if (lower.contains('tin cậy thấp')) {
      return 'Độ tin cậy thấp, hãy kiểm tra lại trước khi dùng.';
    }
    if (lower.contains('mâu thuẫn') || lower.contains('xung đột')) {
      return 'Tài liệu đã lưu có chỗ chưa thống nhất, hãy đọc kỹ phần giải thích.';
    }
    // Keep short human messages; drop very long internal notes.
    if (w.length > 160) return null;
    return w;
  }

  static String inputTypeVi(String? wire) {
    return switch ((wire ?? '').toLowerCase()) {
      'pasted_text' || 'text' || 'paste' => 'Dán chữ',
      'image' => 'Ảnh',
      'camera' => 'Ảnh camera',
      'screenshot' || 'capture' => 'Chụp màn hình',
      'pdf' => 'PDF',
      'practice_text' => 'Luyện tập · chữ',
      'practice_image' ||
      'practice_screenshot' ||
      'practice_camera' =>
        'Luyện tập · ảnh',
      _ => wire == null || wire.isEmpty ? 'Khác' : wire,
    };
  }

  static String sessionStatusVi(String? wire) {
    return switch ((wire ?? '').toLowerCase()) {
      'completed' || 'complete' || 'success' => 'Hoàn tất',
      'practice_completed' => 'Luyện xong',
      'practice_running' => 'Đang luyện',
      'partial' || 'partial_failure' => 'Xong một phần',
      'failed' || 'failure' || 'error' => 'Không thành công',
      'cancelled' || 'canceled' => 'Đã hủy',
      'pending' || 'running' => 'Đang xử lý',
      _ => wire == null || wire.isEmpty ? '' : wire,
    };
  }
}

/// Lifecycle states for a knowledge-ingestion job.
enum IngestionJobStatus {
  queued,
  preservingSource,
  extractingText,
  runningOcr,
  awaitingTextReview,
  structuring,
  awaitingStructureReview,
  saving,
  completed,
  partiallyCompleted,
  failed,
  cancelled;

  String get wireName => switch (this) {
        IngestionJobStatus.preservingSource => 'preserving_source',
        IngestionJobStatus.extractingText => 'extracting_text',
        IngestionJobStatus.runningOcr => 'running_ocr',
        IngestionJobStatus.awaitingTextReview => 'awaiting_text_review',
        IngestionJobStatus.awaitingStructureReview =>
          'awaiting_structure_review',
        IngestionJobStatus.partiallyCompleted => 'partially_completed',
        _ => name,
      };

  static IngestionJobStatus fromWire(String value) {
    return switch (value) {
      'queued' => IngestionJobStatus.queued,
      'preserving_source' => IngestionJobStatus.preservingSource,
      'extracting_text' => IngestionJobStatus.extractingText,
      'running_ocr' => IngestionJobStatus.runningOcr,
      'awaiting_text_review' => IngestionJobStatus.awaitingTextReview,
      'structuring' => IngestionJobStatus.structuring,
      'awaiting_structure_review' => IngestionJobStatus.awaitingStructureReview,
      'saving' => IngestionJobStatus.saving,
      'completed' => IngestionJobStatus.completed,
      'partially_completed' => IngestionJobStatus.partiallyCompleted,
      'failed' => IngestionJobStatus.failed,
      'cancelled' => IngestionJobStatus.cancelled,
      _ => IngestionJobStatus.failed,
    };
  }

  bool get isTerminal =>
      this == IngestionJobStatus.completed ||
      this == IngestionJobStatus.partiallyCompleted ||
      this == IngestionJobStatus.failed ||
      this == IngestionJobStatus.cancelled;

  String get labelVi => switch (this) {
        IngestionJobStatus.queued => 'Đang chờ',
        IngestionJobStatus.preservingSource => 'Đang lưu nguồn gốc',
        IngestionJobStatus.extractingText => 'Đang trích xuất văn bản',
        IngestionJobStatus.runningOcr => 'Đang chạy OCR',
        IngestionJobStatus.awaitingTextReview => 'Chờ duyệt văn bản',
        IngestionJobStatus.structuring => 'Đang cấu trúc hóa',
        IngestionJobStatus.awaitingStructureReview => 'Chờ duyệt cấu trúc',
        IngestionJobStatus.saving => 'Đang lưu',
        IngestionJobStatus.completed => 'Hoàn tất',
        IngestionJobStatus.partiallyCompleted => 'Hoàn tất một phần',
        IngestionJobStatus.failed => 'Thất bại',
        IngestionJobStatus.cancelled => 'Đã hủy',
      };
}

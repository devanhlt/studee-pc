import 'package:flutter/material.dart';
import 'package:studee_pc/features/subjects/application/study_notes_pdf.dart';

/// Asks the user whether to export Markdown or PDF. Returns null if cancelled.
Future<StudyNotesExportFormat?> showStudyNotesFormatDialog(
  BuildContext context,
) {
  return showDialog<StudyNotesExportFormat>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Xuất tài liệu'),
        content: const Text('Chọn định dạng file:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(StudyNotesExportFormat.markdown),
            child: const Text('Markdown'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(StudyNotesExportFormat.pdf),
            child: const Text('PDF'),
          ),
        ],
      );
    },
  );
}

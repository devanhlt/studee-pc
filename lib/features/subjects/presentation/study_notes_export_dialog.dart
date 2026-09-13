import 'package:flutter/material.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_icons.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/app/widgets/studee_chrome.dart';
import 'package:studee_pc/features/subjects/application/study_notes_pdf.dart';

/// Asks the user whether to export Markdown or PDF. Returns null if cancelled.
Future<StudyNotesExportFormat?> showStudyNotesFormatDialog(
  BuildContext context,
) {
  return showDialog<StudyNotesExportFormat>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: StudeeGlass(
          borderRadius: AppLayout.radiusPanel,
          padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Xuất tài liệu',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(AppIcons.close, size: AppIcons.sizeAction),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Chọn định dạng file',
                  style: TextStyle(
                    color: AppColors.secondaryText.withValues(alpha: 0.95),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx)
                              .pop(StudyNotesExportFormat.markdown),
                          child: const Text('Markdown'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(ctx)
                              .pop(StudyNotesExportFormat.pdf),
                          child: const Text('PDF'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

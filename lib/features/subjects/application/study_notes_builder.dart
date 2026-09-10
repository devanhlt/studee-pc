import 'dart:io';

import 'package:studee_pc/domain/entities/question.dart';

/// Builds a study-notes Markdown document: disclaimer + clustered insights.
///
/// The body must not dump every Q&A; insights come from LLM analysis of
/// similar question types (stats + illustrative examples).
abstract final class StudyNotesBuilder {
  static int countExportable(List<Question> questions) {
    return questions.where((q) => q.content.trim().isNotEmpty).length;
  }

  static Future<File> writeToFile({
    required String destinationPath,
    required String markdown,
  }) async {
    final path = destinationPath.toLowerCase().endsWith('.md')
        ? destinationPath
        : '$destinationPath.md';
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(markdown);
    return file;
  }

  static Future<File> writePdfToFile({
    required String destinationPath,
    required List<int> bytes,
  }) async {
    final path = destinationPath.toLowerCase().endsWith('.pdf')
        ? destinationPath
        : '$destinationPath.pdf';
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Resolves the answer as meaning/text — never a bare A/B/C letter.
  ///
  /// [compact] flattens/shortens for LLM payloads.
  static String? answerMeaning(Question q, {bool compact = true}) {
    var content = q.answerContent?.trim();
    final label = q.answerLabel?.trim();

    if ((content == null || content.isEmpty || _isBareLabel(content)) &&
        label != null &&
        label.isNotEmpty &&
        q.choices.isNotEmpty) {
      for (final c in q.choices) {
        if (c.label.trim().toUpperCase() == label.toUpperCase()) {
          final choiceText = c.content.trim();
          if (choiceText.isNotEmpty) {
            content = choiceText;
            break;
          }
        }
      }
    }

    if (content == null || content.isEmpty || _isBareLabel(content)) {
      return null;
    }
    if (!compact) return content.trim();
    return _shorten(_oneLine(content), 200);
  }

  static bool _isBareLabel(String value) {
    return RegExp(r'^[A-Da-d]$').hasMatch(value.trim());
  }

  /// Legal/disclaimer block placed under the document title.
  static const String disclaimerMarkdown = '''
**TUYÊN BỐ MIỄN TRỪ TRÁCH NHIỆM**

Tài liệu này được biên soạn nhằm mục đích tham khảo và hỗ trợ học tập. Mặc dù tác giả đã cố gắng kiểm tra tính chính xác của nội dung, tài liệu vẫn có thể tồn tại sai sót, thiếu sót hoặc thông tin chưa được cập nhật.

Tài liệu không thay thế giáo trình chính thức, ý kiến của giảng viên hoặc tư vấn chuyên môn. Người đọc có trách nhiệm tự kiểm tra, đối chiếu thông tin và tự quyết định việc áp dụng nội dung trong tài liệu.

Trong phạm vi pháp luật cho phép, tác giả không chịu trách nhiệm đối với thiệt hại phát sinh từ việc sử dụng, hiểu sai hoặc phụ thuộc hoàn toàn vào nội dung của tài liệu.''';
}

/// Pure function — easy to unit-test.
///
/// Document shape: title + disclaimer + optional [insightsMarkdown] only.
String buildStudyNotesMarkdown({
  required String subjectName,
  String? insightsMarkdown,
}) {
  final buf = StringBuffer();
  buf.writeln('# ${_oneLine(subjectName)} — thống kê & nhận xét');
  buf.writeln();
  buf.writeln(StudyNotesBuilder.disclaimerMarkdown);
  buf.writeln();

  final insights = insightsMarkdown?.trim();
  if (insights != null && insights.isNotEmpty) {
    buf.writeln(_stripOuterDocumentHeadings(insights));
    buf.writeln();
  }

  return '${buf.toString().trimRight()}\n';
}

/// Drop duplicate top-level headings the model may still emit.
String _stripOuterDocumentHeadings(String markdown) {
  return markdown
      .replaceFirst(
        RegExp(
          r'^#+\s*(Lý thuyết|Tóm tắt kiến thức|Danh sách câu hỏi|Thống kê\s*&\s*nhận xét)\s*\n+',
          caseSensitive: false,
        ),
        '',
      )
      .trim();
}

String _oneLine(String raw) =>
    raw.replaceAll(RegExp(r'\s+'), ' ').trim();

String _shorten(String text, int maxChars) {
  final one = _oneLine(text);
  if (one.length <= maxChars) return one;
  return '${one.substring(0, maxChars - 1).trimRight()}…';
}

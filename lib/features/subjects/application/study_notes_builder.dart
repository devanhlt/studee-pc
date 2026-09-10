import 'dart:io';

import 'package:studee_pc/domain/entities/question.dart';
import 'package:studee_pc/features/subjects/application/study_notes_markdown_code.dart';

/// Builds a concise Q&A study-notes Markdown document for memorization.
///
/// Tips should help remember answer *meaning*. Never treat A/B/C labels as
/// the thing to memorize (choice order changes across exams).
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
  /// [compact] flattens/shortens for tips; leave false for Markdown export
  /// so code blocks stay readable.
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
/// [tipsByQuestionId] maps question id → LLM mnemonic tip.
/// [knowledgeSummaryMarkdown] is an optional grounded summary section.
String buildStudyNotesMarkdown({
  required String subjectName,
  required List<Question> questions,
  Map<String, String> tipsByQuestionId = const {},
  String? knowledgeSummaryMarkdown,
}) {
  final sorted = List<Question>.from(
    questions.where((q) => q.content.trim().isNotEmpty),
  )..sort(_compareQuestions);

  final buf = StringBuffer();
  buf.writeln('# ${_oneLine(subjectName)} — nhớ đáp án');
  buf.writeln();
  buf.writeln(StudyNotesBuilder.disclaimerMarkdown);
  buf.writeln();

  final summary = knowledgeSummaryMarkdown?.trim();
  if (summary != null && summary.isNotEmpty) {
    buf.writeln('## Lý thuyết');
    buf.writeln();
    buf.writeln(_stripDuplicateTheoryHeading(summary));
    buf.writeln();
  }

  buf.writeln('## Danh sách câu hỏi');
  buf.writeln();

  if (sorted.isEmpty) {
    buf.writeln('_Chưa có câu hỏi._');
    return buf.toString();
  }

  for (var i = 0; i < sorted.length; i++) {
    final q = sorted[i];
    final heading = q.questionNumber?.trim().isNotEmpty == true
        ? q.questionNumber!.trim()
        : '${i + 1}';
    final meaning = StudyNotesBuilder.answerMeaning(q, compact: false);
    final tip = tipsByQuestionId[q.id]?.trim();

    buf.writeln('### $heading');
    buf.writeln('**Hỏi:**');
    buf.writeln();
    buf.writeln(StudyNotesMarkdownCode.formatBody(q.content));
    buf.writeln();
    buf.writeln('**Đáp:**');
    buf.writeln();
    buf.writeln(
      meaning == null
          ? '(chưa có)'
          : StudyNotesMarkdownCode.formatBody(meaning),
    );
    if (tip != null && tip.isNotEmpty) {
      buf.writeln();
      buf.writeln('**Mẹo:** ${_oneLine(tip)}');
    }
    buf.writeln();
  }

  return '${buf.toString().trimRight()}\n';
}

String _stripDuplicateTheoryHeading(String markdown) {
  return markdown
      .replaceFirst(
        RegExp(
          r'^#+\s*(Lý thuyết|Tóm tắt kiến thức)\s*\n+',
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

int _compareQuestions(Question a, Question b) {
  final an = _sortKey(a.questionNumber);
  final bn = _sortKey(b.questionNumber);
  if (an != null && bn != null) {
    final byNum = an.compareTo(bn);
    if (byNum != 0) return byNum;
  } else if (an != null) {
    return -1;
  } else if (bn != null) {
    return 1;
  }
  return a.createdAt.compareTo(b.createdAt);
}

double? _sortKey(String? number) {
  if (number == null) return null;
  final m = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(number);
  if (m == null) return null;
  return double.tryParse(m.group(1)!.replaceAll(',', '.'));
}

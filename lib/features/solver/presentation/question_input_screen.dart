import 'package:flutter/material.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/app/widgets/studee_chrome.dart';
import 'package:studee_pc/app/widgets/studee_controls.dart';

/// Full-screen text editor for a question draft.
///
/// Header: back · "Nhập câu hỏi" · "Xong". Returns the edited text, or null
/// if the user dismisses without tapping Xong.
class QuestionInputScreen extends StatefulWidget {
  const QuestionInputScreen({
    super.key,
    required this.initialText,
    required this.hintText,
  });

  final String initialText;
  final String hintText;

  /// Opens as a root fullscreen route; returns null if the user backs out.
  static Future<String?> open(
    BuildContext context, {
    required String initialText,
    required String hintText,
  }) {
    return Navigator.of(context, rootNavigator: true).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => QuestionInputScreen(
          initialText: initialText,
          hintText: hintText,
        ),
      ),
    );
  }

  @override
  State<QuestionInputScreen> createState() => _QuestionInputScreenState();
}

class _QuestionInputScreenState extends State<QuestionInputScreen> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _done() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return StudeePageScaffold(
      atmosphereIntensity: AppLayout.atmospherePage,
      topBar: StudeeGlassAppBar(
        title: 'Nhập câu hỏi',
        actions: [
          TextButton(
            onPressed: _done,
            child: const Text('Xong'),
          ),
        ],
      ),
      body: Padding(
        padding: AppLayout.pageInsets(context),
        child: StudeeFocusComposer(
          child: StudeeGlass(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: widget.hintText,
                alignLabelWithHint: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.all(AppLayout.cardPadding),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

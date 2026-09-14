import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_icons.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/app/theme/app_motion.dart';
import 'package:studee_pc/app/widgets/study_markdown.dart';
import 'package:studee_pc/app/widgets/studee_chrome.dart';
import 'package:studee_pc/app/widgets/studee_controls.dart';
import 'package:studee_pc/domain/entities/practice_turn.dart';
import 'package:studee_pc/features/practice/application/practice_service.dart';

final practiceStateProvider =
    StreamProvider.autoDispose<PracticeSessionState>((ref) {
  return ref.watch(practiceServiceProvider).states;
});

/// Active practice chat: transcript + answer composer (locked when complete).
class PracticeChatPanel extends ConsumerStatefulWidget {
  const PracticeChatPanel({
    super.key,
    required this.onNewQuestion,
    required this.onCancel,
    this.completedMessage,
    this.nextQuestionLabel,
    this.showCancelAlways = false,
  });

  final VoidCallback onNewQuestion;
  final VoidCallback onCancel;
  final String? completedMessage;
  final String? nextQuestionLabel;
  final bool showCancelAlways;

  @override
  ConsumerState<PracticeChatPanel> createState() => _PracticeChatPanelState();
}

class _PracticeChatPanelState extends ConsumerState<PracticeChatPanel> {
  final _answerController = TextEditingController();
  final _scrollController = ScrollController();

  PracticeService get _service => ref.read(practiceServiceProvider);

  @override
  void dispose() {
    _answerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppMotion.slow,
        curve: AppMotion.easeOut,
      );
    });
  }

  Future<void> _submit([String? override]) async {
    final text = override ?? _answerController.text;
    if (override == null) _answerController.clear();
    final result = await _service.submitAnswer(text);
    if (!mounted) return;
    result.when(
      success: (_) => _scrollToEnd(),
      failure: (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.userMessage)),
        );
      },
    );
  }

  Future<void> _pickChoice(PracticeChoice choice) => _submit(choice.display);

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(practiceStateProvider);
    final state = async.asData?.value ?? _service.current;
    ref.listen(practiceStateProvider, (_, next) => _scrollToEnd());

    final locked = state.stage.locksComposer;
    final canAnswer = state.stage == PracticeStage.awaitingUser;
    final thinking = state.stage.isBusy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: AppLayout.pageInsets(context).copyWith(bottom: 8),
            itemCount: state.messages.length + (thinking ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= state.messages.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _ThinkingBubble(),
                  ),
                );
              }
              return PracticeMessageBubble(
                message: state.messages[i],
                index: i,
              );
            },
          ),
        ),
        if (state.stage == PracticeStage.completed) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: StudeeGlass(
              borderRadius: AppLayout.radiusControl,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(
                    AppIcons.checkCircle,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.completedMessage ??
                          'Đã xong bài luyện này. Bấm “Câu hỏi mới” để luyện tiếp.',
                      style: const TextStyle(fontSize: 15, height: 1.35),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onNewQuestion,
                    child: Text(widget.nextQuestionLabel ?? 'Câu hỏi mới'),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (state.errorMessage != null &&
            state.stage != PracticeStage.completed) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppLayout.pagePadding,
              0,
              AppLayout.pagePadding,
              AppLayout.gapSm,
            ),
            child: StudeeGlass(
              padding: const EdgeInsets.all(AppLayout.cardPadding),
              child: Row(
                children: [
                  const Icon(AppIcons.error, color: AppColors.error),
                  const SizedBox(width: AppLayout.gapSm),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.error,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (canAnswer && state.currentChoices.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final choice in state.currentChoices) ...[
                  _ChoiceCard(
                    choice: choice,
                    onTap: () => _pickChoice(choice),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Bấm vào đáp án, hoặc gõ A / B rồi Enter cho nhanh.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.secondaryText.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        StudeeGlassFooter(
          padding: AppLayout.footerInsets,
          child: Row(
            children: [
              if (state.stage.isBusy || widget.showCancelAlways)
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Hủy'),
                ),
              Expanded(
                child: TextField(
                  controller: _answerController,
                  enabled: canAnswer && !locked,
                  textInputAction: TextInputAction.send,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: state.stage == PracticeStage.completed
                        ? 'Bài luyện đã kết thúc'
                        : (state.currentChoices.isNotEmpty
                            ? 'Gõ A hoặc B…'
                            : (state.currentCheckQuestion ??
                                'Nhập câu trả lời của bạn…')),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: canAnswer ? (_) => _submit() : null,
                ),
              ),
              IconButton(
                tooltip: 'Gửi',
                onPressed: canAnswer ? () => _submit() : null,
                icon: const Icon(AppIcons.send),
              ),
              if (state.stage == PracticeStage.completed ||
                  state.stage == PracticeStage.failed)
                IconButton(
                  tooltip: widget.nextQuestionLabel ?? 'Câu hỏi mới',
                  onPressed: widget.onNewQuestion,
                  icon: const Icon(AppIcons.refresh),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.elevated.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(14),
        ),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.sparkle, size: AppIcons.sizeMicro, color: AppColors.violet),
          SizedBox(width: 8),
          Text(
            'Trợ lý Stud',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
            ),
          ),
          SizedBox(width: 10),
          StudeeTypingIndicator(),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatefulWidget {
  const _ChoiceCard({required this.choice, required this.onTap});

  final PracticeChoice choice;
  final VoidCallback onTap;

  @override
  State<_ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<_ChoiceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final label = widget.choice.label.toUpperCase();
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppMotion.duration(context, AppMotion.fast),
        decoration: BoxDecoration(
          borderRadius: AppLayout.controlBorder,
          color: _hovered
              ? AppColors.accent.withValues(alpha: 0.1)
              : AppColors.elevated.withValues(alpha: 0.85),
          border: Border.all(
            color: _hovered
                ? AppColors.accent.withValues(alpha: 0.55)
                : AppColors.border,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: AppLayout.controlBorder,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: AppLayout.smBorder,
                      gradient: AppColors.intelligence,
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StudyMarkdown(widget.choice.display, compact: true),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PracticeMessageBubble extends StatelessWidget {
  const PracticeMessageBubble({
    super.key,
    required this.message,
    this.index = 0,
  });

  final PracticeUiMessage message;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == PracticeMessageRole.user;
    final isCoach = message.role == PracticeMessageRole.coach;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bg = switch (message.role) {
      PracticeMessageRole.user => AppColors.accent.withValues(alpha: 0.18),
      PracticeMessageRole.feedback => AppColors.elevated,
      PracticeMessageRole.system => AppColors.surface,
      PracticeMessageRole.coach => AppColors.elevated,
    };
    final label = switch (message.role) {
      PracticeMessageRole.user => 'Bạn',
      PracticeMessageRole.feedback => 'Nhận xét',
      PracticeMessageRole.system => 'Ghi chú',
      PracticeMessageRole.coach => 'Trợ lý Stud',
    };

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(isUser ? 14 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 14),
    );

    Widget bubble = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(
          color: isCoach
              ? AppColors.violet.withValues(alpha: 0.35)
              : AppColors.border.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCoach) ...[
                const Icon(
                  AppIcons.sparkle,
                  size: 12,
                  color: AppColors.violet,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isCoach
                      ? AppColors.violet
                      : AppColors.secondaryText.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          StudyMarkdown(message.text, compact: true),
        ],
      ),
    );

    if (isCoach) {
      bubble = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.violet.withValues(alpha: 0.55),
              AppColors.cyan.withValues(alpha: 0.45),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: bubble,
        ),
      );
    }

    final content = Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.88,
        ),
        child: bubble,
      ),
    );

    if (AppMotion.reduceMotion(context)) return content;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.base,
      curve: AppMotion.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 8),
            child: child,
          ),
        );
      },
      child: content,
    );
  }
}

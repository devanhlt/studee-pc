import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_icons.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/app/widgets/study_markdown.dart';
import 'package:studee_pc/app/widgets/studee_chrome.dart';
import 'package:studee_pc/app/widgets/studee_controls.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/domain/repositories/deepseek_client.dart';
import 'package:studee_pc/features/settings/presentation/ensure_activation_code.dart';
import 'package:studee_pc/features/settings/presentation/privacy_consent_dialog.dart';
import 'package:studee_pc/features/subjects/application/subject_progress_report.dart';
import 'package:studee_pc/features/subjects/application/subjects_providers.dart';

/// Standalone progress report for a subject.
class SubjectReportScreen extends ConsumerStatefulWidget {
  const SubjectReportScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  ConsumerState<SubjectReportScreen> createState() =>
      _SubjectReportScreenState();
}

class _SubjectReportScreenState extends ConsumerState<SubjectReportScreen> {
  String? _adviceMarkdown;
  String? _adviceError;
  bool _adviceLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(subjectQuestionsProvider(widget.subjectId));
    });
  }

  Future<bool> _ensureReady() async {
    if (!await ensureActivationCode(
      context,
      hasCode: () => ref.read(settingsServiceProvider).hasKey(),
    )) {
      return false;
    }
    if (!mounted) return false;
    return ensureDeepSeekPrivacyConsent(
      context,
      store: ref.read(privacyConsentStoreProvider),
    );
  }

  Future<void> _loadAdvice({
    required String subjectName,
    required SubjectProgressStats stats,
    required List<ProgressWeakSample> weakSamples,
  }) async {
    if (_adviceLoading) return;
    if (!await _ensureReady()) return;
    if (!mounted) return;

    setState(() {
      _adviceLoading = true;
      _adviceError = null;
    });

    try {
      final md = await ref.read(deepSeekClientProvider).generateProgressAdvice(
            subjectName: subjectName,
            totalQuestions: stats.totalQuestions,
            practicedQuestions: stats.practicedQuestions,
            neverPracticedQuestions: stats.neverPracticedQuestions,
            weakQuestions: stats.weakQuestions,
            averageScore: stats.averageScore,
            totalPracticeAttempts: stats.totalPracticeAttempts,
            totalIncorrectAttempts: stats.totalIncorrectAttempts,
            weakSamples: [
              for (final s in weakSamples)
                ProgressAdviceWeakSample(
                  stem: s.stem,
                  practiceCount: s.practiceCount,
                  incorrectCount: s.incorrectCount,
                ),
            ],
          );
      if (!mounted) return;
      setState(() {
        _adviceMarkdown = md;
        _adviceLoading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _adviceLoading = false;
        _adviceError = e is AppFailure
            ? e.userMessage
            : 'Không tạo được lời khuyên: $e';
      });
    }
  }

  void _openReview() {
    context.go('/subjects/${widget.subjectId}?tab=review');
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/subjects/${widget.subjectId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncQuestions =
        ref.watch(subjectQuestionsProvider(widget.subjectId));
    final subject =
        ref.watch(subjectByIdProvider(widget.subjectId)).asData?.value;
    final subjectName = subject?.name ?? 'Môn học';
    final theme = Theme.of(context).textTheme;

    return StudeePageScaffold(
      atmosphereIntensity: AppLayout.atmospherePage,
      topBar: StudeeGlassAppBar(
        title: 'Báo cáo',
        subtitle: subject?.name,
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: _goBack,
          icon: const Icon(AppIcons.back),
        ),
      ),
      body: asyncQuestions.when(
        loading: () => const StudeeSkeletonList(),
        error: (e, _) => StudeeStatusState(
          icon: AppIcons.error,
          title: 'Không tải được báo cáo',
          message: '$e',
        ),
        data: (questions) {
          final stats = computeSubjectProgressStats(questions);
          final weakSamples = collectWeakSamples(questions);

          return ListView(
            padding: AppLayout.pageInsets(context).copyWith(bottom: 28),
            children: [
              StudeeGlass(
                padding: const EdgeInsets.all(AppLayout.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiến độ luyện tập',
                      style: theme.titleSmall,
                    ),
                    const SizedBox(height: AppLayout.gapXs),
                    Text(
                      'Số liệu từ Giải / Luyện / Ôn tập đã lưu trên máy.',
                      style: theme.bodySmall,
                    ),
                    const SizedBox(height: AppLayout.gapMd),
                    Row(
                      children: [
                        Expanded(
                          child: _ReportStatCard(
                            label: 'Số câu đã luyện',
                            value: stats.practicedLabel,
                            hint: 'trên tổng số câu',
                          ),
                        ),
                        const SizedBox(width: AppLayout.gapSm),
                        Expanded(
                          child: _ReportStatCard(
                            label: 'Điểm trung bình',
                            value: stats.averageScoreLabel,
                            hint: stats.averageScore == null
                                ? 'chưa có lần luyện'
                                : 'thang điểm 10',
                          ),
                        ),
                      ],
                    ),
                    if (stats.neverPracticedQuestions > 0 ||
                        stats.weakQuestions > 0) ...[
                      const SizedBox(height: AppLayout.gapMd),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (stats.neverPracticedQuestions > 0)
                            StudeePill(
                              label:
                                  '${stats.neverPracticedQuestions} câu chưa luyện',
                              color: AppColors.secondaryText,
                            ),
                          if (stats.weakQuestions > 0)
                            StudeePill(
                              label: '${stats.weakQuestions} câu còn yếu',
                              color: AppColors.warning,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppLayout.gapMd),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _adviceLoading
                                ? null
                                : () => _loadAdvice(
                                      subjectName: subjectName,
                                      stats: stats,
                                      weakSamples: weakSamples,
                                    ),
                            icon: _adviceLoading
                                ? const SizedBox(
                                    width: AppIcons.sizeInline,
                                    height: AppIcons.sizeInline,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    AppIcons.report,
                                    size: AppIcons.sizeInline,
                                  ),
                            label: Text(
                              _adviceMarkdown == null
                                  ? 'Phân tích với Trợ lý Stud'
                                  : 'Phân tích lại',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppLayout.gapSm),
                        OutlinedButton(
                          onPressed: _openReview,
                          child: const Text('Ôn tập'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppLayout.gapSm),
              StudeeGlass(
                padding: const EdgeInsets.all(AppLayout.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lời khuyên',
                      style: theme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppLayout.gapSm),
                    if (_adviceLoading && _adviceMarkdown == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_adviceError != null)
                      Text(
                        _adviceError!,
                        style: theme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                      )
                    else if (_adviceMarkdown != null)
                      StudyMarkdown(_adviceMarkdown!)
                    else if (stats.totalQuestions == 0)
                      Text(
                        'Chưa có câu hỏi trong môn này. Nhập kiến thức hoặc tệp .stud để bắt đầu.',
                        style: theme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      )
                    else
                      Text(
                        'Nhấn Phân tích với Trợ lý Stud để nhận nhận xét và gợi ý ôn tập.',
                        style: theme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReportStatCard extends StatelessWidget {
  const _ReportStatCard({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: AppLayout.controlBorder,
        color: AppColors.accent.withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.labelMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: theme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

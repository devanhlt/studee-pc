import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/widgets/studee_token_status_bar.dart';
import 'package:studee_pc/features/settings/application/entitlement_provider.dart';
import 'package:studee_pc/features/settings/application/settings_service.dart';

void main() {
  testWidgets('token status bar shows remaining quota text', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          entitlementProvider.overrideWith(
            (ref) async => const EntitlementInfo(
              plan: 'pro',
              maxSolves: 50000,
              solvesUsed: 10000,
              remaining: 40000,
              status: 'active',
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: StudeeTokenStatusBar()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('40,000 / 50,000'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(FractionallySizedBox), findsOneWidget);

    final fill = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(fill.widthFactor, closeTo(0.8, 0.0001));
    expect(
      tester.widget<ColoredBox>(find.descendant(
        of: find.byType(FractionallySizedBox),
        matching: find.byType(ColoredBox),
      )).color,
      AppColors.accent,
    );
  });

  testWidgets('token status bar shows empty-state text without a code', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          entitlementProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(
          home: Scaffold(body: StudeeTokenStatusBar()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa có mã'), findsOneWidget);
    final fill = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(fill.widthFactor, 0);
  });
}

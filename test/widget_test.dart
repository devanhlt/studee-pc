import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/core/utils/text_normalizer.dart';

void main() {
  test('smoke — TextNormalizer preserves Vietnamese', () {
    expect(TextNormalizer.normalize('Nguyễn'), 'Nguyễn');
    expect(TextNormalizer.accentFolded('đường'), 'duong');
  });

  testWidgets('smoke — MaterialApp with Vietnamese title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Studee — Trợ lý học tập')),
        ),
      ),
    );
    expect(find.textContaining('Trợ lý học tập'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/core/logging/app_logger.dart';

void main() {
  group('AppLogger.redact', () {
    test('redacts api key assignments', () {
      final out = AppLogger.redact('api_key: sk-abcdefghijklmnop');
      expect(out.toLowerCase(), contains('redacted'));
      expect(out, isNot(contains('sk-abcdefghijklmnop')));
    });

    test('redacts Bearer tokens', () {
      final out = AppLogger.redact('Authorization Bearer abcdefghijklmnop');
      expect(out, contains('[REDACTED]'));
    });

    test('leaves safe status messages intact', () {
      final out = AppLogger.redact('OCR page 2 completed');
      expect(out, 'OCR page 2 completed');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/data/backend/checkout_client.dart';

void main() {
  group('CheckoutClient SSE parse', () {
    test('parses paid event', () {
      const event =
          'data: {"status":"paid","activation_code":"STU-AAAA-BBBB-CCCC","code_expires_at":"2030-03-01T00:00:00.000Z"}';
      final status = CheckoutClient.parseSseEventForTest(event);
      expect(status, isNotNull);
      expect(status!.status, 'paid');
      expect(status.activationCode, 'STU-AAAA-BBBB-CCCC');
      expect(status.codeExpiresAt, isNotNull);
      expect(status.isPaid, isTrue);
    });

    test('ignores heartbeat comments', () {
      expect(CheckoutClient.parseSseEventForTest(':heartbeat'), isNull);
    });

    test('parses pending with expires_at', () {
      const event =
          'data: {"status":"pending","pay_code":"STUDEEABC12345","expires_at":"2030-01-01T00:00:00.000Z"}';
      final status = CheckoutClient.parseSseEventForTest(event);
      expect(status!.status, 'pending');
      expect(status.payCode, 'STUDEEABC12345');
      expect(status.expiresAt, isNotNull);
    });
  });
}

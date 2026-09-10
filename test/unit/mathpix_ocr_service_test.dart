import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studee_pc/data/mathpix/mathpix_client.dart';
import 'package:studee_pc/data/mathpix/mathpix_ocr_service.dart';
import 'package:studee_pc/domain/repositories/credentials_repository.dart';
import 'package:studee_pc/domain/repositories/ocr_service.dart';
import 'package:studee_pc/domain/repositories/stored_api_credentials.dart';

class _MemCreds implements CredentialsRepository {
  String? deepSeek;
  String? mathpixId = 'test_app';
  String? mathpixKey = 'test_key';
  String? mathpixUrl;

  @override
  Future<StoredApiCredentials> loadAll() async => StoredApiCredentials(
        deepSeekApiKey: deepSeek,
        mathpixAppId: mathpixId,
        mathpixAppKey: mathpixKey,
        mathpixBaseUrl: mathpixUrl,
      );

  @override
  Future<void> deleteDeepSeekApiKey() async => deepSeek = null;

  @override
  Future<void> deleteMathpixCredentials() async {
    mathpixId = null;
    mathpixKey = null;
    mathpixUrl = null;
  }

  @override
  Future<String?> getDeepSeekApiKey() async => deepSeek;

  @override
  Future<String?> getMathpixAppId() async => mathpixId;

  @override
  Future<String?> getMathpixAppKey() async => mathpixKey;

  @override
  Future<String?> getMathpixBaseUrl() async => mathpixUrl;

  @override
  Future<bool> hasDeepSeekApiKey() async =>
      deepSeek != null && deepSeek!.isNotEmpty;

  @override
  Future<bool> hasMathpixCredentials() async =>
      mathpixId != null &&
      mathpixId!.isNotEmpty &&
      mathpixKey != null &&
      mathpixKey!.isNotEmpty;

  @override
  Future<void> setDeepSeekApiKey(String apiKey) async => deepSeek = apiKey;

  @override
  Future<void> setMathpixAppId(String appId) async => mathpixId = appId;

  @override
  Future<void> setMathpixAppKey(String appKey) async => mathpixKey = appKey;

  @override
  Future<void> setMathpixBaseUrl(String? baseUrl) async => mathpixUrl = baseUrl;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MathpixOcrService', () {
    test('mock mode writes page JSON and completes', () async {
      final dir = await Directory.systemTemp.createTemp('mathpix_ocr_');
      final image = File('${dir.path}/in.png');
      await image.writeAsBytes(const [1, 2, 3]);
      final out = '${dir.path}/out';

      final service = MathpixOcrService(
        client: MathpixClient(credentials: _MemCreds()),
        forceMock: true,
      );

      final events = await service
          .process(
            OcrRequest(
              jobId: 'job1',
              action: 'parse_image',
              inputPath: image.path,
              outputDirectory: out,
            ),
          )
          .toList();

      expect(events.whereType<OcrPageCompletedEvent>(), hasLength(1));
      expect(events.whereType<OcrCompletedEvent>(), hasLength(1));
      final pageFile = File('$out/page_0001.json');
      expect(await pageFile.exists(), isTrue);
      final map = jsonDecode(await pageFile.readAsString()) as Map;
      expect(map['engine'], 'mock');
      expect(map['text'], contains('Mock OCR'));
    });

    test('image path calls /v3/text and maps response', () async {
      final dir = await Directory.systemTemp.createTemp('mathpix_ocr_');
      final image = File('${dir.path}/shot.png');
      // Minimal PNG header-ish bytes; client will base64 them.
      await image.writeAsBytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
        ),
      );
      final out = '${dir.path}/out';

      final mockHttp = MockClient((request) async {
        expect(request.url.path, '/v3/text');
        expect(request.headers['app_id'], 'test_app');
        expect(request.headers['app_key'], 'test_key');
        expect(request.method, 'POST');
        // Multipart file upload (guide: file + options_json).
        final contentType = request.headers['content-type'] ?? '';
        expect(contentType, contains('multipart/form-data'));
        return http.Response(
          jsonEncode({
            'text': r'Khi nào $\det(A) \neq 0$?',
            'confidence': 0.92,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = MathpixOcrService(
        client: MathpixClient(
          credentials: _MemCreds(),
          httpClient: mockHttp,
        ),
      );

      final events = await service
          .process(
            OcrRequest(
              jobId: 'job2',
              action: 'parse_image',
              inputPath: image.path,
              outputDirectory: out,
            ),
          )
          .toList();

      expect(events.whereType<OcrFailedEvent>(), isEmpty);
      final done = events.whereType<OcrPageCompletedEvent>().single;
      final map =
          jsonDecode(await File('$out/${done.resultPath}').readAsString())
              as Map;
      expect(map['engine'], 'mathpix');
      expect(map['text'], contains(r'$\det(A)'));
      expect(map['confidence'], closeTo(0.92, 1e-9));
    });

    test('pdf path uploads, polls, splits pagebreaks', () async {
      final dir = await Directory.systemTemp.createTemp('mathpix_pdf_');
      final pdf = File('${dir.path}/doc.pdf');
      await pdf.writeAsBytes([0x25, 0x50, 0x44, 0x46]); // %PDF
      final out = '${dir.path}/out';
      var pollCount = 0;

      final mockHttp = MockClient((request) async {
        if (request.method == 'POST' && request.url.path == '/v3/pdf') {
          return http.Response(
            jsonEncode({'pdf_id': 'pdf_abc'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' && request.url.path == '/v3/pdf/pdf_abc') {
          pollCount++;
          if (pollCount < 2) {
            return http.Response(
              jsonEncode({
                'status': 'processing',
                'num_pages': 2,
                'num_pages_completed': 1,
                'percent_done': 50,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({
              'status': 'completed',
              'num_pages': 2,
              'num_pages_completed': 2,
              'percent_done': 100,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' &&
            request.url.path == '/v3/pdf/pdf_abc.mmd') {
          return http.Response(
            'Page one text\n\\pagebreak\nPage two text\n',
            200,
          );
        }
        return http.Response('unexpected ${request.url}', 500);
      });

      final service = MathpixOcrService(
        client: MathpixClient(
          credentials: _MemCreds(),
          httpClient: mockHttp,
          pdfPollInterval: Duration.zero,
        ),
      );

      final events = await service
          .process(
            OcrRequest(
              jobId: 'job3',
              action: 'parse_document',
              inputPath: pdf.path,
              outputDirectory: out,
            ),
          )
          .toList();

      expect(events.whereType<OcrFailedEvent>(), isEmpty);
      final pages = events.whereType<OcrPageCompletedEvent>().toList();
      expect(pages, hasLength(2));
      final p1 =
          jsonDecode(await File('$out/${pages[0].resultPath}').readAsString())
              as Map;
      final p2 =
          jsonDecode(await File('$out/${pages[1].resultPath}').readAsString())
              as Map;
      expect(p1['text'], 'Page one text');
      expect(p2['text'], 'Page two text');
      expect(events.whereType<OcrCompletedEvent>(), hasLength(1));
    });
    test('testConnection uses ocr-usage not blank image', () async {
      final mockHttp = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/v3/ocr-usage');
        expect(request.headers['app_id'], 'test_app');
        expect(request.headers['app_key'], 'test_key');
        return http.Response(
          jsonEncode({
            'ocr_usage': <Map<String, dynamic>>[],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = MathpixClient(
        credentials: _MemCreds(),
        httpClient: mockHttp,
      );
      await client.testConnection();
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/data/file_storage/app_paths.dart';

/// Copies bundled PaddleOCR-VL 1.6 assets into ApplicationData on first launch.
///
/// Fully automatic — no user download, path picker, or Hugging Face token.
/// When model files are still stubs (`.gitkeep` / empty), uses a placeholder
/// checksum so first-run install succeeds in development.
class ModelBundle {
  ModelBundle({AppPaths? paths}) : _paths = paths ?? AppPaths();

  final AppPaths _paths;
  final AppLogger _log = AppLogger('ModelBundle');

  static const String assetPrefix = 'assets/models/${AppPaths.modelBundleName}';
  static const String checksumFileName = 'checksums.json';

  /// Placeholder digest used when only stub assets (e.g. `.gitkeep`) are present.
  static const String placeholderChecksum =
      '0000000000000000000000000000000000000000000000000000000000000000';

  bool _ensured = false;

  /// Ensures the model directory exists under ApplicationData and matches
  /// expected checksums. Idempotent after the first successful call.
  Future<Result<String>> ensureInstalled() async {
    if (_ensured) {
      return Success(await _paths.paddleOcrModelDir());
    }

    try {
      final destDirPath = await _paths.paddleOcrModelDir();
      final destDir = Directory(destDirPath);
      await destDir.create(recursive: true);

      final assetFiles = await _listBundledAssets();
      if (assetFiles.isEmpty) {
        // Dev stub: create .gitkeep and placeholder checksums.
        final keep = File(p.join(destDirPath, '.gitkeep'));
        if (!await keep.exists()) {
          await keep.writeAsString('', flush: true);
        }
        await _writeChecksumFile(destDirPath, {
          '.gitkeep': placeholderChecksum,
        });
        _log.info('Installed placeholder OCR model bundle (stubs)');
        _ensured = true;
        return Success(destDirPath);
      }

      final expected = <String, String>{};
      for (final assetPath in assetFiles) {
        final relative = assetPath.substring('$assetPrefix/'.length);
        if (relative.isEmpty || relative == checksumFileName) continue;

        final bytes = (await rootBundle.load(assetPath)).buffer.asUint8List();
        final digest = bytes.isEmpty
            ? placeholderChecksum
            : sha256.convert(bytes).toString();
        expected[relative] = digest;

        final out = File(p.join(destDirPath, relative));
        await out.parent.create(recursive: true);
        if (!await out.exists() || !await _fileMatches(out, digest)) {
          await out.writeAsBytes(bytes, flush: true);
        }
      }

      if (expected.isEmpty) {
        expected['.gitkeep'] = placeholderChecksum;
        final keep = File(p.join(destDirPath, '.gitkeep'));
        if (!await keep.exists()) {
          await keep.writeAsString('', flush: true);
        }
      }

      await _writeChecksumFile(destDirPath, expected);

      final verify = await verifyChecksums();
      if (verify is Failure<void>) {
        // Retry once by re-copying from bundle.
        _log.warning('Model checksum failed; restoring from bundle');
        for (final entry in expected.entries) {
          final assetPath = '$assetPrefix/${entry.key}';
          try {
            final bytes =
                (await rootBundle.load(assetPath)).buffer.asUint8List();
            final out = File(p.join(destDirPath, entry.key));
            await out.parent.create(recursive: true);
            await out.writeAsBytes(bytes, flush: true);
          } on Object {
            // Stub assets may not be loadable individually; keep placeholder.
            if (entry.value == placeholderChecksum) {
              final out = File(p.join(destDirPath, entry.key));
              await out.parent.create(recursive: true);
              if (!await out.exists()) {
                await out.writeAsString('', flush: true);
              }
            }
          }
        }
        final retry = await verifyChecksums();
        if (retry is Failure<void>) {
          return Failure(retry.failure);
        }
      }

      _log.info('OCR model bundle ready at ApplicationData/models');
      _ensured = true;
      return Success(destDirPath);
    } on Object catch (e) {
      _log.severe('Model bundle install failed', e);
      return Failure(
        OcrFailure(
          userMessage:
              'Không chuẩn bị được mô hình OCR nội bộ. Thử khởi động lại ứng dụng.',
          code: 'model_bundle_install_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  /// Verifies on-disk files against `checksums.json`.
  Future<Result<void>> verifyChecksums() async {
    try {
      final destDirPath = await _paths.paddleOcrModelDir();
      final checksumFile = File(p.join(destDirPath, checksumFileName));
      if (!await checksumFile.exists()) {
        return const Failure(
          OcrFailure(
            userMessage: 'Thiếu tệp kiểm tra mô hình OCR.',
            code: 'model_checksum_missing',
          ),
        );
      }

      final map =
          jsonDecode(await checksumFile.readAsString()) as Map<String, dynamic>;
      for (final entry in map.entries) {
        final file = File(p.join(destDirPath, entry.key));
        final expected = entry.value as String;
        if (expected == placeholderChecksum) {
          // Stub mode — accept missing or empty files.
          continue;
        }
        if (!await file.exists()) {
          return Failure(
            OcrFailure(
              userMessage: 'Thiếu tệp mô hình OCR.',
              code: 'model_file_missing',
              details: entry.key,
            ),
          );
        }
        if (!await _fileMatches(file, expected)) {
          return Failure(
            OcrFailure(
              userMessage: 'Mô hình OCR không khớp checksum.',
              code: 'model_checksum_mismatch',
              details: entry.key,
            ),
          );
        }
      }
      return const Success(null);
    } on Object catch (e) {
      return Failure(
        OcrFailure(
          userMessage: 'Không kiểm tra được mô hình OCR.',
          code: 'model_verify_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  Future<List<String>> _listBundledAssets() async {
    try {
      final manifestJson =
          await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest =
          jsonDecode(manifestJson) as Map<String, dynamic>;
      return manifest.keys
          .where((k) => k.startsWith('$assetPrefix/'))
          .toList();
    } on Object {
      // AssetManifest may be unavailable in some test/desktop contexts.
      return const [];
    }
  }

  Future<void> _writeChecksumFile(
    String destDirPath,
    Map<String, String> checksums,
  ) async {
    final file = File(p.join(destDirPath, checksumFileName));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(checksums),
      flush: true,
    );
  }

  Future<bool> _fileMatches(File file, String expectedSha256) async {
    if (expectedSha256 == placeholderChecksum) return true;
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString() == expectedSha256;
  }
}

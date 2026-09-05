import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/core/utils/path_safety.dart';
import 'package:studee_pc/data/file_storage/app_paths.dart';

/// Filesystem operations for a single subject's folder tree.
///
/// Preserves originals; never overwrites them with AI-normalized content.
/// All writes are validated to stay under the subject folder.
class SubjectFileStore {
  SubjectFileStore({AppPaths? paths}) : _paths = paths ?? AppPaths();

  final AppPaths _paths;
  final AppLogger _log = AppLogger('SubjectFileStore');

  static const int currentSchemaVersion = 1;

  /// Creates `subjects/subject_<uuid>/` with manifest, empty DB placeholders,
  /// `sources/`, and `attachments/`.
  Future<Result<String>> createSubjectFolder({
    required String subjectId,
    required String displayName,
    String appVersion = '1.0.0',
  }) async {
    try {
      final folder = await _paths.subjectFolder(subjectId);
      final dir = Directory(folder);
      if (await dir.exists()) {
        return Failure(
          ConflictFailure(
            userMessage: 'Thư mục môn học đã tồn tại.',
            code: 'subject_folder_exists',
            details: subjectId,
          ),
        );
      }

      await dir.create(recursive: true);
      await Directory(p.join(folder, 'sources')).create(recursive: true);
      await Directory(p.join(folder, 'attachments')).create(recursive: true);

      final manifest = <String, Object?>{
        'subject_id': subjectId,
        'display_name': displayName,
        'schema_version': currentSchemaVersion,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'app_version': appVersion,
      };
      final manifestFile = File(p.join(folder, 'manifest.json'));
      await manifestFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(manifest),
        flush: true,
      );

      _log.info('Created subject folder id=$subjectId');
      return Success(folder);
    } on Object catch (e) {
      _log.severe('Failed to create subject folder', e);
      return Failure(
        DatabaseFailure(
          userMessage: 'Không tạo được thư mục môn học.',
          code: 'create_subject_folder_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  /// Updates `display_name` in manifest.json only — never renames the folder.
  Future<Result<void>> updateManifestDisplayName({
    required String subjectId,
    required String displayName,
  }) async {
    try {
      final path = await _paths.subjectManifestPath(subjectId);
      final file = File(path);
      if (!await file.exists()) {
        return Failure(
          NotFoundFailure(
            userMessage: 'Không tìm thấy manifest môn học.',
            code: 'manifest_missing',
            details: subjectId,
          ),
        );
      }
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      map['display_name'] = displayName;
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(map),
        flush: true,
      );
      return const Success(null);
    } on Object catch (e) {
      return Failure(
        DatabaseFailure(
          userMessage: 'Không cập nhật được manifest.',
          code: 'manifest_update_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  Future<Result<Map<String, dynamic>>> readManifest(String subjectId) async {
    try {
      final path = await _paths.subjectManifestPath(subjectId);
      final file = File(path);
      if (!await file.exists()) {
        return Failure(
          NotFoundFailure(
            userMessage: 'Không tìm thấy manifest môn học.',
            code: 'manifest_missing',
            details: subjectId,
          ),
        );
      }
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return Success(map);
    } on Object catch (e) {
      return Failure(
        ValidationFailure(
          userMessage: 'Manifest môn học không hợp lệ.',
          code: 'manifest_parse_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  /// Preserves an original source file under `sources/source_<uuid>/`.
  ///
  /// Never overwrites an existing original with the same relative name.
  Future<Result<String>> preserveOriginal({
    required String subjectId,
    required String sourceId,
    required String fileName,
    required List<int> bytes,
  }) async {
    final folder = await _paths.sourceFolder(subjectId, sourceId);
    final subjectRoot = await _paths.subjectFolder(subjectId);
    final relative = p.join('sources', AppPaths.sourceFolderName(sourceId), fileName);
    final resolved = PathSafety.resolveUnderRoot(
      rootDirectory: subjectRoot,
      relativePath: relative,
    );
    if (resolved is Failure<String>) return resolved;

    try {
      await Directory(folder).create(recursive: true);
      final target = File(resolved.valueOrNull!);
      if (await target.exists()) {
        return const Failure(
          ConflictFailure(
            userMessage: 'Tệp gốc đã tồn tại và không bị ghi đè.',
            code: 'original_already_exists',
          ),
        );
      }
      await target.writeAsBytes(bytes, flush: true);
      _log.info('Preserved original sourceId=$sourceId file=$fileName');
      return Success(relative.replaceAll('\\', '/'));
    } on Object catch (e) {
      return Failure(
        DatabaseFailure(
          userMessage: 'Không lưu được tệp gốc.',
          code: 'preserve_original_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  /// Writes raw OCR JSON for a page under `sources/.../ocr/`.
  Future<Result<String>> writeOcrJson({
    required String subjectId,
    required String sourceId,
    required int pageNumber,
    required Map<String, dynamic> ocrJson,
  }) async {
    final pageName = 'page_${pageNumber.toString().padLeft(4, '0')}.json';
    final relative = p.join(
      'sources',
      AppPaths.sourceFolderName(sourceId),
      'ocr',
      pageName,
    );
    return _writeJsonRelative(
      subjectId: subjectId,
      relativePath: relative,
      data: ocrJson,
      overwrite: true,
    );
  }

  /// Writes a derived artifact (e.g. document.md, structured.json).
  Future<Result<String>> writeDerivedFile({
    required String subjectId,
    required String sourceId,
    required String fileName,
    required List<int> bytes,
  }) async {
    final subjectRoot = await _paths.subjectFolder(subjectId);
    final relative = p.join(
      'sources',
      AppPaths.sourceFolderName(sourceId),
      'derived',
      fileName,
    );
    final resolved = PathSafety.resolveUnderRoot(
      rootDirectory: subjectRoot,
      relativePath: relative,
    );
    if (resolved is Failure<String>) return resolved;

    try {
      final file = File(resolved.valueOrNull!);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      return Success(relative.replaceAll('\\', '/'));
    } on Object catch (e) {
      return Failure(
        DatabaseFailure(
          userMessage: 'Không ghi được tệp dẫn xuất.',
          code: 'write_derived_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  /// SHA-256 hex digest of [bytes].
  static String sha256OfBytes(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  /// SHA-256 of a file on disk (validated under subject root).
  Future<Result<String>> sha256OfFile({
    required String subjectId,
    required String relativePath,
  }) async {
    final subjectRoot = await _paths.subjectFolder(subjectId);
    final resolved = PathSafety.resolveUnderRoot(
      rootDirectory: subjectRoot,
      relativePath: relativePath,
    );
    if (resolved is Failure<String>) return resolved;

    try {
      final file = File(resolved.valueOrNull!);
      if (!await file.exists()) {
        return const Failure(
          NotFoundFailure(
            userMessage: 'Không tìm thấy tệp để băm.',
            code: 'hash_file_missing',
          ),
        );
      }
      final digest = await sha256.bind(file.openRead()).first;
      return Success(digest.toString());
    } on Object catch (e) {
      return Failure(
        DatabaseFailure(
          userMessage: 'Không tính được SHA-256.',
          code: 'sha256_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  /// Exports subject folder (manifest + DB + sources + attachments) as one ZIP.
  Future<Result<String>> exportZip({
    required String subjectId,
    required String destinationZipPath,
  }) async {
    try {
      final folder = await _paths.subjectFolder(subjectId);
      final subjectsRoot = await _paths.subjectsRoot();
      final folderCheck = PathSafety.ensureUnderRoot(
        rootDirectory: subjectsRoot,
        absolutePath: folder,
      );
      if (folderCheck is Failure<String>) {
        return Failure(folderCheck.failure);
      }

      final dir = Directory(folder);
      if (!await dir.exists()) {
        return Failure(
          NotFoundFailure(
            userMessage: 'Không tìm thấy thư mục môn học để xuất.',
            code: 'export_folder_missing',
            details: subjectId,
          ),
        );
      }

      final archive = Archive();
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final relative = p.relative(entity.path, from: folder);
        final data = await entity.readAsBytes();
        archive.addFile(
          ArchiveFile(relative.replaceAll('\\', '/'), data.length, data),
        );
      }

      final encoded = ZipEncoder().encode(archive);

      final out = File(destinationZipPath);
      await out.parent.create(recursive: true);
      await out.writeAsBytes(Uint8List.fromList(encoded), flush: true);
      _log.info('Exported subject id=$subjectId');
      return Success(destinationZipPath);
    } on Object catch (e) {
      return Failure(
        DatabaseFailure(
          userMessage: 'Xuất môn học thất bại.',
          code: 'export_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  /// Restores a subject folder from an exported ZIP.
  ///
  /// Returns manifest fields needed to register the subject in the catalog.
  Future<Result<({String subjectId, String displayName, int schemaVersion})>>
      importZip({required String zipPath}) async {
    try {
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        return Failure(
          NotFoundFailure(
            userMessage: 'Không tìm thấy tệp ZIP.',
            code: 'import_zip_missing',
            details: zipPath,
          ),
        );
      }

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      if (archive.isEmpty) {
        return const Failure(
          ValidationFailure(
            userMessage: 'Tệp ZIP trống hoặc không hợp lệ.',
            code: 'import_zip_empty',
          ),
        );
      }

      // Locate manifest.json (root or one folder deep).
      ArchiveFile? manifestEntry;
      String prefix = '';
      for (final file in archive.files) {
        if (!file.isFile) continue;
        final name = file.name.replaceAll('\\', '/');
        if (name == 'manifest.json' || name.endsWith('/manifest.json')) {
          manifestEntry = file;
          final idx = name.lastIndexOf('/');
          prefix = idx >= 0 ? name.substring(0, idx + 1) : '';
          break;
        }
      }
      if (manifestEntry == null) {
        return const Failure(
          ValidationFailure(
            userMessage:
                'ZIP thiếu manifest.json — không phải bản xuất môn học Studee.',
            code: 'import_manifest_missing',
          ),
        );
      }

      final manifestContent = utf8.decode(manifestEntry.content as List<int>);
      final manifest =
          jsonDecode(manifestContent) as Map<String, dynamic>;
      final subjectId = (manifest['subject_id'] as String?)?.trim() ?? '';
      final displayName =
          (manifest['display_name'] as String?)?.trim() ?? 'Môn học đã nhập';
      final schemaVersion =
          (manifest['schema_version'] as num?)?.toInt() ?? currentSchemaVersion;
      if (subjectId.isEmpty) {
        return const Failure(
          ValidationFailure(
            userMessage: 'manifest.json thiếu subject_id.',
            code: 'import_subject_id_missing',
          ),
        );
      }

      final folder = await _paths.subjectFolder(subjectId);
      final subjectsRoot = await _paths.subjectsRoot();
      final folderCheck = PathSafety.ensureUnderRoot(
        rootDirectory: subjectsRoot,
        absolutePath: folder,
      );
      if (folderCheck is Failure<String>) {
        return Failure(folderCheck.failure);
      }

      final dir = Directory(folder);
      if (await dir.exists()) {
        return Failure(
          ConflictFailure(
            userMessage: 'Môn học này đã tồn tại trên máy (cùng ID).',
            code: 'import_subject_exists',
            details: subjectId,
          ),
        );
      }

      await dir.create(recursive: true);

      for (final file in archive.files) {
        if (!file.isFile) continue;
        var relative = file.name.replaceAll('\\', '/');
        if (prefix.isNotEmpty) {
          if (!relative.startsWith(prefix)) continue;
          relative = relative.substring(prefix.length);
        }
        if (relative.isEmpty || relative.endsWith('/')) continue;
        // Block path escape.
        final normalized = p.normalize(relative);
        if (normalized.startsWith('..') || p.isAbsolute(normalized)) {
          continue;
        }
        final outPath = p.join(folder, normalized);
        final outCheck = PathSafety.ensureUnderRoot(
          rootDirectory: folder,
          absolutePath: outPath,
        );
        if (outCheck is Failure<String>) continue;

        final out = File(outPath);
        await out.parent.create(recursive: true);
        await out.writeAsBytes(
          Uint8List.fromList(file.content as List<int>),
          flush: true,
        );
      }

      // Ensure expected top-level dirs exist even if zip omitted empties.
      await Directory(p.join(folder, 'sources')).create(recursive: true);
      await Directory(p.join(folder, 'attachments')).create(recursive: true);

      final dbFile = File(p.join(folder, 'subject.db'));
      if (!await dbFile.exists()) {
        await Directory(folder).delete(recursive: true);
        return const Failure(
          ValidationFailure(
            userMessage: 'ZIP thiếu subject.db — không thể nhập môn học.',
            code: 'import_db_missing',
          ),
        );
      }

      _log.info('Imported subject id=$subjectId from zip');
      return Success((
        subjectId: subjectId,
        displayName: displayName,
        schemaVersion: schemaVersion,
      ));
    } on AppFailure catch (f) {
      return Failure(f);
    } on Object catch (e) {
      return Failure(
        DatabaseFailure(
          userMessage: 'Nhập môn học từ ZIP thất bại.',
          code: 'import_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  /// Deletes the subject folder after confirming [confirmedAbsolutePath] matches.
  Future<Result<void>> deleteSubjectFolder({
    required String subjectId,
    required String confirmedAbsolutePath,
  }) async {
    try {
      final folder = await _paths.subjectFolder(subjectId);
      final normalizedExpected = p.normalize(p.absolute(folder));
      final normalizedConfirmed = p.normalize(p.absolute(confirmedAbsolutePath));
      if (normalizedExpected != normalizedConfirmed) {
        return const Failure(
          ValidationFailure(
            userMessage:
                'Đường dẫn xác nhận không khớp thư mục môn học sẽ bị xóa.',
            code: 'delete_path_mismatch',
          ),
        );
      }

      final subjectsRoot = await _paths.subjectsRoot();
      final safety = PathSafety.ensureUnderRoot(
        rootDirectory: subjectsRoot,
        absolutePath: normalizedExpected,
      );
      if (safety is Failure<String>) {
        return Failure(safety.failure);
      }

      final dir = Directory(normalizedExpected);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      _log.info('Deleted subject folder id=$subjectId');
      return const Success(null);
    } on Object catch (e) {
      return Failure(
        DatabaseFailure(
          userMessage: 'Không xóa được thư mục môn học.',
          code: 'delete_folder_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  Future<Result<String>> _writeJsonRelative({
    required String subjectId,
    required String relativePath,
    required Map<String, dynamic> data,
    required bool overwrite,
  }) async {
    final subjectRoot = await _paths.subjectFolder(subjectId);
    final resolved = PathSafety.resolveUnderRoot(
      rootDirectory: subjectRoot,
      relativePath: relativePath,
    );
    if (resolved is Failure<String>) return resolved;

    try {
      final file = File(resolved.valueOrNull!);
      if (!overwrite && await file.exists()) {
        return const Failure(
          ConflictFailure(
            userMessage: 'Tệp đã tồn tại.',
            code: 'file_exists',
          ),
        );
      }
      await file.parent.create(recursive: true);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
        flush: true,
      );
      return Success(relativePath.replaceAll('\\', '/'));
    } on Object catch (e) {
      return Failure(
        DatabaseFailure(
          userMessage: 'Không ghi được tệp JSON.',
          code: 'write_json_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }
}

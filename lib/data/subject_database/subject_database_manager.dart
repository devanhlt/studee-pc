import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/core/utils/path_safety.dart';
import 'package:studee_pc/data/file_storage/app_paths.dart';
import 'package:studee_pc/data/subject_database/subject_database.dart';

/// Opens and closes per-subject databases; only one active DB at a time.
///
/// Before destructive migrations, creates a recoverable `.bak` copy beside
/// `subject.db`.
class SubjectDatabaseManager {
  SubjectDatabaseManager({AppPaths? paths}) : _paths = paths ?? AppPaths();

  final AppPaths _paths;
  final AppLogger _log = AppLogger('SubjectDatabaseManager');

  SubjectDatabase? _active;
  String? _activeSubjectId;

  String? get activeSubjectId => _activeSubjectId;

  SubjectDatabase? get activeDatabase => _active;

  /// Opens [subjectId]'s database, closing any previously open subject DB.
  Future<SubjectDatabase> open(String subjectId) async {
    if (_activeSubjectId == subjectId && _active != null) {
      return _active!;
    }

    await close();

    final folder = await _paths.subjectFolder(subjectId);
    final dbPath = SubjectDatabase.databaseFileName(folder);
    final safety = PathSafety.ensureUnderRoot(
      rootDirectory: await _paths.subjectsRoot(),
      absolutePath: dbPath,
    );
    if (safety is Failure) {
      throw DatabaseFailure(
        userMessage: 'Đường dẫn cơ sở dữ liệu môn học không hợp lệ.',
        code: 'subject_db_path_invalid',
        details: subjectId,
      );
    }

    _log.info('Opening subject database for id=$subjectId');
    final db = SubjectDatabase.atPath(dbPath);
    // Touch schema / migrations.
    await db.customSelect('SELECT 1').get();
    _active = db;
    _activeSubjectId = subjectId;
    return db;
  }

  /// Closes the active subject database if any.
  Future<void> close() async {
    final db = _active;
    if (db == null) return;
    _log.info('Closing subject database id=$_activeSubjectId');
    await db.close();
    _active = null;
    _activeSubjectId = null;
  }

  /// Returns the open DB or throws if none is active.
  SubjectDatabase requireActive() {
    final db = _active;
    if (db == null) {
      throw const DatabaseFailure(
        userMessage: 'Chưa mở môn học nào. Hãy chọn một môn học trước.',
        code: 'no_active_subject_db',
      );
    }
    return db;
  }

  /// Copies `subject.db` to `subject.db.bak-<timestamp>` before a destructive
  /// migration. Call this from migration orchestration code.
  Future<File> backupBeforeDestructiveMigration(String subjectId) async {
    final folder = await _paths.subjectFolder(subjectId);
    final dbPath = SubjectDatabase.databaseFileName(folder);
    final file = File(dbPath);
    if (!await file.exists()) {
      throw NotFoundFailure(
        userMessage: 'Không tìm thấy subject.db để sao lưu.',
        code: 'subject_db_missing',
        details: subjectId,
      );
    }

    final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final backupPath = p.join(folder, 'subject.db.bak-$stamp');
    final safety = PathSafety.ensureUnderRoot(
      rootDirectory: folder,
      absolutePath: backupPath,
    );
    if (safety is Failure) {
      throw const ValidationFailure(
        userMessage: 'Đường dẫn sao lưu không hợp lệ.',
        code: 'backup_path_invalid',
      );
    }

    _log.info('Backing up subject.db before destructive migration id=$subjectId');
    return file.copy(backupPath);
  }
}

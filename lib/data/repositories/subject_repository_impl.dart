import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/core/utils/path_safety.dart';
import 'package:studee_pc/data/catalog_database/catalog_database.dart';
import 'package:studee_pc/data/file_storage/app_paths.dart';
import 'package:studee_pc/data/file_storage/subject_file_store.dart';
import 'package:studee_pc/data/subject_database/subject_database.dart';
import 'package:studee_pc/data/subject_database/subject_database_manager.dart';
import 'package:studee_pc/domain/entities/create_subject_input.dart';
import 'package:studee_pc/domain/entities/subject.dart' as domain;
import 'package:studee_pc/domain/repositories/subject_repository.dart';
import 'package:uuid/uuid.dart';

/// Catalog + filesystem subject lifecycle implementation.
///
/// Subject folders use UUID names and are never renamed. Rename updates
/// catalog metadata and `manifest.json` only.
class SubjectRepositoryImpl implements SubjectRepository {
  SubjectRepositoryImpl({
    required CatalogDatabase catalog,
    required SubjectDatabaseManager databaseManager,
    SubjectFileStore? fileStore,
    AppPaths? paths,
    Uuid? uuid,
  })  : _catalog = catalog,
        _dbManager = databaseManager,
        _files = fileStore ?? SubjectFileStore(paths: paths),
        _paths = paths ?? AppPaths(),
        _uuid = uuid ?? const Uuid();

  final CatalogDatabase _catalog;
  final SubjectDatabaseManager _dbManager;
  final SubjectFileStore _files;
  final AppPaths _paths;
  final Uuid _uuid;
  final AppLogger _log = AppLogger('SubjectRepository');

  static const int schemaVersion = SubjectFileStore.currentSchemaVersion;

  @override
  String? get activeSubjectId => _dbManager.activeSubjectId;

  @override
  Future<domain.Subject> createSubject(CreateSubjectInput input) async {
    final name = input.name.trim();
    if (name.isEmpty) {
      throw const ValidationFailure(
        userMessage: 'Tên môn học không được để trống.',
        code: 'subject_name_empty',
      );
    }

    final id = _uuid.v4();
    final folderResult = await _files.createSubjectFolder(
      subjectId: id,
      displayName: name,
    );
    if (folderResult is Failure<String>) {
      throw folderResult.failure;
    }
    final folderPath = folderResult.valueOrNull!;

    // Ensure subject.db exists (empty schema via open/close).
    final dbPath = await _paths.subjectDbPath(id);
    final db = SubjectDatabase.atPath(dbPath);
    try {
      await db.customSelect('SELECT 1').get();
    } finally {
      await db.close();
    }

    final now = DateTime.now().toUtc();
    final nowMs = now.millisecondsSinceEpoch;
    final sortOrder = await _nextSortOrder();

    await _catalog.into(_catalog.subjects).insert(
          SubjectsCompanion.insert(
            id: id,
            name: name,
            folderPath: folderPath,
            icon: Value(input.icon),
            color: Value(input.color),
            schemaVersion: const Value(schemaVersion),
            sortOrder: Value(sortOrder),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );

    _log.info('Created subject id=$id');
    return domain.Subject(
      id: id,
      name: name,
      folderPath: folderPath,
      icon: input.icon,
      color: input.color,
      schemaVersion: schemaVersion,
      createdAt: now,
      updatedAt: now,
      sortOrder: sortOrder,
    );
  }

  @override
  Future<List<domain.Subject>> listSubjects() async {
    final rows = await (_catalog.select(_catalog.subjects)
          ..orderBy([
            (t) => OrderingTerm.desc(t.pinned),
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();

    final subjects = <domain.Subject>[];
    for (final row in rows) {
      subjects.add(await _toDomain(row));
    }
    return subjects;
  }

  @override
  Future<void> openSubject(String subjectId) async {
    await _requireCatalogRow(subjectId);
    await _dbManager.open(subjectId);
    _log.info('Opened subject id=$subjectId');
  }

  @override
  Future<void> closeSubject() async {
    await _dbManager.close();
  }

  @override
  Future<void> renameSubject(String subjectId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      throw const ValidationFailure(
        userMessage: 'Tên môn học không được để trống.',
        code: 'subject_name_empty',
      );
    }

    await _requireCatalogRow(subjectId);

    // Metadata only — folder name stays subject_<uuid>.
    final manifestResult = await _files.updateManifestDisplayName(
      subjectId: subjectId,
      displayName: trimmed,
    );
    if (manifestResult is Failure<void>) {
      throw manifestResult.failure;
    }

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_catalog.update(_catalog.subjects)
          ..where((t) => t.id.equals(subjectId)))
        .write(
      SubjectsCompanion(
        name: Value(trimmed),
        updatedAt: Value(nowMs),
      ),
    );
    _log.info('Renamed subject id=$subjectId');
  }

  @override
  Future<void> setSubjectPinned(
    String subjectId, {
    required bool pinned,
  }) async {
    await _requireCatalogRow(subjectId);
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_catalog.update(_catalog.subjects)
          ..where((t) => t.id.equals(subjectId)))
        .write(
      SubjectsCompanion(
        pinned: Value(pinned),
        // Bump updatedAt so freshly pinned subjects rise within the pin section.
        updatedAt: Value(nowMs),
      ),
    );
    _log.info('Subject id=$subjectId pinned=$pinned');
  }

  @override
  Future<void> reorderSubjects(List<String> orderedIds) async {
    if (orderedIds.isEmpty) return;
    await _catalog.transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        final id = orderedIds[i];
        await (_catalog.update(_catalog.subjects)
              ..where((t) => t.id.equals(id)))
            .write(SubjectsCompanion(sortOrder: Value(i)));
      }
    });
    _log.info('Reordered ${orderedIds.length} subjects');
  }

  @override
  Future<void> deleteSubject(String subjectId) async {
    final row = await _requireCatalogRow(subjectId);
    final folderPath = row.folderPath;

    // Confirm with the exact folder path from catalog before deleting.
    if (activeSubjectId == subjectId) {
      await closeSubject();
    }

    final safety = PathSafety.ensureUnderRoot(
      rootDirectory: await _paths.subjectsRoot(),
      absolutePath: folderPath,
    );
    if (safety is Failure<String>) {
      throw safety.failure;
    }

    final deleteResult = await _files.deleteSubjectFolder(
      subjectId: subjectId,
      confirmedAbsolutePath: folderPath,
    );
    if (deleteResult is Failure<void>) {
      throw deleteResult.failure;
    }

    await (_catalog.delete(_catalog.subjects)
          ..where((t) => t.id.equals(subjectId)))
        .go();
    _log.info('Deleted subject id=$subjectId');
  }

  @override
  Future<String> exportSubject(String subjectId, String destination) async {
    await _requireCatalogRow(subjectId);

    final zipPath = destination.toLowerCase().endsWith('.zip')
        ? destination
        : p.join(destination, '${AppPaths.subjectFolderName(subjectId)}.zip');

    final result = await _files.exportZip(
      subjectId: subjectId,
      destinationZipPath: zipPath,
    );
    return switch (result) {
      Success(:final value) => value,
      Failure(:final failure) => throw failure,
    };
  }

  @override
  Future<domain.Subject> importSubject(String zipPath) async {
    final result = await _files.importZip(zipPath: zipPath);
    if (result is Failure<({String subjectId, String displayName, int schemaVersion})>) {
      throw result.failure;
    }
    final imported = result.valueOrNull!;

    final existing = await (_catalog.select(_catalog.subjects)
          ..where((t) => t.id.equals(imported.subjectId)))
        .getSingleOrNull();
    if (existing != null) {
      throw ConflictFailure(
        userMessage: 'Môn học này đã có trong danh sách.',
        code: 'import_catalog_exists',
        details: imported.subjectId,
      );
    }

    final folderPath = await _paths.subjectFolder(imported.subjectId);
    final now = DateTime.now().toUtc();
    final nowMs = now.millisecondsSinceEpoch;
    final sortOrder = await _nextSortOrder();

    await _catalog.into(_catalog.subjects).insert(
          SubjectsCompanion.insert(
            id: imported.subjectId,
            name: imported.displayName,
            folderPath: folderPath,
            schemaVersion: Value(imported.schemaVersion),
            sortOrder: Value(sortOrder),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );

    _log.info('Registered imported subject id=${imported.subjectId}');
    final row = await _requireCatalogRow(imported.subjectId);
    return _toDomain(row);
  }

  Future<domain.Subject> _toDomain(CatalogSubjectRow row) async {
    var sourceCount = 0;
    var knowledgeCount = 0;
    var questionCount = 0;

    try {
      final wasActive = activeSubjectId;
      final db = wasActive == row.id && _dbManager.activeDatabase != null
          ? _dbManager.activeDatabase!
          : SubjectDatabase.atPath(await _paths.subjectDbPath(row.id));
      final openedTemp = wasActive != row.id;
      try {
        sourceCount = await db.sources.count().getSingle();
        knowledgeCount = await db.knowledgeUnits.count().getSingle();
        questionCount = await db.questions.count().getSingle();
      } finally {
        if (openedTemp) {
          await db.close();
        }
      }
    } on Object catch (e) {
      _log.warning(
        'Could not read counts for subject id=${row.id}: ${e.runtimeType}',
      );
    }

    return domain.Subject(
      id: row.id,
      name: row.name,
      folderPath: row.folderPath,
      icon: row.icon,
      color: row.color,
      schemaVersion: row.schemaVersion,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      pinned: row.pinned,
      sortOrder: row.sortOrder,
      sourceCount: sourceCount,
      knowledgeCount: knowledgeCount,
      questionCount: questionCount,
    );
  }

  Future<int> _nextSortOrder() async {
    final row = await _catalog
        .customSelect('SELECT COALESCE(MAX(sort_order), -1) AS m FROM subjects')
        .getSingle();
    return (row.read<int>('m')) + 1;
  }

  Future<CatalogSubjectRow> _requireCatalogRow(String subjectId) async {
    final row = await (_catalog.select(_catalog.subjects)
          ..where((t) => t.id.equals(subjectId)))
        .getSingleOrNull();
    if (row == null) {
      throw NotFoundFailure(
        userMessage: 'Không tìm thấy môn học.',
        code: 'subject_not_found',
        details: subjectId,
      );
    }
    return row;
  }
}

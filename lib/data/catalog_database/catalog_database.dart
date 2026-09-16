import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:studee_pc/data/catalog_database/catalog_tables.dart';
import 'package:studee_pc/data/file_storage/app_paths.dart';

part 'catalog_database.g.dart';

/// Drift database for `catalog.db` (global subject registry).
///
/// Run code generation after schema changes:
/// `dart run build_runner build --delete-conflicting-outputs`
@DriftDatabase(tables: [Subjects])
class CatalogDatabase extends _$CatalogDatabase {
  CatalogDatabase(super.e);

  /// Opens [catalog.db] under the application data root.
  factory CatalogDatabase.connect([AppPaths? paths]) {
    final appPaths = paths ?? AppPaths();
    return CatalogDatabase(
      LazyDatabase(() async {
        final root = await appPaths.ensureApplicationDataRoot();
        final file = File(p.join(root, 'catalog.db'));
        return NativeDatabase.createInBackground(file);
      }),
    );
  }

  /// In-memory database for unit tests.
  factory CatalogDatabase.memory() {
    return CatalogDatabase(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(subjects, subjects.pinned);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

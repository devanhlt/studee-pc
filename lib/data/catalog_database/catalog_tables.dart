import 'package:drift/drift.dart';

/// Global catalog table — subjects metadata only.
///
/// Secrets (API keys) must never be stored here or in any SQLite database.
@DataClassName('CatalogSubjectRow')
class Subjects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get folderPath => text().named('folder_path')();
  TextColumn get icon => text().nullable()();
  IntColumn get color => integer().nullable()();
  IntColumn get schemaVersion =>
      integer().named('schema_version').withDefault(const Constant(1))();
  BoolColumn get pinned =>
      boolean().withDefault(const Constant(false))();
  /// Manual list order (lower = higher in list within pin group).
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

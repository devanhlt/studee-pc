import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:studee_pc/data/catalog_database/catalog_database.dart';
import 'package:studee_pc/data/file_storage/app_paths.dart';
import 'package:studee_pc/data/repositories/subject_repository_impl.dart';
import 'package:studee_pc/data/subject_database/subject_database_manager.dart';
import 'package:studee_pc/domain/entities/create_subject_input.dart';

void main() {
  group('catalog subject isolation', () {
    late Directory tempDir;
    late AppPaths paths;
    late CatalogDatabase catalog;
    late SubjectDatabaseManager dbManager;
    late SubjectRepositoryImpl repo;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('studee_catalog_');
      paths = AppPaths(applicationSupportOverride: () => tempDir);
      catalog = CatalogDatabase.connect(paths);
      dbManager = SubjectDatabaseManager(paths: paths);
      repo = SubjectRepositoryImpl(
        catalog: catalog,
        databaseManager: dbManager,
        paths: paths,
      );
    });

    tearDown(() async {
      await dbManager.close();
      await catalog.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('two subjects use different UUID folders; rename keeps path', () async {
      final a = await repo.createSubject(
        const CreateSubjectInput(name: 'Đại số tuyến tính'),
      );
      final b = await repo.createSubject(
        const CreateSubjectInput(name: 'Giải tích'),
      );

      expect(a.id, isNot(b.id));
      expect(a.folderPath, isNot(b.folderPath));

      final folderA = p.basename(a.folderPath);
      final folderB = p.basename(b.folderPath);
      expect(folderA, AppPaths.subjectFolderName(a.id));
      expect(folderB, AppPaths.subjectFolderName(b.id));
      expect(folderA, startsWith('subject_'));
      expect(folderB, startsWith('subject_'));
      // Folder names contain UUID, not display name.
      expect(folderA.contains('Đại'), isFalse);
      expect(folderA.toLowerCase().contains('tuyen'), isFalse);
      expect(folderB.contains('Giải'), isFalse);

      final pathBefore = a.folderPath;
      await repo.renameSubject(a.id, 'Đại số nâng cao');

      final listed = await repo.listSubjects();
      final renamed = listed.firstWhere((s) => s.id == a.id);
      expect(renamed.name, 'Đại số nâng cao');
      expect(renamed.folderPath, pathBefore);
      expect(p.basename(renamed.folderPath), AppPaths.subjectFolderName(a.id));
      expect(Directory(renamed.folderPath).existsSync(), isTrue);
    });

    test('pinned subjects sort above unpinned', () async {
      final a = await repo.createSubject(
        const CreateSubjectInput(name: 'A'),
      );
      final b = await repo.createSubject(
        const CreateSubjectInput(name: 'B'),
      );

      await repo.setSubjectPinned(a.id, pinned: true);

      final listed = await repo.listSubjects();
      expect(listed.map((s) => s.id).toList(), [a.id, b.id]);
      expect(listed.first.pinned, isTrue);
      expect(listed.last.pinned, isFalse);

      await repo.setSubjectPinned(a.id, pinned: false);
      await repo.setSubjectPinned(b.id, pinned: true);

      final relisted = await repo.listSubjects();
      expect(relisted.first.id, b.id);
      expect(relisted.first.pinned, isTrue);
    });

    test('reorderSubjects persists manual order', () async {
      final a = await repo.createSubject(
        const CreateSubjectInput(name: 'A'),
      );
      final b = await repo.createSubject(
        const CreateSubjectInput(name: 'B'),
      );
      final c = await repo.createSubject(
        const CreateSubjectInput(name: 'C'),
      );

      expect(
        (await repo.listSubjects()).map((s) => s.id).toList(),
        [a.id, b.id, c.id],
      );

      await repo.reorderSubjects([c.id, a.id, b.id]);

      final listed = await repo.listSubjects();
      expect(listed.map((s) => s.id).toList(), [c.id, a.id, b.id]);
      expect(listed.map((s) => s.sortOrder).toList(), [0, 1, 2]);

      await repo.setSubjectPinned(b.id, pinned: true);
      final withPin = await repo.listSubjects();
      expect(withPin.map((s) => s.id).toList(), [b.id, c.id, a.id]);
    });
  });
}

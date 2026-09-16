import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:studee_pc/data/subject_database/subject_database.dart';

void main() {
  test('opens v1-shaped DB and migrates to v3 practice_count', () async {
    final dir = await Directory.systemTemp.createTemp('studee_sem_mig_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    final dbPath = p.join(dir.path, 'subject.db');
    final raw = sqlite3.open(dbPath);
    raw.execute('PRAGMA user_version = 1;');
    raw.execute('''
CREATE TABLE questions (
  id TEXT NOT NULL PRIMARY KEY,
  knowledge_unit_id TEXT NOT NULL,
  question_number TEXT NULL,
  question_type TEXT NOT NULL,
  content TEXT NOT NULL,
  normalized_content TEXT NOT NULL,
  question_fingerprint TEXT NOT NULL,
  answer_label TEXT NULL,
  answer_content TEXT NULL,
  explanation TEXT NULL,
  verification_status TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
''');
    // Minimal stubs so Drift open does not fail on missing tables from createAll
    // when from < 1 — we start at version 1 so only from < 2 / < 3 runs.
    raw.dispose();

    final db = SubjectDatabase.atPath(dbPath);
    addTearDown(db.close);

    // Touch migrations.
    await db.customSelect('SELECT 1').get();
    expect(db.schemaVersion, 3);

    final info = await db.customSelect("PRAGMA table_info('questions')").get();
    final names = info.map((r) => r.read<String>('name')).toSet();
    expect(names.contains('semantic_key'), isTrue);
    expect(names.contains('semantic_fingerprint'), isTrue);
    expect(names.contains('practice_count'), isTrue);
  });
}

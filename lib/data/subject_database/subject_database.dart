import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:studee_pc/data/subject_database/subject_tables.dart';

part 'subject_database.g.dart';

/// Per-subject Drift database (`subject.db`).
///
/// FTS5 virtual tables use the `unicode61` tokenizer so Vietnamese Latin
/// script (including diacritics) tokenizes correctly for retrieval.
///
/// Run code generation after schema changes:
/// `dart run build_runner build --delete-conflicting-outputs`
@DriftDatabase(
  tables: [
    Sources,
    SourcePages,
    KnowledgeUnits,
    Questions,
    QuestionChoices,
    KnowledgeRelations,
    OcrRuns,
    IngestionJobs,
    SolveSessions,
    SolveResults,
    ResultReferences,
    UserFeedback,
    SubjectSettings,
  ],
)
class SubjectDatabase extends _$SubjectDatabase {
  SubjectDatabase(super.e);

  /// Opens a subject database at [dbFile].
  factory SubjectDatabase.atPath(String dbFile) {
    return SubjectDatabase(
      LazyDatabase(() async {
        final file = File(dbFile);
        await file.parent.create(recursive: true);
        return NativeDatabase.createInBackground(file);
      }),
    );
  }

  /// In-memory database for unit tests.
  factory SubjectDatabase.memory() {
    return SubjectDatabase(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createFtsAndTriggers();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Versioned migrations. Destructive changes must go through
          // [SubjectDatabaseManager] which backs up the DB first.
          if (from < 1) {
            await m.createAll();
            await _createFtsAndTriggers();
          }
          if (from < 2) {
            await m.addColumn(questions, questions.semanticKey);
            await m.addColumn(questions, questions.semanticFingerprint);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Creates FTS5 virtual tables and sync triggers.
  ///
  /// `tokenize='unicode61'` supports Vietnamese Latin script (letters with
  /// diacritics such as ă, â, ê, ô, ơ, ư, đ and tone marks). Do not switch to
  /// `porter` or ascii-only tokenizers for this product.
  Future<void> _createFtsAndTriggers() async {
    await customStatement('''
CREATE VIRTUAL TABLE IF NOT EXISTS knowledge_fts USING fts5(
  content,
  normalized_content,
  content='knowledge_units',
  content_rowid='rowid',
  tokenize='unicode61'
);
''');

    await customStatement('''
CREATE VIRTUAL TABLE IF NOT EXISTS questions_fts USING fts5(
  content,
  normalized_content,
  content='questions',
  content_rowid='rowid',
  tokenize='unicode61'
);
''');

    // knowledge_units → knowledge_fts
    await customStatement('''
CREATE TRIGGER IF NOT EXISTS knowledge_units_ai AFTER INSERT ON knowledge_units BEGIN
  INSERT INTO knowledge_fts(rowid, content, normalized_content)
  VALUES (new.rowid, new.content, new.normalized_content);
END;
''');
    await customStatement('''
CREATE TRIGGER IF NOT EXISTS knowledge_units_ad AFTER DELETE ON knowledge_units BEGIN
  INSERT INTO knowledge_fts(knowledge_fts, rowid, content, normalized_content)
  VALUES('delete', old.rowid, old.content, old.normalized_content);
END;
''');
    await customStatement('''
CREATE TRIGGER IF NOT EXISTS knowledge_units_au AFTER UPDATE ON knowledge_units BEGIN
  INSERT INTO knowledge_fts(knowledge_fts, rowid, content, normalized_content)
  VALUES('delete', old.rowid, old.content, old.normalized_content);
  INSERT INTO knowledge_fts(rowid, content, normalized_content)
  VALUES (new.rowid, new.content, new.normalized_content);
END;
''');

    // questions → questions_fts
    await customStatement('''
CREATE TRIGGER IF NOT EXISTS questions_ai AFTER INSERT ON questions BEGIN
  INSERT INTO questions_fts(rowid, content, normalized_content)
  VALUES (new.rowid, new.content, new.normalized_content);
END;
''');
    await customStatement('''
CREATE TRIGGER IF NOT EXISTS questions_ad AFTER DELETE ON questions BEGIN
  INSERT INTO questions_fts(questions_fts, rowid, content, normalized_content)
  VALUES('delete', old.rowid, old.content, old.normalized_content);
END;
''');
    await customStatement('''
CREATE TRIGGER IF NOT EXISTS questions_au AFTER UPDATE ON questions BEGIN
  INSERT INTO questions_fts(questions_fts, rowid, content, normalized_content)
  VALUES('delete', old.rowid, old.content, old.normalized_content);
  INSERT INTO questions_fts(rowid, content, normalized_content)
  VALUES (new.rowid, new.content, new.normalized_content);
END;
''');
  }

  /// Full-text search over knowledge units (Vietnamese-capable unicode61).
  Future<List<KnowledgeUnitRow>> searchKnowledgeFts(
    String query, {
    int limit = 20,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final rows = await customSelect(
      '''
SELECT ku.*
FROM knowledge_fts
JOIN knowledge_units ku ON ku.rowid = knowledge_fts.rowid
WHERE knowledge_fts MATCH ?
  AND ku.verification_status != 'rejected'
ORDER BY rank
LIMIT ?
''',
      variables: [
        Variable.withString(_sanitizeFtsQuery(trimmed)),
        Variable.withInt(limit),
      ],
      readsFrom: {knowledgeUnits},
    ).get();

    return Future.wait(rows.map(knowledgeUnits.mapFromRow));
  }

  /// Full-text search over questions.
  Future<List<QuestionRow>> searchQuestionsFts(
    String query, {
    int limit = 20,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final rows = await customSelect(
      '''
SELECT q.*
FROM questions_fts
JOIN questions q ON q.rowid = questions_fts.rowid
WHERE questions_fts MATCH ?
  AND q.verification_status != 'rejected'
ORDER BY rank
LIMIT ?
''',
      variables: [
        Variable.withString(_sanitizeFtsQuery(trimmed)),
        Variable.withInt(limit),
      ],
      readsFrom: {questions},
    ).get();

    return Future.wait(rows.map(questions.mapFromRow));
  }

  /// Escape FTS5 special characters; OR significant tokens so OCR drift
  /// (extra/missing words) still retrieves the stored question.
  static String _sanitizeFtsQuery(String raw) {
    final cleaned = raw
        .replaceAll('"', ' ')
        .replaceAll(RegExp(r'[^\w\sàáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩị'
            r'òóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ'
            r'ÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊ'
            r'ÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ0-9]', unicode: true), ' ');
    final tokens = cleaned
        .split(RegExp(r'\s+'))
        .map((t) => t.trim())
        .where((t) => t.length >= 2)
        .map((t) => '"$t"')
        .toSet()
        .toList();
    if (tokens.isEmpty) return '""';
    // Prefer OR so partial OCR matches still hit; FTS rank orders results.
    return tokens.join(' OR ');
  }

  /// Absolute path helper when opened via [SubjectDatabase.atPath].
  static String databaseFileName(String subjectFolder) =>
      p.join(subjectFolder, 'subject.db');
}

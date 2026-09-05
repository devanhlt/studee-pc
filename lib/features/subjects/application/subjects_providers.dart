import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/domain/entities/create_subject_input.dart';
import 'package:studee_pc/domain/entities/knowledge_unit.dart';
import 'package:studee_pc/domain/entities/question.dart';
import 'package:studee_pc/domain/entities/source.dart';
import 'package:studee_pc/domain/entities/subject.dart';
import 'package:studee_pc/domain/enums/knowledge_unit_type.dart';
import 'package:studee_pc/domain/enums/question_type.dart';
import 'package:studee_pc/domain/enums/source_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';

final subjectsListProvider =
    FutureProvider.autoDispose<List<Subject>>((ref) async {
  final repo = ref.watch(subjectRepositoryProvider);
  return repo.listSubjects();
});

final subjectByIdProvider =
    FutureProvider.autoDispose.family<Subject?, String>((ref, id) async {
  final list = await ref.watch(subjectsListProvider.future);
  try {
    return list.firstWhere((s) => s.id == id);
  } on StateError {
    return null;
  }
});

class SubjectContentQueries {
  SubjectContentQueries(this._ref);

  final Ref _ref;

  Future<List<KnowledgeUnit>> listKnowledge(String subjectId) async {
    final db = await _ref.read(subjectDatabaseManagerProvider).open(subjectId);
    final rows = await (db.select(db.knowledgeUnits)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows
        .map(
          (r) => KnowledgeUnit(
            id: r.id,
            sourceId: r.sourceId,
            sourcePageId: r.sourcePageId,
            type: KnowledgeUnitType.fromWire(r.type),
            content: r.content,
            normalizedContent: r.normalizedContent,
            bboxJson: r.bboxJson,
            verificationStatus:
                VerificationStatus.fromWire(r.verificationStatus),
            sourcePriority: r.sourcePriority,
            contentHash: r.contentHash,
            createdAt:
                DateTime.fromMillisecondsSinceEpoch(r.createdAt, isUtc: true),
            updatedAt:
                DateTime.fromMillisecondsSinceEpoch(r.updatedAt, isUtc: true),
          ),
        )
        .toList();
  }

  Future<List<Question>> listQuestions(String subjectId) async {
    final db = await _ref.read(subjectDatabaseManagerProvider).open(subjectId);
    final rows = await (db.select(db.questions)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows
        .map(
          (r) => Question(
            id: r.id,
            knowledgeUnitId: r.knowledgeUnitId,
            questionNumber: r.questionNumber,
            questionType: QuestionType.fromWire(r.questionType),
            content: r.content,
            normalizedContent: r.normalizedContent,
            questionFingerprint: r.questionFingerprint,
            answerLabel: r.answerLabel,
            answerContent: r.answerContent,
            explanation: r.explanation,
            verificationStatus:
                VerificationStatus.fromWire(r.verificationStatus),
            createdAt:
                DateTime.fromMillisecondsSinceEpoch(r.createdAt, isUtc: true),
            updatedAt:
                DateTime.fromMillisecondsSinceEpoch(r.updatedAt, isUtc: true),
          ),
        )
        .toList();
  }

  Future<List<Source>> listSources(String subjectId) async {
    final db = await _ref.read(subjectDatabaseManagerProvider).open(subjectId);
    final rows = await (db.select(db.sources)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows
        .map(
          (r) => Source(
            id: r.id,
            type: SourceType.fromWire(r.type),
            title: r.title,
            originalRelativePath: r.originalRelativePath,
            contentSha256: r.contentSha256,
            pageCount: r.pageCount,
            processingStatus: r.processingStatus,
            createdAt:
                DateTime.fromMillisecondsSinceEpoch(r.createdAt, isUtc: true),
            updatedAt:
                DateTime.fromMillisecondsSinceEpoch(r.updatedAt, isUtc: true),
          ),
        )
        .toList();
  }

  Future<List<SolveHistoryItem>> listSolveHistory(String subjectId) async {
    final db = await _ref.read(subjectDatabaseManagerProvider).open(subjectId);
    final sessions = await (db.select(db.solveSessions)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    final items = <SolveHistoryItem>[];
    for (final session in sessions) {
      final result = await (db.select(db.solveResults)
            ..where((t) => t.sessionId.equals(session.id))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();
      items.add(
        SolveHistoryItem(
          sessionId: session.id,
          inputType: session.inputType,
          status: session.status,
          preview: session.rawInputText,
          answerLabel: result?.finalAnswerLabel,
          answerContent: result?.finalAnswerContent ?? result?.shortAnswer,
          confidence: result?.confidenceLevel,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            session.createdAt,
            isUtc: true,
          ),
        ),
      );
    }
    return items;
  }
}

class SolveHistoryItem {
  const SolveHistoryItem({
    required this.sessionId,
    required this.inputType,
    required this.status,
    this.preview,
    this.answerLabel,
    this.answerContent,
    this.confidence,
    required this.createdAt,
  });

  final String sessionId;
  final String inputType;
  final String status;
  final String? preview;
  final String? answerLabel;
  final String? answerContent;
  final String? confidence;
  final DateTime createdAt;
}

final subjectContentProvider = Provider<SubjectContentQueries>((ref) {
  return SubjectContentQueries(ref);
});

final subjectKnowledgeProvider =
    FutureProvider.autoDispose.family<List<KnowledgeUnit>, String>(
  (ref, subjectId) => ref.watch(subjectContentProvider).listKnowledge(subjectId),
);

final subjectQuestionsProvider =
    FutureProvider.autoDispose.family<List<Question>, String>(
  (ref, subjectId) => ref.watch(subjectContentProvider).listQuestions(subjectId),
);

final subjectSourcesProvider =
    FutureProvider.autoDispose.family<List<Source>, String>(
  (ref, subjectId) => ref.watch(subjectContentProvider).listSources(subjectId),
);

final subjectHistoryProvider =
    FutureProvider.autoDispose.family<List<SolveHistoryItem>, String>(
  (ref, subjectId) =>
      ref.watch(subjectContentProvider).listSolveHistory(subjectId),
);

class SubjectsActions {
  SubjectsActions(this._ref);

  final Ref _ref;

  Future<Subject> create(String name, {String? icon, int? color}) {
    return _ref.read(subjectRepositoryProvider).createSubject(
          CreateSubjectInput(name: name, icon: icon, color: color),
        );
  }

  Future<void> rename(String id, String name) {
    return _ref.read(subjectRepositoryProvider).renameSubject(id, name);
  }

  Future<void> delete(String id) {
    return _ref.read(subjectRepositoryProvider).deleteSubject(id);
  }

  Future<String> export(String id, String destination) {
    return _ref.read(subjectRepositoryProvider).exportSubject(id, destination);
  }

  Future<Subject> importZip(String zipPath) {
    return _ref.read(subjectRepositoryProvider).importSubject(zipPath);
  }

  Future<void> open(String id) {
    return _ref.read(subjectRepositoryProvider).openSubject(id);
  }

  void refresh() {
    _ref.invalidate(subjectsListProvider);
  }
}

final subjectsActionsProvider = Provider<SubjectsActions>((ref) {
  return SubjectsActions(ref);
});

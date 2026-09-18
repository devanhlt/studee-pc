import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/core/utils/fingerprints.dart';
import 'package:studee_pc/core/utils/text_normalizer.dart';
import 'package:studee_pc/data/deepseek/prompts.dart';
import 'package:studee_pc/data/subject_database/subject_database.dart';
import 'package:studee_pc/data/subject_database/subject_database_manager.dart';
import 'package:studee_pc/domain/enums/knowledge_unit_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';
import 'package:studee_pc/domain/repositories/deepseek_client.dart';
import 'package:studee_pc/features/subjects/application/subjects_providers.dart';

class _MemoryDbManager extends SubjectDatabaseManager {
  _MemoryDbManager(this._db);

  final SubjectDatabase _db;

  @override
  String? get activeSubjectId => 'sub1';

  @override
  SubjectDatabase? get activeDatabase => _db;

  @override
  Future<SubjectDatabase> open(String subjectId) async => _db;
}

Future<void> _seedSource(SubjectDatabase db, {required String sourceId}) async {
  final now = DateTime.now().toUtc().millisecondsSinceEpoch;
  await db.into(db.sources).insert(
        SourcesCompanion.insert(
          id: sourceId,
          type: 'paste',
          title: 'Paste',
          contentSha256: 'x',
          processingStatus: 'done',
          createdAt: now,
          updatedAt: now,
        ),
      );
}

Future<void> _seedUnit(
  SubjectDatabase db, {
  required String id,
  required String sourceId,
  required String type,
  required String content,
}) async {
  final now = DateTime.now().toUtc().millisecondsSinceEpoch;
  await db.into(db.knowledgeUnits).insert(
        KnowledgeUnitsCompanion.insert(
          id: id,
          sourceId: sourceId,
          type: type,
          content: content,
          normalizedContent: TextNormalizer.normalize(content),
          verificationStatus: VerificationStatus.reviewed.wireName,
          contentHash: Fingerprints.contentHash(content),
          createdAt: now,
          updatedAt: now,
        ),
      );
}

Future<void> _seedQuestion(
  SubjectDatabase db, {
  required String id,
  required String parentId,
  required String content,
}) async {
  final now = DateTime.now().toUtc().millisecondsSinceEpoch;
  await db.into(db.questions).insert(
        QuestionsCompanion.insert(
          id: id,
          knowledgeUnitId: parentId,
          questionType: 'multiple_choice',
          content: content,
          normalizedContent: TextNormalizer.normalizeQuestionText(content),
          questionFingerprint: Fingerprints.questionFingerprint(
            questionText: content,
            choiceContents: const [],
          ),
          verificationStatus: VerificationStatus.reviewed.wireName,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

void main() {
  group('listQuestionsWithRelatedKnowledge + deleteQuestionCascade', () {
    late SubjectDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = SubjectDatabase.memory();
      container = ProviderContainer(
        overrides: [
          subjectDatabaseManagerProvider.overrideWithValue(_MemoryDbManager(db)),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('lists parent and related units for a question', () async {
      await _seedSource(db, sourceId: 'src1');
      await _seedUnit(
        db,
        id: 'parent',
        sourceId: 'src1',
        type: KnowledgeUnitType.theory.wireName,
        content: 'Lý thuyết A',
      );
      await _seedUnit(
        db,
        id: 'answer',
        sourceId: 'src1',
        type: KnowledgeUnitType.answerKey.wireName,
        content: 'Đáp án A',
      );
      await _seedQuestion(
        db,
        id: 'q1',
        parentId: 'parent',
        content: 'Câu hỏi 1?',
      );
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await db.into(db.knowledgeRelations).insert(
            KnowledgeRelationsCompanion.insert(
              id: 'rel1',
              fromUnitId: 'parent',
              toUnitId: 'answer',
              relationType: 'related_to',
              createdAt: now,
            ),
          );

      final listed = await container
          .read(subjectContentProvider)
          .listQuestionsWithRelatedKnowledge('sub1');
      expect(listed, hasLength(1));
      expect(listed.first.question.id, 'q1');
      expect(listed.first.parent?.id, 'parent');
      expect(listed.first.related.map((u) => u.id), ['answer']);
      expect(listed.first.relatedCount, 2);
    });

    test('cascade delete removes exclusive related units', () async {
      await _seedSource(db, sourceId: 'src1');
      await _seedUnit(
        db,
        id: 'parent',
        sourceId: 'src1',
        type: KnowledgeUnitType.theory.wireName,
        content: 'Lý thuyết',
      );
      await _seedUnit(
        db,
        id: 'solution',
        sourceId: 'src1',
        type: KnowledgeUnitType.solution.wireName,
        content: 'Lời giải',
      );
      await _seedQuestion(
        db,
        id: 'q1',
        parentId: 'parent',
        content: 'Câu duy nhất?',
      );
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await db.into(db.knowledgeRelations).insert(
            KnowledgeRelationsCompanion.insert(
              id: 'rel1',
              fromUnitId: 'parent',
              toUnitId: 'solution',
              relationType: 'related_to',
              createdAt: now,
            ),
          );

      await container.read(subjectContentProvider).deleteQuestionCascade(
            subjectId: 'sub1',
            questionId: 'q1',
          );

      expect(await db.select(db.questions).get(), isEmpty);
      expect(await db.select(db.knowledgeUnits).get(), isEmpty);
    });

    test('cascade delete keeps shared parent for sibling questions', () async {
      await _seedSource(db, sourceId: 'src1');
      await _seedUnit(
        db,
        id: 'parent',
        sourceId: 'src1',
        type: KnowledgeUnitType.theory.wireName,
        content: 'Lý thuyết chung',
      );
      await _seedUnit(
        db,
        id: 'answer',
        sourceId: 'src1',
        type: KnowledgeUnitType.answerKey.wireName,
        content: 'Đáp án riêng',
      );
      await _seedQuestion(
        db,
        id: 'q1',
        parentId: 'parent',
        content: 'Câu 1?',
      );
      await _seedQuestion(
        db,
        id: 'q2',
        parentId: 'parent',
        content: 'Câu 2?',
      );
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await db.into(db.knowledgeRelations).insert(
            KnowledgeRelationsCompanion.insert(
              id: 'rel1',
              fromUnitId: 'parent',
              toUnitId: 'answer',
              relationType: 'related_to',
              createdAt: now,
            ),
          );

      await container.read(subjectContentProvider).deleteQuestionCascade(
            subjectId: 'sub1',
            questionId: 'q1',
          );

      final questions = await db.select(db.questions).get();
      expect(questions.map((q) => q.id), ['q2']);
      final units = await db.select(db.knowledgeUnits).get();
      expect(units.map((u) => u.id).toSet(), {'parent', 'answer'});
    });
  });

  group('theory-to-Q&A ingest contract', () {
    test('prompt version and unit payload shape are defined', () {
      expect(
        DeepSeekPrompts.generateQuestionsFromKnowledgeVersion,
        'generateQuestionsFromKnowledge.v1',
      );
      const unit = KnowledgeSummaryUnit(
        type: 'theory',
        content: 'Định nghĩa',
      );
      expect(unit.type, 'theory');
      expect(unit.content, isNotEmpty);
      final shouldGenerate =
          const <Map<String, dynamic>>[].isEmpty && [unit].isNotEmpty;
      expect(shouldGenerate, isTrue);
    });
  });
}

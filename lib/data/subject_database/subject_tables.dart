import 'package:drift/drift.dart';

/// Imported source documents (PDF, image, screenshot, pasted text).
@DataClassName('SourceRow')
class Sources extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get originalRelativePath =>
      text().named('original_relative_path').nullable()();
  TextColumn get contentSha256 => text().named('content_sha256')();
  IntColumn get pageCount => integer().named('page_count').nullable()();
  TextColumn get processingStatus => text().named('processing_status')();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Per-page OCR / text-layer rows for a source.
@DataClassName('SourcePageRow')
class SourcePages extends Table {
  TextColumn get id => text()();
  TextColumn get sourceId => text().named('source_id').references(
        Sources,
        #id,
        onDelete: KeyAction.cascade,
      )();
  IntColumn get pageNumber => integer().named('page_number')();
  TextColumn get imageRelativePath =>
      text().named('image_relative_path').nullable()();
  TextColumn get textLayer => text().named('text_layer').nullable()();
  TextColumn get rawOcrRelativePath =>
      text().named('raw_ocr_relative_path').nullable()();
  TextColumn get normalizedText =>
      text().named('normalized_text').nullable()();
  TextColumn get ocrEngine => text().named('ocr_engine').nullable()();
  TextColumn get ocrModelVersion =>
      text().named('ocr_model_version').nullable()();
  RealColumn get ocrConfidence =>
      real().named('ocr_confidence').nullable()();
  TextColumn get processingStatus => text().named('processing_status')();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {sourceId, pageNumber},
      ];
}

/// Structured knowledge extracted from sources.
@DataClassName('KnowledgeUnitRow')
class KnowledgeUnits extends Table {
  TextColumn get id => text()();
  TextColumn get sourceId => text().named('source_id').references(
        Sources,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get sourcePageId => text().named('source_page_id').nullable()();
  TextColumn get type => text()();
  TextColumn get content => text()();
  TextColumn get normalizedContent => text().named('normalized_content')();
  TextColumn get bboxJson => text().named('bbox_json').nullable()();
  TextColumn get verificationStatus => text().named('verification_status')();
  IntColumn get sourcePriority =>
      integer().named('source_priority').withDefault(const Constant(0))();
  TextColumn get contentHash => text().named('content_hash')();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Parsed / stored questions linked to knowledge units.
@DataClassName('QuestionRow')
class Questions extends Table {
  TextColumn get id => text()();
  TextColumn get knowledgeUnitId => text().named('knowledge_unit_id').references(
        KnowledgeUnits,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get questionNumber =>
      text().named('question_number').nullable()();
  TextColumn get questionType => text().named('question_type')();
  TextColumn get content => text()();
  TextColumn get normalizedContent => text().named('normalized_content')();
  TextColumn get questionFingerprint => text().named('question_fingerprint')();
  /// Canonical meaning key (LLM); used for paraphrase / cross-language match.
  TextColumn get semanticKey => text().named('semantic_key').nullable()();
  TextColumn get semanticFingerprint =>
      text().named('semantic_fingerprint').nullable()();
  TextColumn get answerLabel => text().named('answer_label').nullable()();
  TextColumn get answerContent => text().named('answer_content').nullable()();
  TextColumn get explanation => text().nullable()();
  TextColumn get verificationStatus => text().named('verification_status')();
  /// How many times this question was practiced (Giải / Luyện / Ôn tập).
  IntColumn get practiceCount =>
      integer().named('practice_count').withDefault(const Constant(0))();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Multiple-choice options for a question.
@DataClassName('QuestionChoiceRow')
class QuestionChoices extends Table {
  TextColumn get id => text()();
  TextColumn get questionId => text().named('question_id').references(
        Questions,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get label => text()();
  TextColumn get content => text()();
  TextColumn get normalizedContent => text().named('normalized_content')();
  IntColumn get sortOrder => integer().named('sort_order')();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {questionId, label},
      ];
}

/// Directed relations between knowledge units.
@DataClassName('KnowledgeRelationRow')
class KnowledgeRelations extends Table {
  TextColumn get id => text()();
  TextColumn get fromUnitId => text().named('from_unit_id').references(
        KnowledgeUnits,
        #id,
        onDelete: KeyAction.cascade,
      )();
  @ReferenceName('incomingRelations')
  TextColumn get toUnitId => text().named('to_unit_id').references(
        KnowledgeUnits,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get relationType => text().named('relation_type')();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer().named('created_at')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// OCR engine run records (page-level or source-level).
@DataClassName('OcrRunRow')
class OcrRuns extends Table {
  TextColumn get id => text()();
  TextColumn get sourceId => text().named('source_id').references(
        Sources,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get sourcePageId => text().named('source_page_id').nullable()();
  TextColumn get engine => text()();
  TextColumn get modelVersion => text().named('model_version')();
  TextColumn get status => text()();
  RealColumn get confidence => real().nullable()();
  TextColumn get errorMessage => text().named('error_message').nullable()();
  IntColumn get startedAt => integer().named('started_at')();
  IntColumn get finishedAt => integer().named('finished_at').nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Import / ingestion job progress.
@DataClassName('IngestionJobRow')
class IngestionJobs extends Table {
  TextColumn get id => text()();
  TextColumn get sourceId => text().named('source_id').nullable()();
  TextColumn get status => text()();
  IntColumn get currentPage => integer().named('current_page').nullable()();
  IntColumn get totalPages => integer().named('total_pages').nullable()();
  TextColumn get errorMessage => text().named('error_message').nullable()();
  TextColumn get draftJson => text().named('draft_json').nullable()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A single solve attempt from the overlay / solver.
@DataClassName('SolveSessionRow')
class SolveSessions extends Table {
  TextColumn get id => text()();
  TextColumn get inputType => text().named('input_type')();
  TextColumn get rawInputText => text().named('raw_input_text').nullable()();
  TextColumn get parsedQuestionJson =>
      text().named('parsed_question_json').nullable()();
  TextColumn get status => text()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Persisted solve result (validated DeepSeek / local match output).
@DataClassName('SolveResultRow')
class SolveResults extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().named('session_id').references(
        SolveSessions,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get questionType => text().named('question_type')();
  TextColumn get finalAnswerLabel =>
      text().named('final_answer_label').nullable()();
  TextColumn get finalAnswerContent =>
      text().named('final_answer_content').nullable()();
  TextColumn get shortAnswer => text().named('short_answer').nullable()();
  TextColumn get explanationMarkdown =>
      text().named('explanation_markdown').nullable()();
  TextColumn get confidenceLevel => text().named('confidence_level')();
  IntColumn get modelKnowledgeUsed =>
      integer().named('model_knowledge_used').withDefault(const Constant(0))();
  IntColumn get missingInformation =>
      integer().named('missing_information').withDefault(const Constant(0))();
  TextColumn get warningsJson => text().named('warnings_json').nullable()();
  TextColumn get promptVersion => text().named('prompt_version').nullable()();
  TextColumn get rawResponseJson =>
      text().named('raw_response_json').nullable()();
  IntColumn get createdAt => integer().named('created_at')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Clickable local references attached to a solve result.
@DataClassName('ResultReferenceRow')
class ResultReferences extends Table {
  TextColumn get id => text()();
  TextColumn get resultId => text().named('result_id').references(
        SolveResults,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get evidenceId => text().named('evidence_id')();
  TextColumn get localId => text().named('local_id')();
  TextColumn get sourceTitle => text().named('source_title').nullable()();
  IntColumn get page => integer().nullable()();
  IntColumn get sortOrder => integer().named('sort_order')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// User feedback on solve results (e.g. "incorrect").
@DataClassName('UserFeedbackRow')
class UserFeedback extends Table {
  TextColumn get id => text()();
  TextColumn get resultId => text().named('result_id').references(
        SolveResults,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get feedbackType => text().named('feedback_type')();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer().named('created_at')();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Per-subject key/value settings (never secrets — API keys stay in OS store).
@DataClassName('SubjectSettingRow')
class SubjectSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

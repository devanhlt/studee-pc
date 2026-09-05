import 'package:studee_pc/domain/entities/parsed_question.dart';
import 'package:studee_pc/domain/entities/retrieval_result.dart';

/// Subject-scoped knowledge and question retrieval.
abstract interface class KnowledgeRetriever {
  Future<RetrievalResult> retrieve({
    required String subjectId,
    required ParsedQuestion question,
    required int limit,
  });
}

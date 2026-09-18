import 'package:equatable/equatable.dart';
import 'package:studee_pc/domain/entities/knowledge_unit.dart';
import 'package:studee_pc/domain/entities/question.dart';

/// A stored question plus its parent and related knowledge units.
class QuestionWithRelatedKnowledge extends Equatable {
  const QuestionWithRelatedKnowledge({
    required this.question,
    this.parent,
    this.related = const [],
  });

  final Question question;
  final KnowledgeUnit? parent;

  /// Related units via `knowledge_relations` (excludes [parent]).
  final List<KnowledgeUnit> related;

  /// Parent first, then related — for detail display.
  List<KnowledgeUnit> get allKnowledge {
    final out = <KnowledgeUnit>[];
    if (parent != null) out.add(parent!);
    out.addAll(related);
    return out;
  }

  int get relatedCount => allKnowledge.length;

  @override
  List<Object?> get props => [question, parent, related];
}

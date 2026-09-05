import 'package:equatable/equatable.dart';
import 'package:studee_pc/domain/enums/knowledge_unit_type.dart';

/// A clickable local reference shown with a solve result.
class ResultReference extends Equatable {
  const ResultReference({
    required this.id,
    required this.localId,
    this.evidenceId,
    required this.type,
    this.sourceTitle,
    this.page,
    this.snippet,
  });

  final String id;
  final String localId;
  final String? evidenceId;
  final KnowledgeUnitType type;
  final String? sourceTitle;
  final int? page;
  final String? snippet;

  @override
  List<Object?> get props => [
        id,
        localId,
        evidenceId,
        type,
        sourceTitle,
        page,
        snippet,
      ];
}

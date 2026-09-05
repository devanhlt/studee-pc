import 'package:equatable/equatable.dart';
import 'package:studee_pc/domain/enums/knowledge_unit_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';

/// A structured unit of knowledge extracted from a source page.
class KnowledgeUnit extends Equatable {
  const KnowledgeUnit({
    required this.id,
    required this.sourceId,
    this.sourcePageId,
    required this.type,
    required this.content,
    required this.normalizedContent,
    this.bboxJson,
    required this.verificationStatus,
    this.sourcePriority = 0,
    required this.contentHash,
    required this.createdAt,
    required this.updatedAt,
    this.sourceTitle,
    this.page,
  });

  final String id;
  final String sourceId;
  final String? sourcePageId;
  final KnowledgeUnitType type;
  final String content;
  final String normalizedContent;
  final String? bboxJson;
  final VerificationStatus verificationStatus;
  final int sourcePriority;
  final String contentHash;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Optional denormalized provenance for evidence packages.
  final String? sourceTitle;
  final int? page;

  KnowledgeUnit copyWith({
    String? id,
    String? sourceId,
    String? sourcePageId,
    KnowledgeUnitType? type,
    String? content,
    String? normalizedContent,
    String? bboxJson,
    VerificationStatus? verificationStatus,
    int? sourcePriority,
    String? contentHash,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sourceTitle,
    int? page,
  }) {
    return KnowledgeUnit(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      sourcePageId: sourcePageId ?? this.sourcePageId,
      type: type ?? this.type,
      content: content ?? this.content,
      normalizedContent: normalizedContent ?? this.normalizedContent,
      bboxJson: bboxJson ?? this.bboxJson,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      sourcePriority: sourcePriority ?? this.sourcePriority,
      contentHash: contentHash ?? this.contentHash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sourceId,
        sourcePageId,
        type,
        content,
        normalizedContent,
        bboxJson,
        verificationStatus,
        sourcePriority,
        contentHash,
        createdAt,
        updatedAt,
        sourceTitle,
        page,
      ];
}

import 'package:equatable/equatable.dart';
import 'package:studee_pc/domain/enums/source_type.dart';

/// An imported original source preserved under the subject folder.
class Source extends Equatable {
  const Source({
    required this.id,
    required this.type,
    required this.title,
    this.originalRelativePath,
    required this.contentSha256,
    this.pageCount,
    required this.processingStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final SourceType type;
  final String title;
  final String? originalRelativePath;
  final String contentSha256;
  final int? pageCount;
  final String processingStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  Source copyWith({
    String? id,
    SourceType? type,
    String? title,
    String? originalRelativePath,
    String? contentSha256,
    int? pageCount,
    String? processingStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Source(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      originalRelativePath: originalRelativePath ?? this.originalRelativePath,
      contentSha256: contentSha256 ?? this.contentSha256,
      pageCount: pageCount ?? this.pageCount,
      processingStatus: processingStatus ?? this.processingStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        originalRelativePath,
        contentSha256,
        pageCount,
        processingStatus,
        createdAt,
        updatedAt,
      ];
}

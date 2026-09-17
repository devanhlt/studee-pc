import 'package:equatable/equatable.dart';

/// Catalog entry for an isolated study subject.
class Subject extends Equatable {
  const Subject({
    required this.id,
    required this.name,
    required this.folderPath,
    this.icon,
    this.color,
    required this.schemaVersion,
    required this.createdAt,
    required this.updatedAt,
    this.pinned = false,
    this.sortOrder = 0,
    this.sourceCount = 0,
    this.knowledgeCount = 0,
    this.questionCount = 0,
  });

  final String id;
  final String name;
  final String folderPath;
  final String? icon;
  final int? color;
  final int schemaVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pinned;
  final int sortOrder;
  final int sourceCount;
  final int knowledgeCount;
  final int questionCount;

  Subject copyWith({
    String? id,
    String? name,
    String? folderPath,
    String? icon,
    int? color,
    int? schemaVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pinned,
    int? sortOrder,
    int? sourceCount,
    int? knowledgeCount,
    int? questionCount,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      folderPath: folderPath ?? this.folderPath,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pinned: pinned ?? this.pinned,
      sortOrder: sortOrder ?? this.sortOrder,
      sourceCount: sourceCount ?? this.sourceCount,
      knowledgeCount: knowledgeCount ?? this.knowledgeCount,
      questionCount: questionCount ?? this.questionCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        folderPath,
        icon,
        color,
        schemaVersion,
        createdAt,
        updatedAt,
        pinned,
        sortOrder,
        sourceCount,
        knowledgeCount,
        questionCount,
      ];
}

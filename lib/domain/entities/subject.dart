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
        sourceCount,
        knowledgeCount,
        questionCount,
      ];
}

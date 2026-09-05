import 'package:equatable/equatable.dart';

/// A choice parsed from the current solve input (not yet persisted).
class ParsedChoice extends Equatable {
  const ParsedChoice({
    required this.label,
    required this.content,
  });

  final String label;
  final String content;

  @override
  List<Object?> get props => [label, content];
}

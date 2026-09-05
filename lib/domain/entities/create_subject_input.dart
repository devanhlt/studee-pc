import 'package:equatable/equatable.dart';

/// Input for creating a new subject (UUID folder assigned by infrastructure).
class CreateSubjectInput extends Equatable {
  const CreateSubjectInput({
    required this.name,
    this.icon,
    this.color,
  });

  final String name;
  final String? icon;
  final int? color;

  @override
  List<Object?> get props => [name, icon, color];
}

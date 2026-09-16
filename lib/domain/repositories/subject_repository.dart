import 'package:studee_pc/domain/entities/create_subject_input.dart';
import 'package:studee_pc/domain/entities/subject.dart';

/// Catalog and subject-lifecycle operations.
abstract interface class SubjectRepository {
  Future<Subject> createSubject(CreateSubjectInput input);

  Future<List<Subject>> listSubjects();

  Future<void> openSubject(String subjectId);

  Future<void> closeSubject();

  Future<void> renameSubject(String subjectId, String newName);

  Future<void> setSubjectPinned(String subjectId, {required bool pinned});

  Future<void> deleteSubject(String subjectId);

  /// Exports the subject folder as a ZIP; returns the created archive path.
  Future<String> exportSubject(String subjectId, String destination);

  /// Imports a previously exported subject ZIP; returns the restored subject.
  Future<Subject> importSubject(String zipPath);

  String? get activeSubjectId;
}

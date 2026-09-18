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

  /// Persist a new manual order for [orderedIds] (index = sort order).
  Future<void> reorderSubjects(List<String> orderedIds);

  Future<void> deleteSubject(String subjectId);

  /// Exports the subject folder as an encrypted `.stud` pack.
  Future<String> exportSubject(String subjectId, String destination);

  /// Imports a subject from an encrypted `.stud` pack path.
  Future<Subject> importSubject(String studPath);

  String? get activeSubjectId;
}

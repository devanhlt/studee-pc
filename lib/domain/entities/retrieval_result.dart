import 'package:equatable/equatable.dart';
import 'package:studee_pc/domain/entities/ranked_candidate.dart';

/// Output of subject-scoped knowledge retrieval for a parsed question.
class RetrievalResult extends Equatable {
  const RetrievalResult({
    required this.candidates,
    this.exactMatches = const [],
    this.hasTrustedConflict = false,
  });

  final List<RankedCandidate> candidates;
  final List<RankedCandidate> exactMatches;
  final bool hasTrustedConflict;

  bool get isEmpty => candidates.isEmpty && exactMatches.isEmpty;

  @override
  List<Object?> get props => [candidates, exactMatches, hasTrustedConflict];
}

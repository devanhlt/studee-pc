import 'package:equatable/equatable.dart';
import 'package:studee_pc/domain/enums/knowledge_unit_type.dart';
import 'package:studee_pc/domain/enums/verification_status.dart';

/// One evidence snippet sent to DeepSeek (token-budgeted).
class EvidenceItem extends Equatable {
  const EvidenceItem({
    required this.evidenceId,
    required this.localId,
    required this.type,
    required this.content,
    required this.verificationStatus,
    this.sourceTitle,
    this.page,
  });

  final String evidenceId;
  final String localId;
  final KnowledgeUnitType type;
  final String content;
  final VerificationStatus verificationStatus;
  final String? sourceTitle;
  final int? page;

  @override
  List<Object?> get props => [
        evidenceId,
        localId,
        type,
        content,
        verificationStatus,
        sourceTitle,
        page,
      ];
}

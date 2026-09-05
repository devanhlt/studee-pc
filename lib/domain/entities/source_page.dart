import 'package:equatable/equatable.dart';

/// One page within a multi-page source (PDF or image sequence).
class SourcePage extends Equatable {
  const SourcePage({
    required this.id,
    required this.sourceId,
    required this.pageNumber,
    this.imageRelativePath,
    this.textLayer,
    this.rawOcrRelativePath,
    this.normalizedText,
    this.ocrEngine,
    this.ocrModelVersion,
    this.ocrConfidence,
    required this.processingStatus,
  });

  final String id;
  final String sourceId;
  final int pageNumber;
  final String? imageRelativePath;
  final String? textLayer;
  final String? rawOcrRelativePath;
  final String? normalizedText;
  final String? ocrEngine;
  final String? ocrModelVersion;
  final double? ocrConfidence;
  final String processingStatus;

  SourcePage copyWith({
    String? id,
    String? sourceId,
    int? pageNumber,
    String? imageRelativePath,
    String? textLayer,
    String? rawOcrRelativePath,
    String? normalizedText,
    String? ocrEngine,
    String? ocrModelVersion,
    double? ocrConfidence,
    String? processingStatus,
  }) {
    return SourcePage(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      pageNumber: pageNumber ?? this.pageNumber,
      imageRelativePath: imageRelativePath ?? this.imageRelativePath,
      textLayer: textLayer ?? this.textLayer,
      rawOcrRelativePath: rawOcrRelativePath ?? this.rawOcrRelativePath,
      normalizedText: normalizedText ?? this.normalizedText,
      ocrEngine: ocrEngine ?? this.ocrEngine,
      ocrModelVersion: ocrModelVersion ?? this.ocrModelVersion,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
      processingStatus: processingStatus ?? this.processingStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sourceId,
        pageNumber,
        imageRelativePath,
        textLayer,
        rawOcrRelativePath,
        normalizedText,
        ocrEngine,
        ocrModelVersion,
        ocrConfidence,
        processingStatus,
      ];
}

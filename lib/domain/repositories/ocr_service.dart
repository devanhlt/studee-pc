import 'package:equatable/equatable.dart';

/// Request sent to the OCR service (Mathpix or future middleware).
class OcrRequest extends Equatable {
  const OcrRequest({
    this.protocolVersion = 1,
    required this.jobId,
    this.action = 'parse_document',
    required this.inputPath,
    required this.outputDirectory,
    this.pages,
    this.languageHints = const ['vi', 'en'],
    this.quality = 'highest',
    this.modelDir,
    this.forceOcr = false,
  });

  final int protocolVersion;
  final String jobId;
  final String action;
  final String inputPath;
  final String outputDirectory;
  final List<int>? pages;
  final List<String> languageHints;
  final String quality;
  final String? modelDir;
  final bool forceOcr;

  Map<String, dynamic> toJson() => {
        'protocol_version': protocolVersion,
        'job_id': jobId,
        'action': action,
        'input_path': inputPath,
        'output_directory': outputDirectory,
        if (pages != null) 'pages': pages,
        'language_hints': languageHints,
        'quality': quality,
        if (modelDir != null) 'model_dir': modelDir,
        if (forceOcr) 'force_ocr': forceOcr,
      };

  @override
  List<Object?> get props => [
        protocolVersion,
        jobId,
        action,
        inputPath,
        outputDirectory,
        pages,
        languageHints,
        quality,
        modelDir,
        forceOcr,
      ];
}

/// Streaming events from the OCR service.
sealed class OcrEvent extends Equatable {
  const OcrEvent({required this.jobId});

  final String jobId;

  @override
  List<Object?> get props => [jobId];
}

final class OcrProgressEvent extends OcrEvent {
  const OcrProgressEvent({
    required super.jobId,
    required this.page,
    required this.totalPages,
    required this.stage,
  });

  final int page;
  final int totalPages;
  final String stage;

  @override
  List<Object?> get props => [...super.props, page, totalPages, stage];
}

final class OcrPageCompletedEvent extends OcrEvent {
  const OcrPageCompletedEvent({
    required super.jobId,
    required this.page,
    required this.resultPath,
  });

  final int page;
  final String resultPath;

  @override
  List<Object?> get props => [...super.props, page, resultPath];
}

final class OcrWarningEvent extends OcrEvent {
  const OcrWarningEvent({
    required super.jobId,
    this.page,
    required this.code,
    this.message,
  });

  final int? page;
  final String code;
  final String? message;

  @override
  List<Object?> get props => [...super.props, page, code, message];
}

final class OcrCompletedEvent extends OcrEvent {
  const OcrCompletedEvent({required super.jobId});
}

final class OcrFailedEvent extends OcrEvent {
  const OcrFailedEvent({
    required super.jobId,
    required this.code,
    this.message,
  });

  final String code;
  final String? message;

  @override
  List<Object?> get props => [...super.props, code, message];
}

/// OCR boundary (Mathpix cloud today; middleware-compatible later).
abstract interface class OcrService {
  Stream<OcrEvent> process(OcrRequest request);

  Future<void> cancel(String jobId);
}

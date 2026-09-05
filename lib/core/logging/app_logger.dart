import 'package:logging/logging.dart';

/// Application logger that redacts secrets and study content by default.
///
/// Never log API keys, full prompts, PDF/screenshot payloads, or question
/// bodies. Prefer identifiers and short status codes.
class AppLogger {
  AppLogger(String name) : _logger = Logger(name);

  final Logger _logger;

  static bool _initialized = false;

  /// Configure root logging once at app startup.
  static void initialize({Level level = Level.INFO}) {
    if (_initialized) return;
    _initialized = true;
    hierarchicalLoggingEnabled = true;
    Logger.root.level = level;
    Logger.root.onRecord.listen((record) {
      final safe = redact(record.message);
      // Desktop console sink — intentional for local diagnostics.
      // ignore: avoid_print
      print(
        '${record.time.toIso8601String()} '
        '[${record.level.name}] ${record.loggerName}: $safe',
      );
      if (record.error != null) {
        // ignore: avoid_print
        print('  error: ${redact(record.error.toString())}');
      }
    });
  }

  void finest(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.finest(redact(message), error, stackTrace);

  void finer(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.finer(redact(message), error, stackTrace);

  void fine(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.fine(redact(message), error, stackTrace);

  void info(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.info(redact(message), error, stackTrace);

  void warning(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.warning(redact(message), error, stackTrace);

  void severe(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.severe(redact(message), error, stackTrace);

  void shout(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.shout(redact(message), error, stackTrace);

  /// Redact sensitive patterns from a log message.
  static String redact(String input) {
    var output = input;

    output = output.replaceAllMapped(
      RegExp(
        r'(api[_-]?key|authorization|bearer|token|secret|password)\s*[:=]\s*\S+',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}=[REDACTED]',
    );
    output = output.replaceAllMapped(
      RegExp(r'\bBearer\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false),
      (_) => 'Bearer [REDACTED]',
    );
    output = output.replaceAllMapped(
      RegExp(r'\bsk-[A-Za-z0-9]{8,}\b'),
      (_) => 'sk-[REDACTED]',
    );
    output = output.replaceAllMapped(
      RegExp(r'\b[A-Za-z0-9_-]{32,}\b'),
      (m) {
        final value = m.group(0)!;
        final uuidLike = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
          r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        );
        final shaLike = RegExp(r'^[0-9a-fA-F]{40,64}$');
        if (uuidLike.hasMatch(value) || shaLike.hasMatch(value)) {
          return value;
        }
        if (value.length >= 40) {
          return '[REDACTED_TOKEN]';
        }
        return value;
      },
    );

    output = output.replaceAllMapped(
      RegExp(
        r'(prompt|system_prompt|user_prompt|messages)\s*[:=]\s*.{20,}',
        caseSensitive: false,
        dotAll: true,
      ),
      (m) => '${m.group(1)}=[REDACTED_PROMPT]',
    );

    output = output.replaceAllMapped(
      RegExp(
        r'(/[^\s]+?\.(?:pdf|png|jpe?g|webp|gif|bmp|tiff?))',
        caseSensitive: false,
      ),
      (m) {
        final path = m.group(1)!;
        final fileName = path.split('/').last;
        return '[PATH]/$fileName';
      },
    );
    output = output.replaceAllMapped(
      RegExp(
        r'([A-Za-z]:\\[^\s]+?\.(?:pdf|png|jpe?g|webp|gif|bmp|tiff?))',
        caseSensitive: false,
      ),
      (m) {
        final path = m.group(1)!;
        final fileName = path.split(RegExp(r'[\\/]')).last;
        return '[PATH]/$fileName';
      },
    );

    output = output.replaceAllMapped(
      RegExp(r'data:image/[a-zA-Z+]+;base64,[A-Za-z0-9+/=]{32,}'),
      (_) => 'data:image/[REDACTED]',
    );
    output = output.replaceAllMapped(
      RegExp(
        r'(screenshot|image_bytes|image_base64)\s*[:=]\s*\S+',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}=[REDACTED_IMAGE]',
    );

    output = output.replaceAllMapped(
      RegExp(
        r'(question(_text|_content)?|answer(_content)?|ocr_text|'
        r'normalized_text|page_text)\s*[:=]\s*.{16,}',
        caseSensitive: false,
        dotAll: true,
      ),
      (m) => '${m.group(1)}=[REDACTED_CONTENT]',
    );

    return output;
  }
}

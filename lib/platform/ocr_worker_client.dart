import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/domain/repositories/ocr_service.dart';

/// Resolved launch command for the OCR child process.
class _WorkerLaunch {
  const _WorkerLaunch({
    required this.executable,
    required this.args,
    required this.workingDirectory,
  });

  final String executable;
  final List<String> args;
  final String workingDirectory;
}

/// JSONL stdin/stdout client for the local OCR child process.
class OcrWorkerClient implements OcrService {
  OcrWorkerClient({
    String? pythonExecutable,
    String? workerScriptPath,
    String? modelDir,
    Future<String?> Function()? modelDirResolver,
    bool forceMock = false,
  })  : _pythonExecutable = pythonExecutable,
        _workerScriptPath = workerScriptPath,
        _modelDir = modelDir,
        _modelDirResolver = modelDirResolver,
        _forceMock = forceMock;

  final String? _pythonExecutable;
  final String? _workerScriptPath;
  final String? _modelDir;
  final Future<String?> Function()? _modelDirResolver;
  final bool _forceMock;
  final AppLogger _log = AppLogger('OcrWorkerClient');

  Process? _process;
  final Map<String, Completer<void>> _cancelSignals = {};

  /// Writable runtime venv (outside the .app) for packaged installs.
  static const String supportRuntimeFolder = 'ocr_runtime';

  /// Relocatable runtime shipped inside Contents/Resources/ocr_runtime.
  static const String bundledRuntimeFolder = 'ocr_runtime';

  @override
  Stream<OcrEvent> process(OcrRequest request) async* {
    final cancel = Completer<void>();
    _cancelSignals[request.jobId] = cancel;

    try {
      final launch = await _resolveLaunch();
      if (launch == null) {
        final hint = await _missingHint();
        _log.warning('OCR worker script or python3 not found. $hint');
        yield OcrFailedEvent(
          jobId: request.jobId,
          code: 'worker_missing',
          message:
              'Không tìm thấy tiến trình OCR cục bộ (python3 / ocr_worker).\n$hint',
        );
        return;
      }
      await _writeResolveDiag(
        script: p.join(launch.workingDirectory, 'main.py'),
        python: launch.executable,
      );

      await Directory(request.outputDirectory).create(recursive: true);

      final payload = Map<String, dynamic>.from(request.toJson());
      final resolvedModelDir = request.modelDir ??
          _modelDir ??
          await _modelDirResolver?.call();
      if (resolvedModelDir != null && resolvedModelDir.isNotEmpty) {
        payload['model_dir'] = resolvedModelDir;
      }

      final env = Map<String, String>.from(Platform.environment);
      // Finder-launched apps have a tiny PATH — include Homebrew + system bins.
      final pathParts = <String>[
        '/opt/homebrew/bin',
        '/opt/homebrew/sbin',
        '/usr/local/bin',
        '/usr/bin',
        '/bin',
        '/usr/sbin',
        '/sbin',
        if ((env['PATH'] ?? '').isNotEmpty) env['PATH']!,
      ];
      env['PATH'] = pathParts.join(':');
      env['HOME'] ??= Platform.environment['HOME'] ?? '';
      env['LANG'] ??= Platform.environment['LANG'] ?? 'en_US.UTF-8';
      env['PYTHONUNBUFFERED'] = '1';
      env['PYTHONPATH'] = launch.workingDirectory;

      if (_forceMock) {
        env['OCR_WORKER_FORCE_MOCK'] = '1';
      } else {
        env.remove('OCR_WORKER_FORCE_MOCK');
        env.putIfAbsent(
          'PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK',
          () => 'True',
        );
      }
      if (resolvedModelDir != null && resolvedModelDir.isNotEmpty) {
        env['PADDLEOCR_VL_MODEL_DIR'] = resolvedModelDir;
      }

      // Prefer offline models shipped next to the bundled Python runtime.
      final bundledCache = await _bundledPaddlexCache();
      if (bundledCache != null) {
        env['PADDLE_PDX_CACHE_HOME'] = bundledCache;
        env.putIfAbsent('HF_HUB_OFFLINE', () => '1');
        env.putIfAbsent('TRANSFORMERS_OFFLINE', () => '1');
        _log.info('OCR PaddleX cache: $bundledCache');
      }

      _log.info(
        'Starting OCR worker python=${launch.executable} '
        'cwd=${launch.workingDirectory} mock=$_forceMock',
      );

      _process = await Process.start(
        launch.executable,
        launch.args,
        workingDirectory: launch.workingDirectory,
        environment: env,
        mode: ProcessStartMode.normal,
        runInShell: false,
      );
      final process = _process!;

      // Forward stderr for diagnostics (never log secrets / full OCR text).
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) return;
        _log.info('ocr_worker: ${trimmed.length > 200 ? '${trimmed.substring(0, 200)}…' : trimmed}');
      });

      process.stdin.writeln(jsonEncode(payload));
      await process.stdin.flush();
      // Keep stdin open until job ends so the worker's readline loop stays alive
      // for cancel messages; close after first request for one-shot jobs.
      await process.stdin.close();

      final lines = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        if (cancel.isCompleted) {
          process.kill(ProcessSignal.sigterm);
          yield OcrFailedEvent(
            jobId: request.jobId,
            code: 'cancelled',
            message: 'Đã hủy nhận dạng văn bản.',
          );
          return;
        }

        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        Map<String, dynamic> map;
        try {
          map = jsonDecode(trimmed) as Map<String, dynamic>;
        } on Object {
          _log.warning('OCR worker emitted non-JSON line');
          continue;
        }

        final jobId = map['job_id'] as String? ?? request.jobId;
        final type = map['type'] as String? ?? '';

        switch (type) {
          case 'progress':
            yield OcrProgressEvent(
              jobId: jobId,
              page: (map['page'] as num?)?.toInt() ?? 0,
              totalPages: (map['total_pages'] as num?)?.toInt() ?? 0,
              stage: map['stage'] as String? ?? 'ocr',
            );
          case 'page_completed':
            yield OcrPageCompletedEvent(
              jobId: jobId,
              page: (map['page'] as num?)?.toInt() ?? 0,
              resultPath: map['result_path'] as String? ?? '',
            );
          case 'warning':
            yield OcrWarningEvent(
              jobId: jobId,
              page: (map['page'] as num?)?.toInt(),
              code: map['code'] as String? ?? 'warning',
              message: map['message'] as String?,
            );
          case 'completed':
            yield OcrCompletedEvent(jobId: jobId);
            return;
          case 'failed':
          case 'error':
            yield OcrFailedEvent(
              jobId: jobId,
              code: map['code'] as String? ?? 'ocr_failed',
              message: map['message'] as String?,
            );
            return;
          default:
            _log.warning('Unknown OCR event type=$type');
        }
      }

      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        yield OcrFailedEvent(
          jobId: request.jobId,
          code: 'worker_exit_$exitCode',
          message: 'Tiến trình OCR kết thúc bất thường (mã $exitCode).',
        );
      } else {
        yield OcrCompletedEvent(jobId: request.jobId);
      }
    } on Object catch (e) {
      _log.severe('OCR worker process failed', e);
      yield OcrFailedEvent(
        jobId: request.jobId,
        code: 'worker_spawn_failed',
        message:
            'Không khởi chạy được tiến trình OCR. Kiểm tra python3 và thư mục ocr_worker.',
      );
    } finally {
      _cancelSignals.remove(request.jobId);
      _process = null;
    }
  }

  @override
  Future<void> cancel(String jobId) async {
    final signal = _cancelSignals[jobId];
    if (signal != null && !signal.isCompleted) {
      signal.complete();
    }
    final process = _process;
    if (process != null) {
      try {
        process.kill(ProcessSignal.sigterm);
      } on Object {
        // Best-effort.
      }
    }
    _log.info('Cancelled OCR job id=$jobId');
  }

  Future<_WorkerLaunch?> _resolveLaunch() async {
    final script = await _resolveWorkerScript();
    if (script == null) return null;

    final python = await _resolvePython(scriptDir: p.dirname(script));
    if (python == null) return null;

    return _WorkerLaunch(
      executable: python,
      args: ['-u', script],
      workingDirectory: p.dirname(script),
    );
  }

  Future<String?> _resolvePython({required String scriptDir}) async {
    final configured = _pythonExecutable;
    if (configured != null && configured.isNotEmpty) {
      if (await _fileExists(configured) || await _commandExists(configured)) {
        return configured;
      }
    }

    // 1) Self-contained Python shipped inside the .app (no user install).
    final bundled = await _bundledPython();
    if (bundled != null) return bundled;

    // 2) External runtime venv (older packaged installs / Application Support).
    final supportVenv = await _supportVenvPython();
    if (supportVenv != null) return supportVenv;

    // 3) Local .venv next to worker scripts (dev).
    for (final rel in const [
      ['.venv', 'bin', 'python'],
      ['.venv', 'bin', 'python3'],
      ['.venv', 'Scripts', 'python.exe'],
    ]) {
      final candidate = p.joinAll([scriptDir, ...rel]);
      if (await _fileExists(candidate)) return candidate;
    }

    // 4) Absolute interpreter paths (GUI apps often lack Homebrew on PATH).
    for (final candidate in const [
      '/opt/homebrew/bin/python3.12',
      '/opt/homebrew/bin/python3.11',
      '/opt/homebrew/bin/python3',
      '/usr/local/bin/python3.12',
      '/usr/local/bin/python3.11',
      '/usr/local/bin/python3',
      '/usr/bin/python3',
    ]) {
      if (await _fileExists(candidate)) return candidate;
    }

    for (final candidate in const [
      'python3.12',
      'python3.11',
      'python3',
      'python',
    ]) {
      if (await _commandExists(candidate)) return candidate;
    }
    return null;
  }

  /// Contents/Resources roots next to the running executable.
  Future<List<String>> _resourceRoots() async {
    final roots = <String>{};
    try {
      final exe = await File(Platform.resolvedExecutable).resolveSymbolicLinks();
      var dir = Directory(p.dirname(exe));
      for (var i = 0; i < 12; i++) {
        if (p.basename(dir.path) == 'Contents') {
          roots.add(p.join(dir.path, 'Resources'));
        }
        roots.add(p.join(dir.path, 'Resources'));
        // Dev: …/build/ocr_bundle sits at repo/build/ocr_bundle
        roots.add(p.join(dir.path, 'ocr_bundle'));
        roots.add(p.join(dir.path, 'build', 'ocr_bundle'));
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
    } on Object catch (e) {
      _log.warning('resource root walk failed: $e');
    }
    final execDir = p.dirname(Platform.resolvedExecutable);
    roots.add(p.normalize(p.join(execDir, '..', 'Resources')));
    roots.add('/Applications/Studee.app/Contents/Resources');
    final home = Platform.environment['HOME'] ?? '';
    if (home.isNotEmpty) {
      roots.add(p.join(home, 'studee-pc', 'build', 'ocr_bundle'));
    }
    return roots.where((r) => r.isNotEmpty).toList();
  }

  Future<String?> _bundledPython() async {
    for (final root in await _resourceRoots()) {
      for (final rel in const [
        // Packaged: Resources/ocr_runtime/python/bin/python3
        [bundledRuntimeFolder, 'python', 'bin', 'python3'],
        [bundledRuntimeFolder, 'python', 'bin', 'python'],
        [bundledRuntimeFolder, '.venv', 'bin', 'python3'],
        [bundledRuntimeFolder, '.venv', 'bin', 'python'],
        // Dev ocr_bundle root (== build/ocr_bundle)
        ['python', 'bin', 'python3'],
        ['python', 'bin', 'python'],
      ]) {
        final candidate = p.joinAll([root, ...rel]);
        if (await _fileExists(candidate)) {
          _log.info('OCR bundled python: $candidate');
          return candidate;
        }
      }
    }
    return null;
  }

  Future<String?> _bundledPaddlexCache() async {
    for (final root in await _resourceRoots()) {
      for (final candidate in [
        p.join(root, bundledRuntimeFolder, 'paddlex_cache'),
        p.join(root, 'paddlex_cache'),
      ]) {
        final models = p.join(candidate, 'official_models', 'PaddleOCR-VL-1.6');
        if (await Directory(models).exists()) {
          return candidate;
        }
      }
    }
    return null;
  }

  Future<String?> _resolveWorkerScript() async {
    final configured = _workerScriptPath;
    if (configured != null &&
        configured.isNotEmpty &&
        await _fileExists(configured)) {
      return configured;
    }

    final candidates = <String>{};

    // Packaged setup writes this marker (scripts may live in .app or repo).
    final fromMarker = await _workerSrcFromSupport();
    if (fromMarker != null) {
      candidates.add(p.join(fromMarker, 'main.py'));
    }

    // Prefer walking up from the real executable to Contents/Resources.
    try {
      final exe = await File(Platform.resolvedExecutable).resolveSymbolicLinks();
      var dir = Directory(p.dirname(exe));
      for (var i = 0; i < 12; i++) {
        candidates.add(
          p.join(dir.path, 'Resources', 'ocr_worker', 'main.py'),
        );
        candidates.add(p.join(dir.path, 'ocr_worker', 'main.py'));
        if (p.basename(dir.path) == 'Contents') {
          candidates.add(
            p.join(dir.path, 'Resources', 'ocr_worker', 'main.py'),
          );
        }
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
    } on Object catch (e) {
      _log.warning('resolveExecutable failed: $e');
    }

    final execDir = p.dirname(Platform.resolvedExecutable);
    candidates.addAll([
      p.normalize(
        p.join(execDir, '..', 'Resources', 'ocr_worker', 'main.py'),
      ),
      p.join(Directory.current.path, 'ocr_worker', 'main.py'),
      p.normalize(
        p.join(execDir, '..', '..', '..', '..', 'ocr_worker', 'main.py'),
      ),
      // Common absolute installs / monorepo checkout.
      p.join(
        Platform.environment['HOME'] ?? '',
        'studee-pc',
        'ocr_worker',
        'main.py',
      ),
      '/Applications/Studee.app/Contents/Resources/ocr_worker/main.py',
      ..._ancestorCandidates(Directory.current.path),
      ..._ancestorCandidates(execDir),
    ]);

    for (final path in candidates) {
      if (path.isEmpty) continue;
      if (await _fileExists(path)) {
        _log.info('OCR worker script: $path');
        return path;
      }
    }
    return null;
  }

  /// Application Support roots — path_provider plus hardcoded macOS locations.
  /// Packaged apps / leftover Containers can disagree on the real folder.
  Future<List<String>> _supportRoots() async {
    final roots = <String>{};
    try {
      roots.add((await getApplicationSupportDirectory()).path);
    } on Object catch (e) {
      _log.warning('getApplicationSupportDirectory failed: $e');
    }
    final home = Platform.environment['HOME'] ?? '';
    if (home.isNotEmpty) {
      roots.add(
        p.join(home, 'Library', 'Application Support', 'com.studee.studeePc'),
      );
      roots.add(
        p.join(
          home,
          'Library',
          'Containers',
          'com.studee.studeePc',
          'Data',
          'Library',
          'Application Support',
          'com.studee.studeePc',
        ),
      );
    }
    return roots.where((r) => r.isNotEmpty).toList();
  }

  Future<String?> _workerSrcFromSupport() async {
    for (final support in await _supportRoots()) {
      try {
        final marker = File(
          p.join(support, supportRuntimeFolder, 'worker_src.txt'),
        );
        if (!await marker.exists()) continue;
        final raw = (await marker.readAsString()).trim();
        if (raw.isEmpty) continue;
        if (await Directory(raw).exists()) return raw;
      } on Object catch (e) {
        _log.warning('worker_src marker read failed ($support): $e');
      }
    }
    return null;
  }

  Future<String?> _supportVenvPython() async {
    for (final support in await _supportRoots()) {
      for (final rel in const [
        [supportRuntimeFolder, '.venv', 'bin', 'python3.12'],
        [supportRuntimeFolder, '.venv', 'bin', 'python'],
        [supportRuntimeFolder, '.venv', 'bin', 'python3'],
        [supportRuntimeFolder, '.venv', 'Scripts', 'python.exe'],
      ]) {
        final candidate = p.joinAll([support, ...rel]);
        if (await _fileExists(candidate)) {
          _log.info('OCR support venv: $candidate');
          return candidate;
        }
      }
    }
    return null;
  }

  Future<void> _writeResolveDiag({
    required String? script,
    required String? python,
  }) async {
    try {
      final roots = await _supportRoots();
      final buf = StringBuffer()
        ..writeln('time=${DateTime.now().toIso8601String()}')
        ..writeln('exe=${Platform.resolvedExecutable}')
        ..writeln('cwd=${Directory.current.path}')
        ..writeln('script=$script')
        ..writeln('python=$python')
        ..writeln('support_roots=${roots.join(' | ')}');
      for (final root in roots) {
        final venv = p.join(root, supportRuntimeFolder, '.venv', 'bin', 'python');
        buf.writeln('venv_exists[$root]=${await _fileExists(venv)}');
      }
      final home = Platform.environment['HOME'] ?? '';
      final out = File(
        home.isEmpty
            ? p.join(Directory.systemTemp.path, 'studee_ocr_resolve.log')
            : p.join(home, 'Library', 'Logs', 'studee_ocr_resolve.log'),
      );
      await out.parent.create(recursive: true);
      await out.writeAsString(buf.toString());
    } on Object {
      // Best-effort diagnostics only.
    }
  }

  Future<String> _missingHint() async {
    final script = await _resolveWorkerScript();
    final python = await _resolvePython(
      scriptDir: script != null ? p.dirname(script) : Directory.current.path,
    );
    await _writeResolveDiag(script: script, python: python);

    if (script == null) {
      return 'Thiếu main.py trong Studee.app/Contents/Resources/ocr_worker. '
          'Cài lại bản DMG mới. (chi tiết: ~/Library/Logs/studee_ocr_resolve.log)';
    }
    final bundled = await _bundledPython();
    if (bundled == null) {
      return 'Ứng dụng thiếu Python OCR kèm theo (Resources/ocr_runtime).\n'
          'Hãy cài bản DMG đầy đủ (có OCR runtime), không dùng bản slim.\n'
          'Hoặc (máy dev) chạy:\n'
          '  cd "${p.dirname(script)}" && ./setup_real_ocr.sh && ./warmup_models.sh';
    }
    return 'Đã thấy worker tại $script và Python tại $bundled nhưng không khởi chạy được.\n'
        'Thử mở lại Studee hoặc cài lại bản DMG.';
  }

  List<String> _ancestorCandidates(String start) {
    final out = <String>[];
    var dir = Directory(start);
    for (var i = 0; i < 6; i++) {
      out.add(p.join(dir.path, 'ocr_worker', 'main.py'));
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return out;
  }

  Future<bool> _fileExists(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) return true;
      // Broken relative symlinks: check after resolving parent.
      final resolved = await file.resolveSymbolicLinks();
      return await File(resolved).exists();
    } on Object {
      return false;
    }
  }

  Future<bool> _commandExists(String command) async {
    try {
      final env = Map<String, String>.from(Platform.environment);
      env['PATH'] =
          '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${env['PATH'] ?? ''}';
      final result = await Process.run(
        '/usr/bin/which',
        [command],
        environment: env,
        includeParentEnvironment: false,
      );
      return result.exitCode == 0 &&
          (result.stdout as String).toString().trim().isNotEmpty;
    } on Object {
      return false;
    }
  }
}

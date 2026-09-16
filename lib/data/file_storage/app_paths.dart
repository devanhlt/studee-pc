import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves the ApplicationData root and standard layout paths.
///
/// Layout:
/// ```text
/// ApplicationData/
///   catalog.db
///   credentials.v1.dat   # obfuscated activation code / legacy secrets
///   models/paddleocr-vl-1.6/
///   subjects/subject_<uuid>/
///     manifest.json
///     subject.db
///     sources/source_<uuid>/...
///     attachments/
/// ```
class AppPaths {
  AppPaths({Directory? Function()? applicationSupportOverride})
      : _applicationSupportOverride = applicationSupportOverride;

  final Directory? Function()? _applicationSupportOverride;

  Directory? _cachedRoot;

  static const String modelBundleName = 'paddleocr-vl-1.6';

  /// Absolute path to the ApplicationData root directory.
  Future<String> applicationDataRoot() async {
    if (_cachedRoot != null) return _cachedRoot!.path;

    final override = _applicationSupportOverride?.call();
    if (override != null) {
      _cachedRoot = override;
      return override.path;
    }

    // Desktop: application support is the stable per-app data directory.
    final support = await getApplicationSupportDirectory();
    final root = Directory(p.join(support.path, 'ApplicationData'));
    _cachedRoot = root;
    return root.path;
  }

  /// Ensures the root and top-level folders exist; returns the root path.
  Future<String> ensureApplicationDataRoot() async {
    final root = await applicationDataRoot();
    await Directory(root).create(recursive: true);
    await Directory(p.join(root, 'models')).create(recursive: true);
    await Directory(p.join(root, 'subjects')).create(recursive: true);
    return root;
  }

  Future<String> catalogDbPath() async {
    final root = await ensureApplicationDataRoot();
    return p.join(root, 'catalog.db');
  }

  /// Obfuscated credentials file (activation code + legacy provider keys).
  Future<String> credentialsFilePath() async {
    final root = await ensureApplicationDataRoot();
    return p.join(root, 'credentials.v1.dat');
  }

  Future<String> modelsRoot() async {
    final root = await ensureApplicationDataRoot();
    return p.join(root, 'models');
  }

  Future<String> paddleOcrModelDir() async {
    final models = await modelsRoot();
    return p.join(models, modelBundleName);
  }

  Future<String> subjectsRoot() async {
    final root = await ensureApplicationDataRoot();
    return p.join(root, 'subjects');
  }

  /// Folder name for a subject UUID — never renamed after creation.
  static String subjectFolderName(String subjectId) => 'subject_$subjectId';

  Future<String> subjectFolder(String subjectId) async {
    final root = await subjectsRoot();
    return p.join(root, subjectFolderName(subjectId));
  }

  Future<String> subjectManifestPath(String subjectId) async {
    final folder = await subjectFolder(subjectId);
    return p.join(folder, 'manifest.json');
  }

  Future<String> subjectDbPath(String subjectId) async {
    final folder = await subjectFolder(subjectId);
    return p.join(folder, 'subject.db');
  }

  Future<String> subjectSourcesDir(String subjectId) async {
    final folder = await subjectFolder(subjectId);
    return p.join(folder, 'sources');
  }

  Future<String> subjectAttachmentsDir(String subjectId) async {
    final folder = await subjectFolder(subjectId);
    return p.join(folder, 'attachments');
  }

  static String sourceFolderName(String sourceId) => 'source_$sourceId';

  Future<String> sourceFolder(String subjectId, String sourceId) async {
    final sources = await subjectSourcesDir(subjectId);
    return p.join(sources, sourceFolderName(sourceId));
  }
}

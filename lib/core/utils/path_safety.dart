import 'package:path/path.dart' as p;
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/result/result.dart';

/// Validates that filesystem paths stay under an allowed root.
///
/// Rejects empty paths, absolute escapes, and `..` traversal that would leave
/// [rootDirectory].
abstract final class PathSafety {
  /// Returns true when [candidatePath] resolves strictly under [rootDirectory].
  static bool isUnderRoot(String rootDirectory, String candidatePath) {
    final root = p.normalize(p.absolute(rootDirectory));
    final candidate = p.normalize(p.absolute(candidatePath));
    if (candidate == root) return true;
    final rootWithSep = root.endsWith(p.separator) ? root : '$root${p.separator}';
    return candidate.startsWith(rootWithSep);
  }

  /// Joins [relativePath] under [rootDirectory] after rejecting traversal.
  ///
  /// [relativePath] must be relative. Absolute paths and `..` segments that
  /// escape the root produce [ValidationFailure].
  static Result<String> resolveUnderRoot({
    required String rootDirectory,
    required String relativePath,
  }) {
    if (relativePath.trim().isEmpty) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Đường dẫn tương đối không được để trống.',
          code: 'empty_relative_path',
        ),
      );
    }

    if (p.isAbsolute(relativePath)) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Không chấp nhận đường dẫn tuyệt đối ngoài thư mục gốc.',
          code: 'absolute_path_rejected',
        ),
      );
    }

    // Reject parent references in the raw input before join.
    final rawSegments = relativePath
        .replaceAll('\\', '/')
        .split('/')
        .where((s) => s.isNotEmpty && s != '.');
    if (rawSegments.contains('..')) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Phát hiện đường dẫn vượt thư mục gốc (path traversal).',
          code: 'path_traversal',
        ),
      );
    }

    final root = p.normalize(p.absolute(rootDirectory));
    final resolved = p.normalize(p.join(root, relativePath));

    if (!isUnderRoot(root, resolved)) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Đường dẫn nằm ngoài thư mục được phép.',
          code: 'path_outside_root',
        ),
      );
    }

    return Success(resolved);
  }

  /// Ensures an already-absolute [absolutePath] remains under [rootDirectory].
  static Result<String> ensureUnderRoot({
    required String rootDirectory,
    required String absolutePath,
  }) {
    if (absolutePath.trim().isEmpty) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Đường dẫn không được để trống.',
          code: 'empty_path',
        ),
      );
    }

    final resolved = p.normalize(p.absolute(absolutePath));
    if (!isUnderRoot(rootDirectory, resolved)) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Đường dẫn nằm ngoài thư mục được phép.',
          code: 'path_outside_root',
        ),
      );
    }
    return Success(resolved);
  }
}

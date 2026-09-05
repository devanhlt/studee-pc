import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/core/utils/path_safety.dart';

void main() {
  group('PathSafety', () {
    late String root;

    setUp(() {
      // Absolute-looking root for normalize/join behavior on the host OS.
      root = '/tmp/studee_app_root';
    });

    test('rejects ../ traversal', () {
      final result = PathSafety.resolveUnderRoot(
        rootDirectory: root,
        relativePath: '../escape.txt',
      );
      expect(result, isA<Failure<String>>());
      expect(result.failureOrNull?.code, 'path_traversal');

      final nested = PathSafety.resolveUnderRoot(
        rootDirectory: root,
        relativePath: 'subjects/../../etc/passwd',
      );
      expect(nested, isA<Failure<String>>());
      expect(nested.failureOrNull?.code, 'path_traversal');
    });

    test('rejects absolute escape', () {
      final result = PathSafety.resolveUnderRoot(
        rootDirectory: root,
        relativePath: '/etc/passwd',
      );
      expect(result, isA<Failure<String>>());
      expect(result.failureOrNull?.code, 'absolute_path_rejected');
    });

    test('accepts valid relative under root', () {
      final result = PathSafety.resolveUnderRoot(
        rootDirectory: root,
        relativePath: 'subjects/subject_abc/manifest.json',
      );
      expect(result, isA<Success<String>>());
      final path = result.valueOrNull!;
      expect(PathSafety.isUnderRoot(root, path), isTrue);
      expect(path.contains('manifest.json'), isTrue);
    });

    test('ensureUnderRoot rejects path outside', () {
      final outside = PathSafety.ensureUnderRoot(
        rootDirectory: root,
        absolutePath: '/tmp/other_place/file.txt',
      );
      expect(outside, isA<Failure<String>>());
      expect(outside.failureOrNull?.code, 'path_outside_root');

      final inside = PathSafety.ensureUnderRoot(
        rootDirectory: root,
        absolutePath: '$root/subjects/x',
      );
      expect(inside, isA<Success<String>>());
    });
  });
}

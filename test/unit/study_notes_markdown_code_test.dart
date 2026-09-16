import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/features/subjects/application/study_notes_markdown_code.dart';
import 'package:studee_pc/features/subjects/application/subject_format_kind.dart';

void main() {
  group('StudyNotesMarkdownCode', () {
    test('fences KTLT-style flattened C question', () {
      const raw =
          'Khi chạy chương trình sau trong ngôn ngữ lập trình C thì kết quả xuất ra màn hình là gì? #include<stdio.h> int main() { int a[] = {2,1}; printf("%d", *a); return 0; }';
      final out = StudyNotesMarkdownCode.formatBody(
        raw,
        kind: SubjectFormatKind.code,
      );
      expect(out, contains('```c'));
      expect(out, contains('Khi chạy chương trình'));
      expect(out, contains('#include <stdio.h>'));
      expect(out, contains('int main()'));
      expect(out, contains('printf'));
      expect(out.trim().endsWith('```'), isTrue);
      // Must not leave raw include glued to the question line.
      expect(out, isNot(contains('gì? #include')));
    });

    test('fences answer that is a void function', () {
      const raw =
          'void Search(BOOKS ds[], int n) { for(int i=0; i<n; i++) if(stricmp(ds[i].author,"Dennis")==0) printBooks(ds[i]); }';
      final out = StudyNotesMarkdownCode.formatBody(
        raw,
        kind: SubjectFormatKind.code,
      );
      expect(out, startsWith('```c'));
      expect(out, contains('void Search'));
      expect(out, contains('```'));
    });

    test('keeps LaTeX dollars for formula rendering', () {
      const raw = r'Khi nào $\det(A) \neq 0$?';
      final out = StudyNotesMarkdownCode.formatBody(
        raw,
        kind: SubjectFormatKind.math,
      );
      expect(out, contains(r'$\det(A)'));
      expect(out, isNot(contains('```')));
    });

    test('preserves existing fences', () {
      const raw = 'Ví dụ:\n```c\nint x = 1;\n```\nXong.';
      expect(
        StudyNotesMarkdownCode.formatBody(raw, kind: SubjectFormatKind.code),
        contains('```c'),
      );
      expect(
        StudyNotesMarkdownCode.formatBody(raw, kind: SubjectFormatKind.code),
        contains('int x = 1;'),
      );
    });

    test('plain subject ignores code and math formatters', () {
      const code =
          'void Search(BOOKS ds[], int n) { for(int i=0; i<n; i++) return; }';
      expect(
        StudyNotesMarkdownCode.formatBody(code, kind: SubjectFormatKind.plain),
        code,
      );
      const math = 'A = [[1,0],[0,1]]';
      expect(
        StudyNotesMarkdownCode.formatBody(math, kind: SubjectFormatKind.plain),
        math,
      );
    });

    test('leaves plain prose alone', () {
      const raw = 'Ma trận khả nghịch khi định thức khác không.';
      expect(
        StudyNotesMarkdownCode.formatBody(raw, kind: SubjectFormatKind.math),
        raw,
      );
    });

    test('indents left-aligned multiline C', () {
      const raw = '''
#include<stdio.h>
int main()
{
int *a, n;
printf("n="); scanf("%d", &n);
for(int i=0; i<n; i++)
scanf("%d", a+i);
return 0;
}
''';
      final out = StudyNotesMarkdownCode.prettifyFlattenedCode(raw);
      expect(out, contains('#include <stdio.h>'));
      expect(out, contains('int main() {'));
      expect(out, contains('\n  int *a, n;'));
      expect(out, contains('\n  for(int i=0; i<n; i++)'));
      expect(out, contains('\n  return 0;'));
      expect(out.trim().endsWith('}'), isTrue);
      final body = out
          .split('\n')
          .where((l) => l.trim().isNotEmpty && !l.startsWith('#include'))
          .toList();
      expect(body.any((l) => l.startsWith('  ')), isTrue);
    });

    test('indents brace-jammed opening line', () {
      const raw =
          '#include<stdio.h>\nint main()\n{ int a[] = {2,1};\nprintf("%d", *a);\nreturn 0;\n}';
      final out = StudyNotesMarkdownCode.prettifyFlattenedCode(raw);
      expect(out, contains('int a[] = {2,1};'));
      expect(out, contains('\n  printf'));
      expect(out, contains('\n  return 0;'));
      expect(
        out.split('\n').any((l) => l.startsWith('  int a[]')),
        isTrue,
      );
    });

    test('puts ellipsis placeholder on its own line as ASCII dots', () {
      const raw = '''
#include<stdio.h>
int main()
{
int a[]={1,3}, *p=a, n=2, x;
scanf("%d", &x);
……….. return 0;
}
''';
      final out = StudyNotesMarkdownCode.prettifyFlattenedCode(raw);
      expect(out, isNot(contains('…')));
      expect(out, contains('......'));
      expect(out, contains(RegExp(r'\.{3,}\n\s*return 0;')));
      expect(out, isNot(contains(RegExp(r'\.{3,} return'))));
    });
  });
}

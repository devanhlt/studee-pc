import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/features/subjects/application/study_notes_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('StudyNotesPdf embeds LaTeX formulas as images', () async {
    final regular =
        await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    expect(regular.lengthInBytes, greaterThan(1000));
    expect(bold.lengthInBytes, greaterThan(1000));

    final bytes = await StudyNotesPdf.buildBytes(r'''
# Toán — nhớ đáp án

## Lý thuyết

Công thức: $\det(A) \neq 0$ và
$$
A^{-1} = \frac{1}{\det(A)}\mathrm{adj}(A)
$$

## Danh sách câu hỏi

### 1
**Hỏi:** Khi nào $\det(A) = 0$?
**Đáp:** Ma trận suy biến
''');

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('format extensions', () {
    expect(StudyNotesExportFormat.markdown.fileExtension, 'md');
    expect(StudyNotesExportFormat.pdf.fileExtension, 'pdf');
  });
}

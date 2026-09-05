import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/domain/repositories/deepseek_client.dart';
import 'package:studee_pc/domain/services/source_text_chunker.dart';

void main() {
  group('SourceBlockDetector', () {
    const detector = SourceBlockDetector();

    test('keeps question + choices + answer + explanation as one block', () {
      const text = '''
Câu 1. Tính đạo hàm của \$x^2\$?
A. \$2x\$
B. \$x\$
C. \$x^2\$
Đáp án: A
Giải thích: đạo hàm của x bình bằng 2x.

Câu 2. Chọn khẳng định đúng.
A. 1+1=2
B. 1+1=3
Đáp án: A
''';
      final blocks = detector.detect([
        const StructurePageText(pageNumber: 1, text: text),
      ]);
      final qa = blocks
          .where((b) => b.kind == SourceBlockKind.questionAnswer)
          .toList();
      expect(qa, hasLength(2));
      expect(qa[0].hasChoices, isTrue);
      expect(qa[0].hasInlineAnswer, isTrue);
      expect(qa[0].text, contains('Giải thích'));
      expect(qa[0].text, isNot(contains('Câu 2')));
      expect(qa[0].questionNumber, 1);
      expect(qa[1].questionNumber, 2);
    });

    test('separates theory preamble from questions', () {
      const text = '''
Lý thuyết
Đạo hàm của \$x^n\$ là \$nx^{n-1}\$.

Câu 1. Đạo hàm của \$x^3\$?
A. \$3x^2\$
B. \$x^2\$
Đáp án: A
''';
      final blocks = detector.detect([
        const StructurePageText(pageNumber: 1, text: text),
      ]);
      expect(
        blocks.any((b) => b.kind == SourceBlockKind.knowledge),
        isTrue,
      );
      expect(
        blocks.where((b) => b.kind == SourceBlockKind.questionAnswer),
        hasLength(1),
      );
      final knowledge = blocks.firstWhere(
        (b) => b.kind == SourceBlockKind.knowledge,
      );
      expect(knowledge.text, contains('Đạo hàm'));
      expect(knowledge.text, isNot(contains('Câu 1')));
    });

    test('detects trailing answer key section', () {
      const text = '''
Câu 1. Hỏi gì đó?
A. Một
B. Hai

Câu 2. Hỏi tiếp?
A. Ba
B. Bốn

Đáp án
1. A
2. B
''';
      final blocks = detector.detect([
        const StructurePageText(pageNumber: 1, text: text),
      ]);
      expect(
        blocks.any((b) => b.kind == SourceBlockKind.answerKey),
        isTrue,
      );
      expect(
        blocks.where((b) => b.kind == SourceBlockKind.questionAnswer).length,
        greaterThanOrEqualTo(2),
      );
    });
  });

  group('SourceTextChunker', () {
    const chunker = SourceTextChunker(
      maxCharsPerChunk: 200,
      minCharsPreferSplit: 120,
    );

    test('keeps small source as one chunk', () {
      final chunks = chunker.chunkPages([
        const StructurePageText(
          pageNumber: 1,
          text: 'Câu 1. Nội dung ngắn?\nA. 1\nB. 2\nĐáp án: A',
        ),
      ]);
      expect(chunks, hasLength(1));
      expect(chunks.first.pageTexts, hasLength(1));
      expect(chunks.first.questionCount, 1);
    });

    test('splits on question blocks for large exams without cutting mid-QA', () {
      final buffer = StringBuffer();
      for (var i = 1; i <= 20; i++) {
        buffer.writeln(
          'Câu $i. Đây là câu hỏi số $i với nội dung đủ dài để vượt ngân sách.',
        );
        buffer.writeln('A. Lựa chọn A cho câu $i');
        buffer.writeln('B. Lựa chọn B cho câu $i');
        buffer.writeln('Đáp án: A');
        buffer.writeln('Giải thích: vì chọn A là đúng cho câu $i.');
        buffer.writeln();
      }
      final chunks = chunker.chunkPages([
        StructurePageText(pageNumber: 1, text: buffer.toString()),
      ]);
      expect(chunks.length, greaterThan(1));
      for (final c in chunks) {
        for (final b in c.blocks) {
          if (b.kind != SourceBlockKind.questionAnswer) continue;
          // Each QA block still has its answer when present.
          expect(b.text, contains('Đáp án'));
          expect(b.hasChoices, isTrue);
        }
      }
    });

    test('keeps theory with following questions in same pack when possible', () {
      final theory = 'Lý thuyết\n${'Công thức quan trọng. ' * 5}';
      final qs = List.generate(
        6,
        (i) =>
            'Câu ${i + 1}. Câu hỏi padding ${'x' * 30}?\n'
            'A. a\nB. b\nĐáp án: A\n',
      ).join('\n');
      final chunks = const SourceTextChunker(
        maxCharsPerChunk: 400,
        minCharsPreferSplit: 250,
      ).chunkPages([
        StructurePageText(pageNumber: 1, text: '$theory\n\n$qs'),
      ]);
      expect(chunks, isNotEmpty);
      // First chunk should include knowledge when packing starts with theory.
      final firstKinds = chunks.first.blocks.map((b) => b.kind).toSet();
      expect(firstKinds.contains(SourceBlockKind.knowledge), isTrue);
    });

    test('preserves page numbers across chunks', () {
      final longQ = List.generate(
        8,
        (i) =>
            'Câu ${i + 1}. Câu hỏi trang với nội dung padding ${'x' * 40}\n'
            'A. a\nB. b\nĐáp án: A\n',
      ).join('\n');
      final chunks = const SourceTextChunker(
        maxCharsPerChunk: 250,
        minCharsPreferSplit: 150,
      ).chunkPages([
        StructurePageText(pageNumber: 2, text: longQ),
        StructurePageText(pageNumber: 3, text: longQ),
      ]);
      expect(chunks, isNotEmpty);
      final pages = chunks.expand((c) => c.pageTexts.map((p) => p.pageNumber));
      expect(pages, everyElement(anyOf(2, 3)));
    });
  });

  group('StructureBatchMerger', () {
    test('remaps related_knowledge_indices and relation indices', () {
      final a = StructureSourceResponse(
        knowledgeUnits: [
          {'type': 'theory', 'content': 'T1'},
          {'type': 'formula', 'content': 'F1'},
        ],
        questions: [
          {
            'content': 'Q1',
            'related_knowledge_indices': [0, 1],
          },
        ],
        relations: [
          {'from_index': 0, 'to_index': 1, 'relation_type': 'supports'},
        ],
      );
      final b = StructureSourceResponse(
        knowledgeUnits: [
          {'type': 'definition', 'content': 'D2'},
        ],
        questions: [
          {
            'content': 'Q2',
            'related_knowledge_indices': [0],
          },
        ],
        relations: const [],
      );

      final merged = StructureBatchMerger.merge([a, b]);
      expect(merged.knowledgeUnits, hasLength(3));
      expect(merged.questions, hasLength(2));
      expect(merged.questions[0]['related_knowledge_indices'], [0, 1]);
      expect(merged.questions[1]['related_knowledge_indices'], [2]);
      expect(merged.relations.single['from_index'], 0);
      expect(merged.relations.single['to_index'], 1);
    });
  });
}

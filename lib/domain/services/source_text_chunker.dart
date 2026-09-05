import 'package:equatable/equatable.dart';
import 'package:studee_pc/domain/repositories/deepseek_client.dart';

/// Kind of a locally detected source block (pre-LLM).
enum SourceBlockKind {
  /// Pure theory / definition / formula / note region.
  knowledge,

  /// One question with its choices, answer, and explanation when present.
  questionAnswer,

  /// Answer-key table / list that maps numbers → labels.
  answerKey,

  /// Unclassified text; keep contiguous.
  other,
}

/// Atomic text region that must not be split across LLM batches.
class SourceBlock extends Equatable {
  const SourceBlock({
    required this.kind,
    required this.pageNumber,
    required this.text,
    this.questionNumber,
    this.hasChoices = false,
    this.hasInlineAnswer = false,
  });

  final SourceBlockKind kind;
  final int pageNumber;
  final String text;
  final int? questionNumber;
  final bool hasChoices;
  final bool hasInlineAnswer;

  int get charCount => text.length;

  @override
  List<Object?> get props =>
      [kind, pageNumber, text, questionNumber, hasChoices, hasInlineAnswer];
}

/// Heuristic detector for exam-style Vietnamese/English study text.
///
/// Goals before DeepSeek:
/// - Keep each **question + choices + answer/explanation** as one block
/// - Separate **pure knowledge** from Q&A
/// - Detect trailing **answer keys** so they can ride along with Q batches
class SourceBlockDetector {
  const SourceBlockDetector();

  static final RegExp _questionHeader = RegExp(
    r'^(?:'
    r'(?:Câu|Câu hỏi|Question|Bài|Bài tập)\s*(?:hỏi\s*)?(\d{1,3})\s*[\.\:\-\–\)]?\s*'
    r'|(\d{1,3})\s*[\.\)\-–]\s+'
    r'|\[\s*(\d{1,3})\s*\]\s*'
    r'|\(\s*(\d{1,3})\s*\)\s*'
    r')',
    caseSensitive: false,
  );

  /// Bare answer-key section title (not "Đáp án: A" on the same question).
  static final RegExp _answerKeySectionHeader = RegExp(
    r'^(?:'
    r'Đáp án(?:\s*đúng)?(?:\s*các\s*câu)?'
    r'|Answer\s*key'
    r'|Bảng\s*đáp\s*án'
    r'|Đáp án\s*trắc\s*nghiệm'
    r'|Hướng dẫn\s*chấm'
    r')\s*[:：]?\s*$',
    caseSensitive: false,
  );

  static final RegExp _choiceLine = RegExp(
    r'^(?:[A-Da-d]|[A-Da-d]\s*[\)\.]|[A-Da-d]\s*[-–])\s+\S',
  );

  /// Per-question answer line, e.g. "Đáp án: A" / "Đáp án A".
  static final RegExp _inlineAnswer = RegExp(
    r'^(?:'
    r'Đáp án(?:\s*đúng)?|Answer|Đáp số|Chọn|Kết quả'
    r')\s*[:：\-]?\s*\S',
    caseSensitive: false,
  );

  /// Compact key rows like "1. A" / "2) C" — not full questions.
  static final RegExp _answerKeyEntry = RegExp(
    r'^\d{1,3}\s*[\.\)\-–]\s*[A-Da-d]\b',
    caseSensitive: false,
  );

  static final RegExp _knowledgeHeader = RegExp(
    r'^(?:'
    r'Lý thuyết|Định nghĩa|Công thức|Định lý|Ghi chú|Chú ý|Ví dụ'
    r'|Theory|Definition|Formula|Theorem|Note|Example'
    r'|Phần\s+[IVXLC\d]+|Chương\s+\d+|Mục\s+\d+'
    r')(?:\s*[:：].*)?$',
    caseSensitive: false,
  );

  static final RegExp _explanationHeader = RegExp(
    r'^(?:'
    r'Giải thích|Lời giải|Hướng dẫn giải|Giải|Explanation|Solution'
    r')\s*[:：]?',
    caseSensitive: false,
  );

  /// Detect atomic blocks across reviewed pages (in order).
  List<SourceBlock> detect(List<StructurePageText> pages) {
    final blocks = <SourceBlock>[];
    for (final page in pages) {
      final text = page.text.replaceAll('\r\n', '\n').trim();
      if (text.isEmpty) continue;
      blocks.addAll(_detectPage(page.pageNumber, text));
    }
    return _attachLooseAnswerKeys(blocks);
  }

  List<SourceBlock> _detectPage(int pageNumber, String text) {
    final lines = text.split('\n');
    final blocks = <SourceBlock>[];

    var i = 0;
    while (i < lines.length) {
      final line = lines[i].trimRight();
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        i++;
        continue;
      }

      if (_answerKeySectionHeader.hasMatch(trimmed)) {
        final end = _consumeUntilNextMajor(lines, i + 1);
        blocks.add(
          SourceBlock(
            kind: SourceBlockKind.answerKey,
            pageNumber: pageNumber,
            text: _joinLines(lines, i, end),
          ),
        );
        i = end;
        continue;
      }

      if (_knowledgeHeader.hasMatch(trimmed) &&
          !_looksLikeQuestionStem(trimmed)) {
        final end = _consumeUntilNextMajor(lines, i + 1);
        blocks.add(
          SourceBlock(
            kind: SourceBlockKind.knowledge,
            pageNumber: pageNumber,
            text: _joinLines(lines, i, end),
          ),
        );
        i = end;
        continue;
      }

      final qMatch = _questionHeader.firstMatch(trimmed);
      if ((qMatch != null && _isRealQuestionHeader(trimmed, qMatch)) ||
          _looksLikeQuestionStem(trimmed)) {
        final qNum = _parseQuestionNumber(qMatch);
        final end = _consumeQuestionBlock(lines, i);
        final body = _joinLines(lines, i, end);
        blocks.add(
          SourceBlock(
            kind: SourceBlockKind.questionAnswer,
            pageNumber: pageNumber,
            text: body,
            questionNumber: qNum,
            hasChoices: _hasChoiceLines(body),
            hasInlineAnswer: body
                .split('\n')
                .any((l) => _inlineAnswer.hasMatch(l.trim())),
          ),
        );
        i = end;
        continue;
      }

      // Continuation / other — absorb into a run until a major boundary.
      final end = _consumeUntilNextMajor(lines, i + 1);
      final body = _joinLines(lines, i, end);
      final asQa = _hasChoiceLines(body) ||
          body.split('\n').any((l) => _inlineAnswer.hasMatch(l.trim()));
      blocks.add(
        SourceBlock(
          kind: asQa ? SourceBlockKind.questionAnswer : SourceBlockKind.other,
          pageNumber: pageNumber,
          text: body,
          hasChoices: _hasChoiceLines(body),
          hasInlineAnswer:
              body.split('\n').any((l) => _inlineAnswer.hasMatch(l.trim())),
        ),
      );
      i = end;
    }

    return blocks;
  }

  /// Merge tiny single-question answer snippets into the previous Q&A block.
  /// Multi-item answer tables stay as [SourceBlockKind.answerKey].
  List<SourceBlock> _attachLooseAnswerKeys(List<SourceBlock> input) {
    if (input.length < 2) return input;
    final out = <SourceBlock>[];
    for (var i = 0; i < input.length; i++) {
      final b = input[i];
      if (b.kind != SourceBlockKind.answerKey) {
        out.add(b);
        continue;
      }
      final numbered = RegExp(r'^\s*\d{1,3}\s*[\.\)\-–]', multiLine: true)
          .allMatches(b.text)
          .length;
      final looksLikeTable = numbered >= 2 || b.charCount >= 800;
      if (!looksLikeTable &&
          out.isNotEmpty &&
          out.last.kind == SourceBlockKind.questionAnswer &&
          b.charCount < 800) {
        final prev = out.removeLast();
        out.add(
          SourceBlock(
            kind: SourceBlockKind.questionAnswer,
            pageNumber: prev.pageNumber,
            text: '${prev.text.trim()}\n\n${b.text.trim()}',
            questionNumber: prev.questionNumber,
            hasChoices: prev.hasChoices,
            hasInlineAnswer: true,
          ),
        );
      } else {
        out.add(b);
      }
    }
    return out;
  }

  int _consumeQuestionBlock(List<String> lines, int start) {
    var i = start + 1;
    var sawChoice = false;
    var sawAnswer = false;
    var sawExplanation = false;

    while (i < lines.length) {
      final trimmed = lines[i].trim();
      if (trimmed.isEmpty) {
        final next = _nextNonEmpty(lines, i + 1);
        if (next == null) {
          i++;
          break;
        }
        final n = lines[next].trim();
        if (_isMajorBoundary(n) && (sawChoice || sawAnswer || i > start + 2)) {
          break;
        }
        i++;
        continue;
      }

      if (_isMajorBoundary(trimmed) && i > start) {
        break;
      }

      if (_choiceLine.hasMatch(trimmed)) sawChoice = true;
      if (_inlineAnswer.hasMatch(trimmed)) sawAnswer = true;
      if (_explanationHeader.hasMatch(trimmed)) sawExplanation = true;

      if (sawAnswer || sawExplanation) {
        final next = _nextNonEmpty(lines, i + 1);
        if (next != null) {
          final n = lines[next].trim();
          if (_explanationHeader.hasMatch(n)) {
            // Keep going to absorb explanation under this question.
          } else if (_isMajorBoundary(n)) {
            i++;
            break;
          }
        }
      }

      i++;
    }
    return i;
  }

  int _consumeUntilNextMajor(List<String> lines, int start) {
    var i = start;
    while (i < lines.length) {
      final trimmed = lines[i].trim();
      if (trimmed.isNotEmpty && _isMajorBoundary(trimmed)) {
        break;
      }
      // Keep compact answer-key rows inside an answer-key section.
      i++;
    }
    return i;
  }

  bool _isMajorBoundary(String trimmed) {
    if (_answerKeySectionHeader.hasMatch(trimmed)) return true;
    if (_knowledgeHeader.hasMatch(trimmed) &&
        !_looksLikeQuestionStem(trimmed)) {
      return true;
    }
    final q = _questionHeader.firstMatch(trimmed);
    return q != null && _isRealQuestionHeader(trimmed, q);
  }

  /// Reject compact key rows ("1. A") and tiny numbered stubs.
  bool _isRealQuestionHeader(String trimmed, RegExpMatch match) {
    if (_answerKeyEntry.hasMatch(trimmed)) return false;
    final after = trimmed.substring(match.end).trim();
    // Numbered "1. …" needs a real stem, not only a letter label.
    final usedNumberOnly = match.group(1) == null &&
        (match.group(2) != null ||
            match.group(3) != null ||
            match.group(4) != null);
    if (usedNumberOnly) {
      if (after.length < 8 && RegExp(r'^[A-Da-d]\s*$').hasMatch(after)) {
        return false;
      }
      if (after.length < 3) return false;
    }
    return true;
  }

  bool _looksLikeQuestionStem(String line) {
    final t = line.trim();
    if (_answerKeyEntry.hasMatch(t)) return false;
    if (t.endsWith('?') || t.endsWith('？')) return true;
    if (RegExp(
      r'(?:chọn|tính|tìm|xác định|khẳng định|phủ định)',
      caseSensitive: false,
    ).hasMatch(t)) {
      return t.length > 20;
    }
    return false;
  }

  bool _hasChoiceLines(String body) {
    var count = 0;
    for (final line in body.split('\n')) {
      if (_choiceLine.hasMatch(line.trim())) count++;
    }
    return count >= 2;
  }

  int? _parseQuestionNumber(RegExpMatch? match) {
    if (match == null) return null;
    for (var g = 1; g <= match.groupCount; g++) {
      final v = match.group(g);
      if (v == null || v.isEmpty) continue;
      return int.tryParse(v);
    }
    return null;
  }

  int? _nextNonEmpty(List<String> lines, int from) {
    for (var i = from; i < lines.length; i++) {
      if (lines[i].trim().isNotEmpty) return i;
    }
    return null;
  }

  String _joinLines(List<String> lines, int start, int end) {
    return lines.sublist(start, end.clamp(start, lines.length)).join('\n').trim();
  }
}

/// Splits reviewed source text into LLM-sized batches using [SourceBlockDetector].
class SourceTextChunker {
  const SourceTextChunker({
    this.maxCharsPerChunk = 5500,
    this.minCharsPreferSplit = 4000,
    this.detector = const SourceBlockDetector(),
  });

  final int maxCharsPerChunk;
  final int minCharsPreferSplit;
  final SourceBlockDetector detector;

  /// Back-compat for tests / callers that matched the old API.
  static final RegExp questionStart = SourceBlockDetector._questionHeader;

  List<SourceTextChunk> chunkPages(List<StructurePageText> pages) {
    final normalized = pages
        .map(
          (p) => StructurePageText(
            pageNumber: p.pageNumber,
            text: p.text.trim(),
          ),
        )
        .where((p) => p.text.isNotEmpty)
        .toList();
    if (normalized.isEmpty) return const [];

    final totalChars =
        normalized.fold<int>(0, (sum, p) => sum + p.text.length);
    if (totalChars <= maxCharsPerChunk) {
      return [
        SourceTextChunk(
          index: 0,
          pageTexts: normalized,
          blocks: detector.detect(normalized),
        ),
      ];
    }

    final blocks = detector.detect(normalized);
    if (blocks.isEmpty) {
      return [
        SourceTextChunk(index: 0, pageTexts: normalized, blocks: const []),
      ];
    }

    // Global answer keys (large tables) are appended to every Q chunk.
    final globalKeys = blocks
        .where(
          (b) => b.kind == SourceBlockKind.answerKey && b.charCount >= 800,
        )
        .toList();
    final packable = blocks
        .where(
          (b) => !(b.kind == SourceBlockKind.answerKey && b.charCount >= 800),
        )
        .toList();

    final groups = <List<SourceBlock>>[];
    var bucket = <SourceBlock>[];
    var bucketChars = 0;

    void flush() {
      if (bucket.isEmpty) return;
      groups.add(List<SourceBlock>.from(bucket));
      bucket = [];
      bucketChars = 0;
    }

    for (final block in packable) {
      final len = block.charCount;
      final isAtomicQa = block.kind == SourceBlockKind.questionAnswer;

      if (bucket.isNotEmpty &&
          bucketChars + len > maxCharsPerChunk &&
          bucketChars >= minCharsPreferSplit) {
        // Prefer not to split after a knowledge preamble alone — keep it with
        // the next Q if the bucket is only knowledge/other.
        final onlyContext = bucket.every(
          (b) =>
              b.kind == SourceBlockKind.knowledge ||
              b.kind == SourceBlockKind.other,
        );
        if (!(onlyContext && isAtomicQa && bucketChars < maxCharsPerChunk)) {
          flush();
        }
      }

      if (len > maxCharsPerChunk && !isAtomicQa) {
        flush();
        for (final piece in _hardSplit(block.text, maxCharsPerChunk)) {
          groups.add([
            SourceBlock(
              kind: block.kind,
              pageNumber: block.pageNumber,
              text: piece,
              questionNumber: block.questionNumber,
              hasChoices: block.hasChoices,
              hasInlineAnswer: block.hasInlineAnswer,
            ),
          ]);
        }
        continue;
      }

      if (len > maxCharsPerChunk && isAtomicQa) {
        // Never hard-split a Q+A block mid-structure — send alone even if large.
        flush();
        groups.add([block]);
        continue;
      }

      bucket.add(block);
      bucketChars += len;
    }
    flush();

    final chunks = <SourceTextChunk>[];
    for (var i = 0; i < groups.length; i++) {
      final group = [...groups[i], ...globalKeys];
      chunks.add(
        SourceTextChunk(
          index: i,
          pageTexts: _blocksToPages(group),
          blocks: group,
        ),
      );
    }
    return chunks;
  }

  List<StructurePageText> _blocksToPages(List<SourceBlock> blocks) {
    final byPage = <int, StringBuffer>{};
    for (final b in blocks) {
      final buf = byPage.putIfAbsent(b.pageNumber, StringBuffer.new);
      if (buf.isNotEmpty) buf.writeln('\n');
      buf.write(b.text.trim());
    }
    final pages = byPage.entries
        .map(
          (e) => StructurePageText(
            pageNumber: e.key,
            text: e.value.toString().trim(),
          ),
        )
        .toList()
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
    return pages;
  }

  static List<String> _hardSplit(String text, int maxChars) {
    if (text.length <= maxChars) return [text];
    final out = <String>[];
    var start = 0;
    while (start < text.length) {
      var end = (start + maxChars).clamp(0, text.length);
      if (end < text.length) {
        final window = text.substring(start, end);
        final breakAt = window.lastIndexOf(RegExp(r'[\n.?!;]'));
        if (breakAt >= maxChars ~/ 3) {
          end = start + breakAt + 1;
        }
      }
      final piece = text.substring(start, end).trim();
      if (piece.isNotEmpty) out.add(piece);
      start = end;
    }
    return out;
  }
}

class SourceTextChunk extends Equatable {
  const SourceTextChunk({
    required this.index,
    required this.pageTexts,
    this.blocks = const [],
  });

  final int index;
  final List<StructurePageText> pageTexts;
  final List<SourceBlock> blocks;

  int get charCount =>
      pageTexts.fold<int>(0, (sum, p) => sum + p.text.length);

  int get questionCount =>
      blocks.where((b) => b.kind == SourceBlockKind.questionAnswer).length;

  @override
  List<Object?> get props => [index, pageTexts, blocks];
}

/// Merges batched [StructureSourceResponse]s and remaps unit indices.
abstract final class StructureBatchMerger {
  static StructureSourceResponse merge(
    List<StructureSourceResponse> parts,
  ) {
    if (parts.isEmpty) {
      return const StructureSourceResponse(
        knowledgeUnits: [],
        questions: [],
        relations: [],
      );
    }
    if (parts.length == 1) return parts.single;

    final units = <Map<String, dynamic>>[];
    final questions = <Map<String, dynamic>>[];
    final relations = <Map<String, dynamic>>[];
    var unitOffset = 0;
    String? promptVersion;
    final rawParts = <String>[];

    for (final part in parts) {
      promptVersion ??= part.promptVersion;
      if (part.rawJson != null) rawParts.add(part.rawJson!);

      units.addAll(part.knowledgeUnits);

      for (final q in part.questions) {
        final copy = Map<String, dynamic>.from(q);
        final related = copy['related_knowledge_indices'];
        if (related is List) {
          copy['related_knowledge_indices'] = related
              .map((raw) {
                final idx = (raw as num?)?.toInt();
                if (idx == null) return null;
                return idx + unitOffset;
              })
              .whereType<int>()
              .toList();
        }
        questions.add(copy);
      }

      for (final r in part.relations) {
        final copy = Map<String, dynamic>.from(r);
        final from = (copy['from_index'] as num?)?.toInt();
        final to = (copy['to_index'] as num?)?.toInt();
        if (from != null) copy['from_index'] = from + unitOffset;
        if (to != null) copy['to_index'] = to + unitOffset;
        relations.add(copy);
      }

      unitOffset += part.knowledgeUnits.length;
    }

    return StructureSourceResponse(
      knowledgeUnits: units,
      questions: questions,
      relations: relations,
      promptVersion: promptVersion,
      rawJson: rawParts.isEmpty ? null : '[${rawParts.join(',')}]',
    );
  }
}

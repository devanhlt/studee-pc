import 'package:studee_pc/domain/entities/subject.dart';

/// How question/answer text should be prepared for display and storage.
enum SubjectFormatKind {
  /// Math / physics / chemistry — LaTeX enrichers and math polish.
  math,

  /// Programming — code fences / monospace; never math cases/LaTeX.
  code,

  /// Languages, history, civics, etc. — no enrichers / prettify.
  plain,
}

extension SubjectFormatKindWire on SubjectFormatKind {
  String get wire => switch (this) {
        SubjectFormatKind.math => 'math',
        SubjectFormatKind.code => 'code',
        SubjectFormatKind.plain => 'plain',
      };

  /// Short Vietnamese label for LLM subject-context prompts.
  String get promptLabelVi => switch (this) {
        SubjectFormatKind.math => 'Toán / Lý / Hóa (công thức LaTeX)',
        SubjectFormatKind.code => 'Lập trình (mã nguồn)',
        SubjectFormatKind.plain => 'Văn bản / ngoại ngữ (không ép định dạng)',
      };
}

/// Subject name + inferred display format for LLM / client pipelines.
class SubjectFormatContext {
  const SubjectFormatContext({
    required this.name,
    required this.kind,
  });

  final String name;
  final SubjectFormatKind kind;

  static const empty = SubjectFormatContext(
    name: '',
    kind: SubjectFormatKind.plain,
  );
}

/// Infer [SubjectFormatKind] from subject name and optional icon key.
SubjectFormatKind inferSubjectFormatKind({
  String? name,
  String? icon,
}) {
  final n = _fold(name);
  final i = (icon ?? '').trim().toLowerCase();

  if (i == 'calculate' || i == 'science') {
    // Science icon usually means physics/chemistry → formulas.
    if (_looksPlainLanguage(n)) return SubjectFormatKind.plain;
    if (_looksCode(n)) return SubjectFormatKind.code;
    return SubjectFormatKind.math;
  }
  if (i == 'language' || i == 'history_edu') {
    if (_looksCode(n)) return SubjectFormatKind.code;
    if (_looksMath(n)) return SubjectFormatKind.math;
    return SubjectFormatKind.plain;
  }

  if (_looksCode(n)) return SubjectFormatKind.code;
  if (_looksMath(n)) return SubjectFormatKind.math;
  if (_looksPlainLanguage(n) || _looksHumanities(n)) {
    return SubjectFormatKind.plain;
  }

  // Unknown subject → do not force math/code formatters.
  return SubjectFormatKind.plain;
}

SubjectFormatKind formatKindForSubject(Subject? subject) {
  if (subject == null) return SubjectFormatKind.plain;
  return inferSubjectFormatKind(name: subject.name, icon: subject.icon);
}

SubjectFormatContext formatContextForSubject(Subject? subject) {
  if (subject == null) return SubjectFormatContext.empty;
  return SubjectFormatContext(
    name: subject.name.trim(),
    kind: inferSubjectFormatKind(name: subject.name, icon: subject.icon),
  );
}

bool _looksMath(String n) {
  const keys = <String>[
    'toán',
    'toan',
    'math',
    'đại số',
    'dai so',
    'giải tích',
    'giai tich',
    'hình học',
    'hinh hoc',
    'algebra',
    'calculus',
    'geometry',
    'lý',
    'ly ',
    'vật lý',
    'vat ly',
    'physics',
    'hóa',
    'hoa ',
    'hóa học',
    'hoa hoc',
    'chemistry',
    'xác suất',
    'xac suat',
    'thống kê',
    'thong ke',
  ];
  return keys.any(n.contains);
}

bool _looksCode(String n) {
  const keys = <String>[
    'lập trình',
    'lap trinh',
    'programming',
    'coding',
    'programmer',
    'ktlt',
    'ktlt',
    'cấu trúc dữ liệu',
    'cau truc du lieu',
    'thuật toán',
    'thuat toan',
    'algorithm',
    'tin học',
    'tin hoc',
    'c++',
    'java',
    'python',
    'javascript',
    'golang',
    'rust',
    'cnpm',
    'công nghệ phần mềm',
    'cong nghe phan mem',
    'database',
    'sql',
    'oop',
    'nhập môn lập trình',
    'nhap mon lap trinh',
  ];
  return keys.any(n.contains);
}

bool _looksPlainLanguage(String n) {
  const keys = <String>[
    'anh',
    'english',
    'tiếng anh',
    'tieng anh',
    'ngữ văn',
    'ngu van',
    'văn',
    'literature',
    'pháp',
    'phap',
    'trung',
    'nhật',
    'nhat',
    'hàn',
    'han ',
  ];
  return keys.any(n.contains);
}

bool _looksHumanities(String n) {
  const keys = <String>[
    'sử',
    'su ',
    'lịch sử',
    'lich su',
    'history',
    'địa',
    'dia ',
    'địa lý',
    'dia ly',
    'geography',
    'gdcd',
    'công dân',
    'cong dan',
    'triết',
    'triet',
    'kinh tế',
    'kinh te',
    'luật',
    'luat',
  ];
  return keys.any(n.contains);
}

String _fold(String? raw) {
  var s = (raw ?? '').trim().toLowerCase();
  const pairs = <List<String>>[
    ['àáạảãâầấậẩẫăằắặẳẵ', 'a'],
    ['èéẹẻẽêềếệểễ', 'e'],
    ['ìíịỉĩ', 'i'],
    ['òóọỏõôồốộổỗơờớợởỡ', 'o'],
    ['ùúụủũưừứựửữ', 'u'],
    ['ỳýỵỷỹ', 'y'],
    ['đ', 'd'],
  ];
  for (final p in pairs) {
    for (final ch in p[0].split('')) {
      s = s.replaceAll(ch, p[1]);
    }
  }
  return s;
}

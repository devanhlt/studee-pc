/// Token costs charged against an activation code.
///
/// Legacy "lượt giải" counts map to tokens at [perLegacySolve].
abstract final class QuotaTokens {
  static const int perLegacySolve = 100;
  static const int text = 100;
  static const int picture = 200;
}

enum QuotaSolveKind { text, picture }

extension QuotaSolveKindX on QuotaSolveKind {
  String get apiValue => switch (this) {
        QuotaSolveKind.text => 'text',
        QuotaSolveKind.picture => 'picture',
      };

  int get tokens => switch (this) {
        QuotaSolveKind.text => QuotaTokens.text,
        QuotaSolveKind.picture => QuotaTokens.picture,
      };
}

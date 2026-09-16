/// Token amounts charged against an activation code per billable action.
///
/// Legacy "lượt giải" counts map to tokens at [perLegacySolve].
abstract final class QuotaTokens {
  static const int perLegacySolve = 100;
  static const int text = 100;
  static const int picture = 200;

  /// One full "Nhập kiến thức" structuring run (any source size).
  static const int ingest = 1000;
}

/// Billable action kinds sent to `/v1/solves/consume`.
enum QuotaSolveKind { text, picture, ingest }

extension QuotaSolveKindX on QuotaSolveKind {
  String get apiValue => switch (this) {
        QuotaSolveKind.text => 'text',
        QuotaSolveKind.picture => 'picture',
        QuotaSolveKind.ingest => 'ingest',
      };

  int get tokens => switch (this) {
        QuotaSolveKind.text => QuotaTokens.text,
        QuotaSolveKind.picture => QuotaTokens.picture,
        QuotaSolveKind.ingest => QuotaTokens.ingest,
      };
}

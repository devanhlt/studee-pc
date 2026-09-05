/// Cancellation token for in-flight DeepSeek HTTP requests.
///
/// Similar in spirit to Dio's CancelToken: create one, pass/bind it to the
/// client, and call [cancel] to abort waiting work.
class CancelToken {
  bool _isCancelled = false;
  String? _reason;
  final List<void Function()> _listeners = [];

  bool get isCancelled => _isCancelled;

  String? get reason => _reason;

  /// Cancels all operations linked to this token.
  void cancel([String? reason]) {
    if (_isCancelled) return;
    _isCancelled = true;
    _reason = reason;
    for (final listener in List.of(_listeners)) {
      listener();
    }
    _listeners.clear();
  }

  void addListener(void Function() listener) {
    if (_isCancelled) {
      listener();
      return;
    }
    _listeners.add(listener);
  }

  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  /// Throws [CancelledException] if already cancelled.
  void throwIfCancelled() {
    if (_isCancelled) {
      throw CancelledException(reason);
    }
  }
}

/// Thrown when a [CancelToken] aborts an operation.
class CancelledException implements Exception {
  CancelledException([this.reason]);

  final String? reason;

  @override
  String toString() =>
      reason == null ? 'CancelledException' : 'CancelledException($reason)';
}

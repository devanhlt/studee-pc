import 'package:studee_pc/core/errors/app_failure.dart';

/// Discriminated success/failure result without throwing.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        Failure() => null,
      };

  AppFailure? get failureOrNull => switch (this) {
        Success() => null,
        Failure(:final failure) => failure,
      };

  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) {
    return switch (this) {
      Success(:final value) => success(value),
      Failure(failure: final appFailure) => failure(appFailure),
    };
  }

  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success(:final value) => Success(transform(value)),
      Failure(:final failure) => Failure(failure),
    };
  }

  Result<R> flatMap<R>(Result<R> Function(T value) transform) {
    return switch (this) {
      Success(:final value) => transform(value),
      Failure(:final failure) => Failure(failure),
    };
  }

  T getOrThrow() {
    return switch (this) {
      Success(:final value) => value,
      Failure(:final failure) => throw failure,
    };
  }

  T getOrElse(T Function(AppFailure failure) fallback) {
    return switch (this) {
      Success(:final value) => value,
      Failure(:final failure) => fallback(failure),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Success<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

final class Failure<T> extends Result<T> {
  const Failure(this.failure);

  final AppFailure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Failure($failure)';
}

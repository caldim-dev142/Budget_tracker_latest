/// Result / Either type for use-case return values.
/// Keeps the domain layer free from exceptions in the happy path.
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

final class Failure<T> extends Result<T> {
  final AppFailure failure;
  const Failure(this.failure);
}

extension ResultX<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T get value => (this as Success<T>).value;
  AppFailure get failure => (this as Failure<T>).failure;

  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) {
    return switch (this) {
      Success<T>(:final value) => success(value),
      Failure<T>(failure: final fail) => failure(fail),
    };
  }
}

/// Typed failure hierarchy for the domain layer.
sealed class AppFailure {
  final String message;
  const AppFailure(this.message);
}

final class ValidationFailure extends AppFailure {
  final String field;
  const ValidationFailure(this.field, super.message);
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message);
}

final class ClosedMonthFailure extends AppFailure {
  const ClosedMonthFailure(super.message);
}

final class NetworkFailure extends AppFailure {
  final int? statusCode;
  const NetworkFailure(super.message, {this.statusCode});
}

final class AuthFailure extends AppFailure {
  const AuthFailure(super.message);
}

final class ConflictFailure extends AppFailure {
  const ConflictFailure(super.message);
}

final class UnexpectedFailure extends AppFailure {
  final Object? cause;
  const UnexpectedFailure(super.message, {this.cause});
}

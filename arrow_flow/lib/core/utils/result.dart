/// A simple Result type for operations that can succeed or fail.
/// Keeps error handling explicit without throwing exceptions across layers.
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final String message;
  final Object? error;
  const Failure(this.message, [this.error]);
}

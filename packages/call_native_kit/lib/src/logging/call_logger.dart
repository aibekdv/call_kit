import 'dart:developer' as dev;

/// Where the plugin reports what it did and what went wrong.
///
/// Implement it to route into your app's logger and crash reporter — several
/// failures here are silent by nature (an audio session that never activates,
/// a picture-in-picture track that never attaches) and are only visible if
/// they are reported.
abstract interface class CallLogger {
  void log(String message);

  void recordError(Object error, StackTrace stackTrace, {String? reason});
}

/// Drops everything. The default, so a package never spams a host's logs.
class SilentCallLogger implements CallLogger {
  const SilentCallLogger();

  @override
  void log(String message) {}

  @override
  void recordError(Object error, StackTrace stackTrace, {String? reason}) {}
}

/// Writes to `dart:developer`. Useful in development and in the example app.
class ConsoleCallLogger implements CallLogger {
  const ConsoleCallLogger({this.name = 'call_native_kit'});

  final String name;

  @override
  void log(String message) => dev.log(message, name: name);

  @override
  void recordError(Object error, StackTrace stackTrace, {String? reason}) =>
      dev.log(
        reason ?? 'error',
        name: name,
        error: error,
        stackTrace: stackTrace,
      );
}

import 'dart:developer' as developer;

/// Provides structured logging for the application.
///
/// Wraps dart:developer log with additional context and severity levels.
class LoggingService {
  LoggingService._();

  /// The singleton instance.
  static final LoggingService instance = LoggingService._();

  bool _enabled = true;
  LogLevel _minLevel = LogLevel.debug;

  /// Whether logging is enabled.
  bool get enabled => _enabled;
  set enabled(bool value) => _minLevel = value ? _minLevel : LogLevel.off;

  /// The minimum log level to record.
  LogLevel get minLevel => _minLevel;
  set minLevel(LogLevel value) => _minLevel = value;

  /// Logs a debug message.
  void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  /// Logs an info message.
  void info(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  /// Logs a warning message.
  void warning(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    Object? error,
  }) {
    _log(LogLevel.warning, message, tag: tag, data: data, error: error);
  }

  /// Logs an error message.
  void error(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Logs a critical error message.
  void critical(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.critical,
      message,
      tag: tag,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < _minLevel.index) return;

    final prefix = '[${_levelName(level)}]';
    final tagStr = tag != null ? '[$tag]' : '';
    final dataStr = data != null ? ' ${data.toString()}' : '';
    final errorStr = error != null ? ' | Error: $error' : '';

    final fullMessage = '$prefix$tagStr $message$dataStr$errorStr';

    developer.log(
      fullMessage,
      name: tag ?? '1000',
      error: error,
      stackTrace: stackTrace,
    );
  }

  String _levelName(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.critical:
        return 'CRITICAL';
      case LogLevel.off:
        return 'OFF';
    }
  }
}

/// Log severity levels.
enum LogLevel { debug, info, warning, error, critical, off }

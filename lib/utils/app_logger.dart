import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// App-wide logging facade.
///
/// Replaces raw `print()` calls (which stay in device logs in release
/// builds and can leak patient data / identifiers) with a single
/// controllable logger that is automatically silenced in release builds.
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      colors: false,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
    level: kReleaseMode ? Level.warning : Level.debug,
  );

  static void d(String message) => _logger.d(message);
  static void i(String message) => _logger.i(message);
  static void w(String message) => _logger.w(message);
  static void e(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}

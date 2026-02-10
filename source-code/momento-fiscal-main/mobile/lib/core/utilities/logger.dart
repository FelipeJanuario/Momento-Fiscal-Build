// Import logger with alias to avoid name conflicts
import 'package:logger/logger.dart' as logger_package;

enum LoggerLevel {
  all(0),
  trace(1000),
  debug(2000),
  info(3000),
  warning(4000),
  error(5000),
  fatal(6000),
  off(10000);

  final int value;
  const LoggerLevel(this.value);

  logger_package.Level get toLibLevel {
    switch (this) {
      case LoggerLevel.debug:
        return logger_package.Level.debug;
      case LoggerLevel.info:
        return logger_package.Level.info;
      case LoggerLevel.warning:
        return logger_package.Level.warning;
      case LoggerLevel.error:
        return logger_package.Level.error;
      case LoggerLevel.all:
        return logger_package.Level.all;
      case LoggerLevel.trace:
        return logger_package.Level.trace;
      case LoggerLevel.fatal:
        return logger_package.Level.fatal;
      case LoggerLevel.off:
        return logger_package.Level.off;
    }
  }
}

class Logger {
  static void log(String message, {LoggerLevel level = LoggerLevel.info, Object? error, StackTrace? stackTrace}) {
    var logger = logger_package.Logger();

    logger.log(level.toLibLevel, message, error: error, stackTrace: stackTrace);
    print('[MomentoFiscal][${level.name.toUpperCase()}] $message');
  }
}

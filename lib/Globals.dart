import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';

final int durationMilliSecondControl = 250;

pri(String str){
  debugPrint("DEBUGG: "+str);
}


class Log {
  static final Logger _logger = Logger(
    level: Level.debug,  // Set the desired logging level
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  static void debug(String message) {
    _logger.d(message);
  }

  static void info(String message) {
    _logger.i(message);
  }

  static void warning(String message) {
    _logger.w(message);
  }

  static void error(String message) {
    _logger.e(message);
  }
}

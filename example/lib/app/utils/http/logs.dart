part of 'http.dart';

@visibleForTesting
bool showHttpErrors = true;

void _printLogs(
  Map<String, dynamic> logs,
  StackTrace? stackTrace,
) {
  if (kDebugMode) {
    // coverage:ignore-end
    log(
      '''
🔥
--------------------------------
${const JsonEncoder.withIndent('  ').convert(logs)}
--------------------------------
🔥
''',
      stackTrace: stackTrace,
    );
  }
}

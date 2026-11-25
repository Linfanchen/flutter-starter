import 'dart:io';

/// Runs Flutter in a specified directory and returns the process exit code.
typedef FlutterRunner = Future<int> Function(
    Directory cwd, List<String> arguments);

/// Streams subprocess stdout and stderr to the caller's terminal.
Future<int> runFlutter(Directory cwd, List<String> arguments) async {
  stdout.writeln('> flutter ${arguments.join(' ')}');
  final process = await Process.start(
    'flutter',
    arguments,
    workingDirectory: cwd.path,
    // Windows resolves the SDK launcher through flutter.bat.
    runInShell: Platform.isWindows,
    mode: ProcessStartMode.inheritStdio,
  );
  return process.exitCode;
}

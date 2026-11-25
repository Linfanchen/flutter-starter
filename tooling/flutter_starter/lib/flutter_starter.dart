import 'dart:io';
import 'dart:isolate';

import 'src/create_options.dart';
import 'src/flutter_runner.dart';
import 'src/project_generator.dart';
import 'src/template_registry.dart';

const _usage = '''
flutter-starter list
flutter-starter create <project_name> [--template <name>]
    [--org com.example] [--platforms android,web] [--verify]

Creates an independent app in the current directory. Defaults: base, web.
--verify runs flutter analyze and flutter test before publishing the directory.
''';

/// Dispatches a CLI command and returns the corresponding process exit code.
Future<int> runStarter(List<String> arguments) async {
  try {
    if (arguments.isEmpty ||
        (arguments.length == 1 &&
            {'--help', '-h', 'help'}.contains(arguments.first))) {
      stdout.write(_usage);
      return 0;
    }
    if (arguments.length == 1 && arguments.first == 'list') {
      for (final template in templateRegistry.values) {
        stdout.writeln('${template.id}  ${template.description}');
      }
      return 0;
    }
    if (arguments.first == 'create') {
      if (arguments.length == 2 && {'--help', '-h'}.contains(arguments[1])) {
        stdout.write(_usage);
        return 0;
      }
      final options = CreateOptions.parse(arguments.sublist(1));
      final generator = ProjectGenerator(
        starterRoot: await _discoverStarterRoot(),
        runFlutter: runFlutter,
      );
      final project = await generator.create(options, Directory.current);
      stdout.writeln(
          'Created ${project.path}\n  cd ${options.name}\n  flutter run');
      return 0;
    }
    throw const FormatException('Unknown command. Run flutter-starter --help.');
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    return 64;
  } on ProcessException catch (error) {
    stderr.writeln(
        'Could not start ${error.executable}. Check your Flutter SDK and PATH.');
    return 1;
  } on Exception catch (error) {
    stderr.writeln(error);
    return 1;
  }
}

Future<Directory> _discoverStarterRoot() async {
  // Resolve assets from the installed CLI rather than the user's current directory.
  final source = await Isolate.resolvePackageUri(
    Uri.parse('package:flutter_starter/flutter_starter.dart'),
  );
  if (source == null || !source.isScheme('file')) {
    throw const GenerationException(
      'Cannot locate Starter assets. Activate this repository with --source path.',
    );
  }
  return Directory.fromUri(source.resolve('../../../'));
}

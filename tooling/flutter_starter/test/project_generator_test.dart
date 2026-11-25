import 'dart:io';

import 'package:flutter_starter/src/create_options.dart';
import 'package:flutter_starter/src/project_generator.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late Directory assets;
  late Directory output;
  late List<String> commands;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('starter-generator-test-');
    addTearDown(() => root.delete(recursive: true));
    assets = await Directory.fromUri(root.uri.resolve('source/')).create();
    output = await Directory.fromUri(root.uri.resolve('output/')).create();
    commands = [];
    await _write(assets, 'templates/base/lib/main.dart.tmpl',
        "import '{{material_import}}';\nconst appName = '{{project_name}}';");
    await _write(
        assets, 'templates/base/lib/app/template_home.dart.tmpl', '// base');
    await _write(assets, 'templates/content/lib/app/template_home.dart.tmpl',
        '// content');
    for (final package in ['starter_network', 'starter_config']) {
      await _write(
          assets, 'packages/$package/pubspec.yaml', 'name: $package\n');
      await _write(
          assets, 'packages/$package/lib/src/internal.dart', '// fixture');
    }
  });

  ProjectGenerator generator({
    String? failCommand,
    bool useMaterialPackage = true,
    Future<void> Function()? onVerify,
  }) =>
      ProjectGenerator(
        starterRoot: assets,
        runFlutter: (cwd, arguments) async {
          final command = arguments.join(' ');
          commands.add(command);
          if (arguments.first == 'create') {
            final name = arguments.last;
            await _write(cwd, '$name/lib/main.dart', '// scaffold');
            await _write(cwd, '$name/pubspec.yaml', '''
# Scaffold comment
name: $name
environment:
  sdk: ^3.14.0
dependencies:
  flutter:
    sdk: flutter
${useMaterialPackage ? '  material_ui: ^1.1.0\n' : ''}dev_dependencies:
  flutter_test:
    sdk: flutter
''');
          }
          if (command == 'test') await onVerify?.call();
          return command == failCommand ? 23 : 0;
        },
      );

  CreateOptions options({bool verify = false}) => CreateOptions.parse([
        'demo_app',
        '--template',
        'content',
        if (verify) '--verify',
      ]);

  test('merges YAML, renders overlays and validates before publishing',
      () async {
    final project = await generator(onVerify: () async {
      expect(Directory.fromUri(output.uri.resolve('demo_app/')).existsSync(),
          isFalse);
    }).create(options(verify: true), output);

    expect(commands, [
      'create --empty --no-pub --org com.example --platforms web demo_app',
      'pub get',
      'analyze',
      'test',
    ]);
    expect(await _read(project, 'lib/app/template_home.dart'), '// content');
    expect(await _read(project, 'lib/main.dart'),
        contains('package:material_ui/material_ui.dart'));
    expect(await _read(project, 'lib/main.dart'), contains('demo_app'));
    expect(
        await _read(project, 'packages/starter_config/lib/src/internal.dart'),
        '// fixture');
    final manifest = await _read(project, 'pubspec.yaml');
    expect(manifest, contains('# Scaffold comment'));
    expect(manifest, contains('sdk: ^3.14.0'));
    expect(manifest, contains('material_ui: ^1.1.0'));
    expect(manifest, contains('packages/starter_config'));
    expect(manifest, contains('packages/starter_network'));
    expect(manifest, isNot(contains('starter_auth')));
    expect(output.listSync(), hasLength(1));
  });

  test('preserves legacy Material support and skips optional checks', () async {
    final project =
        await generator(useMaterialPackage: false).create(options(), output);
    expect(await _read(project, 'lib/main.dart'),
        contains('package:flutter/material.dart'));
    expect(commands, hasLength(2));
    expect(commands.last, 'pub get');
  });

  test('preserves an existing destination without calling Flutter', () async {
    await _write(output, 'demo_app/keep.txt', 'keep');
    await expectLater(
        generator().create(options(), output), throwsFormatException);
    expect(commands, isEmpty);
    expect(await _read(output, 'demo_app/keep.txt'), 'keep');
  });

  test('preserves a destination created while verification is running',
      () async {
    final build = generator(onVerify: () async {
      await _write(output, 'demo_app/keep.txt', 'created during verification');
    });
    await expectLater(
      build.create(options(verify: true), output),
      throwsFormatException,
    );
    expect(commands.last, 'test');
    expect(await _read(output, 'demo_app/keep.txt'),
        'created during verification');
    expect(output.listSync(), hasLength(1));
  });

  test('reports failed dependency resolution and cleans staging', () async {
    await expectLater(
      generator(failCommand: 'pub get').create(options(verify: true), output),
      throwsA(isA<GenerationException>().having(
        (error) => error.message,
        'message',
        contains('flutter pub get exited with code 23'),
      )),
    );
    expect(commands, hasLength(2));
    expect(output.listSync(), isEmpty);
  });

  test('cleans staging after a verification failure', () async {
    await expectLater(
        generator(failCommand: 'test').create(options(verify: true), output),
        throwsA(isA<GenerationException>()));
    expect(commands.last, 'test');
    expect(output.listSync(), isEmpty);
  });

  test('rejects undeclared template overwrites and cleans staging', () async {
    await _write(
        assets, 'templates/content/lib/main.dart.tmpl', '// invalid override');
    await expectLater(
      generator().create(options(), output),
      throwsA(isA<GenerationException>().having(
        (error) => error.message,
        'message',
        contains('cannot overwrite lib/main.dart'),
      )),
    );
    expect(commands, hasLength(1));
    expect(output.listSync(), isEmpty);
  });
}

Future<void> _write(Directory root, String relative, String text) async {
  final file = File.fromUri(root.uri.resolve(relative));
  await file.parent.create(recursive: true);
  await file.writeAsString(text);
}

Future<String> _read(Directory root, String relative) =>
    File.fromUri(root.uri.resolve(relative)).readAsString();

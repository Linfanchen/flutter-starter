import 'dart:convert';
import 'dart:io';

// Keep expectations independent of the generator so a bad dependency change
// cannot update both the behavior and its verification implicitly.
const _templates = <String, List<String>>{
  'base': ['starter_network', 'starter_auth'],
  'content': ['starter_network', 'starter_config'],
  'shop': ['starter_network', 'starter_storage'],
  'character': ['starter_network', 'starter_storage', 'starter_database'],
  'course': [
    'starter_network',
    'starter_config',
    'starter_storage',
    'starter_sync',
    'starter_database',
  ],
};

const _excludedRoots = {
  '.dart_tool',
  '.flutter-plugins',
  '.flutter-plugins-dependencies',
  '.git',
  'build',
};

/// Runs the complete matrix, or one half for an isolated CI handoff.
Future<void> main(List<String> args) async {
  if (args.length == 1 && args.single == '--help') {
    stdout.writeln(
      'Usage: dart run template_smoke.dart '
      '[--prepare <new-directory> | --verify <bundle-directory>]',
    );
    return;
  }
  if (args.isNotEmpty &&
      (args.length != 2 || !{'--prepare', '--verify'}.contains(args.first))) {
    stderr.writeln('Invalid arguments. Run with --help for usage.');
    exitCode = 64;
    return;
  }

  Directory? workspace;
  final localRun = args.isEmpty;
  try {
    final verifyOnly = !localRun && args.first == '--verify';
    final prepareOnly = !localRun && args.first == '--prepare';
    workspace = localRun
        ? await Directory.systemTemp.createTemp('flutter-starter-smoke-')
        : Directory(args[1]).absolute;
    if (prepareOnly) {
      if (FileSystemEntity.typeSync(workspace.path, followLinks: false) !=
          FileSystemEntityType.notFound) {
        throw StateError(
            'Bundle destination already exists: ${workspace.path}');
      }
      await workspace.create(recursive: true);
    }
    stdout.writeln('Smoke workspace: ${workspace.path}');
    await _run('flutter', ['--version'], workspace);

    Directory? sourceCheckout;
    if (!verifyOnly) {
      final script = File.fromUri(Platform.script);
      final cli = script.parent.parent;
      sourceCheckout = cli.parent.parent;
      await _prepare(cli, workspace);
      if (prepareOnly) {
        await script.copy(
            File.fromUri(workspace.uri.resolve('template_smoke.dart')).path);
      }
    }
    if (!prepareOnly) await _verify(workspace, sourceCheckout);
    if (localRun) await workspace.delete(recursive: true);
  } catch (error) {
    stderr.writeln(error);
    if (workspace?.existsSync() ?? false) {
      stderr.writeln('Smoke workspace retained: ${workspace!.path}');
    }
    exitCode = 1;
  }
}

Future<void> _prepare(Directory cli, Directory workspace) async {
  final dart = Platform.resolvedExecutable;
  await _run(dart, ['pub', 'get'], cli);
  final generator = [
    '--packages=${File.fromUri(cli.uri.resolve('.dart_tool/package_config.json')).path}',
    File.fromUri(cli.uri.resolve('bin/flutter_starter.dart')).path,
  ];
  final listing = await Process.run(dart, [...generator, 'list'],
      workingDirectory: cli.path);
  if (listing.exitCode != 0) {
    throw StateError('flutter-starter list failed: ${listing.stderr}');
  }
  final advertised = (listing.stdout as String)
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .map((line) => line.trim().split(RegExp(r'\s+')).first)
      .toList();
  _expectNames('CLI template list', advertised, _templates.keys);

  final generated = Directory.fromUri(workspace.uri.resolve('generated/'));
  await generated.create();
  final apps = Directory.fromUri(workspace.uri.resolve('apps/'));
  await apps.create();
  await _runMatrix('generate', (template) async {
    await _run(
        dart,
        [
          ...generator,
          'create',
          '${template}_smoke',
          '--template',
          template,
          '--org',
          'com.example',
          '--platforms',
          'web',
        ],
        generated);
    final source =
        Directory.fromUri(generated.uri.resolve('${template}_smoke/'));
    final relocated = Directory.fromUri(apps.uri.resolve('${template}_smoke/'));
    await _copyFreshApp(source, relocated);
  });
  // Keep only relocated source in the bundle handed to the verify job.
  await generated.delete(recursive: true);
}

Future<void> _verify(Directory workspace, Directory? sourceCheckout) async {
  final apps = Directory.fromUri(workspace.uri.resolve('apps/'));
  await _runMatrix('verify', (template) async {
    final app = Directory.fromUri(apps.uri.resolve('${template}_smoke/'));
    final expected = _templates[template]!;
    _expectNames('features', _childNames(app, 'lib/features/'), [
      if (template != 'base') template,
    ]);
    _expectNames('local packages', _childNames(app, 'packages/'), expected);
    for (final root in ['lib/', 'test/', 'packages/']) {
      final files =
          Directory.fromUri(app.uri.resolve(root)).listSync(recursive: true);
      for (final file in files.whereType<File>()) {
        if (file.path.endsWith('.tmpl') ||
            (file.path.endsWith('.dart') &&
                RegExp(r'\{\{[a-z_]+\}\}')
                    .hasMatch(await file.readAsString()))) {
          throw StateError('Unrendered template: ${file.path}');
        }
      }
    }

    await _run('flutter', ['pub', 'get'], app);
    await _verifyResolution(app, expected, sourceCheckout);
    await _run(
        Platform.resolvedExecutable,
        [
          'format',
          '--output=none',
          '--set-exit-if-changed',
          'lib',
          'test',
          'packages',
        ],
        app);
    await _run('flutter', ['analyze', '--no-pub'], app);
    await _run('flutter', ['test', '--no-pub'], app);
    await _run('flutter', ['build', 'web', '--no-pub'], app);
    if (!File.fromUri(app.uri.resolve('build/web/index.html')).existsSync()) {
      throw StateError('Web build did not produce index.html.');
    }
  });
}

Future<void> _verifyResolution(
  Directory app,
  List<String> expected,
  Directory? sourceCheckout,
) async {
  final config =
      File.fromUri(app.uri.resolve('.dart_tool/package_config.json'));
  final decoded =
      jsonDecode(await config.readAsString()) as Map<String, dynamic>;
  final packages = <String, Uri>{
    for (final entry in decoded['packages'] as List)
      entry['name'] as String: config.uri.resolve(entry['rootUri'] as String),
  };
  _expectNames(
    'resolved starter packages',
    packages.keys.where((name) => name.startsWith('starter_')),
    expected,
  );
  for (final name in expected) {
    final actual =
        Directory.fromUri(packages[name]!).resolveSymbolicLinksSync();
    final local = Directory.fromUri(app.uri.resolve('packages/$name/'))
        .resolveSymbolicLinksSync();
    if (actual != local)
      throw StateError('$name resolved outside the local package.');
  }
  if (sourceCheckout == null) return;
  final checkout = Directory(sourceCheckout.resolveSymbolicLinksSync()).uri;
  for (final entry in packages.entries) {
    final resolved =
        Directory(Directory.fromUri(entry.value).resolveSymbolicLinksSync())
            .uri;
    if (resolved.toString().startsWith(checkout.toString())) {
      throw StateError('${entry.key} depends on the Starter checkout.');
    }
  }
}

Set<String> _childNames(Directory app, String path) {
  final directory = Directory.fromUri(app.uri.resolve(path));
  if (!directory.existsSync()) return {};
  return {
    for (final child
        in directory.listSync(followLinks: false).whereType<Directory>())
      child.uri.pathSegments.where((segment) => segment.isNotEmpty).last,
  };
}

void _expectNames(
    String label, Iterable<String> actual, Iterable<String> expected) {
  final left = actual.toList()..sort();
  final right = expected.toList()..sort();
  if (left.join(',') != right.join(',')) {
    throw StateError('$label: expected $right, got $left.');
  }
}

Future<void> _copyFreshApp(Directory source, Directory target) async {
  await target.create();
  await for (final entry in source.list(recursive: true, followLinks: false)) {
    final relative = entry.uri.path.substring(source.uri.path.length);
    if (_excludedRoots.contains(relative.split('/').first)) continue;
    if (entry is Link)
      throw StateError('Unexpected link in generated app: ${entry.path}');
    final destination = target.uri.resolve(relative);
    if (entry is Directory) {
      await Directory.fromUri(destination).create(recursive: true);
    } else if (entry is File) {
      final file = File.fromUri(destination);
      await file.parent.create(recursive: true);
      await entry.copy(file.path);
    }
  }
}

Future<void> _runMatrix(
  String phase,
  Future<void> Function(String template) action,
) async {
  final failed = <String>[];
  for (final template in _templates.keys) {
    stdout.writeln('\n[$phase/$template]');
    try {
      await action(template);
      stdout.writeln('PASS $phase/$template');
    } catch (error) {
      failed.add(template);
      stderr.writeln('FAIL $phase/$template: $error');
    }
  }
  if (failed.isNotEmpty)
    throw StateError('$phase failed for: ${failed.join(', ')}');
  stdout.writeln('\n$phase passed for all ${_templates.length} templates.');
}

Future<void> _run(
    String executable, List<String> arguments, Directory cwd) async {
  stdout.writeln('> $executable ${arguments.join(' ')}');
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: cwd.path,
    runInShell: Platform.isWindows && executable == 'flutter',
    mode: ProcessStartMode.inheritStdio,
  );
  final status = await process.exitCode;
  if (status != 0) {
    throw StateError(
        '${cwd.path}: $executable ${arguments.join(' ')} exited with $status.');
  }
}

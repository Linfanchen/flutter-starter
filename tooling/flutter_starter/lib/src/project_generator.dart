import 'dart:io';

import 'package:yaml_edit/yaml_edit.dart';

import 'create_options.dart';
import 'flutter_runner.dart';
import 'template_registry.dart';

/// A failed generation step with enough context for the CLI to report it.
final class GenerationException implements Exception {
  const GenerationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Builds and checks a project in staging before publishing it to disk.
final class ProjectGenerator {
  const ProjectGenerator({required this.starterRoot, required this.runFlutter});

  final Directory starterRoot;
  final FlutterRunner runFlutter;

  /// Generates one project under [outputRoot] and returns its final directory.
  Future<Directory> create(CreateOptions options, Directory outputRoot) async {
    final destination = Directory.fromUri(outputRoot.uri.resolve(options.name));
    _requireAbsent(destination);
    final template = options.template;
    final base = _template(TemplateDefinition.baseFiles);
    final overlay =
        template.overlay == null ? null : _template(template.overlay!);
    final packages = template.packages;
    for (final package in packages) {
      final source = starterRoot.uri.resolve('packages/$package/');
      if (!File.fromUri(source.resolve('pubspec.yaml')).existsSync() ||
          !Directory.fromUri(source.resolve('lib/')).existsSync()) {
        throw GenerationException(
            'Starter package is missing or incomplete: $package.');
      }
    }

    // Staging beside the destination keeps the final rename on the same volume.
    final staging = await outputRoot.createTemp('.flutter-starter-');
    try {
      await _run('create scaffold', staging, [
        'create',
        '--empty',
        '--no-pub',
        '--org',
        options.org,
        '--platforms',
        options.platforms.join(','),
        options.name,
      ]);
      final app = Directory.fromUri(staging.uri.resolve(options.name));
      final manifest = File.fromUri(app.uri.resolve('pubspec.yaml'));
      final editor = YamlEditor(await manifest.readAsString());
      final dependencies = _dependencies(editor);
      final materialImport = dependencies.containsKey('material_ui')
          ? 'package:material_ui/material_ui.dart'
          : 'package:flutter/material.dart';

      await _install(base, app, options.name, materialImport,
          TemplateDefinition.baseReplacements);
      if (overlay != null) {
        await _install(overlay, app, options.name, materialImport,
            TemplateDefinition.overlayReplacements);
      }
      for (final package in packages) {
        if (dependencies.containsKey(package)) {
          throw GenerationException(
              'Flutter scaffold already declares $package.');
        }
        await _copyPackage(app, package);
        editor.update(['dependencies', package], {'path': 'packages/$package'});
      }
      await manifest.writeAsString(editor.toString());
      await _run('resolve dependencies', app, ['pub', 'get'],
          minimumFlutter: template.minimumFlutterVersion);
      if (options.verify) {
        await _run('analyze', app, ['analyze']);
        await _run('test', app, ['test']);
      }
      _requireAbsent(destination);
      return await app.rename(destination.path);
    } finally {
      await staging.delete(recursive: true);
    }
  }

  Directory _template(String id) {
    final directory =
        Directory.fromUri(starterRoot.uri.resolve('templates/$id/'));
    if (!directory.existsSync()) {
      throw GenerationException('Starter template is missing: $id.');
    }
    return directory;
  }

  Future<void> _copyPackage(Directory app, String name) async {
    final source = starterRoot.uri.resolve('packages/$name/');
    final target = app.uri.resolve('packages/$name/');
    await Directory.fromUri(target).create(recursive: true);
    await File.fromUri(source.resolve('pubspec.yaml'))
        .copy(File.fromUri(target.resolve('pubspec.yaml')).path);
    final lib = Directory.fromUri(source.resolve('lib/'));
    // Copy private implementation files along with the public entry point.
    await for (final entry in lib.list(recursive: true, followLinks: false)) {
      if (entry is! File) continue;
      final relative = entry.uri.path.substring(lib.uri.path.length);
      final file = File.fromUri(target.resolve('lib/$relative'));
      await file.parent.create(recursive: true);
      await entry.copy(file.path);
    }
  }

  Future<void> _run(
    String phase,
    Directory cwd,
    List<String> arguments, {
    String? minimumFlutter,
  }) async {
    final status = await runFlutter(cwd, arguments);
    if (status == 0) return;
    final sdkHint = minimumFlutter == null
        ? ''
        : ' This template requires Flutter $minimumFlutter or newer.';
    throw GenerationException(
      'Failed to $phase: flutter ${arguments.join(' ')} exited with code $status.$sdkHint',
    );
  }
}

Map<dynamic, dynamic> _dependencies(YamlEditor editor) {
  final root = editor.parseAt([]).value;
  if (root is Map && root['dependencies'] is Map) {
    return root['dependencies'] as Map;
  }
  throw const GenerationException(
      'Unexpected dependencies section in Flutter pubspec.yaml.');
}

void _requireAbsent(Directory destination) {
  if (FileSystemEntity.typeSync(destination.path, followLinks: false) !=
      FileSystemEntityType.notFound) {
    throw FormatException('Destination already exists: ${destination.path}');
  }
}

Future<void> _install(
  Directory source,
  Directory app,
  String name,
  String materialImport,
  Set<String> allowedReplacements,
) async {
  // Render only template files, preserving the path relative to this layer.
  await for (final entry in source.list(recursive: true, followLinks: false)) {
    if (entry is! File || !entry.path.endsWith('.tmpl')) continue;
    final relative = entry.uri.path.substring(
      source.uri.path.length,
      entry.uri.path.length - '.tmpl'.length,
    );
    final target = File.fromUri(app.uri.resolve(relative));
    final type = await FileSystemEntity.type(target.path, followLinks: false);
    if (type != FileSystemEntityType.notFound &&
        (type != FileSystemEntityType.file ||
            !allowedReplacements.contains(relative))) {
      throw GenerationException('Template cannot overwrite $relative.');
    }
    await target.parent.create(recursive: true);
    final sourceText = await entry.readAsString();
    await target.writeAsString(sourceText
        .replaceAll('{{project_name}}', name)
        .replaceAll('{{material_import}}', materialImport));
  }
}

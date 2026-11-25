import 'dart:io';

/// Formats Dart template sources after replacing their small set of tokens.
///
/// Generated projects are the source of truth for formatting. This utility
/// keeps the template files aligned without asking Dart format to parse the
/// human-readable template markers directly.
Future<void> main() async {
  final current = Directory.current;
  final root = Directory(
    Directory('${current.path}${Platform.pathSeparator}templates').existsSync()
        ? current.path
        : current.parent.parent.path,
  );
  final temporary = await Directory.systemTemp.createTemp('flutter_templates');
  try {
    final templates = Directory(
      '${root.path}${Platform.pathSeparator}templates',
    );
    await for (final entity in templates.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.tmpl')) continue;
      final source = await entity.readAsString();
      final rendered = source
          .replaceAll('{{material_import}}', 'package:flutter/material.dart')
          .replaceAll('{{project_name}}', 'template_app');
      final temporaryFile = File(
        '${temporary.path}${Platform.pathSeparator}${entity.uri.pathSegments.last.replaceAll('.tmpl', '')}',
      );
      await temporaryFile.writeAsString(rendered);
      final result = await Process.run('dart', ['format', temporaryFile.path]);
      if (result.exitCode != 0) {
        stderr.write(result.stderr);
        exitCode = result.exitCode;
        return;
      }
      final formatted = await temporaryFile.readAsString();
      final restored = formatted
          .replaceAll('package:flutter/material.dart', '{{material_import}}')
          .replaceAll('template_app', '{{project_name}}');
      await entity.writeAsString(restored);
    }
  } finally {
    await temporary.delete(recursive: true);
  }
}

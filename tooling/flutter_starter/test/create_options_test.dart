import 'package:flutter_starter/src/create_options.dart';
import 'package:test/test.dart';

void main() {
  test('preserves the default template, organization and Web target', () {
    final result = CreateOptions.parse(['demo_app']);
    expect(result.template.id, 'base');
    expect(result.template.packages, ['starter_network', 'starter_auth']);
    expect(result.org, 'com.example');
    expect(result.platforms, ['web']);
    expect(result.verify, isFalse);
  });

  test('resolves explicit options through the template registry', () {
    final result = CreateOptions.parse([
      'demo_app',
      '--template',
      'course',
      '--org',
      'org.example',
      '--platforms',
      'android,web',
      '--verify',
    ]);
    expect(result.template.overlay, 'course');
    expect(result.template.packages, [
      'starter_network',
      'starter_config',
      'starter_storage',
      'starter_sync',
      'starter_database',
    ]);
    expect(result.org, 'org.example');
    expect(result.platforms, ['android', 'web']);
    expect(result.verify, isTrue);
  });

  test('rejects invalid names, flags and unsupported platform choices', () {
    for (final arguments in <List<String>>[
      [],
      ['../escape'],
      ['CON'],
      ['nul'],
      ['app\n'],
      ['app', '--template', 'missing'],
      ['app', '--org', 'invalid'],
      ['app', '--platforms', 'web,web'],
      ['app', '--platforms', 'nintendo'],
      ['app', '--platforms', '--verify'],
      ['app', '--verify', '--verify'],
    ]) {
      expect(() => CreateOptions.parse(arguments), throwsFormatException,
          reason: 'Expected invalid arguments: $arguments');
    }
  });
}

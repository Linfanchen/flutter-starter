import 'template_registry.dart';

/// Validated inputs for one project generation.
final class CreateOptions {
  CreateOptions._(
      this.name, this.template, this.org, this.platforms, this.verify);

  final String name;
  final TemplateDefinition template;
  final String org;
  final List<String> platforms;
  final bool verify;

  /// Parses the existing create flags before filesystem or process work starts.
  factory CreateOptions.parse(List<String> arguments) {
    if (arguments.isEmpty) {
      throw const FormatException('A project name is required.');
    }
    final name = arguments.first;
    final reserved = RegExp(r'^(con|prn|aux|nul|com[0-9]|lpt[0-9])$');
    if (RegExp(r'^[a-z][a-z0-9_]*$').firstMatch(name)?.end != name.length ||
        reserved.hasMatch(name)) {
      throw const FormatException(
          'Use a lowercase Dart package name, such as my_app.');
    }
    final options = <String, String>{};
    var verify = false;
    for (var index = 1; index < arguments.length; index++) {
      final option = arguments[index];
      if (option == '--verify' && !verify) {
        verify = true;
        continue;
      }
      if (!{'--template', '--org', '--platforms'}.contains(option) ||
          options.containsKey(option) ||
          index + 1 == arguments.length ||
          arguments[index + 1].startsWith('--')) {
        throw FormatException(
            'Invalid option: $option. Run flutter-starter create --help.');
      }
      options[option] = arguments[++index];
    }

    final templateId = options['--template'] ?? 'base';
    final template = templateRegistry[templateId];
    if (template == null) {
      throw FormatException(
          'Unknown template: $templateId. Run flutter-starter list.');
    }
    final org = options['--org'] ?? 'com.example';
    final orgPattern = RegExp(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$');
    if (orgPattern.firstMatch(org)?.end != org.length) {
      throw const FormatException(
          'Use a reverse-DNS organization, such as com.example.');
    }
    final platforms = (options['--platforms'] ?? 'web').split(',');
    if (!platforms.every(template.platforms.contains) ||
        platforms.toSet().length != platforms.length) {
      throw FormatException(
          'Choose distinct platforms from ${template.platforms.join(', ')}.');
    }
    return CreateOptions._(
        name, template, org, List.unmodifiable(platforms), verify);
  }
}

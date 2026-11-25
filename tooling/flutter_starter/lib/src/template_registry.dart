/// Metadata used to advertise, validate and assemble one generated template.
final class TemplateDefinition {
  const TemplateDefinition({
    required this.id,
    required this.description,
    this.usesOverlay = true,
    this.extraPackages = const [],
    this.minimumFlutterVersion,
    this.platforms = allPlatforms,
  });

  final String id;
  final String description;
  final bool usesOverlay;
  final List<String> extraPackages;
  final String? minimumFlutterVersion;
  final Set<String> platforms;

  static const allPlatforms = {
    'android',
    'ios',
    'web',
    'windows',
    'macos',
    'linux'
  };
  static const baseFiles = 'base';

  /// Folder applied on top of the shared base, if any.
  String? get overlay => usesOverlay ? id : null;

  /// Paths that the shared template may replace in the Flutter scaffold.
  static const baseReplacements = {'lib/main.dart', 'test/widget_test.dart'};

  /// Business overlays may replace only these inherited entry points.
  static const overlayReplacements = {
    'lib/app/template_home.dart',
    'test/widget_test.dart',
  };

  /// Source packages copied into the app and declared as local dependencies.
  List<String> get packages => ['starter_network', ...extraPackages];
}

/// The production template catalog. Keep smoke expectations independent.
final templateRegistry = Map<String, TemplateDefinition>.unmodifiable({
  for (final template in _definitions) template.id: template,
});

const _definitions = [
  TemplateDefinition(
    id: 'base',
    description: 'Basic app shell',
    usesOverlay: false,
    extraPackages: ['starter_auth'],
  ),
  TemplateDefinition(
    id: 'content',
    description: 'List and detail app',
    extraPackages: ['starter_config'],
  ),
  TemplateDefinition(
    id: 'shop',
    description: 'Product catalog and shopping cart',
    extraPackages: ['starter_storage'],
    minimumFlutterVersion: '3.41.0',
  ),
  TemplateDefinition(
    id: 'character',
    description: 'Character selection and branching story',
    extraPackages: ['starter_storage', 'starter_database'],
    minimumFlutterVersion: '3.41.0',
  ),
  TemplateDefinition(
    id: 'course',
    description: 'Online course catalog, lessons and learning progress',
    extraPackages: [
      'starter_config',
      'starter_storage',
      'starter_sync',
      'starter_database',
    ],
    minimumFlutterVersion: '3.41.0',
  ),
];

import 'package:starter_config/starter_config.dart';
import 'package:test/test.dart';

void main() {
  AppConfig parse(String url, {String env = 'dev', String sample = ''}) =>
      AppConfig.parse(
        apiKey: 'TEST_API_BASE_URL',
        apiUrl: url,
        environment: env,
        sampleData: sample,
      );

  test('uses samples by default and accepts an explicit remote API', () {
    expect(parse('').useSampleData, isTrue);
    final remote = parse('https://example.test/api/', env: 'staging');
    expect(remote.environment, AppEnvironment.staging);
    expect(remote.apiBaseUrl, Uri.parse('https://example.test/api/'));
    expect(remote.useSampleData, isFalse);
    expect(parse('https://example.test', sample: 'true').useSampleData, isTrue);
  });

  test('rejects invalid settings without echoing supplied values', () {
    for (final url in [
      'ftp://example.test',
      'https://u:secret@example.test',
      'https://example.test/?token=secret'
    ]) {
      expect(
        () => parse(url),
        throwsA(isA<ConfigException>().having(
          (error) => error.toString(),
          'message',
          isNot(contains('secret')),
        )),
      );
    }
    expect(() => parse('', sample: 'false'), throwsA(isA<ConfigException>()));
    expect(() => parse('', sample: 'yes'), throwsA(isA<ConfigException>()));
    expect(() => parse('', env: 'qa'), throwsA(isA<ConfigException>()));
  });
}

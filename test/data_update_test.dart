import 'dart:convert';
import 'dart:io';

import 'package:google_i18n_address/src/data/us.json.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

@GenerateNiceMocks([MockSpec<http.Client>(), MockSpec<Downloader>()])
import 'data_update_test.mocks.dart';

/// For test purposes only
const String mainUrl = 'https://chromium-i18n.appspot.com/ssl-address/data';

/// For test purposes only
String serialize(Map<String, dynamic> data, String path) {
  final jsonStr = json.encode(data);
  File(path).writeAsStringSync(jsonStr);
  return jsonStr;
}

// Simplified Downloader interface for script testing
class Downloader {
  Future<void> download({String? country}) async {
    // This would be the actual implementation
  }
}

// This ArgumentParser is a test-specific implementation that simulates
// the behavior of the argument parsing in the actual script.
// It's simplistic by design to isolate command-line argument logic in tests.
// In a future refactoring, we could extract the real parser into its own class
// that could be shared between the implementation and tests.
class ArgumentParser {
  final Map<String, dynamic> _options = {};
  final Map<String, String> _descriptions = {};
  String get usage => _descriptions.entries.map((e) => '${e.key}: ${e.value}').join('\n');

  void addFlag(String name, {String? abbr, String? help, bool negatable = true}) {
    _options[name] = false;
    if (abbr != null) {
      _options[abbr] = false;
    }
    if (help != null) {
      _descriptions[name] = help;
    }
  }

  void addOption(String name, {String? abbr, String? help}) {
    _options[name] = null;
    if (abbr != null) {
      _options[abbr] = null;
    }
    if (help != null) {
      _descriptions[name] = help;
    }
  }

  Map<String, dynamic> parse(List<String> arguments) {
    final result = <String, dynamic>{};
    for (final key in _options.keys) {
      result[key] = _options[key];
    }

    for (var i = 0; i < arguments.length; i++) {
      final arg = arguments[i];
      if (arg.startsWith('--')) {
        final option = arg.substring(2);
        if (_options.containsKey(option)) {
          if (_options[option] is bool) {
            result[option] = true;
          } else {
            if (i + 1 < arguments.length && !arguments[i + 1].startsWith('-')) {
              result[option] = arguments[i + 1];
              i++;
            }
          }
        }
      } else if (arg.startsWith('-')) {
        final option = arg.substring(1);
        if (_options.containsKey(option)) {
          if (_options[option] is bool) {
            result[option] = true;
          } else {
            if (i + 1 < arguments.length && !arguments[i + 1].startsWith('-')) {
              result[option] = arguments[i + 1];
              i++;
            }
          }
        }
      }
    }
    return result;
  }
}

// This is a test helper function that wraps the download functionality with a mock client
// We use this approach to isolate the HTTP interactions in testing
// Note: In a future refactoring, the core downloader could be updated to accept
// a custom HTTP client directly, which would make this wrapper unnecessary
Future<void> downloadWithClient(
    String? country, String outputPath, http.Client client) async {
  // Create data directory if it doesn't exist
  final dataDir = Directory(outputPath);
  if (!dataDir.existsSync()) {
    dataDir.createSync(recursive: true);
  }

  final allData = <String, Map<String, dynamic>>{};

  // Get countries list
  final response = await client.get(Uri.parse('$mainUrl/countries'));
  final countries = (json.decode(response.body)['countries'] as String).split('~');

  if (country != null) {
    final normalizedCountry = country.toUpperCase();
    if (!countries.contains(normalizedCountry)) {
      throw ArgumentError('$country is not a supported country code');
    }
    countries.clear();
    countries.add(normalizedCountry);
  }

  // Process each country
  for (final countryCode in countries) {
    // Call our test-specific processData that uses the mock client
    await processDataWithClient(countryCode, null, allData, client);
  }

  // Write "all.json" file
  final allOutput = StringBuffer('{');

  // Write individual country files
  for (int i = 0; i < countries.length; i++) {
    final countryCode = countries[i];
    final countryData = <String, Map<String, dynamic>>{};

    for (final entry in allData.entries) {
      if (entry.key.startsWith(countryCode)) {
        countryData[entry.key] = entry.value;
      }
    }

    final countryFilePath = '$outputPath/${countryCode.toLowerCase()}.json';
    final countryJson = serialize(countryData, countryFilePath);

    // Add to the "all.json" file
    allOutput.write(countryJson.substring(1, countryJson.length - 1));
    if (i < countries.length - 1) {
      allOutput.write(',');
    }
  }

  allOutput.write('}');
  File('$outputPath/all.json').writeAsStringSync(allOutput.toString());
}

// This function adapts the real processData to work with our mock client in tests
// It follows the same logic as the real implementation, but allows us to
// inject a mock HTTP client for testing.
// Note: Ideally the actual implementation would accept a client parameter,
// which would make this function unnecessary.
Future<Map<String, dynamic>> processDataWithClient(String key, String? language,
    Map<String, Map<String, dynamic>> allData, http.Client client) async {
  final fullKey = language != null ? '$key?lang=$language' : key;
  final url = '$mainUrl/$fullKey';

  // Fetch data using the mock client
  final response = await client.get(Uri.parse(url));
  final data = json.decode(response.body) as Map<String, dynamic>;

  // Store the data
  final keyToStore = language != null ? '$key--$language' : key;
  allData[keyToStore] = data;

  // Check for additional languages
  final lang = data['lang'] as String?;
  final languages = data['languages'] as String?;

  if (languages != null && lang != null) {
    final languageList = languages.split('~');
    languageList.remove(lang);

    // Process each additional language
    for (final additionalLang in languageList) {
      await processDataWithClient(key, additionalLang, allData, client);
    }
  }

  // Check for sub-keys
  if (data.containsKey('sub_keys')) {
    final subKeys = (data['sub_keys'] as String).split('~');

    // Process each sub-key
    for (final subKey in subKeys) {
      await processDataWithClient('$key/$subKey', language, allData, client);
    }
  }

  return {key: data};
}

void main() {
  group('Downloader Basic Tests', () {
    late Directory tempDir;

    setUp(() {
      // Create a temporary directory for test files
      tempDir = Directory.systemTemp.createTempSync('google_i18n_address_test_');
    });

    tearDown(() {
      // Clean up after tests
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('serialize writes JSON to file', () {
      final testData = {'test': 'data'};
      final filePath = '${tempDir.path}/test.json';

      final result = serialize(testData, filePath);

      expect(result, '{"test":"data"}');
      expect(File(filePath).existsSync(), isTrue);
      expect(json.decode(File(filePath).readAsStringSync()), equals(testData));
    });
  });

  group('Downloader Comprehensive Tests', () {
    late Directory tempDir;
    late MockClient mockClient;

    setUp(() {
      // Create a temporary directory for test files
      tempDir = Directory.systemTemp.createTempSync('google_i18n_address_test_');
      mockClient = MockClient();
    });

    tearDown(() {
      // Clean up after tests
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('download with single country argument', () async {
      // Mocking responses for country listing and individual country data
      when(mockClient.get(Uri.parse('$mainUrl/countries')))
          .thenAnswer((_) async => http.Response('{"countries": "PL~US"}', 200));

      when(mockClient.get(Uri.parse('$mainUrl/PL'))).thenAnswer((_) async =>
          http.Response('{"key": "PL", "lang": "pl", "name": "POLAND"}', 200));

      // Set output directory to temp directory
      final dataDir = '${tempDir.path}/data';
      Directory(dataDir).createSync();

      // Run download with mocked client
      await downloadWithClient('PL', dataDir, mockClient);

      // Verify that the file was created correctly
      final plFile = File('$dataDir/pl.json');
      final allFile = File('$dataDir/all.json');

      expect(plFile.existsSync(), true);
      expect(allFile.existsSync(), true);

      final plData = json.decode(plFile.readAsStringSync());
      expect(plData, contains('PL'));
    });

    test('download throws on invalid country code', () async {
      // Mock countries response
      when(mockClient.get(Uri.parse('$mainUrl/countries')))
          .thenAnswer((_) async => http.Response('{"countries": "PL~US"}', 200));

      // Make sure invalid country code throws
      expect(
        () => downloadWithClient('XX', tempDir.path, mockClient),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('process data handles sub-keys correctly', () async {
      // Setup mocks for a country with sub-regions
      when(mockClient.get(Uri.parse('$mainUrl/CH')))
          .thenAnswer((_) async => http.Response('''
                {
                  "key": "CH",
                  "lang": "de",
                  "name": "SWITZERLAND",
                  "languages": "de~fr",
                  "sub_keys": "AG~AR",
                  "sub_names": "Aargau~Appenzell Ausserrhoden"
                }
                ''', 200));

      when(mockClient.get(Uri.parse('$mainUrl/CH/AG'))).thenAnswer(
          (_) async => http.Response('{"key": "CH/AG", "name": "Aargau"}', 200));

      when(mockClient.get(Uri.parse('$mainUrl/CH/AR'))).thenAnswer((_) async =>
          http.Response('{"key": "CH/AR", "name": "Appenzell Ausserrhoden"}', 200));

      when(mockClient.get(Uri.parse('$mainUrl/CH?lang=fr'))).thenAnswer((_) async =>
          http.Response('{"key": "CH", "lang": "fr", "name": "SUISSE"}', 200));

      // Run the process test with mocked client
      final allData = <String, Map<String, dynamic>>{};
      await processDataWithClient('CH', null, allData, mockClient);

      // Verify the correct data was processed
      expect(allData.containsKey('CH'), true);
      expect(allData.containsKey('CH/AG'), true);
      expect(allData.containsKey('CH/AR'), true);

      expect(allData['CH']?['name'], 'SWITZERLAND');
      expect(allData['CH/AG']?['name'], 'Aargau');
      expect(allData['CH/AR']?['name'], 'Appenzell Ausserrhoden');
    });

    test('download all countries', () async {
      // Mocking responses for country listing
      when(mockClient.get(Uri.parse('$mainUrl/countries')))
          .thenAnswer((_) async => http.Response('{"countries": "PL~US"}', 200));

      when(mockClient.get(Uri.parse('$mainUrl/PL'))).thenAnswer((_) async =>
          http.Response('{"key": "PL", "lang": "pl", "name": "POLAND"}', 200));

      when(mockClient.get(Uri.parse('$mainUrl/US'))).thenAnswer((_) async =>
          http.Response('{"key": "US", "lang": "en", "name": "UNITED STATES"}', 200));

      // Set output directory to temp directory
      final dataDir = '${tempDir.path}/data';
      Directory(dataDir).createSync();

      // Run download with mocked client for all countries
      await downloadWithClient(null, dataDir, mockClient);

      // Verify that all files were created correctly
      final plFile = File('$dataDir/pl.json');
      final usFile = File('$dataDir/us.json');
      final allFile = File('$dataDir/all.json');

      expect(plFile.existsSync(), true);
      expect(usFile.existsSync(), true);
      expect(allFile.existsSync(), true);

      final allData = json.decode(allFile.readAsStringSync());
      expect(allData, contains('PL'));
      expect(allData, contains('US'));
    });

    test('serialize handles unicode data correctly', () {
      final testData = {'test': 'data with unicode: äöü'};
      final filePath = '${tempDir.path}/test.json';

      final result = serialize(testData, filePath);

      expect(result, '{"test":"data with unicode: äöü"}');
      expect(File(filePath).existsSync(), isTrue);
      expect(json.decode(File(filePath).readAsStringSync()), equals(testData));
    });

    test('download with existing data directory', () async {
      // Create data directory before download
      final dataDir = '${tempDir.path}/data';
      Directory(dataDir).createSync();

      // Mocking responses for country listing
      when(mockClient.get(Uri.parse('$mainUrl/countries')))
          .thenAnswer((_) async => http.Response('{"countries": "PL"}', 200));

      when(mockClient.get(Uri.parse('$mainUrl/PL'))).thenAnswer((_) async =>
          http.Response('{"key": "PL", "lang": "pl", "name": "POLAND"}', 200));

      // Run download with mocked client
      await downloadWithClient('PL', dataDir, mockClient);

      // Verify that the file was created in the existing directory
      expect(File('$dataDir/pl.json').existsSync(), true);
    });
  });

  group('Script Integration Tests', () {
    late MockDownloader mockDownloader;

    setUp(() {
      mockDownloader = MockDownloader();
    });

    // This function tests the CLI argument parsing behavior, which is why we need
    // a simplified version here. In an ideal world, we would extract the real
    // argument parsing logic into its own class that could be unit tested directly.
    Future<void> mockDownloadJsonFiles({List<String>? arguments}) async {
      final parser = ArgumentParser();
      parser
        ..addFlag('help', abbr: 'h', help: 'Show this help message', negatable: false)
        ..addOption('country', abbr: 'c', help: 'Country code to download');

      final results = parser.parse(arguments ?? []);

      if (results['help'] == true) {
        return;
      }

      final country = results['country'] as String?;

      await mockDownloader.download(country: country);
    }

    test('download_json_files all countries', () async {
      when(mockDownloader.download()).thenAnswer((_) async {});

      // Mock as if the script was called without any arguments
      await mockDownloadJsonFiles(arguments: []);

      // Verify the downloader was called with no country specified
      verify(mockDownloader.download()).called(1);
    });

    test('download_json_files specific country', () async {
      when(mockDownloader.download(country: 'US')).thenAnswer((_) async {});

      // Mock as if the script was called with a country argument
      await mockDownloadJsonFiles(arguments: ['--country', 'US']);

      // Verify the downloader was called with the specific country
      verify(mockDownloader.download(country: 'US')).called(1);
    });

    test('download_json_files help flag', () async {
      // Mock as if the script was called with the help flag
      await mockDownloadJsonFiles(arguments: ['--help']);

      // No need to verify, as the help text would be printed
      verifyNever(mockDownloader.download(country: anyNamed('country')));
    });
  });

  // Optional reference test that was skipped in the original file
  test('New JSON downloaded matches the old JSON',
      skip:
          'Skipping this test as it is a convenience test to be used manually to test the downloader',
      () async {
    final referenceJsonFile = File('test/usJsonReference.json');
    final referenceJson = json.decode(referenceJsonFile.readAsStringSync());
    final newJson = usJson;

    expect(newJson, equals(referenceJson));
  });
}

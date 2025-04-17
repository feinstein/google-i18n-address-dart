// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

/// Main URL for Google's i18n address data
const String mainUrl = 'https://chromium-i18n.appspot.com/ssl-address/data';

/// Directory where data files are stored
const String dataDir = 'lib/src/data';

/// Logger for the tool
final _log = Logger('JsonUpdater');

/// Gets a list of all countries from the Google i18n API
Future<List<String>> getCountries() async {
  _log.info('Fetching list of countries...');
  final data = await fetch(mainUrl);
  final countries = (data['countries'] as String).split('~');
  countries.add('ZZ'); // Add default country
  return countries;
}

/// Fetches data from a URL.
Future<Map<String, dynamic>> fetch(String url) async {
  _log.info('Fetching: $url');
  final response = await http.get(Uri.parse(url));

  if (response.statusCode != 200) {
    throw Exception('Failed to fetch data: ${response.statusCode}');
  }

  return json.decode(response.body) as Map<String, dynamic>;
}

/// Processes a key/language pair and returns data.
/// Also adds any sub-keys and language variants to the collection.
Future<Map<String, dynamic>> processData(String key, String? language,
    Map<String, Map<String, dynamic>> allData) async {
  final fullKey = language != null ? '$key--$language' : key;
  final url = '$mainUrl/$fullKey';

  try {
    final data = await fetch(url);

    // Store the data
    allData[fullKey] = data;

    // Check for additional languages
    final lang = data['lang'] as String?;
    final languages = data['languages'] as String?;

    if (languages != null && lang != null) {
      final languageList = languages.split('~');
      languageList.remove(lang);

      // Process each additional language
      for (final additionalLang in languageList) {
        await processData(key, additionalLang, allData);
      }
    }

    // Check for sub-keys
    if (data.containsKey('sub_keys')) {
      final subKeys = (data['sub_keys'] as String).split('~');

      // Process each sub-key
      for (final subKey in subKeys) {
        await processData('$key/$subKey', language, allData);
      }
    }

    return {fullKey: data};
  } catch (e) {
    _log.severe('Failed to process $key with language $language', e);
    rethrow;
  }
}

/// Writes country data to JSON file
void writeJsonFile(
    String countryCode, Map<String, Map<String, dynamic>> allData) {
  final filePath = path.join(dataDir, '${countryCode.toLowerCase()}.json');
  _log.info('Writing JSON file: $filePath');

  final countryData = <String, Map<String, dynamic>>{};

  for (final entry in allData.entries) {
    if (entry.key.startsWith(countryCode)) {
      countryData[entry.key] = entry.value;
    }
  }

  final file = File(filePath);
  file.writeAsStringSync(json.encode(countryData));
}

/// Writes all country data to a combined file
void writeAllJsonFile(Map<String, Map<String, dynamic>> allData) {
  final filePath = path.join(dataDir, 'all.json');
  _log.info('Writing combined JSON file: $filePath');

  final file = File(filePath);
  file.writeAsStringSync(json.encode(allData));
}

/// Converts JSON file to Dart getter
void convertJsonToDart(String countryCode) {
  final stopwatch = Stopwatch()..start();
  final jsonFilePath = path.join(dataDir, '${countryCode.toLowerCase()}.json');
  final dartFilePath =
      path.join(dataDir, '${countryCode.toLowerCase()}.json.dart');

  _log.info('Converting $jsonFilePath to $dartFilePath');

  final jsonFile = File(jsonFilePath);
  if (!jsonFile.existsSync()) {
    _log.warning('JSON file does not exist: $jsonFilePath');
    return;
  }

  final jsonContent = jsonFile.readAsStringSync().replaceAll(r'$', r'\$');

  final dartFile = File(dartFilePath);
  dartFile.writeAsStringSync('''
// Generated Dart file from ${countryCode.toLowerCase()}.json
// Do not edit manually

Map<String, Map<String, String>> get ${countryCode.toLowerCase()}Json => $jsonContent;
''');

  stopwatch.stop();
  _log.info('JSON file converted to Dart in ${stopwatch.elapsed}');
}

/// Creates the json_data.dart file that maps all getters
void createJsonDataFile() {
  _log.info('Creating json_data.dart file');
  final dataDirectory = Directory(dataDir);
  final dartFiles = dataDirectory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.json.dart'))
      .map((file) => path.basename(file.path))
      .toList();

  final jsonDataFile = File(path.join(dataDir, 'json_data.dart'));

  final imports = dartFiles.map((file) => "import '$file';").join('\n');

  final mapEntries = ([
    ...dartFiles.map((file) {
      final countryCode =
          path.basenameWithoutExtension(file).replaceAll('.json', '');
      return "  '$countryCode': () => ${countryCode}Json,";
    })
  ]..sort((a, b) => a.compareTo(b)))
      .join('\n');

  jsonDataFile.writeAsStringSync('''
// Generated Dart file
// Do not edit manually

$imports

/// Maps country codes to their respective JSON data getter functions.
/// 
/// The data is loaded lazily through getters, so memory is only used when the
/// specific country data is requested.
Map<String, Map<String, Map<String, String>> Function()> jsonDataMap = {
$mapEntries
};
''');
}

/// Downloads address data for countries
Future<void> downloadCountryData({String? specificCountry}) async {
  final countries = specificCountry != null
      ? [specificCountry.toUpperCase()]
      : await getCountries();

  final allData = <String, Map<String, dynamic>>{};

  // Process each country
  for (final country in countries) {
    _log.info('Processing country: $country');
    await processData(country, null, allData);
  }

  _log.info('Processing completed, writing files...');

  // Write "all.json" file if downloading all countries
  if (specificCountry == null) {
    writeAllJsonFile(allData);
  }

  // Write individual country files
  for (final country in countries) {
    writeJsonFile(country, allData);
  }

  _log.info('Download completed successfully');
}

/// Main function to update JSON files
Future<void> main(List<String> arguments) async {
  // Configure logging
  Logger.root.level = Level.INFO;

  setupLogs();

  // Parse command-line arguments
  final parser = ArgParser()
    ..addFlag('help',
        abbr: 'h', negatable: false, help: 'Show usage information')
    ..addFlag('download',
        abbr: 'd', negatable: false, help: 'Download JSON files')
    ..addFlag('convert',
        abbr: 'c', negatable: false, help: 'Convert JSON files to Dart getters')
    ..addOption('country',
        abbr: 'o', help: 'Process only the specified country code');

  final stopwatch = Stopwatch()..start();
  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      print('Usage: dart tool/update_json_files.dart [options]\n');
      print(parser.usage);
      return;
    }

    var shouldDownload = results['download'] as bool;
    var shouldConvert = results['convert'] as bool;
    final specificCountry = results['country'] as String?;

    // Default behavior: download and convert if no flags are specified
    if (!shouldDownload && !shouldConvert) {
      _log.info(
          'No specific operation selected. Will download and convert files.');
      shouldDownload = true;
      shouldConvert = true;
    }

    // Create data directory if it doesn't exist
    final directory = Directory(dataDir);
    if (!directory.existsSync()) {
      _log.info('Creating data directory: $dataDir');
      directory.createSync(recursive: true);
    }

    if (shouldDownload) {
      await downloadCountryData(specificCountry: specificCountry);
    }

    if (shouldConvert) {
      // Find all JSON files in the data directory
      final countries = directory
          .listSync()
          .whereType<File>()
          .where((file) =>
              file.path.endsWith('.json') && !file.path.endsWith('.json.dart'))
          .map((file) => path.basenameWithoutExtension(file.path))
          .toList();

      if (specificCountry != null) {
        final country = specificCountry.toLowerCase();
        if (countries.contains(country)) {
          convertJsonToDart(country);
        } else {
          _log.warning('No JSON file found for country: $country');
        }
      } else {
        await runCountriesConversions(countries);
      }

      // Create the json_data.dart file
      createJsonDataFile();
    }

    _log.info('Fixing Dart file... (${stopwatch.elapsed})');
    Process.runSync('dart', ['fix', '--apply', dataDir]);

    _log.info('Formatting Dart files... (${stopwatch.elapsed})');
    Process.runSync('dart', ['format', dataDir]);

    stopwatch.stop();
    _log.info('Operation completed successfully in ${stopwatch.elapsed}');
  } catch (e) {
    _log.severe('An error occurred: $e');
    exitCode = 1;
  } finally {
    stopwatch.stop();
  }
}

void setupLogs() {
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.message}');
  });
}

Future<void> runCountriesConversions(List<String> countries) async {
  // gets how many cores are available
  final coresCount = Platform.numberOfProcessors;

  final batchesCount = countries.length ~/ coresCount;
  final countriesBatches = countries.slices(batchesCount);

  void convertBatch(List<String> batch) {
    // We need to setup logs for each isolate
    setupLogs();

    for (final country in batch) {
      convertJsonToDart(country);
    }
  }

  await [
    for (final countriesBatch in countriesBatches)
      Isolate.run(() => convertBatch(countriesBatch))
  ].wait;
}

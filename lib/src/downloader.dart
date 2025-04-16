import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'data_loader.dart';

/// Main URL for Google's i18n address data
const String mainUrl = 'https://chromium-i18n.appspot.com/ssl-address/data';

/// Path to store data files
String dataPath(String countryCode) =>
    path.join(Directory.current.path, validationDataDir, '$countryCode.json');

/// Logger for the downloader
final _log = Logger('Downloader');

/// Fetches data from a URL.
///
/// Returns the JSON data from the URL.
Future<Map<String, dynamic>> fetch(String url) async {
  _log.info('Fetching: $url');
  final response = await http.get(Uri.parse(url));

  if (response.statusCode != 200) {
    throw Exception('Failed to fetch data: ${response.statusCode}');
  }

  return json.decode(response.body) as Map<String, dynamic>;
}

/// Gets a list of all countries.
///
/// Returns a list of country codes.
Future<List<String>> getCountries() async {
  final data = await fetch(mainUrl);
  final countries = (data['countries'] as String).split('~');
  countries.add('ZZ'); // Add default
  return countries;
}

/// Processes a key/language pair and returns data.
///
/// Returns a tuple containing the full key and the fetched data.
/// Also adds any sub-keys to the work queue.
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

/// Serializes data to JSON and writes it to a file.
///
/// Returns the serialized JSON string.
String serialize(Map<String, dynamic> data, String path) {
  final jsonStr = json.encode(data);
  File(path).writeAsStringSync(jsonStr);
  return jsonStr;
}

/// Downloads address data for countries.
///
/// If [country] is specified, only downloads data for that country.
/// Otherwise, downloads data for all countries.
Future<void> download({String? country}) async {
  // Create data directory if it doesn't exist
  final dataDir =
      Directory(path.join(Directory.current.path, validationDataDir));
  if (!dataDir.existsSync()) {
    dataDir.createSync(recursive: true);
  }

  final allData = <String, Map<String, dynamic>>{};
  final countries = await getCountries();

  if (country != null) {
    final normalizedCountry = country.toUpperCase();
    if (!countries.contains(normalizedCountry)) {
      throw ArgumentError('$country is not a supported country code');
    }
    countries.clear();
    countries.add(normalizedCountry);
  }

  // Process each country
  for (final country in countries) {
    await processData(country, null, allData);
  }

  _log.info('Processing completed, writing files...');

  // Write "all.json" file
  final allOutput = StringBuffer('{');

  // Write individual country files
  for (int i = 0; i < countries.length; i++) {
    final country = countries[i];
    final countryData = <String, Map<String, dynamic>>{};

    for (final entry in allData.entries) {
      if (entry.key.startsWith(country)) {
        countryData[entry.key] = entry.value;
      }
    }

    _log.info('Saving $country');
    final countryJson = serialize(countryData, dataPath(country.toLowerCase()));

    // Add to the "all.json" file
    allOutput.write(countryJson.substring(1, countryJson.length - 1));
    if (i < countries.length - 1) {
      allOutput.write(',');
    }
  }

  allOutput.write('}');
  File(dataPath('all')).writeAsStringSync(allOutput.toString());

  _log.info('Download completed successfully');
}

/// Command-line function to download address data.
///
/// If [country] is specified, only downloads data for that country.
void downloadJsonFiles({String? country}) {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.message}');
  });

  download(country: country).catchError((e) {
    _log.severe('Download failed', e);
    // ignore: avoid_print
    print('Download failed: $e');
    exit(1);
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

/// Logger for the data loader
final _log = Logger('DataLoader');

/// Pattern for valid country codes
final RegExp validCountryCode = RegExp(r'^\w{2,3}$');

/// Path to the validation data directory
final String validationDataDir = path.join('lib', 'src', 'data');

/// Loads validation data for the specified country code.
///
/// If [countryCode] is "all", returns data for all countries.
/// Throws [ArgumentError] if the country code is invalid.
Map<String, dynamic> loadValidationData(String countryCode) {
  if (!validCountryCode.hasMatch(countryCode)) {
    throw ArgumentError(
        '"$countryCode" is not a valid country code', 'countryCode');
  }

  final normalizedCountryCode = countryCode.toLowerCase();
  final filePath = path.join(
      Directory.current.path, validationDataDir, '$normalizedCountryCode.json');

  final file = File(filePath);
  if (!file.existsSync()) {
    throw ArgumentError(
        '"$countryCode" is not a valid country code', 'countryCode');
  }

  try {
    final jsonData = file.readAsStringSync();
    return json.decode(jsonData) as Map<String, dynamic>;
  } catch (e) {
    _log.severe('Failed to load validation data for $countryCode', e);
    throw ArgumentError(
        'Failed to load validation data for $countryCode', 'countryCode');
  }
}

/// Loads country data for the specified country code.
///
/// Returns a tuple containing the country data and the full database.
/// The full database is needed to get sub-regions data.
///
///
/// def _load_country_data(country_code):
// database = load_validation_data("zz")
// country_data = database["ZZ"]
// if country_code:
//     country_code = country_code.upper()
//     if country_code.lower() == "zz":
//         raise ValueError(f"{country_code!r} is not a valid country code")
//     database = load_validation_data(country_code.lower())
//     country_data.update(database[country_code])
// return country_data, database

({Map<String, dynamic> countryData, Map<String, dynamic> database})
    loadCountryData(String? countryCode) {
  var database = loadValidationData('zz');
  final Map<String, dynamic> countryData = Map.from(database['ZZ']);

  if (countryCode != null && countryCode.isNotEmpty) {
    final normalizedCountryCode = countryCode.toUpperCase();
    if (normalizedCountryCode.toLowerCase() == 'zz') {
      throw ArgumentError(
          '"$normalizedCountryCode" is not a valid country code',
          'countryCode');
    }

    database = loadValidationData(normalizedCountryCode.toLowerCase());
    countryData.addAll(database[normalizedCountryCode]);
  }

  return (countryData: countryData, database: database);
}

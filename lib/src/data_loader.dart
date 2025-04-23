import 'package:logging/logging.dart';
import 'data/json_data.dart';

/// Logger for the data loader
final _log = Logger('DataLoader');

/// Pattern for valid country codes
final RegExp validCountryCode = RegExp(r'^\w{2,3}$');

/// Loads validation data for the specified country code.
///
/// If [countryCode] is "all", returns data for all countries.
/// Throws [ArgumentError] if the country code is invalid.
Map<String, Map<String, String>> loadValidationData(String countryCode) {
  if (!validCountryCode.hasMatch(countryCode)) {
    throw ArgumentError('"$countryCode" is not a valid country code', 'countryCode');
  }

  final normalizedCountryCode = countryCode.toLowerCase();

  if (!jsonDataMap.containsKey(normalizedCountryCode)) {
    throw ArgumentError('"$countryCode" is not a valid country code', 'countryCode');
  }

  try {
    return jsonDataMap[normalizedCountryCode]!();
  } catch (e) {
    _log.severe('Failed to load validation data for $countryCode', e);
    throw ArgumentError('Failed to load validation data for $countryCode', 'countryCode');
  }
}

/// Loads country data for the specified country code.
///
/// Returns a tuple containing the country data and the full database.
/// The full database is needed to get sub-regions data.
({Map<String, String> countryData, Map<String, Map<String, String>> database})
loadCountryData(String? countryCode) {
  var database = loadValidationData('zz');
  final countryData = <String, String>{...(database['ZZ'] ?? {})};

  if (countryCode != null && countryCode.isNotEmpty) {
    final normalizedCountryCode = countryCode.toUpperCase();
    if (normalizedCountryCode.toLowerCase() == 'zz') {
      throw ArgumentError(
        '"$normalizedCountryCode" is not a valid country code',
        'countryCode',
      );
    }

    database = loadValidationData(normalizedCountryCode.toLowerCase());
    countryData.addAll(database[normalizedCountryCode] ?? {});
  }

  return (countryData: countryData, database: database);
}

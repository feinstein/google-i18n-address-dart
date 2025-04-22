import 'data_loader.dart';
import 'validation.dart';

/// Latinizes an address.
///
/// Converts address fields to their Latin equivalent where possible.
/// If [isNormalized] is true, assumes the address is already normalized.
Map<String, String> latinizeAddress(Map<String, String> address,
    {bool isNormalized = false}) {
  // Normalize the address if needed
  final normalizedAddress = isNormalized ? {...address} : normalizeAddress(address);

  // Return early if empty address
  if (normalizedAddress.isEmpty) {
    return normalizedAddress;
  }

  // Get country data
  final countryCode = normalizedAddress['country_code']?.toUpperCase();
  if (countryCode == null || countryCode.isEmpty) {
    return normalizedAddress;
  }

  final results = loadCountryData(countryCode);
  final database = results.database;

  final cleanedData = <String, String>{...normalizedAddress};

  // Process country area
  final countryArea = normalizedAddress['country_area'];
  if (countryArea != null && countryArea.isNotEmpty) {
    final key = '$countryCode/$countryArea';
    final countryAreaData = database[key] as Map<String, dynamic>?;

    if (countryAreaData != null) {
      // Get the latinized name, or use the standard name, or keep the original
      cleanedData['country_area'] = countryAreaData['lname'] as String? ??
          countryAreaData['name'] as String? ??
          countryArea;

      // Process city
      final city = normalizedAddress['city'];
      if (city != null && city.isNotEmpty) {
        final cityKey = '$key/$city';
        final cityData = database[cityKey] as Map<String, dynamic>?;

        if (cityData != null) {
          // Get the latinized name, or use the standard name, or keep the original
          cleanedData['city'] =
              cityData['lname'] as String? ?? cityData['name'] as String? ?? city;

          // Process city area
          final cityArea = normalizedAddress['city_area'];
          if (cityArea != null && cityArea.isNotEmpty) {
            final cityAreaKey = '$cityKey/$cityArea';
            final cityAreaData = database[cityAreaKey] as Map<String, dynamic>?;

            if (cityAreaData != null) {
              // Get the latinized name, or use the standard name, or keep the original
              cleanedData['city_area'] = cityAreaData['lname'] as String? ??
                  cityAreaData['name'] as String? ??
                  cityArea;
            }
          }
        }
      }
    }
  }

  // Ensure sorting_code exists (for compatibility with the Python version)
  if (!cleanedData.containsKey('sorting_code')) {
    cleanedData['sorting_code'] = '';
  }

  return cleanedData;
}

import 'package:google_i18n_address/google_i18n_address.dart';

import 'data_loader.dart';

/// Latinizes an address.
///
/// Converts address fields to their Latin equivalent where possible.
/// If [isNormalized] is true, assumes the address is already normalized.
Map<AddressField, String> latinizeAddress(
  Map<AddressField, String> address, {
  bool isNormalized = false,
}) {
  // Normalize the address if needed
  final normalizedAddress = isNormalized ? {...address} : normalizeAddress(address);

  // Return early if empty address
  if (normalizedAddress.isEmpty) {
    return normalizedAddress;
  }

  // Get country data
  final countryCode = normalizedAddress[AddressField.countryCode]?.toUpperCase();
  if (countryCode == null || countryCode.isEmpty) {
    return normalizedAddress;
  }

  final results = loadCountryData(countryCode);
  final database = results.database;

  final cleanedData = <AddressField, String>{...normalizedAddress};

  // Process country area
  final countryArea = normalizedAddress[AddressField.countryArea];
  if (countryArea != null && countryArea.isNotEmpty) {
    final key = '$countryCode/$countryArea';
    final countryAreaData = database[key] as Map<String, dynamic>?;

    if (countryAreaData != null) {
      // Get the latinized name, or use the standard name, or keep the original
      cleanedData[AddressField.countryArea] =
          countryAreaData['lname'] as String? ??
          countryAreaData['name'] as String? ??
          countryArea;

      // Process city
      final city = normalizedAddress[AddressField.city];
      if (city != null && city.isNotEmpty) {
        final cityKey = '$key/$city';
        final cityData = database[cityKey] as Map<String, dynamic>?;

        if (cityData != null) {
          // Get the latinized name, or use the standard name, or keep the original
          cleanedData[AddressField.city] =
              cityData['lname'] as String? ?? cityData['name'] as String? ?? city;

          // Process city area
          final cityArea = normalizedAddress[AddressField.cityArea];
          if (cityArea != null && cityArea.isNotEmpty) {
            final cityAreaKey = '$cityKey/$cityArea';
            final cityAreaData = database[cityAreaKey] as Map<String, dynamic>?;

            if (cityAreaData != null) {
              // Get the latinized name, or use the standard name, or keep the original
              cleanedData[AddressField.cityArea] =
                  cityAreaData['lname'] as String? ??
                  cityAreaData['name'] as String? ??
                  cityArea;
            }
          }
        }
      }
    }
  }

  // Ensure sortingCode exists (for compatibility with the Python version)
  if (!cleanedData.containsKey(AddressField.sortingCode)) {
    cleanedData[AddressField.sortingCode] = '';
  }

  return cleanedData;
}

import 'data_loader.dart';
import 'validation.dart';

/// Latinizes an address.
///
/// Converts address fields to their Latin equivalent where possible.
/// If [isNormalized] is true, assumes the address is already normalized.
///
///
///
// def latinize_address(address, normalized=False):
//     if not normalized:
//         address = normalize_address(address)
//     cleaned_data = address.copy()
//     country_code = address.get("country_code", "").upper()
//     dummy_country_data, database = _load_country_data(country_code)
//     if country_code:
//         country_area = address["country_area"]
//         if country_area:
//             key = f"{country_code}/{country_area}"
//             country_area_data = database.get(key)
//             if country_area_data:
//                 cleaned_data["country_area"] = country_area_data.get(
//                     "lname", country_area_data.get("name", country_area)
//                 )
//                 city = address["city"]
//                 key = f"{country_code}/{country_area}/{city}"
//                 city_data = database.get(key)
//                 if city_data:
//                     cleaned_data["city"] = city_data.get(
//                         "lname", city_data.get("name", city)
//                     )
//                     city_area = address["city_area"]
//                     key = f"{country_code}/{country_area}/{city}/{city_area}"
//                     city_area_data = database.get(key)
//                     if city_area_data:
//                         cleaned_data["city_area"] = city_area_data.get(
//                             "lname", city_area_data.get("name", city_area)
//                         )
//     return cleaned_data
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

import 'data_loader.dart';
import 'models.dart';

/// Gets validation rules for an address.
///
/// The address should at least have a country_code field.
ValidationRules getValidationRules(Map<String, String> address) {
  final countryCode = address['country_code']?.toUpperCase() ?? '';
  final (countryData: countryData, database: database) = loadCountryData(countryCode);

  final countryName = countryData['name'] ?? '';
  final addressFormat = countryData['fmt'] as String;
  final addressLatinFormat = countryData['lfmt'] ?? addressFormat;

  // Parse format fields to determine allowed fields
  final formatFields = RegExp(r'%([ACDNOSXZ])').allMatches(addressFormat);
  final allowedFields = <String>{
    for (final match in formatFields) fieldMapping[match.group(1)!]!
  };

  // Get required fields
  final requiredFieldsStr = countryData['require'] ?? '';
  final requiredFields = <String>{
    for (final char in requiredFieldsStr.split('')) fieldMapping[char]!
  };

  // Get upper fields
  final upperFieldsStr = countryData['upper'] ?? '';
  final upperFields = <String>{
    for (final char in upperFieldsStr.split('')) fieldMapping[char]!
  };

  // Get languages
  final languages = <String?>[null];
  if (countryData.containsKey('languages')) {
    languages.clear();
    languages.addAll((countryData['languages'] as String).split('~'));
  }

  // Get postal code matchers
  final postalCodeMatchers = <RegExp>[];
  if (allowedFields.contains('postal_code') && countryData.containsKey('zip')) {
    postalCodeMatchers.add(RegExp('^${countryData['zip']}\$'));
  }

  // Get postal code examples
  var postalCodeExamples = <String>[];
  if (countryData.containsKey('zipex')) {
    postalCodeExamples.addAll((countryData['zipex'] as String).split(','));
  }

  // Get field types
  final countryAreaType = countryData['state_name_type'] ?? '';
  final cityType = countryData['locality_name_type'] ?? '';
  final cityAreaType = countryData['sublocality_name_type'] ?? '';
  final postalCodeType = countryData['zip_name_type'] ?? '';
  final postalCodePrefix = countryData['postprefix'] ?? '';

  var countryAreaChoices = <List<String>>[];
  var cityChoices = <List<String>>[];
  var cityAreaChoices = <List<String>>[];

  String? countryArea;
  String? city;
  String? cityArea;

  // Process sub-regions
  if (database.containsKey(countryCode) && countryData.containsKey('sub_keys')) {
    for (final language in languages) {
      final isDefaultLanguage = language == null || language == countryData['lang'];

      Map<String, String> localizedCountryData;
      if (isDefaultLanguage) {
        localizedCountryData = database[countryCode] ?? {};
      } else {
        localizedCountryData = database['$countryCode--$language'] ?? {};
      }

      final localizedCountryAreaChoices = ChoicesMaker.makeChoices(localizedCountryData);
      countryAreaChoices.addAll(localizedCountryAreaChoices);

      final existingChoice = countryArea != null;
      countryArea =
          ChoicesMaker.matchChoices(address['country_area'], localizedCountryAreaChoices);

      if (countryArea != null) {
        // Third level of data is for cities
        Map<String, String> countryAreaData;
        if (isDefaultLanguage) {
          countryAreaData = database['$countryCode/$countryArea'] ?? {};
        } else {
          countryAreaData = database['$countryCode/$countryArea--$language'] ?? {};
        }

        if (!existingChoice) {
          if (countryAreaData.containsKey('zip')) {
            postalCodeMatchers.add(RegExp('^${countryAreaData['zip']}'));
          }
          if (countryAreaData.containsKey('zipex')) {
            postalCodeExamples = (countryAreaData['zipex'] as String).split(',');
          }
        }

        if (countryAreaData.containsKey('sub_keys')) {
          final localizedCityChoices = ChoicesMaker.makeChoices(countryAreaData);
          cityChoices.addAll(localizedCityChoices);

          final existingCityChoice = city != null;
          city = ChoicesMaker.matchChoices(address['city'], localizedCityChoices);

          if (city != null) {
            // Fourth level of data is for city areas
            Map<String, String> cityData;
            if (isDefaultLanguage) {
              cityData = database['$countryCode/$countryArea/$city'] ?? {};
            } else {
              cityData = database['$countryCode/$countryArea/$city--$language'] ?? {};
            }

            if (!existingCityChoice) {
              if (cityData.containsKey('zip')) {
                postalCodeMatchers.add(RegExp('^${cityData['zip']}'));
              }
              if (cityData.containsKey('zipex')) {
                postalCodeExamples = (cityData['zipex'] as String).split(',');
              }
            }

            if (cityData.containsKey('sub_keys')) {
              final localizedCityAreaChoices = ChoicesMaker.makeChoices(cityData);
              cityAreaChoices.addAll(localizedCityAreaChoices);

              final existingCityAreaChoice = cityArea != null;
              cityArea = ChoicesMaker.matchChoices(
                  address['city_area'], localizedCityAreaChoices);

              if (cityArea != null) {
                Map<String, dynamic> cityAreaData;
                if (isDefaultLanguage) {
                  cityAreaData =
                      database['$countryCode/$countryArea/$city/$cityArea'] ?? {};
                } else {
                  cityAreaData =
                      database['$countryCode/$countryArea/$city/$cityArea--$language'] ??
                          {};
                }

                if (!existingCityAreaChoice) {
                  if (cityAreaData.containsKey('zip')) {
                    postalCodeMatchers.add(RegExp('^${cityAreaData['zip']}'));
                  }
                  if (cityAreaData.containsKey('zipex')) {
                    postalCodeExamples = (cityAreaData['zipex'] as String).split(',');
                  }
                }
              }
            }
          }
        }
      }
    }

    countryAreaChoices = ChoicesMaker.compactChoices(countryAreaChoices);
    cityChoices = ChoicesMaker.compactChoices(cityChoices);
    cityAreaChoices = ChoicesMaker.compactChoices(cityAreaChoices);
  }

  return ValidationRules(
    countryCode: countryCode,
    countryName: countryName,
    addressFormat: addressFormat,
    addressLatinFormat: addressLatinFormat,
    allowedFields: allowedFields,
    requiredFields: requiredFields,
    upperFields: upperFields,
    countryAreaType: countryAreaType,
    countryAreaChoices: countryAreaChoices,
    cityType: cityType,
    cityChoices: cityChoices,
    cityAreaType: cityAreaType,
    cityAreaChoices: cityAreaChoices,
    postalCodeType: postalCodeType,
    postalCodeMatchers: postalCodeMatchers,
    postalCodeExamples: postalCodeExamples,
    postalCodePrefix: postalCodePrefix,
  );
}

/// Normalizes a field in an address.
///
/// Updates the cleaned data map and adds any errors to the errors map.
void _normalizeField(String name, ValidationRules rules, Map<String, String> data,
    List<List<String>> choices, Map<String, String> errors) {
  final value = data[name];

  // Handle uppercase fields
  if (rules.upperFields.contains(name) && value != null) {
    data[name] = value.toUpperCase();
  }

  // Handle fields not in allowed fields
  if (!rules.allowedFields.contains(name)) {
    data[name] = '';
  }
  // Handle required fields
  else if (value == null || value.isEmpty) {
    if (rules.requiredFields.contains(name)) {
      errors[name] = 'required';
    }
  }
  // Handle choices
  else if (choices.isNotEmpty) {
    if (value.isNotEmpty || rules.requiredFields.contains(name)) {
      final matchedValue = ChoicesMaker.matchChoices(value, choices);
      if (matchedValue != null) {
        data[name] = matchedValue;
      } else {
        errors[name] = 'invalid';
      }
    }
  }

  // Ensure empty values are represented as empty strings
  if (data[name] == null) {
    data[name] = '';
  }
}

/// Normalizes an address based on country rules.
///
/// Returns a validated and normalized address map.
/// Throws [InvalidAddressError] if validation fails.
Map<String, String> normalizeAddress(Map<String, String> address) {
  final errors = <String, String>{};
  ValidationRules rules;

  try {
    rules = getValidationRules(address);
  } catch (e) {
    errors['country_code'] = 'invalid';
    throw InvalidAddressError('Invalid address', errors);
  }

  final cleanedData = <String, String>{...address};

  // Validate country code
  final countryCode = cleanedData['country_code'];
  if (countryCode == null || countryCode.isEmpty) {
    errors['country_code'] = 'required';
  } else {
    cleanedData['country_code'] = countryCode.toUpperCase();
  }

  // Normalize fields
  _normalizeField('country_area', rules, cleanedData, rules.countryAreaChoices, errors);
  _normalizeField('city', rules, cleanedData, rules.cityChoices, errors);
  _normalizeField('city_area', rules, cleanedData, rules.cityAreaChoices, errors);
  _normalizeField('postal_code', rules, cleanedData, [], errors);

  // Validate postal code format
  final postalCode = cleanedData['postal_code'] ?? '';
  if (rules.postalCodeMatchers.isNotEmpty && postalCode.isNotEmpty) {
    for (final matcher in rules.postalCodeMatchers) {
      if (!matcher.hasMatch(postalCode)) {
        errors['postal_code'] = 'invalid';
        break;
      }
    }
  }

  _normalizeField('street_address', rules, cleanedData, [], errors);
  _normalizeField('sorting_code', rules, cleanedData, [], errors);

  if (errors.isNotEmpty) {
    throw InvalidAddressError('Invalid address', errors);
  }

  return cleanedData;
}

/// Gets the expected field order for an address form.
///
/// Returns a list of lists, where each inner list represents a line
/// in the address format. This can be used to build form layouts.
List<List<String>> getFieldOrder(Map<String, String> address, {bool latin = false}) {
  final rules = getValidationRules(address);
  final addressFormat = latin ? rules.addressLatinFormat : rules.addressFormat;
  final addressLines = addressFormat.split('%n');

  final replacements = <String, String>{};
  fieldMapping.forEach((code, fieldName) {
    replacements['%$code'] = fieldName;
  });

  final allLines = [
    for (final line in addressLines)
      [
        ...RegExp(r'(%.)')
            .allMatches(line)
            .map((match) => replacements[match.group(0)])
            .where((field) => field != null)
            .cast<String>()
      ]
  ];

  return allLines;
}

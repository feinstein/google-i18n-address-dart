import 'package:meta/meta.dart';

import 'data_loader.dart';
import 'models.dart';

/// Gets validation rules for an address.
///
/// The address should at least have a country_code field.
ValidationRules getValidationRules(Map<AddressField, String> address) {
  final countryCode = address[AddressField.countryCode]?.toUpperCase() ?? '';
  final (countryData: countryData, database: database) = loadCountryData(countryCode);

  final countryName = countryData['name'] ?? '';
  final addressFormat = countryData['fmt'] as String;
  final addressLatinFormat = countryData['lfmt'] ?? addressFormat;

  // Parse format fields to determine allowed fields
  final allowedFields = parseFormatFields(addressFormat);

  // Get required fields
  final requiredFields = parseRequiredFields(countryData['require'] ?? '');

  // Get upper fields
  final upperFields = parseUpperFields(countryData['upper'] ?? '');

  // Get languages
  final languages = <String?>[null];
  if (countryData.containsKey('languages')) {
    languages.clear();
    languages.addAll((countryData['languages'] as String).split('~'));
  }

  // Get postal code matchers
  final postalCodeMatchers = <RegExp>[];
  if (allowedFields.contains(AddressField.postalCode) && countryData.containsKey('zip')) {
    postalCodeMatchers.add(RegExp('^${countryData['zip']}\$'));
  }

  // Get postal code examples
  var postalCodeExamples = <String>[];
  if (countryData.containsKey('zipex')) {
    postalCodeExamples.addAll((countryData['zipex'] as String).split(','));
  }

  // Get field types
  final countryAreaType = countryAreaTypeFromString(countryData['state_name_type']);
  final cityType = cityTypeFromString(countryData['locality_name_type']);
  final cityAreaType = cityAreaTypeFromString(countryData['sublocality_name_type']);
  final postalCodeType = postalCodeTypeFromString(countryData['zip_name_type']);
  final postalCodePrefix = countryData['postprefix'] ?? '';

  var countryAreaChoices = <({String code, String name})>[];
  var cityChoices = <({String code, String name})>[];
  var cityAreaChoices = <({String code, String name})>[];

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

      final localizedCountryAreaChoices = makeChoices(localizedCountryData);
      countryAreaChoices.addAll(localizedCountryAreaChoices);

      final existingChoice = countryArea != null;
      countryArea = matchChoices(
        address[AddressField.countryArea],
        localizedCountryAreaChoices,
      );

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
          final localizedCityChoices = makeChoices(countryAreaData);
          cityChoices.addAll(localizedCityChoices);

          final existingCityChoice = city != null;
          city = matchChoices(address[AddressField.city], localizedCityChoices);

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
              final localizedCityAreaChoices = makeChoices(cityData);
              cityAreaChoices.addAll(localizedCityAreaChoices);

              final existingCityAreaChoice = cityArea != null;
              cityArea = matchChoices(
                address[AddressField.cityArea],
                localizedCityAreaChoices,
              );

              if (cityArea != null) {
                final Map<String, dynamic> cityAreaData;
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

    countryAreaChoices = compactChoices(countryAreaChoices);
    cityChoices = compactChoices(cityChoices);
    cityAreaChoices = compactChoices(cityAreaChoices);
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
void _normalizeField(
  AddressField field,
  ValidationRules rules,
  Map<AddressField, String> data,
  List<({String code, String name})> choices,
  Map<AddressField, String> errors,
) {
  final value = data[field];

  // Handle uppercase fields
  if (rules.upperFields.contains(field) && value != null) {
    data[field] = value.toUpperCase();
  }

  // Handle fields not in allowed fields
  if (!rules.allowedFields.contains(field)) {
    data[field] = '';
  }
  // Handle required fields
  else if (value == null || value.isEmpty) {
    if (rules.requiredFields.contains(field)) {
      errors[field] = 'required';
    }
  }
  // Handle choices
  else if (choices.isNotEmpty) {
    if (value.isNotEmpty || rules.requiredFields.contains(field)) {
      final matchedValue = matchChoices(value, choices);
      if (matchedValue != null) {
        data[field] = matchedValue;
      } else {
        errors[field] = 'invalid';
      }
    }
  }

  // Ensure empty values are represented as empty strings
  if (data[field] == null) {
    data[field] = '';
  }
}

/// Normalizes an address based on country rules.
///
/// Returns a validated and normalized address map.
/// Throws [InvalidAddressError] if validation fails.
Map<AddressField, String> normalizeAddress(Map<AddressField, String> address) {
  final errors = <AddressField, String>{};
  ValidationRules rules;

  try {
    rules = getValidationRules(address);
  } catch (e) {
    errors[AddressField.countryCode] = 'invalid';
    throw InvalidAddressError('Invalid address', errors);
  }

  final cleanedData = <AddressField, String>{...address};

  // Validate country code
  final countryCode = cleanedData[AddressField.countryCode];
  if (countryCode == null || countryCode.isEmpty) {
    errors[AddressField.countryCode] = 'required';
  } else {
    cleanedData[AddressField.countryCode] = countryCode.toUpperCase();
  }

  // Normalize fields
  _normalizeField(
    AddressField.countryArea,
    rules,
    cleanedData,
    rules.countryAreaChoices,
    errors,
  );
  _normalizeField(AddressField.city, rules, cleanedData, rules.cityChoices, errors);
  _normalizeField(
    AddressField.cityArea,
    rules,
    cleanedData,
    rules.cityAreaChoices,
    errors,
  );
  _normalizeField(AddressField.postalCode, rules, cleanedData, [], errors);

  // Validate postal code format
  final postalCode = cleanedData[AddressField.postalCode] ?? '';
  if (rules.postalCodeMatchers.isNotEmpty && postalCode.isNotEmpty) {
    for (final matcher in rules.postalCodeMatchers) {
      if (!matcher.hasMatch(postalCode)) {
        errors[AddressField.postalCode] = 'invalid';
        break;
      }
    }
  }

  _normalizeField(AddressField.streetAddress, rules, cleanedData, [], errors);
  _normalizeField(AddressField.sortingCode, rules, cleanedData, [], errors);

  if (errors.isNotEmpty) {
    throw InvalidAddressError('Invalid address', errors);
  }

  return cleanedData;
}

/// Gets the expected field order for an address form.
///
/// Returns a list of lists, where each inner list represents a line
/// in the address format. This can be used to build form layouts.
List<List<AddressField>> getFieldOrder(
  Map<AddressField, String> address, {
  bool latin = false,
}) {
  final rules = getValidationRules(address);
  final addressFormat = latin ? rules.addressLatinFormat : rules.addressFormat;
  final addressLines = addressFormat.split('%n');

  final allLines = [
    for (final line in addressLines)
      [
        ...RegExp(r'(%.)')
            .allMatches(line)
            .map((match) => addressFieldFromCode(match.group(1)![1]))
            .nonNulls,
      ],
  ];

  return allLines;
}

final _formatFieldRegExp = RegExp(r'%([ACDNOSXZ])');

@visibleForTesting
Set<AddressField> parseFormatFields(String format) {
  final formatFields = _formatFieldRegExp.allMatches(format);
  return {for (final match in formatFields) addressFieldFromCode(match.group(1)!)};
}

@visibleForTesting
Set<AddressField> parseRequiredFields(String requiredFieldsStr) {
  return {for (final char in requiredFieldsStr.split('')) addressFieldFromCode(char)};
}

@visibleForTesting
Set<AddressField> parseUpperFields(String upperFieldsStr) {
  return {for (final char in upperFieldsStr.split('')) addressFieldFromCode(char)};
}

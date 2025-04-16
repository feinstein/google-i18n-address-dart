import 'package:meta/meta.dart';

/// Set of all known address fields.
final Set<String> knownFields = {
  'country_code',
  'country_area',
  'city',
  'city_area',
  'street_address',
  'postal_code',
  'sorting_code',
  'name',
  'company_name',
};

/// Mapping of format codes to field names.
final Map<String, String> fieldMapping = {
  'A': 'street_address',
  'C': 'city',
  'D': 'city_area',
  'N': 'name',
  'O': 'company_name',
  'S': 'country_area',
  'X': 'sorting_code',
  'Z': 'postal_code',
};

/// Address validation rules for a specific country or region.
@immutable
class ValidationRules {
  /// ISO 3166-1 country code.
  final String countryCode;

  /// Country name.
  final String countryName;

  /// Format string for addresses (local format).
  final String addressFormat;

  /// Format string for addresses (latin format).
  final String addressLatinFormat;

  /// Set of allowed address fields.
  final Set<String> allowedFields;

  /// Set of required address fields.
  final Set<String> requiredFields;

  /// Set of fields that should be uppercase.
  final Set<String> upperFields;

  /// Type of country area (e.g., "state", "province").
  final String countryAreaType;

  /// List of available country areas as (code, name) pairs.
  final List<List<String>> countryAreaChoices;

  /// Type of city (e.g., "city", "town").
  final String cityType;

  /// List of available cities as (code, name) pairs.
  final List<List<String>> cityChoices;

  /// Type of city area (e.g., "district", "suburb").
  final String cityAreaType;

  /// List of available city areas as (code, name) pairs.
  final List<List<String>> cityAreaChoices;

  /// Type of postal code (e.g., "zip", "postal").
  final String postalCodeType;

  /// Regular expressions for matching postal codes.
  final List<RegExp> postalCodeMatchers;

  /// Example postal codes.
  final List<String> postalCodeExamples;

  /// Postal code prefix.
  final String postalCodePrefix;

  /// Creates a new validation rules instance.
  const ValidationRules({
    required this.countryCode,
    required this.countryName,
    required this.addressFormat,
    required this.addressLatinFormat,
    required this.allowedFields,
    required this.requiredFields,
    required this.upperFields,
    required this.countryAreaType,
    required this.countryAreaChoices,
    required this.cityType,
    required this.cityChoices,
    required this.cityAreaType,
    required this.cityAreaChoices,
    required this.postalCodeType,
    required this.postalCodeMatchers,
    required this.postalCodeExamples,
    required this.postalCodePrefix,
  });

  @override
  String toString() {
    return 'ValidationRules('
        'countryCode: $countryCode, '
        'countryName: $countryName, '
        'addressFormat: $addressFormat, '
        'addressLatinFormat: $addressLatinFormat, '
        'allowedFields: $allowedFields, '
        'requiredFields: $requiredFields, '
        'upperFields: $upperFields, '
        'countryAreaType: $countryAreaType, '
        'countryAreaChoices: $countryAreaChoices, '
        'cityType: $cityType, '
        'cityChoices: $cityChoices, '
        'cityAreaType: $cityAreaType, '
        'cityAreaChoices: $cityAreaChoices, '
        'postalCodeType: $postalCodeType, '
        'postalCodeMatchers: $postalCodeMatchers, '
        'postalCodeExamples: $postalCodeExamples, '
        'postalCodePrefix: $postalCodePrefix)';
  }
}

/// Exception thrown when an address validation fails.
class InvalidAddressError implements Exception {
  /// Error message.
  final String message;

  /// Map of field names to error codes.
  final Map<String, String> errors;

  /// Creates a new invalid address error.
  InvalidAddressError(this.message, this.errors);

  @override
  String toString() => 'InvalidAddressError: $message';
}

/// Helper class to make choices from address data
class ChoicesMaker {
  /// Make choices from address rules
  static List<List<String>> makeChoices(Map<String, dynamic> rules,
      {bool translated = false}) {
    final subKeys = rules['sub_keys'];
    if (subKeys == null) {
      return [];
    }

    final choices = <List<String>>[];
    final subKeysList = subKeys.split('~');
    final subNames = rules['sub_names'];

    if (subNames != null) {
      final subNamesList = subNames.split('~');
      for (int i = 0; i < subKeysList.length && i < subNamesList.length; i++) {
        if (subNamesList[i].isNotEmpty) {
          choices.add([subKeysList[i], subNamesList[i]]);
        }
      }
    } else if (!translated) {
      for (final key in subKeysList) {
        choices.add([key, key]);
      }
    }

    if (!translated) {
      final subLNames = rules['sub_lnames'];
      if (subLNames != null) {
        final subLNamesList = subLNames.split('~');
        for (int i = 0; i < subKeysList.length && i < subLNamesList.length; i++) {
          if (subLNamesList[i].isNotEmpty) {
            choices.add([subKeysList[i], subLNamesList[i]]);
          }
        }
      }

      final subLFNames = rules['sub_lfnames'];
      if (subLFNames != null) {
        final subLFNamesList = subLFNames.split('~');
        for (int i = 0; i < subKeysList.length && i < subLFNamesList.length; i++) {
          if (subLFNamesList[i].isNotEmpty) {
            choices.add([subKeysList[i], subLFNamesList[i]]);
          }
        }
      }
    }

    return choices;
  }

  /// Compact choices to avoid duplicates
  static List<List<String>> compactChoices(List<List<String>> choices) {
    final valueMap = <String, Set<String>>{};

    for (final choice in choices) {
      final key = choice[0];
      final value = choice[1];
      valueMap.putIfAbsent(key, () => <String>{}).add(value);
    }

    final result = <List<String>>[];
    for (final entry in valueMap.entries) {
      for (final value in entry.value.toList()..sort()) {
        result.add([entry.key, value]);
      }
    }

    return result;
  }

  /// Match a value against a list of choices
  static String? matchChoices(String? value, List<List<String>> choices) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final normalizedValue = value.trim().toLowerCase();

    for (final choice in choices) {
      final name = choice[0];
      final label = choice[1];

      if (name.toLowerCase() == normalizedValue) {
        return name;
      }

      if (label.toLowerCase() == normalizedValue) {
        return name;
      }
    }

    return null;
  }
}

import 'package:meta/meta.dart';

/// Enum representing address fields.
enum AddressField {
  countryCode,
  streetAddress,
  city,
  cityArea,
  name,
  companyName,
  countryArea,
  sortingCode,
  postalCode,
}

/// Get an address field by its code
AddressField addressFieldFromCode(String code) {
  return switch (code) {
    'A' => AddressField.streetAddress,
    'C' => AddressField.city,
    'D' => AddressField.cityArea,
    'N' => AddressField.name,
    'O' => AddressField.companyName,
    'S' => AddressField.countryArea,
    'X' => AddressField.sortingCode,
    'Z' => AddressField.postalCode,
    _ => throw ArgumentError('Invalid field code: $code'),
  };
}

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
  final Set<AddressField> allowedFields;

  /// Set of required address fields.
  final Set<AddressField> requiredFields;

  /// Set of fields that should be uppercase.
  final Set<AddressField> upperFields;

  /// Type of country area (e.g., "state", "province").
  final String countryAreaType;

  /// List of available country areas as (code, name) pairs.
  final List<({String code, String name})> countryAreaChoices;

  /// Type of city (e.g., "city", "town").
  final String cityType;

  /// List of available cities as (code, name) pairs.
  /// Be aware that many cities have the "code" as their native names and the "name" as their latin names
  // TODO(mfeinstein): [23/04/2025] Review this structure as many cities have the "code" as their native names and the "name" as their latin names
  final List<({String code, String name})> cityChoices;

  /// Type of city area (e.g., "district", "suburb").
  final String cityAreaType;

  /// List of available city areas as (code, name) pairs.
  final List<({String code, String name})> cityAreaChoices;

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
  final Map<AddressField, String> errors;

  /// Creates a new invalid address error.
  InvalidAddressError(this.message, this.errors);

  @override
  String toString() => 'InvalidAddressError: $message';
}

/// Make choices from address rules
List<({String code, String name})> makeChoices(
  Map<String, String> rules, {
  bool translated = false,
}) {
  final subKeys = rules['sub_keys'];
  if (subKeys == null) {
    return [];
  }

  final choices = <({String code, String name})>[];
  final subKeysList = subKeys.split('~');
  final subNames = rules['sub_names'];

  if (subNames != null) {
    final subNamesList = subNames.split('~');
    for (int i = 0; i < subKeysList.length && i < subNamesList.length; i++) {
      if (subNamesList[i].isNotEmpty) {
        choices.add((code: subKeysList[i], name: subNamesList[i]));
      }
    }
  } else if (!translated) {
    for (final key in subKeysList) {
      choices.add((code: key, name: key));
    }
  }

  if (!translated) {
    final subLNames = rules['sub_lnames'];
    if (subLNames != null) {
      final subLNamesList = subLNames.split('~');
      for (int i = 0; i < subKeysList.length && i < subLNamesList.length; i++) {
        if (subLNamesList[i].isNotEmpty) {
          choices.add((code: subKeysList[i], name: subLNamesList[i]));
        }
      }
    }

    final subLFNames = rules['sub_lfnames'];
    if (subLFNames != null) {
      final subLFNamesList = subLFNames.split('~');
      for (int i = 0; i < subKeysList.length && i < subLFNamesList.length; i++) {
        if (subLFNamesList[i].isNotEmpty) {
          choices.add((code: subKeysList[i], name: subLFNamesList[i]));
        }
      }
    }
  }

  return choices;
}

/// Compact choices to avoid duplicates
List<({String code, String name})> compactChoices(
  List<({String code, String name})> choices,
) {
  final valueMap = <String, Set<String>>{};

  for (final choice in choices) {
    final code = choice.code;
    final name = choice.name;
    valueMap.putIfAbsent(code, () => <String>{}).add(name);
  }

  final result = <({String code, String name})>[
    for (final entry in valueMap.entries)
      for (final value in entry.value.toList()..sort()) (code: entry.key, name: value),
  ];
  return result;
}

/// Match a value against a list of choices returning the code of the matched choice
String? matchChoices(String? value, List<({String code, String name})> choices) {
  if (value == null || value.isEmpty) {
    return null;
  }

  final normalizedValue = value.trim().toLowerCase();

  for (final choice in choices) {
    final code = choice.code;
    final name = choice.name;

    if (code.toLowerCase() == normalizedValue) {
      return code;
    }

    if (name.toLowerCase() == normalizedValue) {
      return code;
    }
  }

  return null;
}

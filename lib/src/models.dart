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

/// Enum for country area types
enum CountryAreaType {
  area,
  county,
  department,
  district,
  doOrSi, // Specific to South Korea
  emirate,
  island,
  oblast,
  parish,
  prefecture,
  province,
  state,
}

CountryAreaType countryAreaTypeFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'area':
      return CountryAreaType.area;
    case 'county':
      return CountryAreaType.county;
    case 'department':
      return CountryAreaType.department;
    case 'district':
      return CountryAreaType.district;
    case 'do_si':
      return CountryAreaType.doOrSi;
    case 'emirate':
      return CountryAreaType.emirate;
    case 'island':
      return CountryAreaType.island;
    case 'oblast':
      return CountryAreaType.oblast;
    case 'parish':
      return CountryAreaType.parish;
    case 'prefecture':
      return CountryAreaType.prefecture;
    case 'province':
      return CountryAreaType.province;
    case 'state':
      return CountryAreaType.state;
    default:
      throw ArgumentError('Invalid country area type: $value');
  }
}

/// Enum for city types
enum CityType { city, district, postTown, suburb }

CityType cityTypeFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'city':
      return CityType.city;
    case 'district':
      return CityType.district;
    case 'post_town':
      return CityType.postTown;
    case 'suburb':
      return CityType.suburb;
    default:
      throw ArgumentError('Invalid city type: $value');
  }
}

/// Enum for city area types
enum CityAreaType { district, neighborhood, suburb, townland, villageOrTownship }

CityAreaType cityAreaTypeFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'district':
      return CityAreaType.district;
    case 'neighborhood':
      return CityAreaType.neighborhood;
    case 'suburb':
      return CityAreaType.suburb;
    case 'townland':
      return CityAreaType.townland;
    case 'village_township':
      return CityAreaType.villageOrTownship;
    default:
      throw ArgumentError('Invalid city area type: $value');
  }
}

/// Enum for postal code types
enum PostalCodeType { eircode, pin, postal, zip }

PostalCodeType postalCodeTypeFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'eircode':
      return PostalCodeType.eircode;
    case 'pin':
      return PostalCodeType.pin;
    case 'postal':
      return PostalCodeType.postal;
    case 'zip':
      return PostalCodeType.zip;
    default:
      throw ArgumentError('Invalid postal code type: $value');
  }
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
  final CountryAreaType countryAreaType;

  /// List of available country areas as (code, name) pairs.
  final List<({String code, String name})> countryAreaChoices;

  /// Type of city (e.g., "city", "town").
  final CityType cityType;

  /// List of available cities as (code, name) pairs.
  /// Be aware that many cities have the "code" as their native names and the "name" as their latin names
  // TODO(mfeinstein): [23/04/2025] Review this structure as many cities have the "code" as their native names and the "name" as their latin names
  final List<({String code, String name})> cityChoices;

  /// Type of city area (e.g., "district", "suburb").
  final CityAreaType cityAreaType;

  /// List of available city areas as (code, name) pairs.
  final List<({String code, String name})> cityAreaChoices;

  /// Type of postal code (e.g., "zip", "postal").
  final PostalCodeType postalCodeType;

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

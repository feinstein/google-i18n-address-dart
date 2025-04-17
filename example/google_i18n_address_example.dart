// ignore_for_file: avoid_print

import 'package:google_i18n_address/google_i18n_address.dart';

void main() {
  // Example 1: Validating an address
  print('Example 1: Validating an address');
  try {
    final address = normalizeAddress({
      'country_code': 'US',
      'country_area': 'California',
      'city': 'Mountain View',
      'postal_code': '94043',
      'street_address': '1600 Amphitheatre Pkwy'
    });
    print('Normalized address: $address');
  } on InvalidAddressError catch (e) {
    print('Validation error: ${e.errors}');
  }
  print('');

  // Example 2: Validating an invalid address
  print('Example 2: Validating an invalid address');
  try {
    final address = normalizeAddress({
      'country_code': 'US',
      'country_area': 'California',
      'city': 'Mountain View',
      'postal_code': '74043', // Invalid postal code for California
      'street_address': '1600 Amphitheatre Pkwy'
    });
    print('Normalized address: $address');
  } on InvalidAddressError catch (e) {
    print('Validation error: ${e.errors}');
  }
  print('');

  // Example 3: Getting validation rules
  print('Example 3: Getting validation rules');
  final rules = getValidationRules({'country_code': 'US', 'country_area': 'CA'});
  print('Required fields: ${rules.requiredFields}');
  print('Postal code examples: ${rules.postalCodeExamples}');
  print('');

  // Example 4: Latinizing an address
  print('Example 4: Latinizing an address');
  final chineseAddress = {
    'country_code': 'CN',
    'country_area': '云南省',
    'postal_code': '677400',
    'city': '临沧市',
    'city_area': '凤庆县',
    'street_address': '中关村东路1号'
  };
  final latinized = latinizeAddress(chineseAddress);
  print('Original: $chineseAddress');
  print('Latinized: $latinized');
  print('');

  // Example 5: Formatting an address
  print('Example 5: Formatting an address');
  final usAddress = {
    'name': 'John Doe',
    'company_name': 'Example Corp',
    'country_code': 'US',
    'country_area': 'CA',
    'postal_code': '94043',
    'city': 'Mountain View',
    'street_address': '1600 Amphitheatre Pkwy'
  };
  print('Formatted address:');
  print(formatAddress(usAddress));
  print('');

  // Example 6: Getting field order
  print('Example 6: Getting field order');
  final fieldOrder = getFieldOrder({'country_code': 'PL'});
  print('Field order for Poland: $fieldOrder');
  print('');
}

// ignore_for_file: avoid_print

import 'package:google_i18n_address/google_i18n_address.dart';

void main() {
  // Example 1: Validating an address
  print('Example 1: Validating an address');
  try {
    final address = normalizeAddress({
      AddressField.countryCode: 'US',
      AddressField.countryArea: 'California',
      AddressField.city: 'Mountain View',
      AddressField.postalCode: '94043',
      AddressField.streetAddress: '1600 Amphitheatre Pkwy'
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
      AddressField.countryCode: 'US',
      AddressField.countryArea: 'California',
      AddressField.city: 'Mountain View',
      AddressField.postalCode: '74043', // Invalid postal code for California
      AddressField.streetAddress: '1600 Amphitheatre Pkwy'
    });
    print('Normalized address: $address');
  } on InvalidAddressError catch (e) {
    print('Validation error: ${e.errors}');
  }
  print('');

  // Example 3: Getting validation rules
  print('Example 3: Getting validation rules');
  final rules = getValidationRules(
      {AddressField.countryCode: 'US', AddressField.countryArea: 'CA'});
  print('Required fields: ${rules.requiredFields}');
  print('Postal code examples: ${rules.postalCodeExamples}');
  print('');

  // Example 4: Latinizing an address
  print('Example 4: Latinizing an address');
  final chineseAddress = {
    AddressField.countryCode: 'CN',
    AddressField.countryArea: '云南省',
    AddressField.postalCode: '677400',
    AddressField.city: '临沧市',
    AddressField.cityArea: '凤庆县',
    AddressField.streetAddress: '中关村东路1号'
  };
  final latinized = latinizeAddress(chineseAddress);
  print('Original: $chineseAddress');
  print('Latinized: $latinized');
  print('');

  // Example 5: Formatting an address
  print('Example 5: Formatting an address');
  final usAddress = {
    AddressField.name: 'John Doe',
    AddressField.companyName: 'Example Corp',
    AddressField.countryCode: 'US',
    AddressField.countryArea: 'CA',
    AddressField.postalCode: '94043',
    AddressField.city: 'Mountain View',
    AddressField.streetAddress: '1600 Amphitheatre Pkwy'
  };
  print('Formatted address:');
  print(formatAddress(usAddress));
  print('');

  // Example 6: Getting field order
  print('Example 6: Getting field order');
  final fieldOrder = getFieldOrder({AddressField.countryCode: 'PL'});
  print('Field order for Poland: $fieldOrder');
  print('');
}

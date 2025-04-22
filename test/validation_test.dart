import 'package:google_i18n_address/google_i18n_address.dart';
import 'package:test/test.dart';

void main() {
  group('ValidationRules', () {
    test('getValidationRules returns correct data for Canada', () {
      final validationRules = getValidationRules({'country_code': 'CA'});

      expect(validationRules.countryCode, 'CA');

      // Test that country area choices include both English and French names
      expect(
        validationRules.countryAreaChoices,
        containsAll([
          ['AB', 'Alberta'],
          ['QC', 'Quebec'],
          ['QC', 'Québec'],
        ]),
      );
    });

    test('getValidationRules returns correct data for Switzerland', () {
      final validationRules = getValidationRules({'country_code': 'CH'});

      expect(
          validationRules.allowedFields,
          containsAll([
            AddressField.companyName,
            AddressField.city,
            AddressField.postalCode,
            AddressField.streetAddress,
            AddressField.name,
          ]));

      expect(
          validationRules.requiredFields,
          containsAll([
            AddressField.city,
            AddressField.postalCode,
            AddressField.streetAddress,
          ]));
    });
  });

  group('normalizeAddress', () {
    test('throws InvalidAddressError on empty address', () {
      expect(
        () => normalizeAddress({}),
        throwsA(isA<InvalidAddressError>()),
      );
    });

    test('throws InvalidAddressError with missing fields for Argentina', () {
      expect(
        () => normalizeAddress({'country_code': 'AR'}),
        throwsA(
          predicate((e) =>
              e is InvalidAddressError &&
              e.errors.containsKey('city') &&
              e.errors.containsKey('street_address')),
        ),
      );
    });

    test('throws InvalidAddressError with invalid city for China', () {
      expect(
        () => normalizeAddress({
          'country_code': 'CN',
          'country_area': '北京市',
          'postal_code': '100084',
          'city': 'Invalid',
          'street_address': '...',
        }),
        throwsA(
          predicate((e) =>
              e is InvalidAddressError &&
              e.errors.containsKey('city') &&
              e.errors['city'] == 'invalid'),
        ),
      );
    });

    test('throws InvalidAddressError with invalid postal code for Germany', () {
      expect(
        () => normalizeAddress({
          'country_code': 'DE',
          'city': 'Berlin',
          'postal_code': '77-777',
          'street_address': '...',
        }),
        throwsA(
          predicate((e) =>
              e is InvalidAddressError &&
              e.errors.containsKey('postal_code') &&
              e.errors['postal_code'] == 'invalid'),
        ),
      );
    });

    test('normalizes a valid US address', () {
      final address = normalizeAddress({
        'country_code': 'US',
        'country_area': 'California',
        'city': 'Mountain View',
        'postal_code': '94043',
        'street_address': '1600 Amphitheatre Pkwy',
      });

      expect(address['country_code'], 'US');
      expect(address['country_area'], 'CA');
      expect(address['city'], 'MOUNTAIN VIEW');
      expect(address['postal_code'], '94043');
      expect(address['street_address'], '1600 Amphitheatre Pkwy');
    });

    test('handles address with exact matching postal code', () {
      final address = normalizeAddress({
        'country_code': 'US',
        'country_area': 'California',
        'city': 'Mountain View',
        'postal_code': '94043',
        'street_address': '1600 Amphitheatre Pkwy',
      });

      expect(address['postal_code'], '94043');
    });
  });

  group('getFieldOrder', () {
    test('returns correct field order for Poland', () {
      final fieldOrder = getFieldOrder({'country_code': 'PL'});

      expect(fieldOrder, [
        [AddressField.name],
        [AddressField.companyName],
        [AddressField.streetAddress],
        [AddressField.postalCode, AddressField.city],
      ]);
    });

    test('returns correct field order for China', () {
      final fieldOrder = getFieldOrder({'country_code': 'CN'});

      expect(fieldOrder, [
        [AddressField.postalCode],
        [
          AddressField.countryArea,
          AddressField.city,
          AddressField.cityArea
        ],
        [AddressField.streetAddress],
        [AddressField.companyName],
        [AddressField.name],
      ]);
    });
  });
}

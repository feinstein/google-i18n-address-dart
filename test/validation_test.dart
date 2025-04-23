import 'package:google_i18n_address/google_i18n_address.dart';
import 'package:test/test.dart';

void main() {
  group('ValidationRules', () {
    test('getValidationRules returns correct data for Canada', () {
      final validationRules = getValidationRules({AddressField.countryCode: 'CA'});

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
      final validationRules = getValidationRules({AddressField.countryCode: 'CH'});

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
        () => normalizeAddress({AddressField.countryCode: 'AR'}),
        throwsA(
          predicate((e) =>
              e is InvalidAddressError &&
              e.errors.containsKey(AddressField.city) &&
              e.errors.containsKey(AddressField.streetAddress)),
        ),
      );
    });

    test('throws InvalidAddressError with invalid city for China', () {
      expect(
        () => normalizeAddress({
          AddressField.countryCode: 'CN',
          AddressField.countryArea: '北京市',
          AddressField.postalCode: '100084',
          AddressField.city: 'Invalid',
          AddressField.streetAddress: '...',
        }),
        throwsA(
          predicate((e) =>
              e is InvalidAddressError &&
              e.errors.containsKey(AddressField.city) &&
              e.errors[AddressField.city] == 'invalid'),
        ),
      );
    });

    test('throws InvalidAddressError with invalid postal code for Germany', () {
      expect(
        () => normalizeAddress({
          AddressField.countryCode: 'DE',
          AddressField.city: 'Berlin',
          AddressField.postalCode: '77-777',
          AddressField.streetAddress: '...',
        }),
        throwsA(
          predicate((e) =>
              e is InvalidAddressError &&
              e.errors.containsKey(AddressField.postalCode) &&
              e.errors[AddressField.postalCode] == 'invalid'),
        ),
      );
    });

    test('normalizes a valid US address', () {
      final address = normalizeAddress({
        AddressField.countryCode: 'US',
        AddressField.countryArea: 'California',
        AddressField.city: 'Mountain View',
        AddressField.postalCode: '94043',
        AddressField.streetAddress: '1600 Amphitheatre Pkwy',
      });

      expect(address[AddressField.countryCode], 'US');
      expect(address[AddressField.countryArea], 'CA');
      expect(address[AddressField.city], 'MOUNTAIN VIEW');
      expect(address[AddressField.postalCode], '94043');
      expect(address[AddressField.streetAddress], '1600 Amphitheatre Pkwy');
    });

    test('handles address with exact matching postal code', () {
      final address = normalizeAddress({
        AddressField.countryCode: 'US',
        AddressField.countryArea: 'California',
        AddressField.city: 'Mountain View',
        AddressField.postalCode: '94043',
        AddressField.streetAddress: '1600 Amphitheatre Pkwy',
      });

      expect(address[AddressField.postalCode], '94043');
    });
  });

  group('getFieldOrder', () {
    test('returns correct field order for Poland', () {
      final fieldOrder = getFieldOrder({AddressField.countryCode: 'PL'});

      expect(fieldOrder, [
        [AddressField.name],
        [AddressField.companyName],
        [AddressField.streetAddress],
        [AddressField.postalCode, AddressField.city],
      ]);
    });

    test('returns correct field order for China', () {
      final fieldOrder = getFieldOrder({AddressField.countryCode: 'CN'});

      expect(fieldOrder, [
        [AddressField.postalCode],
        [AddressField.countryArea, AddressField.city, AddressField.cityArea],
        [AddressField.streetAddress],
        [AddressField.companyName],
        [AddressField.name],
      ]);
    });

    test('returns correct field order for Bangladesh', () {
      final fieldOrder = getFieldOrder({AddressField.countryCode: 'BD'});

      expect(fieldOrder, [
        [AddressField.name],
        [AddressField.companyName],
        [AddressField.streetAddress],
        [AddressField.city, AddressField.postalCode],
      ]);
    });

    test('returns correct field order for Saint Pierre and Miquelon', () {
      final fieldOrder = getFieldOrder({AddressField.countryCode: 'PM'});

      expect(fieldOrder, [
        [AddressField.companyName],
        [AddressField.name],
        [AddressField.streetAddress],
        [AddressField.postalCode, AddressField.city, AddressField.sortingCode],
      ]);
    });
  });
}

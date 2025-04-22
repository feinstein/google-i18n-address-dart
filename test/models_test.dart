import 'package:google_i18n_address/src/models.dart';
import 'package:test/test.dart';

void main() {
  group('ValidationRules', () {
    test('creates instance with all required fields', () {
      final rules = ValidationRules(
        countryCode: 'US',
        countryName: 'UNITED STATES',
        addressFormat: '%N%n%O%n%A%n%C, %S %Z',
        addressLatinFormat: '%N%n%O%n%A%n%C, %S %Z',
        allowedFields: {
          AddressField.name,
          AddressField.companyName,
          AddressField.streetAddress,
          AddressField.city,
          AddressField.countryArea,
          AddressField.postalCode,
        },
        requiredFields: {
          AddressField.streetAddress,
          AddressField.city,
          AddressField.countryArea,
          AddressField.postalCode,
        },
        upperFields: {
          AddressField.city,
          AddressField.countryArea,
        },
        countryAreaType: 'state',
        countryAreaChoices: [
          ['CA', 'California'],
          ['NY', 'New York']
        ],
        cityType: 'city',
        cityChoices: [],
        cityAreaType: 'district',
        cityAreaChoices: [],
        postalCodeType: 'zip',
        postalCodeMatchers: [RegExp(r'^\d{5}$'), RegExp(r'^\d{5}-\d{4}$')],
        postalCodeExamples: ['90210', '20500'],
        postalCodePrefix: '',
      );

      expect(rules.countryCode, 'US');
      expect(rules.countryName, 'UNITED STATES');
      expect(rules.addressFormat, '%N%n%O%n%A%n%C, %S %Z');
      expect(rules.addressLatinFormat, '%N%n%O%n%A%n%C, %S %Z');
      expect(rules.allowedFields, contains(AddressField.name));
      expect(rules.requiredFields, contains(AddressField.streetAddress));
      expect(rules.upperFields, contains(AddressField.city));
      expect(rules.countryAreaType, 'state');
      expect(rules.countryAreaChoices, [
        ['CA', 'California'],
        ['NY', 'New York']
      ]);
      expect(rules.cityType, 'city');
      expect(rules.cityChoices, isEmpty);
      expect(rules.cityAreaType, 'district');
      expect(rules.cityAreaChoices, isEmpty);
      expect(rules.postalCodeType, 'zip');
      expect(rules.postalCodeMatchers, hasLength(2));
      expect(rules.postalCodeExamples, ['90210', '20500']);
      expect(rules.postalCodePrefix, '');
    });

    test('toString returns a string representation', () {
      final rules = ValidationRules(
        countryCode: 'US',
        countryName: 'UNITED STATES',
        addressFormat: '%N%n%O%n%A%n%C, %S %Z',
        addressLatinFormat: '%N%n%O%n%A%n%C, %S %Z',
        allowedFields: {AddressField.name, AddressField.companyName},
        requiredFields: {AddressField.streetAddress},
        upperFields: {AddressField.city},
        countryAreaType: 'state',
        countryAreaChoices: [
          ['CA', 'California']
        ],
        cityType: 'city',
        cityChoices: [],
        cityAreaType: 'district',
        cityAreaChoices: [],
        postalCodeType: 'zip',
        postalCodeMatchers: [RegExp(r'^\d{5}$')],
        postalCodeExamples: ['90210'],
        postalCodePrefix: '',
      );

      expect(rules.toString(), contains('ValidationRules'));
      expect(rules.toString(), contains('countryCode: US'));
      expect(rules.toString(), contains('countryName: UNITED STATES'));
    });
  });

  group('InvalidAddressError', () {
    test('creates instance with message and errors', () {
      final error = InvalidAddressError('Invalid address', {'city': 'required'});
      expect(error.message, 'Invalid address');
      expect(error.errors, {'city': 'required'});
    });

    test('toString returns a string representation', () {
      final error = InvalidAddressError('Invalid address', {'city': 'required'});
      expect(error.toString(), 'InvalidAddressError: Invalid address');
    });
  });

  group('ChoicesMaker', () {
    test('makeChoices creates simple choices from rules', () {
      final rules = {
        'sub_keys': 'CA~NY~TX',
        'sub_names': 'California~New York~Texas',
      };

      final choices = ChoicesMaker.makeChoices(rules);

      expect(choices, [
        ['CA', 'California'],
        ['NY', 'New York'],
        ['TX', 'Texas'],
      ]);
    });

    test('makeChoices handles missing sub_names', () {
      final rules = {'sub_keys': 'CA~NY~TX'};

      final choices = ChoicesMaker.makeChoices(rules);

      expect(choices, [
        ['CA', 'CA'],
        ['NY', 'NY'],
        ['TX', 'TX'],
      ]);
    });

    test('makeChoices includes latin names when not translated', () {
      final rules = {
        'sub_keys': 'CA~NY~TX',
        'sub_names': 'California~New York~Texas',
        'sub_lnames': 'Calif~NY~Tex',
      };

      final choices = ChoicesMaker.makeChoices(rules);

      expect(
          choices,
          containsAll([
            ['CA', 'California'],
            ['NY', 'New York'],
            ['TX', 'Texas'],
            ['CA', 'Calif'],
            ['NY', 'NY'],
            ['TX', 'Tex'],
          ]));
    });

    test('makeChoices includes latin full names when not translated', () {
      final rules = {
        'sub_keys': 'CA~NY~TX',
        'sub_names': 'California~New York~Texas',
        'sub_lfnames': 'California State~New York State~Texas State',
      };

      final choices = ChoicesMaker.makeChoices(rules);

      expect(
          choices,
          containsAll([
            ['CA', 'California'],
            ['NY', 'New York'],
            ['TX', 'Texas'],
            ['CA', 'California State'],
            ['NY', 'New York State'],
            ['TX', 'Texas State'],
          ]));
    });

    test('makeChoices skips latin names when translated', () {
      final rules = {
        'sub_keys': 'CA~NY~TX',
        'sub_names': 'California~New York~Texas',
        'sub_lnames': 'Calif~NY~Tex',
        'sub_lfnames': 'California State~New York State~Texas State',
      };

      final choices = ChoicesMaker.makeChoices(rules, translated: true);

      expect(choices, [
        ['CA', 'California'],
        ['NY', 'New York'],
        ['TX', 'Texas'],
      ]);
    });

    test('compactChoices removes duplicates', () {
      final choices = [
        ['CA', 'California'],
        ['CA', 'California'],
        ['NY', 'New York'],
        ['TX', 'Texas'],
        ['TX', 'TX'],
      ];

      final compacted = ChoicesMaker.compactChoices(choices);

      // Expect unique entries (sorted by value within each key)
      expect(compacted, [
        ['CA', 'California'],
        ['NY', 'New York'],
        ['TX', 'TX'],
        ['TX', 'Texas'],
      ]);
    });

    test('matchChoices returns matching key', () {
      final choices = [
        ['CA', 'California'],
        ['NY', 'New York'],
        ['TX', 'Texas'],
      ];

      expect(ChoicesMaker.matchChoices('California', choices), 'CA');
      expect(ChoicesMaker.matchChoices('ca', choices), 'CA');
      expect(ChoicesMaker.matchChoices('New York', choices), 'NY');
      expect(ChoicesMaker.matchChoices('new york', choices), 'NY');
      expect(ChoicesMaker.matchChoices('NY', choices), 'NY');
      expect(ChoicesMaker.matchChoices('TX', choices), 'TX');
    });

    test('matchChoices returns null for no match', () {
      final choices = [
        ['CA', 'California'],
        ['NY', 'New York'],
        ['TX', 'Texas'],
      ];

      expect(ChoicesMaker.matchChoices('Florida', choices), isNull);
      expect(ChoicesMaker.matchChoices('', choices), isNull);
      expect(ChoicesMaker.matchChoices(null, choices), isNull);
    });

    test('matchChoices handles whitespace', () {
      final choices = [
        ['CA', 'California'],
        ['NY', 'New York'],
      ];

      expect(ChoicesMaker.matchChoices(' California ', choices), 'CA');
      expect(ChoicesMaker.matchChoices(' New York ', choices), 'NY');
    });
  });

  group('AddressField', () {
    test('maps format codes to field names', () {
      expect(AddressField.asMap, {
        'A': 'street_address',
        'C': 'city',
        'D': 'city_area',
        'N': 'name',
        'O': 'company_name',
        'S': 'country_area',
        'X': 'sorting_code',
        'Z': 'postal_code',
      });
    });

    test('fromCode returns correct field', () {
      expect(AddressField.fromCode('A'), AddressField.streetAddress);
      expect(AddressField.fromCode('C'), AddressField.city);
      expect(AddressField.fromCode('D'), AddressField.cityArea);
      expect(AddressField.fromCode('N'), AddressField.name);
      expect(AddressField.fromCode('O'), AddressField.companyName);
      expect(AddressField.fromCode('S'), AddressField.countryArea);
      expect(AddressField.fromCode('X'), AddressField.sortingCode);
      expect(AddressField.fromCode('Z'), AddressField.postalCode);
    });

    test('fromCode throws on invalid code', () {
      expect(() => AddressField.fromCode('invalid'), throwsArgumentError);
    });

    test('fieldNameFromCode returns correct field name', () {
      expect(AddressField.fieldNameFromCode('A'), 'street_address');
      expect(AddressField.fieldNameFromCode('C'), 'city');
      expect(AddressField.fieldNameFromCode('D'), 'city_area');
      expect(AddressField.fieldNameFromCode('N'), 'name');
      expect(AddressField.fieldNameFromCode('O'), 'company_name');
      expect(AddressField.fieldNameFromCode('S'), 'country_area');
      expect(AddressField.fieldNameFromCode('X'), 'sorting_code');
      expect(AddressField.fieldNameFromCode('Z'), 'postal_code');
    });

    test('fromFieldName returns correct field', () {
      expect(AddressField.fromFieldName('street_address'), AddressField.streetAddress);
      expect(AddressField.fromFieldName('city'), AddressField.city);
      expect(AddressField.fromFieldName('city_area'), AddressField.cityArea);
      expect(AddressField.fromFieldName('name'), AddressField.name);
      expect(AddressField.fromFieldName('company_name'), AddressField.companyName);
      expect(AddressField.fromFieldName('country_area'), AddressField.countryArea);
      expect(AddressField.fromFieldName('sorting_code'), AddressField.sortingCode);
      expect(AddressField.fromFieldName('postal_code'), AddressField.postalCode);
    });

    test('fromFieldName throws on invalid field name', () {
      expect(() => AddressField.fromFieldName('invalid'), throwsArgumentError);
    });
  });

  group('Constants', () {
    test('knownFields contains all expected fields', () {
      expect(
          knownFields,
          containsAll([
            'country_code',
            'country_area',
            'city',
            'city_area',
            'street_address',
            'postal_code',
            'sorting_code',
            'name',
            'company_name',
          ]));
    });
  });
}

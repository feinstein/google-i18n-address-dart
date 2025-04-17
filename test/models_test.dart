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
          'name',
          'company_name',
          'street_address',
          'city',
          'country_area',
          'postal_code'
        },
        requiredFields: {
          'street_address',
          'city',
          'country_area',
          'postal_code'
        },
        upperFields: {'city', 'country_area'},
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
      expect(rules.allowedFields, contains('name'));
      expect(rules.requiredFields, contains('street_address'));
      expect(rules.upperFields, contains('city'));
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
        allowedFields: {'name', 'company_name'},
        requiredFields: {'street_address'},
        upperFields: {'city'},
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
      final error =
          InvalidAddressError('Invalid address', {'city': 'required'});
      expect(error.message, 'Invalid address');
      expect(error.errors, {'city': 'required'});
    });

    test('toString returns a string representation', () {
      final error =
          InvalidAddressError('Invalid address', {'city': 'required'});
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

    test('fieldMapping maps format codes to field names', () {
      expect(fieldMapping, {
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
  });
}

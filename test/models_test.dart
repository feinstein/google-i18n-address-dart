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
        upperFields: {AddressField.city, AddressField.countryArea},
        countryAreaType: CountryAreaType.state,
        countryAreaChoices: [
          (code: 'CA', name: 'California'),
          (code: 'NY', name: 'New York'),
        ],
        cityType: CityType.city,
        cityChoices: [],
        cityAreaType: CityAreaType.district,
        cityAreaChoices: [],
        postalCodeType: PostalCodeType.zip,
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
      expect(rules.countryAreaType, CountryAreaType.state);
      expect(rules.countryAreaChoices, [
        (code: 'CA', name: 'California'),
        (code: 'NY', name: 'New York'),
      ]);
      expect(rules.cityType, CityType.city);
      expect(rules.cityChoices, isEmpty);
      expect(rules.cityAreaType, CityAreaType.district);
      expect(rules.cityAreaChoices, isEmpty);
      expect(rules.postalCodeType, PostalCodeType.zip);
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
        countryAreaType: CountryAreaType.state,
        countryAreaChoices: [(code: 'CA', name: 'California')],
        cityType: CityType.city,
        cityChoices: [],
        cityAreaType: CityAreaType.district,
        cityAreaChoices: [],
        postalCodeType: PostalCodeType.zip,
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
      final error = InvalidAddressError('Invalid address', {
        AddressField.city: 'required',
      });
      expect(error.message, 'Invalid address');
      expect(error.errors, {AddressField.city: 'required'});
    });

    test('toString returns a string representation', () {
      final error = InvalidAddressError('Invalid address', {
        AddressField.city: 'required',
      });
      expect(error.toString(), 'InvalidAddressError: Invalid address');
    });
  });

  group('ChoicesMaker', () {
    test('makeChoices creates simple choices from rules', () {
      final rules = {'sub_keys': 'CA~NY~TX', 'sub_names': 'California~New York~Texas'};

      final choices = makeChoices(rules);

      expect(choices, [
        (code: 'CA', name: 'California'),
        (code: 'NY', name: 'New York'),
        (code: 'TX', name: 'Texas'),
      ]);
    });

    test('makeChoices handles missing sub_names', () {
      final rules = {'sub_keys': 'CA~NY~TX'};

      final choices = makeChoices(rules);

      expect(choices, [
        (code: 'CA', name: 'CA'),
        (code: 'NY', name: 'NY'),
        (code: 'TX', name: 'TX'),
      ]);
    });

    test('makeChoices includes latin names when not translated', () {
      final rules = {
        'sub_keys': 'CA~NY~TX',
        'sub_names': 'California~New York~Texas',
        'sub_lnames': 'Calif~NY~Tex',
      };

      final choices = makeChoices(rules);

      expect(
        choices,
        containsAll([
          (code: 'CA', name: 'California'),
          (code: 'NY', name: 'New York'),
          (code: 'TX', name: 'Texas'),
          (code: 'CA', name: 'Calif'),
          (code: 'NY', name: 'NY'),
          (code: 'TX', name: 'Tex'),
        ]),
      );
    });

    test('makeChoices includes latin full names when not translated', () {
      final rules = {
        'sub_keys': 'CA~NY~TX',
        'sub_names': 'California~New York~Texas',
        'sub_lfnames': 'California State~New York State~Texas State',
      };

      final choices = makeChoices(rules);

      expect(
        choices,
        containsAll([
          (code: 'CA', name: 'California'),
          (code: 'NY', name: 'New York'),
          (code: 'TX', name: 'Texas'),
          (code: 'CA', name: 'California State'),
          (code: 'NY', name: 'New York State'),
          (code: 'TX', name: 'Texas State'),
        ]),
      );
    });

    test('makeChoices skips latin names when translated', () {
      final rules = {
        'sub_keys': 'CA~NY~TX',
        'sub_names': 'California~New York~Texas',
        'sub_lnames': 'Calif~NY~Tex',
        'sub_lfnames': 'California State~New York State~Texas State',
      };

      final choices = makeChoices(rules, translated: true);

      expect(choices, [
        (code: 'CA', name: 'California'),
        (code: 'NY', name: 'New York'),
        (code: 'TX', name: 'Texas'),
      ]);
    });

    test('compactChoices removes duplicates', () {
      final choices = [
        (code: 'CA', name: 'California'),
        (code: 'CA', name: 'California'),
        (code: 'NY', name: 'New York'),
        (code: 'TX', name: 'Texas'),
        (code: 'TX', name: 'TX'),
      ];

      final compacted = compactChoices(choices);

      // Expect unique entries (sorted by value within each key)
      expect(compacted, [
        (code: 'CA', name: 'California'),
        (code: 'NY', name: 'New York'),
        (code: 'TX', name: 'TX'),
        (code: 'TX', name: 'Texas'),
      ]);
    });

    test('matchChoices returns matching key', () {
      final choices = [
        (code: 'CA', name: 'California'),
        (code: 'NY', name: 'New York'),
        (code: 'TX', name: 'Texas'),
      ];

      expect(matchChoices('California', choices), 'CA');
      expect(matchChoices('ca', choices), 'CA');
      expect(matchChoices('New York', choices), 'NY');
      expect(matchChoices('new york', choices), 'NY');
      expect(matchChoices('NY', choices), 'NY');
      expect(matchChoices('TX', choices), 'TX');
    });

    test('matchChoices returns null for no match', () {
      final choices = [
        (code: 'CA', name: 'California'),
        (code: 'NY', name: 'New York'),
        (code: 'TX', name: 'Texas'),
      ];

      expect(matchChoices('Florida', choices), isNull);
      expect(matchChoices('', choices), isNull);
      expect(matchChoices(null, choices), isNull);
    });

    test('matchChoices handles whitespace', () {
      final choices = [(code: 'CA', name: 'California'), (code: 'NY', name: 'New York')];

      expect(matchChoices(' California ', choices), 'CA');
      expect(matchChoices(' New York ', choices), 'NY');
    });
  });

  group('AddressField', () {
    test('addressFieldFromCode returns correct field', () {
      expect(addressFieldFromCode('A'), AddressField.streetAddress);
      expect(addressFieldFromCode('C'), AddressField.city);
      expect(addressFieldFromCode('D'), AddressField.cityArea);
      expect(addressFieldFromCode('N'), AddressField.name);
      expect(addressFieldFromCode('O'), AddressField.companyName);
      expect(addressFieldFromCode('S'), AddressField.countryArea);
      expect(addressFieldFromCode('X'), AddressField.sortingCode);
      expect(addressFieldFromCode('Z'), AddressField.postalCode);
    });

    test('fromCode throws on invalid code', () {
      expect(() => addressFieldFromCode('invalid'), throwsArgumentError);
    });
  });
}

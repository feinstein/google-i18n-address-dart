import 'package:google_i18n_address/google_i18n_address.dart';
import 'package:test/test.dart';

void main() {
  group('normalization', () {
    group('normalize_address errors', () {
      final testCases = [
        {
          'address': <AddressField, String>{},
          'errors': {
            AddressField.countryCode: 'required',
            AddressField.city: 'required',
            AddressField.streetAddress: 'required',
          },
        },
        {
          'address': {AddressField.countryCode: 'AR'},
          'errors': {
            AddressField.city: 'required',
            AddressField.streetAddress: 'required',
          },
        },
        {
          'address': {
            AddressField.countryCode: 'CN',
            AddressField.countryArea: '北京市',
            AddressField.postalCode: '100084',
            AddressField.city: 'Invalid',
            AddressField.streetAddress: '...',
          },
          'errors': {AddressField.city: 'invalid'},
        },
        {
          'address': {
            AddressField.countryCode: 'CN',
            AddressField.countryArea: '云南省',
            AddressField.postalCode: '677400',
            AddressField.city: '临沧市',
            AddressField.cityArea: 'Invalid',
            AddressField.streetAddress: '...',
          },
          'errors': {AddressField.cityArea: 'invalid'},
        },
        {
          'address': {
            AddressField.countryCode: 'DE',
            AddressField.city: 'Berlin',
            AddressField.postalCode: '77-777',
            AddressField.streetAddress: '...',
          },
          'errors': {AddressField.postalCode: 'invalid'},
        },
        {
          'address': {
            AddressField.countryCode: 'PL',
            AddressField.city: 'Wrocław',
            AddressField.postalCode: '77777',
            AddressField.streetAddress: '...',
          },
          'errors': {AddressField.postalCode: 'invalid'},
        },
        {
          'address': {AddressField.countryCode: 'KR'},
          'errors': {
            AddressField.countryArea: 'required',
            AddressField.postalCode: 'required',
            AddressField.city: 'required',
            AddressField.streetAddress: 'required',
          },
        },
        {
          'address': {
            AddressField.countryCode: 'US',
            AddressField.countryArea: 'Nevada',
            AddressField.postalCode: '90210',
            AddressField.city: 'Las Vegas',
            AddressField.streetAddress: '...',
          },
          'errors': {AddressField.postalCode: 'invalid'},
        },
        {
          'address': {AddressField.countryCode: 'XX'},
          'errors': {AddressField.countryCode: 'invalid'},
        },
        {
          'address': {AddressField.countryCode: 'ZZ'},
          'errors': {AddressField.countryCode: 'invalid'},
        },
      ];

      for (var i = 0; i < testCases.length; i++) {
        final testCase = testCases[i];
        final address = testCase['address'] as Map<AddressField, String>;
        final expectedErrors = testCase['errors'] as Map<AddressField, String>;

        test('test case $i validates errors correctly', () {
          expect(
            () => normalizeAddress(address),
            throwsA(
              predicate((e) =>
                  e is InvalidAddressError && _compareErrors(e.errors, expectedErrors)),
            ),
          );
        });
      }
    });

    group('validate_known_addresses', () {
      final knownAddresses = [
        {
          AddressField.countryCode: 'AE',
          AddressField.countryArea: 'Dubai',
          AddressField.city: 'Dubai',
          AddressField.streetAddress: 'P.O Box 1234',
        },
        {
          AddressField.countryCode: 'CA',
          AddressField.countryArea: 'QC',
          AddressField.city: 'Montreal',
          AddressField.postalCode: 'H3Z 2Y7',
          AddressField.streetAddress: '10-123 1/2 MAIN STREET NW',
        },
        {
          AddressField.countryCode: 'CH',
          AddressField.city: 'Zürich',
          AddressField.postalCode: '8022',
          AddressField.streetAddress: 'Kappelergasse 1',
        },
        {
          AddressField.countryCode: 'CN',
          AddressField.countryArea: '北京市',
          AddressField.postalCode: '100084',
          AddressField.city: '海淀区',
          AddressField.streetAddress: '中关村东路1号',
        },
        {
          AddressField.countryCode: 'CN',
          AddressField.countryArea: '云南省',
          AddressField.postalCode: '677400',
          AddressField.city: '临沧市',
          AddressField.cityArea: '凤庆县',
          AddressField.streetAddress: '中关村东路1号',
        },
        {
          AddressField.countryCode: 'CN',
          AddressField.countryArea: 'Beijing Shi',
          AddressField.postalCode: '100084',
          AddressField.city: 'Haidian Qu',
          AddressField.streetAddress: '#1 Zhongguancun East Road',
        },
        {
          AddressField.countryCode: 'JP',
          AddressField.countryArea: '東京都',
          AddressField.postalCode: '150-8512',
          AddressField.city: '渋谷区',
          AddressField.streetAddress: '桜丘町26-1',
        },
        {
          AddressField.countryCode: 'JP',
          AddressField.countryArea: 'Tokyo',
          AddressField.postalCode: '150-8512',
          AddressField.city: 'Shibuya-ku',
          AddressField.streetAddress: '26-1 Sakuragaoka-cho',
        },
        {
          AddressField.countryCode: 'KR',
          AddressField.countryArea: '서울',
          AddressField.postalCode: '06136',
          AddressField.city: '강남구',
          AddressField.streetAddress: '역삼동 737번지 강남파이낸스센터',
        },
        {
          AddressField.countryCode: 'KR',
          AddressField.countryArea: '서울특별시',
          AddressField.postalCode: '06136',
          AddressField.city: '강남구',
          AddressField.streetAddress: '역삼동 737번지 강남파이낸스센터',
        },
        {
          AddressField.countryCode: 'KR',
          AddressField.countryArea: 'Seoul',
          AddressField.postalCode: '06136',
          AddressField.city: 'Gangnam-gu',
          AddressField.streetAddress: '역삼동 737번지 강남파이낸스센터',
        },
        {
          AddressField.countryCode: 'PL',
          AddressField.city: 'Warszawa',
          AddressField.postalCode: '00-374',
          AddressField.streetAddress: 'Aleje Jerozolimskie 2',
        },
        {
          AddressField.countryCode: 'US',
          AddressField.countryArea: 'California',
          AddressField.postalCode: '94037',
          AddressField.city: 'Mountain View',
          AddressField.streetAddress: '1600 Charleston Rd.',
        },
      ];

      for (var i = 0; i < knownAddresses.length; i++) {
        final address = knownAddresses[i];
        test('validates known address $i correctly', () {
          expect(normalizeAddress(address), isNotNull);
        });
      }
    });

    test('localization handling', () {
      var address = normalizeAddress({
        AddressField.countryCode: 'us',
        AddressField.countryArea: 'California',
        AddressField.postalCode: '94037',
        AddressField.city: 'Mountain View',
        AddressField.streetAddress: '1600 Charleston Rd.',
      });
      expect(address[AddressField.countryCode], 'US');
      expect(address[AddressField.countryArea], 'CA');

      address = normalizeAddress({
        AddressField.countryCode: 'us',
        AddressField.countryArea: 'CALIFORNIA',
        AddressField.postalCode: '94037',
        AddressField.city: 'Mountain View',
        AddressField.streetAddress: '1600 Charleston Rd.',
      });
      expect(address[AddressField.countryArea], 'CA');

      address = normalizeAddress({
        AddressField.countryCode: 'CN',
        AddressField.countryArea: 'Beijing Shi',
        AddressField.postalCode: '100084',
        AddressField.city: 'Haidian Qu',
        AddressField.streetAddress: '#1 Zhongguancun East Road',
      });
      expect(address[AddressField.countryArea], '北京市');
      expect(address[AddressField.city], '海淀区');

      address = normalizeAddress({
        AddressField.countryCode: 'AE',
        AddressField.countryArea: 'Dubai',
        AddressField.postalCode: '123456',
        AddressField.sortingCode: '654321',
        AddressField.streetAddress: 'P.O Box 1234',
      });
      expect(address[AddressField.countryArea], 'إمارة دبيّ');
      expect(address[AddressField.city], '');
      expect(address[AddressField.postalCode], '');
      expect(address[AddressField.sortingCode], '');
    });

    test('address formatting', () {
      final address = {
        AddressField.countryCode: 'CN',
        AddressField.countryArea: '云南省',
        AddressField.postalCode: '677400',
        AddressField.city: '临沧市',
        AddressField.cityArea: '凤庆县',
        AddressField.streetAddress: '中关村东路1号',
      };
      final result = formatAddress(address);
      expect(result, '677400\n云南省临沧市凤庆县\n中关村东路1号\nCHINA');
    });

    test('capitalization', () {
      final address = normalizeAddress({
        AddressField.countryCode: 'GB',
        AddressField.postalCode: 'sw1a 0aa',
        AddressField.city: 'London',
        AddressField.streetAddress: 'Westminster',
      });
      expect(address[AddressField.city], 'LONDON');
      expect(address[AddressField.postalCode], 'SW1A 0AA');
    });

    group('address_latinization', () {
      test('empty address stays empty', () {
        var address = <AddressField, String>{};
        address = latinizeAddress(address, isNormalized: true);
        expect(address, <AddressField, String>{});
      });

      test('latinize US address', () {
        var address = {
          AddressField.countryCode: 'US',
          AddressField.countryArea: 'CA',
          AddressField.postalCode: '94037',
          AddressField.city: 'Mountain View',
          AddressField.streetAddress: '1600 Charleston Rd.',
        };
        address = latinizeAddress(address);
        expect(address[AddressField.countryArea], 'California');
      });

      test('latinize Chinese address', () {
        var address = {
          AddressField.countryCode: 'CN',
          AddressField.countryArea: '云南省',
          AddressField.postalCode: '677400',
          AddressField.city: '临沧市',
          AddressField.cityArea: '凤庆县',
          AddressField.streetAddress: '中关村东路1号',
        };
        address = latinizeAddress(address);
        expect(address, {
          AddressField.countryCode: 'CN',
          AddressField.countryArea: 'Yunnan Sheng',
          AddressField.postalCode: '677400',
          AddressField.city: 'Lincang Shi',
          AddressField.cityArea: 'Fengqing Xian',
          AddressField.streetAddress: '中关村东路1号',
          AddressField.sortingCode: '',
        });
      });

      test('latinize and format address', () {
        var address = {
          AddressField.name: 'Zhang San',
          AddressField.companyName: 'Beijing Kid Toy Company',
          AddressField.countryCode: 'CN',
          AddressField.countryArea: '北京市',
          AddressField.city: '海淀区',
          AddressField.postalCode: '100084',
          AddressField.sortingCode: '',
          AddressField.streetAddress: '#1 Zhongguancun East Road',
        };
        address = latinizeAddress(address);
        final result = formatAddress(address, latin: true);
        expect(result, '''Zhang San
Beijing Kid Toy Company
#1 Zhongguancun East Road
Haidian Qu
BEIJING SHI, 100084
CHINA''');
      });
    });
  });
}

// Helper function to compare error maps
bool _compareErrors(
    Map<AddressField, String> actual, Map<AddressField, String> expected) {
  if (actual.length != expected.length) {
    return false;
  }

  for (final key in expected.keys) {
    if (!actual.containsKey(key) || actual[key] != expected[key]) {
      return false;
    }
  }

  return true;
}

import 'package:google_i18n_address/google_i18n_address.dart';
import 'package:test/test.dart';

void main() {
  group('normalization', () {
    group('normalize_address errors', () {
      final testCases = [
        {
          'address': <String, String>{},
          'errors': {
            'country_code': 'required',
            'city': 'required',
            'street_address': 'required',
          },
        },
        {
          'address': {'country_code': 'AR'},
          'errors': {
            'city': 'required',
            'street_address': 'required',
          },
        },
        {
          'address': {
            'country_code': 'CN',
            'country_area': '北京市',
            'postal_code': '100084',
            'city': 'Invalid',
            'street_address': '...',
          },
          'errors': {'city': 'invalid'},
        },
        {
          'address': {
            'country_code': 'CN',
            'country_area': '云南省',
            'postal_code': '677400',
            'city': '临沧市',
            'city_area': 'Invalid',
            'street_address': '...',
          },
          'errors': {'city_area': 'invalid'},
        },
        {
          'address': {
            'country_code': 'DE',
            'city': 'Berlin',
            'postal_code': '77-777',
            'street_address': '...',
          },
          'errors': {'postal_code': 'invalid'},
        },
        {
          'address': {
            'country_code': 'PL',
            'city': 'Wrocław',
            'postal_code': '77777',
            'street_address': '...',
          },
          'errors': {'postal_code': 'invalid'},
        },
        {
          'address': {'country_code': 'KR'},
          'errors': {
            'country_area': 'required',
            'postal_code': 'required',
            'city': 'required',
            'street_address': 'required',
          },
        },
        {
          'address': {
            'country_code': 'US',
            'country_area': 'Nevada',
            'postal_code': '90210',
            'city': 'Las Vegas',
            'street_address': '...',
          },
          'errors': {'postal_code': 'invalid'},
        },
        {
          'address': {'country_code': 'XX'},
          'errors': {'country_code': 'invalid'},
        },
        {
          'address': {'country_code': 'ZZ'},
          'errors': {'country_code': 'invalid'},
        },
      ];

      for (var i = 0; i < testCases.length; i++) {
        final testCase = testCases[i];
        final address = testCase['address'] as Map<String, String>;
        final expectedErrors = testCase['errors'] as Map<String, String>;

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
          'country_code': 'AE',
          'country_area': 'Dubai',
          'city': 'Dubai',
          'street_address': 'P.O Box 1234',
        },
        {
          'country_code': 'CA',
          'country_area': 'QC',
          'city': 'Montreal',
          'postal_code': 'H3Z 2Y7',
          'street_address': '10-123 1/2 MAIN STREET NW',
        },
        {
          'country_code': 'CH',
          'city': 'Zürich',
          'postal_code': '8022',
          'street_address': 'Kappelergasse 1',
        },
        {
          'country_code': 'CN',
          'country_area': '北京市',
          'postal_code': '100084',
          'city': '海淀区',
          'street_address': '中关村东路1号',
        },
        {
          'country_code': 'CN',
          'country_area': '云南省',
          'postal_code': '677400',
          'city': '临沧市',
          'city_area': '凤庆县',
          'street_address': '中关村东路1号',
        },
        {
          'country_code': 'CN',
          'country_area': 'Beijing Shi',
          'postal_code': '100084',
          'city': 'Haidian Qu',
          'street_address': '#1 Zhongguancun East Road',
        },
        {
          'country_code': 'JP',
          'country_area': '東京都',
          'postal_code': '150-8512',
          'city': '渋谷区',
          'street_address': '桜丘町26-1',
        },
        {
          'country_code': 'JP',
          'country_area': 'Tokyo',
          'postal_code': '150-8512',
          'city': 'Shibuya-ku',
          'street_address': '26-1 Sakuragaoka-cho',
        },
        {
          'country_code': 'KR',
          'country_area': '서울',
          'postal_code': '06136',
          'city': '강남구',
          'street_address': '역삼동 737번지 강남파이낸스센터',
        },
        {
          'country_code': 'KR',
          'country_area': '서울특별시',
          'postal_code': '06136',
          'city': '강남구',
          'street_address': '역삼동 737번지 강남파이낸스센터',
        },
        {
          'country_code': 'KR',
          'country_area': 'Seoul',
          'postal_code': '06136',
          'city': 'Gangnam-gu',
          'street_address': '역삼동 737번지 강남파이낸스센터',
        },
        {
          'country_code': 'PL',
          'city': 'Warszawa',
          'postal_code': '00-374',
          'street_address': 'Aleje Jerozolimskie 2',
        },
        {
          'country_code': 'US',
          'country_area': 'California',
          'postal_code': '94037',
          'city': 'Mountain View',
          'street_address': '1600 Charleston Rd.',
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
        'country_code': 'us',
        'country_area': 'California',
        'postal_code': '94037',
        'city': 'Mountain View',
        'street_address': '1600 Charleston Rd.',
      });
      expect(address['country_code'], 'US');
      expect(address['country_area'], 'CA');

      address = normalizeAddress({
        'country_code': 'us',
        'country_area': 'CALIFORNIA',
        'postal_code': '94037',
        'city': 'Mountain View',
        'street_address': '1600 Charleston Rd.',
      });
      expect(address['country_area'], 'CA');

      address = normalizeAddress({
        'country_code': 'CN',
        'country_area': 'Beijing Shi',
        'postal_code': '100084',
        'city': 'Haidian Qu',
        'street_address': '#1 Zhongguancun East Road',
      });
      expect(address['country_area'], '北京市');
      expect(address['city'], '海淀区');

      address = normalizeAddress({
        'country_code': 'AE',
        'country_area': 'Dubai',
        'postal_code': '123456',
        'sorting_code': '654321',
        'street_address': 'P.O Box 1234',
      });
      expect(address['country_area'], 'إمارة دبيّ');
      expect(address['city'], '');
      expect(address['postal_code'], '');
      expect(address['sorting_code'], '');
    });

    test('address formatting', () {
      final address = {
        'country_code': 'CN',
        'country_area': '云南省',
        'postal_code': '677400',
        'city': '临沧市',
        'city_area': '凤庆县',
        'street_address': '中关村东路1号',
      };
      final result = formatAddress(address);
      expect(result, '677400\n云南省临沧市凤庆县\n中关村东路1号\nCHINA');
    });

    test('capitalization', () {
      final address = normalizeAddress({
        'country_code': 'GB',
        'postal_code': 'sw1a 0aa',
        'city': 'London',
        'street_address': 'Westminster',
      });
      expect(address['city'], 'LONDON');
      expect(address['postal_code'], 'SW1A 0AA');
    });

    group('address_latinization', () {
      test('empty address stays empty', () {
        var address = <String, String>{};
        address = latinizeAddress(address, isNormalized: true);
        expect(address, <String, String>{});
      });

      test('latinize US address', () {
        var address = {
          'country_code': 'US',
          'country_area': 'CA',
          'postal_code': '94037',
          'city': 'Mountain View',
          'street_address': '1600 Charleston Rd.',
        };
        address = latinizeAddress(address);
        expect(address['country_area'], 'California');
      });

      test('latinize Chinese address', () {
        var address = {
          'country_code': 'CN',
          'country_area': '云南省',
          'postal_code': '677400',
          'city': '临沧市',
          'city_area': '凤庆县',
          'street_address': '中关村东路1号',
        };
        address = latinizeAddress(address);
        expect(address, {
          'country_code': 'CN',
          'country_area': 'Yunnan Sheng',
          'postal_code': '677400',
          'city': 'Lincang Shi',
          'city_area': 'Fengqing Xian',
          'street_address': '中关村东路1号',
          'sorting_code': '',
        });
      });

      test('latinize and format address', () {
        var address = {
          'name': 'Zhang San',
          'company_name': 'Beijing Kid Toy Company',
          'country_code': 'CN',
          'country_area': '北京市',
          'city': '海淀区',
          'postal_code': '100084',
          'sorting_code': '',
          'street_address': '#1 Zhongguancun East Road',
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
bool _compareErrors(Map<String, dynamic> actual, Map<String, dynamic> expected) {
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

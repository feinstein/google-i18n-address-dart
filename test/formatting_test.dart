import 'package:google_i18n_address/google_i18n_address.dart';
import 'package:test/test.dart';

void main() {
  group('formatAddress', () {
    test('formats a Chinese address correctly', () {
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

    test('formats a Chinese address correctly in Latin format', () {
      final address = {
        'country_code': 'CN',
        'country_area': '云南省',
        'postal_code': '677400',
        'city': '临沧市',
        'city_area': '凤庆县',
        'street_address': '中关村东路1号',
      };

      final result = formatAddress(address, latin: true);

      expect(result, contains('中关村东路1号'));
      expect(result, contains('CHINA'));
    });

    test('formats a US address correctly', () {
      final address = {
        'name': 'John Doe',
        'company_name': 'Example Corp',
        'country_code': 'US',
        'country_area': 'CA',
        'postal_code': '94043',
        'city': 'Mountain View',
        'street_address': '1600 Amphitheatre Pkwy',
      };

      final result = formatAddress(address);

      expect(result,
          'John Doe\nExample Corp\n1600 Amphitheatre Pkwy\nMOUNTAIN VIEW, CA 94043\nUNITED STATES');
    });
  });

  group('latinizeAddress', () {
    test('latinizes a Chinese address correctly', () {
      final address = {
        'country_code': 'CN',
        'country_area': '云南省',
        'postal_code': '677400',
        'city': '临沧市',
        'city_area': '凤庆县',
        'street_address': '中关村东路1号',
      };

      final latinized = latinizeAddress(address);

      expect(latinized['country_area'], 'Yunnan Sheng');
      expect(latinized['city'], 'Lincang Shi');
      expect(latinized['city_area'], 'Fengqing Xian');
      expect(latinized['street_address'], '中关村东路1号');
      expect(latinized['sorting_code'], '');
    });

    test('latinizes a US address correctly (expands state codes)', () {
      final address = {
        'country_code': 'US',
        'country_area': 'CA',
        'postal_code': '94037',
        'city': 'MOUNTAIN VIEW',
        'street_address': '1600 Charleston Rd.',
      };

      final latinized = latinizeAddress(address);

      expect(latinized['country_area'], 'California');
      expect(latinized['city'], 'MOUNTAIN VIEW');
    });

    test('handles empty address', () {
      final result = latinizeAddress({}, isNormalized: true);
      expect(result, {});
    });
  });
}

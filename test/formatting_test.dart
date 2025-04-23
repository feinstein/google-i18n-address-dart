import 'package:google_i18n_address/google_i18n_address.dart';
import 'package:test/test.dart';

void main() {
  group('formatAddress', () {
    test('formats a Chinese address correctly', () {
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

    test('formats a Chinese address correctly in Latin format', () {
      final address = {
        AddressField.countryCode: 'CN',
        AddressField.countryArea: '云南省',
        AddressField.postalCode: '677400',
        AddressField.city: '临沧市',
        AddressField.cityArea: '凤庆县',
        AddressField.streetAddress: '中关村东路1号',
      };

      final result = formatAddress(address, latin: true);

      expect(result, contains('中关村东路1号'));
      expect(result, contains('CHINA'));
    });

    test('formats a US address correctly', () {
      final address = {
        AddressField.name: 'John Doe',
        AddressField.companyName: 'Example Corp',
        AddressField.countryCode: 'US',
        AddressField.countryArea: 'CA',
        AddressField.postalCode: '94043',
        AddressField.city: 'Mountain View',
        AddressField.streetAddress: '1600 Amphitheatre Pkwy',
      };

      final result = formatAddress(address);

      expect(
        result,
        'John Doe\nExample Corp\n1600 Amphitheatre Pkwy\nMOUNTAIN VIEW, CA 94043\nUNITED STATES',
      );
    });
  });

  group('latinizeAddress', () {
    test('latinizes a Chinese address correctly', () {
      final address = {
        AddressField.countryCode: 'CN',
        AddressField.countryArea: '云南省',
        AddressField.postalCode: '677400',
        AddressField.city: '临沧市',
        AddressField.cityArea: '凤庆县',
        AddressField.streetAddress: '中关村东路1号',
      };

      final latinized = latinizeAddress(address);

      expect(latinized[AddressField.countryArea], 'Yunnan Sheng');
      expect(latinized[AddressField.city], 'Lincang Shi');
      expect(latinized[AddressField.cityArea], 'Fengqing Xian');
      expect(latinized[AddressField.streetAddress], '中关村东路1号');
      expect(latinized[AddressField.sortingCode], '');
    });

    test('latinizes a US address correctly (expands state codes)', () {
      final address = {
        AddressField.countryCode: 'US',
        AddressField.countryArea: 'CA',
        AddressField.postalCode: '94037',
        AddressField.city: 'MOUNTAIN VIEW',
        AddressField.streetAddress: '1600 Charleston Rd.',
      };

      final latinized = latinizeAddress(address);

      expect(latinized[AddressField.countryArea], 'California');
      expect(latinized[AddressField.city], 'MOUNTAIN VIEW');
    });

    test('handles empty address', () {
      final result = latinizeAddress({}, isNormalized: true);
      expect(result, {});
    });
  });
}

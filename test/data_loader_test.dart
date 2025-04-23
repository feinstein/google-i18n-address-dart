import 'package:google_i18n_address/src/data_loader.dart';
import 'package:test/test.dart';

void main() {
  group('DataLoader', () {
    test('loadValidationData loads valid country data', () {
      final data = loadValidationData('us');
      expect(data, isA<Map<String, dynamic>>());
      expect(data.containsKey('US'), isTrue);
      expect(data['US']?.containsKey('name'), isTrue);
      expect(data['US']?['name'], 'UNITED STATES');
    });

    test('loadValidationData throws on invalid country code', () {
      expect(
        () => loadValidationData('XX'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('is not a valid country code'),
          ),
        ),
      );

      expect(
        () => loadValidationData('../../../etc/passwd'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('is not a valid country code'),
          ),
        ),
      );
    });

    test('loadValidationData dictionary access works correctly', () {
      final data = loadValidationData('US');
      final state = data['US/NV'];
      expect(state?['name'], 'Nevada');
    });

    test('loadCountryData loads base data for null country code', () {
      final result = loadCountryData(null);
      expect(result.countryData, isA<Map<String, dynamic>>());
      expect(result.database, isA<Map<String, dynamic>>());

      // Base data should have default formats
      expect(result.countryData.containsKey('fmt'), isTrue);
      expect(result.countryData.containsKey('require'), isTrue);
    });

    test('loadCountryData loads specific country data', () {
      final result = loadCountryData('US');
      expect(result.countryData, isA<Map<String, dynamic>>());
      expect(result.database, isA<Map<String, dynamic>>());

      // Should have US-specific data
      expect(result.countryData.containsKey('name'), isTrue);
      expect(result.countryData['name'], 'UNITED STATES');

      // Database should contain US sub-regions
      expect(result.database.containsKey('US/CA'), isTrue);
      expect(result.database['US/CA']?['name'], 'California');
    });

    test('loadCountryData throws on ZZ country code', () {
      expect(
        () => loadCountryData('ZZ'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('is not a valid country code'),
          ),
        ),
      );
    });

    test('validCountryCode pattern works correctly', () {
      expect(validCountryCode.hasMatch('US'), isTrue);
      expect(validCountryCode.hasMatch('CA'), isTrue);
      expect(validCountryCode.hasMatch('GB'), isTrue);
      expect(
        validCountryCode.hasMatch('ZZZ'),
        isTrue,
      ); // Just checking pattern, not validity

      expect(validCountryCode.hasMatch(''), isFalse);
      expect(validCountryCode.hasMatch('A'), isFalse);
      expect(validCountryCode.hasMatch('INVALID'), isFalse);
      expect(validCountryCode.hasMatch('../../../etc/passwd'), isFalse);
    });
  });
}

import 'package:google_i18n_address/google_i18n_address.dart';
import 'package:google_i18n_address/src/data_loader.dart';
import 'package:test/test.dart';

void main() {
  group('i18naddress', () {
    test('invalid country code throws error', () {
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
        () => loadValidationData('AZZ'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('is not a valid country code'),
          ),
        ),
      );
    });

    test('dictionary access works correctly', () {
      final data = loadValidationData('US');
      final state = data['US/NV'];
      expect(state?['name'], 'Nevada');
    });

    test('validation rules for Canada', () {
      final validationData = getValidationRules({AddressField.countryCode: 'CA'});
      expect(validationData.countryCode, 'CA');
      expect(
        validationData.countryAreaChoices,
        containsAll([
          (code: 'AB', name: 'Alberta'),
          (code: 'BC', name: 'British Columbia'),
          (code: 'BC', name: 'Colombie-Britannique'),
          (code: 'MB', name: 'Manitoba'),
          (code: 'NB', name: 'New Brunswick'),
          (code: 'NB', name: 'Nouveau-Brunswick'),
          (code: 'NL', name: 'Newfoundland and Labrador'),
          (code: 'NL', name: 'Terre-Neuve-et-Labrador'),
          (code: 'NT', name: 'Northwest Territories'),
          (code: 'NT', name: 'Territoires du Nord-Ouest'),
          (code: 'NS', name: 'Nouvelle-Écosse'),
          (code: 'NS', name: 'Nova Scotia'),
          (code: 'NU', name: 'Nunavut'),
          (code: 'ON', name: 'Ontario'),
          (code: 'PE', name: 'Prince Edward Island'),
          (code: 'PE', name: 'Île-du-Prince-Édouard'),
          (code: 'QC', name: 'Quebec'),
          (code: 'QC', name: 'Québec'),
          (code: 'SK', name: 'Saskatchewan'),
          (code: 'YT', name: 'Yukon'),
        ]),
      );
    });

    test('validation for India', () {
      final validationData = getValidationRules({AddressField.countryCode: 'IN'});
      expect(
        validationData.countryAreaChoices,
        containsAll([
          (code: 'Andaman and Nicobar Islands', name: 'Andaman & Nicobar'),
          (code: 'Andhra Pradesh', name: 'Andhra Pradesh'),
          (code: 'Andhra Pradesh', name: 'आंध्र प्रदेश'),
          (code: 'Arunachal Pradesh', name: 'Arunachal Pradesh'),
          (code: 'Arunachal Pradesh', name: 'अरुणाचल प्रदेश'),
          (code: 'Assam', name: 'Assam'),
          (code: 'Assam', name: 'असम'),
          (code: 'Bihar', name: 'Bihar'),
          (code: 'Bihar', name: 'बिहार'),
          (code: 'Chandigarh', name: 'Chandigarh'),
          (code: 'Chandigarh', name: 'चंडीगढ़'),
          (code: 'Chhattisgarh', name: 'Chhattisgarh'),
          (code: 'Chhattisgarh', name: 'छत्तीसगढ़'),
          (
            code: 'Dadra and Nagar Haveli and Daman and Diu',
            name: 'Dadra & Nagar Haveli & Daman & Diu',
          ),
          (code: 'Delhi', name: 'Delhi'),
          (code: 'Delhi', name: 'दिल्ली'),
          (code: 'Goa', name: 'Goa'),
          (code: 'Goa', name: 'गोआ'),
          (code: 'Gujarat', name: 'Gujarat'),
          (code: 'Gujarat', name: 'गुजरात'),
          (code: 'Haryana', name: 'Haryana'),
          (code: 'Haryana', name: 'हरियाणा'),
          (code: 'Himachal Pradesh', name: 'Himachal Pradesh'),
          (code: 'Himachal Pradesh', name: 'हिमाचल प्रदेश'),
          (code: 'Jammu and Kashmir', name: 'Jammu & Kashmir'),
          (code: 'Jharkhand', name: 'Jharkhand'),
          (code: 'Jharkhand', name: 'झारखण्ड'),
          (code: 'Karnataka', name: 'Karnataka'),
          (code: 'Karnataka', name: 'कर्नाटक'),
          (code: 'Kerala', name: 'Kerala'),
          (code: 'Kerala', name: 'केरल'),
          (code: 'Ladakh', name: 'Ladakh'),
          (code: 'Ladakh', name: 'लद्दाख़'),
          (code: 'Lakshadweep', name: 'Lakshadweep'),
          (code: 'Lakshadweep', name: 'लक्षद्वीप'),
          (code: 'Madhya Pradesh', name: 'Madhya Pradesh'),
          (code: 'Madhya Pradesh', name: 'मध्य प्रदेश'),
          (code: 'Maharashtra', name: 'Maharashtra'),
          (code: 'Maharashtra', name: 'महाराष्ट्र'),
          (code: 'Manipur', name: 'Manipur'),
          (code: 'Manipur', name: 'मणिपुर'),
          (code: 'Meghalaya', name: 'Meghalaya'),
          (code: 'Mizoram', name: 'Mizoram'),
          (code: 'Mizoram', name: 'मिजोरम'),
          (code: 'Nagaland', name: 'Nagaland'),
          (code: 'Nagaland', name: 'नागालैंड'),
          (code: 'Odisha', name: 'Odisha'),
          (code: 'Odisha', name: 'ओड़िशा'),
          (code: 'Puducherry', name: 'Puducherry'),
          (code: 'Puducherry', name: 'पांडिचेरी'),
          (code: 'Punjab', name: 'Punjab'),
          (code: 'Punjab', name: 'पंजाब'),
          (code: 'Rajasthan', name: 'Rajasthan'),
          (code: 'Rajasthan', name: 'राजस्थान'),
          (code: 'Sikkim', name: 'Sikkim'),
          (code: 'Sikkim', name: 'सिक्किम'),
          (code: 'Tamil Nadu', name: 'Tamil Nadu'),
          (code: 'Tamil Nadu', name: 'तमिल नाडु'),
          (code: 'Telangana', name: 'Telangana'),
          (code: 'Telangana', name: 'तेलंगाना'),
          (code: 'Tripura', name: 'Tripura'),
          (code: 'Tripura', name: 'त्रिपुरा'),
          (code: 'Uttar Pradesh', name: 'Uttar Pradesh'),
          (code: 'Uttar Pradesh', name: 'उत्तर प्रदेश'),
          (code: 'Uttarakhand', name: 'Uttarakhand'),
          (code: 'Uttarakhand', name: 'उत्तराखण्ड'),
          (code: 'West Bengal', name: 'West Bengal'),
          (code: 'West Bengal', name: 'पश्चिम बंगाल'),
          (code: 'Andaman & Nicobar', name: 'अंडमान और निकोबार द्वीपसमूह'),
          (code: 'Jammu & Kashmir', name: 'जम्मू और कश्मीर'),
          (
            code: 'Dadra & Nagar Haveli & Daman & Diu',
            name: 'दादरा और नगर हवेली और दमन और दिउ',
          ),
        ]),
      );
    });

    test('validation rules for Switzerland', () {
      final validationData = getValidationRules({AddressField.countryCode: 'CH'});
      expect(
        validationData.allowedFields,
        containsAll([
          AddressField.companyName,
          AddressField.city,
          AddressField.postalCode,
          AddressField.streetAddress,
          AddressField.name,
        ]),
      );
      expect(
        validationData.requiredFields,
        containsAll([
          AddressField.city,
          AddressField.postalCode,
          AddressField.streetAddress,
        ]),
      );
    });

    test('field order for Poland', () {
      final fieldOrder = getFieldOrder({AddressField.countryCode: 'PL'});
      expect(fieldOrder, [
        [AddressField.name],
        [AddressField.companyName],
        [AddressField.streetAddress],
        [AddressField.postalCode, AddressField.city],
      ]);
    });

    test('field order for China', () {
      final fieldOrder = getFieldOrder({AddressField.countryCode: 'CN'});
      expect(fieldOrder, [
        [AddressField.postalCode],
        [AddressField.countryArea, AddressField.city, AddressField.cityArea],
        [AddressField.streetAddress],
        [AddressField.companyName],
        [AddressField.name],
      ]);
    });

    group('locality types', () {
      final testData = {
        'CN': ['province', 'city', 'district'],
        'JP': ['prefecture', 'city', 'suburb'],
        'KR': ['do_si', 'city', 'district'],
      };

      for (final entry in testData.entries) {
        final country = entry.key;
        final levels = entry.value;

        test('locality types for $country', () {
          final validationData = getValidationRules({AddressField.countryCode: country});
          expect(validationData.countryAreaType, levels[0]);
          expect(validationData.cityType, levels[1]);
          expect(validationData.cityAreaType, levels[2]);
        });
      }
    });
  });
}

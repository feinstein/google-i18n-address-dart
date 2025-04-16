import 'package:google_i18n_address/google_i18n_address.dart';
import 'package:google_i18n_address/src/data_loader.dart';
import 'package:test/test.dart';

void main() {
  group('i18naddress', () {
    test('invalid country code throws error', () {
      expect(
        () => loadValidationData('XX'),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('is not a valid country code'),
        )),
      );

      expect(
        () => loadValidationData('AZZ'),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('is not a valid country code'),
        )),
      );
    });

    test('dictionary access works correctly', () {
      final data = loadValidationData('US');
      final state = data['US/NV'];
      expect(state['name'], 'Nevada');
    });

    test('validation rules for Canada', () {
      final validationData = getValidationRules({'country_code': 'CA'});
      expect(validationData.countryCode, 'CA');
      expect(
          validationData.countryAreaChoices,
          containsAll([
            ['AB', 'Alberta'],
            ['BC', 'British Columbia'],
            ['BC', 'Colombie-Britannique'],
            ['MB', 'Manitoba'],
            ['NB', 'New Brunswick'],
            ['NB', 'Nouveau-Brunswick'],
            ['NL', 'Newfoundland and Labrador'],
            ['NL', 'Terre-Neuve-et-Labrador'],
            ['NT', 'Northwest Territories'],
            ['NT', 'Territoires du Nord-Ouest'],
            ['NS', 'Nouvelle-Écosse'],
            ['NS', 'Nova Scotia'],
            ['NU', 'Nunavut'],
            ['ON', 'Ontario'],
            ['PE', 'Prince Edward Island'],
            ['PE', 'Île-du-Prince-Édouard'],
            ['QC', 'Quebec'],
            ['QC', 'Québec'],
            ['SK', 'Saskatchewan'],
            ['YT', 'Yukon'],
          ]));
    });

    test('validation for India', () {
      final validationData = getValidationRules({'country_code': 'IN'});
      expect(
          validationData.countryAreaChoices,
          containsAll([
            ['Andaman and Nicobar Islands', 'Andaman & Nicobar'],
            ['Andhra Pradesh', 'Andhra Pradesh'],
            ['Andhra Pradesh', 'आंध्र प्रदेश'],
            ['Arunachal Pradesh', 'Arunachal Pradesh'],
            ['Arunachal Pradesh', 'अरुणाचल प्रदेश'],
            ['Assam', 'Assam'],
            ['Assam', 'असम'],
            ['Bihar', 'Bihar'],
            ['Bihar', 'बिहार'],
            ['Chandigarh', 'Chandigarh'],
            ['Chandigarh', 'चंडीगढ़'],
            ['Chhattisgarh', 'Chhattisgarh'],
            ['Chhattisgarh', 'छत्तीसगढ़'],
            [
              'Dadra and Nagar Haveli and Daman and Diu',
              'Dadra & Nagar Haveli & Daman & Diu'
            ],
            ['Delhi', 'Delhi'],
            ['Delhi', 'दिल्ली'],
            ['Goa', 'Goa'],
            ['Goa', 'गोआ'],
            ['Gujarat', 'Gujarat'],
            ['Gujarat', 'गुजरात'],
            ['Haryana', 'Haryana'],
            ['Haryana', 'हरियाणा'],
            ['Himachal Pradesh', 'Himachal Pradesh'],
            ['Himachal Pradesh', 'हिमाचल प्रदेश'],
            ['Jammu and Kashmir', 'Jammu & Kashmir'],
            ['Jharkhand', 'Jharkhand'],
            ['Jharkhand', 'झारखण्ड'],
            ['Karnataka', 'Karnataka'],
            ['Karnataka', 'कर्नाटक'],
            ['Kerala', 'Kerala'],
            ['Kerala', 'केरल'],
            ['Ladakh', 'Ladakh'],
            ['Ladakh', 'लद्दाख़'],
            ['Lakshadweep', 'Lakshadweep'],
            ['Lakshadweep', 'लक्षद्वीप'],
            ['Madhya Pradesh', 'Madhya Pradesh'],
            ['Madhya Pradesh', 'मध्य प्रदेश'],
            ['Maharashtra', 'Maharashtra'],
            ['Maharashtra', 'महाराष्ट्र'],
            ['Manipur', 'Manipur'],
            ['Manipur', 'मणिपुर'],
            ['Meghalaya', 'Meghalaya'],
            ['Meghalaya', 'मेघालय'],
            ['Mizoram', 'Mizoram'],
            ['Mizoram', 'मिजोरम'],
            ['Nagaland', 'Nagaland'],
            ['Nagaland', 'नागालैंड'],
            ['Odisha', 'Odisha'],
            ['Odisha', 'ओड़िशा'],
            ['Puducherry', 'Puducherry'],
            ['Puducherry', 'पांडिचेरी'],
            ['Punjab', 'Punjab'],
            ['Punjab', 'पंजाब'],
            ['Rajasthan', 'Rajasthan'],
            ['Rajasthan', 'राजस्थान'],
            ['Sikkim', 'Sikkim'],
            ['Sikkim', 'सिक्किम'],
            ['Tamil Nadu', 'Tamil Nadu'],
            ['Tamil Nadu', 'तमिल नाडु'],
            ['Telangana', 'Telangana'],
            ['Telangana', 'तेलंगाना'],
            ['Tripura', 'Tripura'],
            ['Tripura', 'त्रिपुरा'],
            ['Uttar Pradesh', 'Uttar Pradesh'],
            ['Uttar Pradesh', 'उत्तर प्रदेश'],
            ['Uttarakhand', 'Uttarakhand'],
            ['Uttarakhand', 'उत्तराखण्ड'],
            ['West Bengal', 'West Bengal'],
            ['West Bengal', 'पश्चिम बंगाल'],
            ['Andaman & Nicobar', 'अंडमान और निकोबार द्वीपसमूह'],
            ['Jammu & Kashmir', 'जम्मू और कश्मीर'],
            ['Dadra & Nagar Haveli & Daman & Diu', 'दादरा और नगर हवेली और दमन और दिउ'],
          ]));
    });

    test('validation rules for Switzerland', () {
      final validationData = getValidationRules({'country_code': 'CH'});
      expect(
          validationData.allowedFields,
          containsAll({
            'company_name',
            'city',
            'postal_code',
            'street_address',
            'name',
          }));
      expect(
          validationData.requiredFields,
          containsAll({
            'city',
            'postal_code',
            'street_address',
          }));
    });

    test('field order for Poland', () {
      final fieldOrder = getFieldOrder({'country_code': 'PL'});
      expect(fieldOrder, [
        ['name'],
        ['company_name'],
        ['street_address'],
        ['postal_code', 'city'],
      ]);
    });

    test('field order for China', () {
      final fieldOrder = getFieldOrder({'country_code': 'CN'});
      expect(fieldOrder, [
        ['postal_code'],
        ['country_area', 'city', 'city_area'],
        ['street_address'],
        ['company_name'],
        ['name'],
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
          final validationData = getValidationRules({'country_code': country});
          expect(validationData.countryAreaType, levels[0]);
          expect(validationData.cityType, levels[1]);
          expect(validationData.cityAreaType, levels[2]);
        });
      }
    });
  });
}

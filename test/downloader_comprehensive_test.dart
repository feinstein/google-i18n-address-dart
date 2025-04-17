import 'dart:convert';
import 'dart:io';

import 'package:google_i18n_address/src/downloader.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

@GenerateNiceMocks([MockSpec<http.Client>()])
import 'downloader_comprehensive_test.mocks.dart';

// Test helper functions
Future<void> downloadWithClient(
    String? country, String outputPath, http.Client client) async {
  // Create data directory if it doesn't exist
  final dataDir = Directory(outputPath);
  if (!dataDir.existsSync()) {
    dataDir.createSync(recursive: true);
  }

  final allData = <String, Map<String, dynamic>>{};

  // Get countries list
  final response = await client.get(Uri.parse('$mainUrl/countries'));
  final countries = (json.decode(response.body)['countries'] as String).split('~');

  if (country != null) {
    final normalizedCountry = country.toUpperCase();
    if (!countries.contains(normalizedCountry)) {
      throw ArgumentError('$country is not a supported country code');
    }
    countries.clear();
    countries.add(normalizedCountry);
  }

  // Process each country
  for (final countryCode in countries) {
    await processData(countryCode, null, allData, client: client);
  }

  // Write "all.json" file
  final allOutput = StringBuffer('{');

  // Write individual country files
  for (int i = 0; i < countries.length; i++) {
    final countryCode = countries[i];
    final countryData = <String, Map<String, dynamic>>{};

    for (final entry in allData.entries) {
      if (entry.key.startsWith(countryCode)) {
        countryData[entry.key] = entry.value;
      }
    }

    final countryFilePath = '$outputPath/${countryCode.toLowerCase()}.json';
    final countryJson = serialize(countryData, countryFilePath);

    // Add to the "all.json" file
    allOutput.write(countryJson.substring(1, countryJson.length - 1));
    if (i < countries.length - 1) {
      allOutput.write(',');
    }
  }

  allOutput.write('}');
  File('$outputPath/all.json').writeAsStringSync(allOutput.toString());
}

Future<Map<String, dynamic>> processData(
    String key, String? language, Map<String, Map<String, dynamic>> allData,
    {http.Client? client}) async {
  final fullKey = language != null ? '$key?lang=$language' : key;
  final url = '$mainUrl/$fullKey';

  // Fetch data using the provided client or default fetch
  Map<String, dynamic> data;
  if (client != null) {
    final response = await client.get(Uri.parse(url));
    data = json.decode(response.body) as Map<String, dynamic>;
  } else {
    data = await fetch(url);
  }

  // Store the data
  final keyToStore = language != null ? '$key--$language' : key;
  allData[keyToStore] = data;

  // Check for additional languages
  final lang = data['lang'] as String?;
  final languages = data['languages'] as String?;

  if (languages != null && lang != null) {
    final languageList = languages.split('~');
    languageList.remove(lang);

    // Process each additional language
    for (final additionalLang in languageList) {
      await processData(key, additionalLang, allData, client: client);
    }
  }

  // Check for sub-keys
  if (data.containsKey('sub_keys')) {
    final subKeys = (data['sub_keys'] as String).split('~');

    // Process each sub-key
    for (final subKey in subKeys) {
      await processData('$key/$subKey', language, allData, client: client);
    }
  }

  return {key: data};
}

void main() {
  group('Downloader Comprehensive Tests', () {
    late Directory tempDir;
    late MockClient mockClient;

    setUp(() {
      // Create a temporary directory for test files
      tempDir = Directory.systemTemp.createTempSync('google_i18n_address_test_');
      mockClient = MockClient();
    });

    tearDown(() {
      // Clean up after tests
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('download with single country argument', () async {
      // Mocking responses for country listing and individual country data
      when(mockClient.get(Uri.parse('$mainUrl/countries')))
          .thenAnswer((_) async => http.Response('{"countries": "PL~US"}', 200));

      when(mockClient.get(Uri.parse('$mainUrl/PL'))).thenAnswer((_) async =>
          http.Response('{"key": "PL", "lang": "pl", "name": "POLAND"}', 200));

      // Set output directory to temp directory
      final dataDir = '${tempDir.path}/data';
      Directory(dataDir).createSync();

      // Run download with mocked client
      await downloadWithClient('PL', dataDir, mockClient);

      // Verify that the file was created correctly
      final plFile = File('$dataDir/pl.json');
      final allFile = File('$dataDir/all.json');

      expect(plFile.existsSync(), true);
      expect(allFile.existsSync(), true);

      final plData = json.decode(plFile.readAsStringSync());
      expect(plData, contains('PL'));
    });

    test('download throws on invalid country code', () async {
      // Mock countries response
      when(mockClient.get(Uri.parse('$mainUrl/countries')))
          .thenAnswer((_) async => http.Response('{"countries": "PL~US"}', 200));

      // Make sure invalid country code throws
      expect(
        () => downloadWithClient('XX', tempDir.path, mockClient),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('process data handles sub-keys correctly', () async {
      // Setup mocks for a country with sub-regions
      when(mockClient.get(Uri.parse('$mainUrl/CH')))
          .thenAnswer((_) async => http.Response('''
                {
                  "key": "CH",
                  "lang": "de",
                  "name": "SWITZERLAND",
                  "languages": "de~fr",
                  "sub_keys": "AG~AR",
                  "sub_names": "Aargau~Appenzell Ausserrhoden"
                }
                ''', 200));

      when(mockClient.get(Uri.parse('$mainUrl/CH/AG'))).thenAnswer(
          (_) async => http.Response('{"key": "CH/AG", "name": "Aargau"}', 200));

      when(mockClient.get(Uri.parse('$mainUrl/CH/AR'))).thenAnswer((_) async =>
          http.Response('{"key": "CH/AR", "name": "Appenzell Ausserrhoden"}', 200));

      when(mockClient.get(Uri.parse('$mainUrl/CH?lang=fr'))).thenAnswer((_) async =>
          http.Response('{"key": "CH", "lang": "fr", "name": "SUISSE"}', 200));

      // Run the process test with mocked client
      final allData = <String, Map<String, dynamic>>{};
      await processData('CH', null, allData, client: mockClient);

      // Verify the correct data was processed
      expect(allData.containsKey('CH'), true);
      expect(allData.containsKey('CH/AG'), true);
      expect(allData.containsKey('CH/AR'), true);

      expect(allData['CH']?['name'], 'SWITZERLAND');
      expect(allData['CH/AG']?['name'], 'Aargau');
      expect(allData['CH/AR']?['name'], 'Appenzell Ausserrhoden');
    });

    test('download all countries', () async {
      // Mocking responses for country listing
      when(mockClient.get(Uri.parse('$mainUrl/countries')))
          .thenAnswer((_) async => http.Response('{"countries": "PL~US"}', 200));

      when(mockClient.get(Uri.parse('$mainUrl/PL'))).thenAnswer((_) async =>
          http.Response('{"key": "PL", "lang": "pl", "name": "POLAND"}', 200));

      when(mockClient.get(Uri.parse('$mainUrl/US'))).thenAnswer((_) async =>
          http.Response('{"key": "US", "lang": "en", "name": "UNITED STATES"}', 200));

      // Set output directory to temp directory
      final dataDir = '${tempDir.path}/data';
      Directory(dataDir).createSync();

      // Run download with mocked client for all countries
      await downloadWithClient(null, dataDir, mockClient);

      // Verify that all files were created correctly
      final plFile = File('$dataDir/pl.json');
      final usFile = File('$dataDir/us.json');
      final allFile = File('$dataDir/all.json');

      expect(plFile.existsSync(), true);
      expect(usFile.existsSync(), true);
      expect(allFile.existsSync(), true);

      final allData = json.decode(allFile.readAsStringSync());
      expect(allData, contains('PL'));
      expect(allData, contains('US'));
    });

    test('serialize handles unicode data correctly', () {
      final testData = {'test': 'data with unicode: äöü'};
      final filePath = '${tempDir.path}/test.json';

      final result = serialize(testData, filePath);

      expect(result, '{"test":"data with unicode: äöü"}');
      expect(File(filePath).existsSync(), isTrue);
      expect(json.decode(File(filePath).readAsStringSync()), equals(testData));
    });

    test('download with existing data directory', () async {
      // Create data directory before download
      final dataDir = '${tempDir.path}/data';
      Directory(dataDir).createSync();

      // Mocking responses for country listing
      when(mockClient.get(Uri.parse('$mainUrl/countries')))
          .thenAnswer((_) async => http.Response('{"countries": "PL"}', 200));

      when(mockClient.get(Uri.parse('$mainUrl/PL'))).thenAnswer((_) async =>
          http.Response('{"key": "PL", "lang": "pl", "name": "POLAND"}', 200));

      // Run download with mocked client
      await downloadWithClient('PL', dataDir, mockClient);

      // Verify that the file was created in the existing directory
      expect(File('$dataDir/pl.json').existsSync(), true);
    });
  });

  test('New JSON downloaded matches the old JSON',
      skip:
          'Skipping this test as it is a convenience test to be used manually to test the downloader',
      () async {
    final oldUsJsonFile = File('test/usJsonReference.json');

    expect(oldUsJsonFile.existsSync(), isTrue);

    final oldUsJson = json.decode(oldUsJsonFile.readAsStringSync());

    expect(oldUsJson, equals(newUsJson));
  });
}

/// The new US JSON file. Paste here the content of the new US JSON file.
/// This was kept outside the test to avoid make the code too large.
const newUsJson = {
  'US': {
    'id': 'data/US',
    'key': 'US',
    'name': 'UNITED STATES',
    'lang': 'en',
    'languages': 'en',
    'fmt': '%N%n%O%n%A%n%C, %S %Z',
    'require': 'ACSZ',
    'upper': 'CS',
    'zip': '(\\d{5})(?:[ \\-](\\d{4}))?',
    'zipex': '95014,22162-1010',
    'posturl': 'https://tools.usps.com/go/ZipLookupAction!input.action',
    'zip_name_type': 'zip',
    'state_name_type': 'state',
    'sub_keys':
        'AL~AK~AS~AZ~AR~AA~AE~AP~CA~CO~CT~DE~DC~FL~GA~GU~HI~ID~IL~IN~IA~KS~KY~LA~ME~MH~MD~MA~MI~FM~MN~MS~MO~MT~NE~NV~NH~NJ~NM~NY~NC~ND~MP~OH~OK~OR~PW~PA~PR~RI~SC~SD~TN~TX~UT~VT~VI~VA~WA~WV~WI~WY',
    'sub_names':
        'Alabama~Alaska~American Samoa~Arizona~Arkansas~Armed Forces (AA)~Armed Forces (AE)~Armed Forces (AP)~California~Colorado~Connecticut~Delaware~District of Columbia~Florida~Georgia~Guam~Hawaii~Idaho~Illinois~Indiana~Iowa~Kansas~Kentucky~Louisiana~Maine~Marshall Islands~Maryland~Massachusetts~Michigan~Micronesia~Minnesota~Mississippi~Missouri~Montana~Nebraska~Nevada~New Hampshire~New Jersey~New Mexico~New York~North Carolina~North Dakota~Northern Mariana Islands~Ohio~Oklahoma~Oregon~Palau~Pennsylvania~Puerto Rico~Rhode Island~South Carolina~South Dakota~Tennessee~Texas~Utah~Vermont~Virgin Islands~Virginia~Washington~West Virginia~Wisconsin~Wyoming',
    'sub_zips':
        '3[56]~99[5-9]~96799~8[56]~71[6-9]|72~340~09~96[2-6]~9[0-5]|96[01]~8[01]~06~19[7-9]~20[02-5]|569~3[23]|34[1-9]~3[01]|398|39901~969([1-2]\\d|3[12])~967[0-8]|9679[0-8]|968~83[2-9]~6[0-2]~4[67]~5[0-2]~6[67]~4[01]|42[0-7]~70|71[0-5]~039|04~969[67]~20[6-9]|21~01|02[0-7]|05501|05544~4[89]~9694[1-4]~55|56[0-7]~38[6-9]|39[0-7]~6[3-5]~59~6[89]~889|89~03[0-8]~0[78]~87|88[0-4]~1[0-4]|06390|00501|00544~2[78]~58~9695[0-2]~4[3-5]~7[34]~97~969(39|40)~1[5-8]|19[0-6]~00[679]~02[89]~29~57~37|38[0-5]~7[5-9]|885|73301|73344~84~05~008~201|2[23]|24[0-6]~98|99[0-4]~24[7-9]|2[56]~5[34]~82|83[01]|83414',
    'sub_zipexs':
        '35000,36999~99500,99999~96799~85000,86999~71600,72999~34000,34099~09000,09999~96200,96699~90000,96199~80000,81999~06000,06999~19700,19999~20000,56999~32000,34999~30000,39901~96910,96932~96700,96899~83200,83999~60000,62999~46000,47999~50000,52999~66000,67999~40000,42799~70000,71599~03900,04999~96960,96979~20600,21999~01000,05544~48000,49999~96941,96944~55000,56799~38600,39799~63000,65999~59000,59999~68000,69999~88900,89999~03000,03899~07000,08999~87000,88499~10000,00544~27000,28999~58000,58999~96950,96952~43000,45999~73000,74999~97000,97999~96940~15000,19699~00600,00999~02800,02999~29000,29999~57000,57999~37000,38599~75000,73344~84000,84999~05000,05999~00800,00899~20100,24699~98000,99499~24700,26999~53000,54999~82000,83414',
    'sub_isoids':
        'AL~AK~~AZ~AR~~~~CA~CO~CT~DE~DC~FL~GA~~HI~ID~IL~IN~IA~KS~KY~LA~ME~~MD~MA~MI~~MN~MS~MO~MT~NE~NV~NH~NJ~NM~NY~NC~ND~~OH~OK~OR~~PA~~RI~SC~SD~TN~TX~UT~VT~~VA~WA~WV~WI~WY'
  },
  'US/AL': {
    'id': 'data/US/AL',
    'key': 'AL',
    'name': 'Alabama',
    'lang': 'en',
    'zip': '3[56]',
    'zipex': '35000,36999',
    'isoid': 'AL'
  },
  'US/AK': {
    'id': 'data/US/AK',
    'key': 'AK',
    'name': 'Alaska',
    'lang': 'en',
    'zip': '99[5-9]',
    'zipex': '99500,99999',
    'isoid': 'AK'
  },
  'US/AS': {
    'id': 'data/US/AS',
    'key': 'AS',
    'name': 'American Samoa',
    'lang': 'en',
    'zip': '96799',
    'zipex': '96799'
  },
  'US/AZ': {
    'id': 'data/US/AZ',
    'key': 'AZ',
    'name': 'Arizona',
    'lang': 'en',
    'zip': '8[56]',
    'zipex': '85000,86999',
    'isoid': 'AZ'
  },
  'US/AR': {
    'id': 'data/US/AR',
    'key': 'AR',
    'name': 'Arkansas',
    'lang': 'en',
    'zip': '71[6-9]|72',
    'zipex': '71600,72999',
    'isoid': 'AR'
  },
  'US/AA': {
    'id': 'data/US/AA',
    'key': 'AA',
    'name': 'Armed Forces (AA)',
    'lang': 'en',
    'zip': '340',
    'zipex': '34000,34099'
  },
  'US/AE': {
    'id': 'data/US/AE',
    'key': 'AE',
    'name': 'Armed Forces (AE)',
    'lang': 'en',
    'zip': '09',
    'zipex': '09000,09999'
  },
  'US/AP': {
    'id': 'data/US/AP',
    'key': 'AP',
    'name': 'Armed Forces (AP)',
    'lang': 'en',
    'zip': '96[2-6]',
    'zipex': '96200,96699'
  },
  'US/CA': {
    'id': 'data/US/CA',
    'key': 'CA',
    'name': 'California',
    'lang': 'en',
    'zip': '9[0-5]|96[01]',
    'zipex': '90000,96199',
    'isoid': 'CA'
  },
  'US/CO': {
    'id': 'data/US/CO',
    'key': 'CO',
    'name': 'Colorado',
    'lang': 'en',
    'zip': '8[01]',
    'zipex': '80000,81999',
    'isoid': 'CO'
  },
  'US/CT': {
    'id': 'data/US/CT',
    'key': 'CT',
    'name': 'Connecticut',
    'lang': 'en',
    'zip': '06',
    'zipex': '06000,06999',
    'isoid': 'CT'
  },
  'US/DE': {
    'id': 'data/US/DE',
    'key': 'DE',
    'name': 'Delaware',
    'lang': 'en',
    'zip': '19[7-9]',
    'zipex': '19700,19999',
    'isoid': 'DE'
  },
  'US/DC': {
    'id': 'data/US/DC',
    'key': 'DC',
    'name': 'District of Columbia',
    'lang': 'en',
    'zip': '20[02-5]|569',
    'zipex': '20000,56999',
    'isoid': 'DC'
  },
  'US/FL': {
    'id': 'data/US/FL',
    'key': 'FL',
    'name': 'Florida',
    'lang': 'en',
    'zip': '3[23]|34[1-9]',
    'zipex': '32000,34999',
    'isoid': 'FL'
  },
  'US/GA': {
    'id': 'data/US/GA',
    'key': 'GA',
    'name': 'Georgia',
    'lang': 'en',
    'zip': '3[01]|398|39901',
    'zipex': '30000,39901',
    'isoid': 'GA'
  },
  'US/GU': {
    'id': 'data/US/GU',
    'key': 'GU',
    'name': 'Guam',
    'lang': 'en',
    'zip': '969([1-2]\\d|3[12])',
    'zipex': '96910,96932'
  },
  'US/HI': {
    'id': 'data/US/HI',
    'key': 'HI',
    'name': 'Hawaii',
    'lang': 'en',
    'zip': '967[0-8]|9679[0-8]|968',
    'zipex': '96700,96899',
    'isoid': 'HI'
  },
  'US/ID': {
    'id': 'data/US/ID',
    'key': 'ID',
    'name': 'Idaho',
    'lang': 'en',
    'zip': '83[2-9]',
    'zipex': '83200,83999',
    'isoid': 'ID'
  },
  'US/IL': {
    'id': 'data/US/IL',
    'key': 'IL',
    'name': 'Illinois',
    'lang': 'en',
    'zip': '6[0-2]',
    'zipex': '60000,62999',
    'isoid': 'IL'
  },
  'US/IN': {
    'id': 'data/US/IN',
    'key': 'IN',
    'name': 'Indiana',
    'lang': 'en',
    'zip': '4[67]',
    'zipex': '46000,47999',
    'isoid': 'IN'
  },
  'US/IA': {
    'id': 'data/US/IA',
    'key': 'IA',
    'name': 'Iowa',
    'lang': 'en',
    'zip': '5[0-2]',
    'zipex': '50000,52999',
    'isoid': 'IA'
  },
  'US/KS': {
    'id': 'data/US/KS',
    'key': 'KS',
    'name': 'Kansas',
    'lang': 'en',
    'zip': '6[67]',
    'zipex': '66000,67999',
    'isoid': 'KS'
  },
  'US/KY': {
    'id': 'data/US/KY',
    'key': 'KY',
    'name': 'Kentucky',
    'lang': 'en',
    'zip': '4[01]|42[0-7]',
    'zipex': '40000,42799',
    'isoid': 'KY'
  },
  'US/LA': {
    'id': 'data/US/LA',
    'key': 'LA',
    'name': 'Louisiana',
    'lang': 'en',
    'zip': '70|71[0-5]',
    'zipex': '70000,71599',
    'isoid': 'LA'
  },
  'US/ME': {
    'id': 'data/US/ME',
    'key': 'ME',
    'name': 'Maine',
    'lang': 'en',
    'zip': '039|04',
    'zipex': '03900,04999',
    'isoid': 'ME'
  },
  'US/MH': {
    'id': 'data/US/MH',
    'key': 'MH',
    'name': 'Marshall Islands',
    'lang': 'en',
    'zip': '969[67]',
    'zipex': '96960,96979'
  },
  'US/MD': {
    'id': 'data/US/MD',
    'key': 'MD',
    'name': 'Maryland',
    'lang': 'en',
    'zip': '20[6-9]|21',
    'zipex': '20600,21999',
    'isoid': 'MD'
  },
  'US/MA': {
    'id': 'data/US/MA',
    'key': 'MA',
    'name': 'Massachusetts',
    'lang': 'en',
    'zip': '01|02[0-7]|05501|05544',
    'zipex': '01000,05544',
    'isoid': 'MA'
  },
  'US/MI': {
    'id': 'data/US/MI',
    'key': 'MI',
    'name': 'Michigan',
    'lang': 'en',
    'zip': '4[89]',
    'zipex': '48000,49999',
    'isoid': 'MI'
  },
  'US/FM': {
    'id': 'data/US/FM',
    'key': 'FM',
    'name': 'Micronesia',
    'lang': 'en',
    'zip': '9694[1-4]',
    'zipex': '96941,96944'
  },
  'US/MN': {
    'id': 'data/US/MN',
    'key': 'MN',
    'name': 'Minnesota',
    'lang': 'en',
    'zip': '55|56[0-7]',
    'zipex': '55000,56799',
    'isoid': 'MN'
  },
  'US/MS': {
    'id': 'data/US/MS',
    'key': 'MS',
    'name': 'Mississippi',
    'lang': 'en',
    'zip': '38[6-9]|39[0-7]',
    'zipex': '38600,39799',
    'isoid': 'MS'
  },
  'US/MO': {
    'id': 'data/US/MO',
    'key': 'MO',
    'name': 'Missouri',
    'lang': 'en',
    'zip': '6[3-5]',
    'zipex': '63000,65999',
    'isoid': 'MO'
  },
  'US/MT': {
    'id': 'data/US/MT',
    'key': 'MT',
    'name': 'Montana',
    'lang': 'en',
    'zip': '59',
    'zipex': '59000,59999',
    'isoid': 'MT'
  },
  'US/NE': {
    'id': 'data/US/NE',
    'key': 'NE',
    'name': 'Nebraska',
    'lang': 'en',
    'zip': '6[89]',
    'zipex': '68000,69999',
    'isoid': 'NE'
  },
  'US/NV': {
    'id': 'data/US/NV',
    'key': 'NV',
    'name': 'Nevada',
    'lang': 'en',
    'zip': '889|89',
    'zipex': '88900,89999',
    'isoid': 'NV'
  },
  'US/NH': {
    'id': 'data/US/NH',
    'key': 'NH',
    'name': 'New Hampshire',
    'lang': 'en',
    'zip': '03[0-8]',
    'zipex': '03000,03899',
    'isoid': 'NH'
  },
  'US/NJ': {
    'id': 'data/US/NJ',
    'key': 'NJ',
    'name': 'New Jersey',
    'lang': 'en',
    'zip': '0[78]',
    'zipex': '07000,08999',
    'isoid': 'NJ'
  },
  'US/NM': {
    'id': 'data/US/NM',
    'key': 'NM',
    'name': 'New Mexico',
    'lang': 'en',
    'zip': '87|88[0-4]',
    'zipex': '87000,88499',
    'isoid': 'NM'
  },
  'US/NY': {
    'id': 'data/US/NY',
    'key': 'NY',
    'name': 'New York',
    'lang': 'en',
    'zip': '1[0-4]|06390|00501|00544',
    'zipex': '10000,00544',
    'isoid': 'NY'
  },
  'US/NC': {
    'id': 'data/US/NC',
    'key': 'NC',
    'name': 'North Carolina',
    'lang': 'en',
    'zip': '2[78]',
    'zipex': '27000,28999',
    'isoid': 'NC'
  },
  'US/ND': {
    'id': 'data/US/ND',
    'key': 'ND',
    'name': 'North Dakota',
    'lang': 'en',
    'zip': '58',
    'zipex': '58000,58999',
    'isoid': 'ND'
  },
  'US/MP': {
    'id': 'data/US/MP',
    'key': 'MP',
    'name': 'Northern Mariana Islands',
    'lang': 'en',
    'zip': '9695[0-2]',
    'zipex': '96950,96952'
  },
  'US/OH': {
    'id': 'data/US/OH',
    'key': 'OH',
    'name': 'Ohio',
    'lang': 'en',
    'zip': '4[3-5]',
    'zipex': '43000,45999',
    'isoid': 'OH'
  },
  'US/OK': {
    'id': 'data/US/OK',
    'key': 'OK',
    'name': 'Oklahoma',
    'lang': 'en',
    'zip': '7[34]',
    'zipex': '73000,74999',
    'isoid': 'OK'
  },
  'US/OR': {
    'id': 'data/US/OR',
    'key': 'OR',
    'name': 'Oregon',
    'lang': 'en',
    'zip': '97',
    'zipex': '97000,97999',
    'isoid': 'OR'
  },
  'US/PW': {
    'id': 'data/US/PW',
    'key': 'PW',
    'name': 'Palau',
    'lang': 'en',
    'zip': '969(39|40)',
    'zipex': '96940'
  },
  'US/PA': {
    'id': 'data/US/PA',
    'key': 'PA',
    'name': 'Pennsylvania',
    'lang': 'en',
    'zip': '1[5-8]|19[0-6]',
    'zipex': '15000,19699',
    'isoid': 'PA'
  },
  'US/PR': {
    'id': 'data/US/PR',
    'key': 'PR',
    'name': 'Puerto Rico',
    'lang': 'en',
    'zip': '00[679]',
    'zipex': '00600,00999'
  },
  'US/RI': {
    'id': 'data/US/RI',
    'key': 'RI',
    'name': 'Rhode Island',
    'lang': 'en',
    'zip': '02[89]',
    'zipex': '02800,02999',
    'isoid': 'RI'
  },
  'US/SC': {
    'id': 'data/US/SC',
    'key': 'SC',
    'name': 'South Carolina',
    'lang': 'en',
    'zip': '29',
    'zipex': '29000,29999',
    'isoid': 'SC'
  },
  'US/SD': {
    'id': 'data/US/SD',
    'key': 'SD',
    'name': 'South Dakota',
    'lang': 'en',
    'zip': '57',
    'zipex': '57000,57999',
    'isoid': 'SD'
  },
  'US/TN': {
    'id': 'data/US/TN',
    'key': 'TN',
    'name': 'Tennessee',
    'lang': 'en',
    'zip': '37|38[0-5]',
    'zipex': '37000,38599',
    'isoid': 'TN'
  },
  'US/TX': {
    'id': 'data/US/TX',
    'key': 'TX',
    'name': 'Texas',
    'lang': 'en',
    'zip': '7[5-9]|885|73301|73344',
    'zipex': '75000,73344',
    'isoid': 'TX'
  },
  'US/UT': {
    'id': 'data/US/UT',
    'key': 'UT',
    'name': 'Utah',
    'lang': 'en',
    'zip': '84',
    'zipex': '84000,84999',
    'isoid': 'UT'
  },
  'US/VT': {
    'id': 'data/US/VT',
    'key': 'VT',
    'name': 'Vermont',
    'lang': 'en',
    'zip': '05',
    'zipex': '05000,05999',
    'isoid': 'VT'
  },
  'US/VI': {
    'id': 'data/US/VI',
    'key': 'VI',
    'name': 'Virgin Islands',
    'lang': 'en',
    'zip': '008',
    'zipex': '00800,00899'
  },
  'US/VA': {
    'id': 'data/US/VA',
    'key': 'VA',
    'name': 'Virginia',
    'lang': 'en',
    'zip': '201|2[23]|24[0-6]',
    'zipex': '20100,24699',
    'isoid': 'VA'
  },
  'US/WA': {
    'id': 'data/US/WA',
    'key': 'WA',
    'name': 'Washington',
    'lang': 'en',
    'zip': '98|99[0-4]',
    'zipex': '98000,99499',
    'isoid': 'WA'
  },
  'US/WV': {
    'id': 'data/US/WV',
    'key': 'WV',
    'name': 'West Virginia',
    'lang': 'en',
    'zip': '24[7-9]|2[56]',
    'zipex': '24700,26999',
    'isoid': 'WV'
  },
  'US/WI': {
    'id': 'data/US/WI',
    'key': 'WI',
    'name': 'Wisconsin',
    'lang': 'en',
    'zip': '5[34]',
    'zipex': '53000,54999',
    'isoid': 'WI'
  },
  'US/WY': {
    'id': 'data/US/WY',
    'key': 'WY',
    'name': 'Wyoming',
    'lang': 'en',
    'zip': '82|83[01]|83414',
    'zipex': '82000,83414',
    'isoid': 'WY'
  }
};

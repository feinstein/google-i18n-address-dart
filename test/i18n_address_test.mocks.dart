// Mock implementation
import 'package:mockito/mockito.dart';

class MockDataLoader extends Mock {
  Map<String, dynamic> loadCountryData(String countryCode) {
    return super.noSuchMethod(
      Invocation.method(#loadCountryData, [countryCode]),
      returnValue: <String, dynamic>{
        'US': {'name': 'UNITED STATES'},
        'US/NV': {'name': 'Nevada'},
      },
    );
  }
}

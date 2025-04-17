// Mock implementation
import 'package:mockito/mockito.dart';

import 'scripts_test.dart';

class MockDownloader extends Mock implements Downloader {
  @override
  Future<void> download({String? country, String? outputDir}) {
    return super.noSuchMethod(
      Invocation.method(
          #download, [], {#country: country, #outputDir: outputDir}),
      returnValue: Future.value(),
    );
  }
}

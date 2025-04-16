import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

@GenerateNiceMocks([MockSpec<Downloader>()])
import 'scripts_test.mocks.dart';

class Downloader {
  Future<void> download({String? country, String? outputDir}) async {
    // This would be the actual implementation
  }
}

class ArgumentParser {
  final Map<String, dynamic> _options = {};
  final Map<String, String> _descriptions = {};
  String get usage => _descriptions.entries.map((e) => '${e.key}: ${e.value}').join('\n');

  void addFlag(String name, {String? abbr, String? help, bool negatable = true}) {
    _options[name] = false;
    if (abbr != null) {
      _options[abbr] = false;
    }
    if (help != null) {
      _descriptions[name] = help;
    }
  }

  void addOption(String name, {String? abbr, String? help}) {
    _options[name] = null;
    if (abbr != null) {
      _options[abbr] = null;
    }
    if (help != null) {
      _descriptions[name] = help;
    }
  }

  Map<String, dynamic> parse(List<String> arguments) {
    final result = <String, dynamic>{};
    for (final key in _options.keys) {
      result[key] = _options[key];
    }

    for (var i = 0; i < arguments.length; i++) {
      final arg = arguments[i];
      if (arg.startsWith('--')) {
        final option = arg.substring(2);
        if (_options.containsKey(option)) {
          if (_options[option] is bool) {
            result[option] = true;
          } else {
            if (i + 1 < arguments.length && !arguments[i + 1].startsWith('-')) {
              result[option] = arguments[i + 1];
              i++;
            }
          }
        }
      } else if (arg.startsWith('-')) {
        final option = arg.substring(1);
        if (_options.containsKey(option)) {
          if (_options[option] is bool) {
            result[option] = true;
          } else {
            if (i + 1 < arguments.length && !arguments[i + 1].startsWith('-')) {
              result[option] = arguments[i + 1];
              i++;
            }
          }
        }
      }
    }
    return result;
  }
}

void main() {
  group('Scripts', () {
    late MockDownloader mockDownloader;

    setUp(() {
      mockDownloader = MockDownloader();
    });

    // This is a mock for the script functionality that would be
// called from a command-line tool
    Future<void> mockDownloadJsonFiles({List<String>? arguments}) async {
      final parser = ArgumentParser();
      parser
        ..addFlag('help', abbr: 'h', help: 'Show this help message', negatable: false)
        ..addOption('country', abbr: 'c', help: 'Country code to download')
        ..addOption('output-dir', abbr: 'o', help: 'Output directory');

      final results = parser.parse(arguments ?? []);

      if (results['help'] == true) {
        return;
      }

      final country = results['country'] as String?;
      final outputDir = results['output-dir'] as String?;

      await mockDownloader.download(country: country, outputDir: outputDir);
    }

    test('download_json_files all countries', () async {
      when(mockDownloader.download()).thenAnswer((_) async {});

      // Mock as if the script was called without any arguments
      await mockDownloadJsonFiles(arguments: []);

      // Verify the downloader was called with no country specified
      verify(mockDownloader.download()).called(1);
    });

    test('download_json_files specific country', () async {
      when(mockDownloader.download(country: 'US')).thenAnswer((_) async {});

      // Mock as if the script was called with a country argument
      await mockDownloadJsonFiles(arguments: ['--country', 'US']);

      // Verify the downloader was called with the specific country
      verify(mockDownloader.download(country: 'US')).called(1);
    });

    test('download_json_files with output directory', () async {
      when(mockDownloader.download(outputDir: '/tmp/output')).thenAnswer((_) async {});

      // Mock as if the script was called with an output directory argument
      await mockDownloadJsonFiles(arguments: ['--output-dir', '/tmp/output']);

      // Verify the downloader was called with the output directory
      verify(mockDownloader.download(outputDir: '/tmp/output')).called(1);
    });

    test('download_json_files with both country and output directory', () async {
      when(mockDownloader.download(country: 'US', outputDir: '/tmp/output'))
          .thenAnswer((_) async {});

      // Mock as if the script was called with both arguments
      await mockDownloadJsonFiles(
          arguments: ['--country', 'US', '--output-dir', '/tmp/output']);

      // Verify the downloader was called with both parameters
      verify(mockDownloader.download(country: 'US', outputDir: '/tmp/output')).called(1);
    });

    test('download_json_files help flag', () async {
      // Mock as if the script was called with the help flag
      await mockDownloadJsonFiles(arguments: ['--help']);

      // No need to verify, as the help text would be printed
      verifyNever(mockDownloader.download(country: anyNamed('country'), outputDir: anyNamed('outputDir')));
    });
  });
}

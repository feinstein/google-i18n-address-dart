import 'dart:io';

import 'package:args/args.dart';
import 'package:google_i18n_address/google_i18n_address.dart' as i18n;

/// Command-line tool to download address validation files.
///
/// This can be used to update the address data from Google's i18n database.
void main(List<String> arguments) async {
  // Parse command-line arguments
  final parser = ArgParser()
    ..addOption('country',
        abbr: 'c',
        help:
            'Alpha-2 code of the country to download (downloads all if not specified)');

  try {
    final argResults = parser.parse(arguments);
    final country = argResults['country'] as String?;

    // Download the files
    i18n.downloadJsonFiles(country: country);
  } catch (e) {
    // ignore: avoid_print
    print('Error: $e');
    // ignore: avoid_print
    print('Usage: update_validation_files [options]');
    // ignore: avoid_print
    print(parser.usage);
    exit(1);
  }
}

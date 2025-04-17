# JSON Data Update Tool

This tool downloads address data from Google's i18n address database and converts it to Dart getters for lazy loading.

## Features

- Downloads JSON files from Google's i18n address database
- Converts JSON files to Dart getters
- Creates a jsonData.dart file that maps all getters
- Supports updating a single country or all countries

## Usage

```bash
# Update all countries (download and convert)
dart tool/update_json_files.dart

# Show help
dart tool/update_json_files.dart --help

# Only download JSON files, don't convert to Dart
dart tool/update_json_files.dart --download

# Only convert existing JSON files to Dart
dart tool/update_json_files.dart --convert

# Update a specific country (e.g., US)
dart tool/update_json_files.dart --country=us
```

## Options

- `-h, --help` - Show usage information
- `-d, --download` - Download JSON files
- `-c, --convert` - Convert JSON files to Dart getters
- `-o, --country=<code>` - Process only the specified country code

## How it works

The tool downloads JSON files containing address formatting information from Google's i18n address database. It then converts these files into Dart getters, which are only loaded when needed.

This approach ensures memory efficiency since the data is only loaded when a specific country's address format is requested.

The output includes:
1. JSON files for each country (e.g., `us.json`)
2. Dart getter files for each country (e.g., `us.json.dart`)
3. A `jsonData.dart` file that maps country codes to their respective getter functions 
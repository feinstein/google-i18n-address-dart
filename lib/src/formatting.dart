import 'models.dart';
import 'validation.dart';

/// Formats an address line according to a format string.
///
/// Replaces placeholders with actual field values.
String _formatAddressLine(
    String lineFormat, Map<String, String> address, ValidationRules rules) {
  // Helper function to get field value
  String getField(String name) {
    var value = address[name] ?? '';
    if (rules.upperFields.contains(name)) {
      value = value.toUpperCase();
    }
    return value;
  }

  // Create replacements map
  final replacements = <String, String>{};
  fieldMapping.forEach((code, fieldName) {
    replacements['%$code'] = getField(fieldName);
  });

  // Split format into parts and replace placeholders
  final parts =
      RegExp(r'(%.)').allMatches(lineFormat).map((match) => match.group(0)!).toList();

  // Keep track of the current position in the format string
  var currentPos = 0;
  final result = StringBuffer();

  for (final part in parts) {
    // Find the position of the current part
    final partPos = lineFormat.indexOf(part, currentPos);

    // Add any text between the previous part and this one
    if (partPos > currentPos) {
      result.write(lineFormat.substring(currentPos, partPos));
    }

    // Add the replacement for this part
    result.write(replacements[part] ?? part);

    // Update current position
    currentPos = partPos + part.length;
  }

  // Add any remaining text after the last part
  if (currentPos < lineFormat.length) {
    result.write(lineFormat.substring(currentPos));
  }

  return result.toString().trim();
}

/// Formats an address according to country-specific rules.
///
/// Returns a formatted address string suitable for printing on an envelope.
/// If [latin] is true, uses Latin-friendly format where available.
String formatAddress(Map<String, String> address, {bool latin = false}) {
  final rules = getValidationRules(address);
  final addressFormat = latin ? rules.addressLatinFormat : rules.addressFormat;
  final addressLineFormats = addressFormat.split('%n');

  final addressLines = <String>[];

  // Format each line
  for (final lineFormat in addressLineFormats) {
    final formattedLine = _formatAddressLine(lineFormat, address, rules);
    if (formattedLine.isNotEmpty) {
      addressLines.add(formattedLine);
    }
  }

  // Add country name
  addressLines.add(rules.countryName);

  // Filter out empty lines and join
  return addressLines.where((line) => line.isNotEmpty).join('\n');
}

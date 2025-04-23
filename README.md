# Google i18n Address for Dart

This package contains a copy of [Google's i18n address](https://chromium-i18n.appspot.com/ssl-address) metadata repository that contains great data but comes with no uptime guarantees.

Contents of this package will allow you to programmatically build address forms that adhere to rules of a particular region or country, validate local addresses, and format them to produce a valid address label for delivery.

## Address Validation

The `normalizeAddress` function checks the address and either returns its canonical form (suitable for storage and use in addressing envelopes) or throws an `InvalidAddressError` exception that contains a list of errors.

### Address Fields

Here is the list of recognized fields:

- `AddressField.countryCode` is a two-letter ISO 3166-1 country code
- `AddressField.countryArea` is a designation of a region, province, or state. Recognized values include official names, designated abbreviations, official translations, and Latin transliterations
- `AddressField.city` is a city or town name. Recognized values include official names, official translations, and Latin transliterations
- `AddressField.cityArea` is a sublocality like a district. Recognized values include official names, official translations, and Latin transliterations
- `AddressField.streetAddress` is the (possibly multiline) street address
- `AddressField.postalCode` is a postal code or zip code
- `AddressField.sortingCode` is a sorting code
- `AddressField.name` is a person's name
- `AddressField.companyName` is a name of a company or organization

### Errors

Address validation with only country code:

```dart
import 'package:google_i18n_address/google_i18n_address.dart';

void main() {
  try {
    final address = normalizeAddress({AddressField.countryCode: 'US'});
  } on InvalidAddressError catch (e) {
    print(e.errors);
  }
}
```

Output:

```console
{AddressField.city: required, AddressField.countryArea: required, AddressField.postalCode: required, AddressField.streetAddress: required}
```

With correct address:

```dart
import 'package:google_i18n_address/google_i18n_address.dart';

void main() {
  final address = normalizeAddress({
    AddressField.countryCode: 'US',
    AddressField.countryArea: 'California',
    AddressField.city: 'Mountain View',
    AddressField.postalCode: '94043',
    AddressField.streetAddress: '1600 Amphitheatre Pkwy'
  });
  print(address);
}
```

Output:

```console
{AddressField.city: MOUNTAIN VIEW, AddressField.cityArea: , AddressField.countryArea: CA, AddressField.countryCode: US, AddressField.postalCode: 94043, AddressField.sortingCode: , AddressField.streetAddress: 1600 Amphitheatre Pkwy}
```

Postal code/zip code validation example:

```dart
import 'package:google_i18n_address/google_i18n_address.dart';

void main() {
  try {
    final address = normalizeAddress({
      AddressField.countryCode: 'US',
      AddressField.countryArea: 'California',
      AddressField.city: 'Mountain View',
      AddressField.postalCode: '74043',
      AddressField.streetAddress: '1600 Amphitheatre Pkwy'
    });
  } on InvalidAddressError catch (e) {
    print(e.errors);
  }
}
```

Output:

```console
{AddressField.postalCode: invalid}
```

## Address Latinization

In some cases, it may be useful to display foreign addresses in a more accessible format. You can use the `latinizeAddress` function to obtain a more verbose, Latinized version of an address.

This version is suitable for display and useful for full-text search indexing, but the normalized form is what should be stored in the database and used when printing address labels.

```dart
import 'package:google_i18n_address/google_i18n_address.dart';

void main() {
  final address = {
    AddressField.countryCode: 'CN',
    AddressField.countryArea: '云南省',
    AddressField.postalCode: '677400',
    AddressField.city: '临沧市',
    AddressField.cityArea: '凤庆县',
    AddressField.streetAddress: '中关村东路1号'
  };
  
  final latinized = latinizeAddress(address);
  print(latinized);
}
```

Output:

```console
{AddressField.countryCode: CN, AddressField.countryArea: Yunnan Sheng, AddressField.city: Lincang Shi, AddressField.cityArea: Fengqing Xian, AddressField.sortingCode: , AddressField.postalCode: 677400, AddressField.streetAddress: 中关村东路1号}
```

It will also return expanded names for area types that normally use codes and abbreviations such as state names in the US:

```dart
import 'package:google_i18n_address/google_i18n_address.dart';

void main() {
  final address = {
    AddressField.countryCode: 'US',
    AddressField.countryArea: 'CA',
    AddressField.postalCode: '94037',
    AddressField.city: 'Mountain View',
    AddressField.streetAddress: '1600 Charleston Rd.'
  };
  
  final latinized = latinizeAddress(address);
  print(latinized);
}
```

Output:

```console
{AddressField.countryCode: US, AddressField.countryArea: California, AddressField.city: Mountain View, AddressField.cityArea: , AddressField.sortingCode: , AddressField.postalCode: 94037, AddressField.streetAddress: 1600 Charleston Rd.}
```

## Address Formatting

You can use the `formatAddress` function to format the address following the destination country's post office regulations:

```dart
import 'package:google_i18n_address/google_i18n_address.dart';

void main() {
  final address = {
    AddressField.countryCode: 'CN',
    AddressField.countryArea: '云南省',
    AddressField.postalCode: '677400',
    AddressField.city: '临沧市',
    AddressField.cityArea: '凤庆县',
    AddressField.streetAddress: '中关村东路1号'
  };
  
  print(formatAddress(address));
}
```

Output:

```console
677400
云南省临沧市凤庆县
中关村东路1号
CHINA
```

You can also ask for a Latin-friendly version:

```dart
import 'package:google_i18n_address/google_i18n_address.dart';

void main() {
  final address = {
    AddressField.countryCode: 'CN',
    AddressField.countryArea: '云南省',
    AddressField.postalCode: '677400',
    AddressField.city: '临沧市',
    AddressField.cityArea: '凤庆县',
    AddressField.streetAddress: '中关村东路1号'
  };
  
  print(formatAddress(address, latin: true));
}
```

Output:

```console
中关村东路1号
凤庆县
临沧市
云南省, 677400
CHINA
```

## Validation Rules

You can use the `getValidationRules` function to obtain validation data useful for constructing address forms specific for a particular country:

```dart
import 'package:google_i18n_address/google_i18n_address.dart';

void main() {
  final rules = getValidationRules({AddressField.countryCode: 'US', AddressField.countryArea: 'CA'});
  print(rules);
}
```

Output:

```console
ValidationRules(countryCode: US, countryName: UNITED STATES, addressFormat: %N%n%O%n%A%n%C, %S %Z, addressLatinFormat: %N%n%O%n%A%n%C, %S %Z, allowedFields: {AddressField.streetAddress, AddressField.companyName, AddressField.city, AddressField.name, AddressField.countryArea, AddressField.postalCode}, requiredFields: {AddressField.streetAddress, AddressField.city, AddressField.countryArea, AddressField.postalCode}, upperFields: {AddressField.city, AddressField.countryArea}, countryAreaType: state, countryAreaChoices: [[AL, Alabama], [AK, Alaska], ...], cityType: city, cityChoices: [], cityAreaType: suburb, cityAreaChoices: [], postalCodeType: zip, postalCodeMatchers: [RegExp: pattern=^(\d{5})(?:[ \-](\d{4}))?$], postalCodeExamples: [90000, 96199], postalCodePrefix: )
```

## Field Order

You can use the `getFieldOrder` function to get the expected order of address form fields:

```dart
import 'package:google_i18n_address/google_i18n_address.dart';

void main() {
  final fieldOrder = getFieldOrder({AddressField.countryCode: 'PL'});
  print(fieldOrder);
}
```

Output:

```console
[[name], [company_name], [AddressField.streetAddress], [AddressField.postalCode, AddressField.city]]
```

## Development

### Updating Address Data

This package includes a tool to update the address data from Google's i18n address database. The tool downloads JSON files and converts them to Dart getters for lazy loading.

```bash
# Update all countries (download and convert to Dart)
dart tool/update_json_files.dart

# Update a specific country (e.g., US)
dart tool/update_json_files.dart --country=us

# Only download the JSON files without converting to Dart
dart tool/update_json_files.dart --download

# Only convert existing JSON files to Dart
dart tool/update_json_files.dart --convert

# Show all options
dart tool/update_json_files.dart --help
```

For more details, see the [tool README](tool/README.md).

## License

This project is licensed under the MIT License.

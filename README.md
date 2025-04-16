# Google i18n Address for Dart

This package contains a copy of [Google's i18n address](https://chromium-i18n.appspot.com/ssl-address) metadata repository that contains great data but comes with no uptime guarantees.

Contents of this package will allow you to programmatically build address forms that adhere to rules of a particular region or country, validate local addresses, and format them to produce a valid address label for delivery.

## Installation

Add this package to your `pubspec.yaml` file:

```yaml
dependencies:
  google_i18n_address: ^1.0.0
```

Then run:

```dart
dart pub get
```

## Address Validation

The `normalizeAddress` function checks the address and either returns its canonical form (suitable for storage and use in addressing envelopes) or throws an `InvalidAddressError` exception that contains a list of errors.

### Address Fields

Here is the list of recognized fields:

- `country_code` is a two-letter ISO 3166-1 country code
- `country_area` is a designation of a region, province, or state. Recognized values include official names, designated abbreviations, official translations, and Latin transliterations
- `city` is a city or town name. Recognized values include official names, official translations, and Latin transliterations
- `city_area` is a sublocality like a district. Recognized values include official names, official translations, and Latin transliterations
- `street_address` is the (possibly multiline) street address
- `postal_code` is a postal code or zip code
- `sorting_code` is a sorting code
- `name` is a person's name
- `company_name` is a name of a company or organization

### Errors

Address validation with only country code:

```dart
import 'package:google_i18n_address/google_i18n_address.dart';

void main() {
  try {
    final address = normalizeAddress({'country_code': 'US'});
  } on InvalidAddressError catch (e) {
    print(e.errors);
  }
}
```

Output:

```dart
{city: required, country_area: required, postal_code: required, street_address: required}
```

With correct address:

```dart
import 'package:google_i18n_address/google_i18n_address.dart';

void main() {
  final address = normalizeAddress({
    'country_code': 'US',
    'country_area': 'California',
    'city': 'Mountain View',
    'postal_code': '94043',
    'street_address': '1600 Amphitheatre Pkwy'
  });
  print(address);
}
```

Output:

```dart
{city: MOUNTAIN VIEW, city_area: , country_area: CA, country_code: US, postal_code: 94043, sorting_code: , street_address: 1600 Amphitheatre Pkwy}
```

Postal code/zip code validation example:

```dart
import 'package:google_i18n_address/google_i18n_address.dart';

void main() {
  try {
    final address = normalizeAddress({
      'country_code': 'US',
      'country_area': 'California',
      'city': 'Mountain View',
      'postal_code': '74043',
      'street_address': '1600 Amphitheatre Pkwy'
    });
  } on InvalidAddressError catch (e) {
    print(e.errors);
  }
}
```

Output:

```dart
{postal_code: invalid}
```

## Address Latinization

In some cases, it may be useful to display foreign addresses in a more accessible format. You can use the `latinizeAddress` function to obtain a more verbose, Latinized version of an address.

This version is suitable for display and useful for full-text search indexing, but the normalized form is what should be stored in the database and used when printing address labels.

```dart
import 'package:google_i18n_address/google_i18n_address.dart';

void main() {
  final address = {
    'country_code': 'CN',
    'country_area': '云南省',
    'postal_code': '677400',
    'city': '临沧市',
    'city_area': '凤庆县',
    'street_address': '中关村东路1号'
  };
  
  final latinized = latinizeAddress(address);
  print(latinized);
}
```

Output:

```dart
{country_code: CN, country_area: Yunnan Sheng, city: Lincang Shi, city_area: Fengqing Xian, sorting_code: , postal_code: 677400, street_address: 中关村东路1号}
```

It will also return expanded names for area types that normally use codes and abbreviations such as state names in the US:

```dart
import 'package:google_i18n_address/google_i18n_address.dart';

void main() {
  final address = {
    'country_code': 'US',
    'country_area': 'CA',
    'postal_code': '94037',
    'city': 'Mountain View',
    'street_address': '1600 Charleston Rd.'
  };
  
  final latinized = latinizeAddress(address);
  print(latinized);
}
```

Output:

```dart
{country_code: US, country_area: California, city: Mountain View, city_area: , sorting_code: , postal_code: 94037, street_address: 1600 Charleston Rd.}
```

## Address Formatting

You can use the `formatAddress` function to format the address following the destination country's post office regulations:

```dart
import 'package:google_i18n_address/google_i18n_address.dart';

void main() {
  final address = {
    'country_code': 'CN',
    'country_area': '云南省',
    'postal_code': '677400',
    'city': '临沧市',
    'city_area': '凤庆县',
    'street_address': '中关村东路1号'
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
    'country_code': 'CN',
    'country_area': '云南省',
    'postal_code': '677400',
    'city': '临沧市',
    'city_area': '凤庆县',
    'street_address': '中关村东路1号'
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
  final rules = getValidationRules({'country_code': 'US', 'country_area': 'CA'});
  print(rules);
}
```

Output:

```dart
ValidationRules(countryCode: US, countryName: UNITED STATES, addressFormat: %N%n%O%n%A%n%C, %S %Z, addressLatinFormat: %N%n%O%n%A%n%C, %S %Z, allowedFields: {street_address, company_name, city, name, country_area, postal_code}, requiredFields: {street_address, city, country_area, postal_code}, upperFields: {city, country_area}, countryAreaType: state, countryAreaChoices: [[AL, Alabama], [AK, Alaska], ...], cityType: city, cityChoices: [], cityAreaType: suburb, cityAreaChoices: [], postalCodeType: zip, postalCodeMatchers: [RegExp: pattern=^(\d{5})(?:[ \-](\d{4}))?$], postalCodeExamples: [90000, 96199], postalCodePrefix: )
```

## Field Order

You can use the `getFieldOrder` function to get the expected order of address form fields:

```dart
import 'package:google_i18n_address/google_i18n_address.dart';

void main() {
  final fieldOrder = getFieldOrder({'country_code': 'PL'});
  print(fieldOrder);
}
```

Output:

```dart
[[name], [company_name], [street_address], [postal_code, city]]
```

## All Known Fields

You can use the `knownFields` set to render optional address fields as hidden elements of your form:

```dart
import 'package:google_i18n_address/google_i18n_address.dart';

void main() {
  final rules = getValidationRules({'country_code': 'US'});
  print(knownFields.difference(rules.allowedFields));
}
```

Output:

```dart
{city_area, sorting_code}
```

## License

This project is licensed under the MIT License.

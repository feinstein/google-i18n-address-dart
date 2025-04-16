# Flutter Example for google_i18n_address

This example demonstrates how to use the `google_i18n_address` package in a Flutter application to create dynamically validated address forms that adapt to the format of each country.

## Features

- Dynamic form fields based on country selection
- Field validation according to country-specific rules
- Address normalization
- Display of validated address data

## Getting Started

1. Make sure you have the Flutter SDK installed
2. Clone the repository
3. Navigate to this example directory:
   ```
   cd example/flutter_example
   ```
4. Get dependencies:
   ```
   flutter pub get
   ```
5. Run the example:
   ```
   flutter run
   ```

## How It Works

The example consists of two main components:

1. `AddressForm` - A Flutter widget that creates a form with fields that adapt based on the selected country.
2. `MyHomePage` - A demo page that displays the form and the validated address data.

When the user selects a country, the form updates to show the appropriate fields for that country's address format. Field validation is performed according to the country's rules, and when the form is submitted, the address is normalized to a standard format.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_i18n_address/google_i18n_address.dart';

/// A form widget that uses google_i18n_address to validate and format
/// address input according to the selected country.
class AddressForm extends StatefulWidget {
  const AddressForm({super.key, this.onSubmit});

  final void Function(Map<AddressField, String>)? onSubmit;

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final _formKey = GlobalKey<FormState>();
  final _addressData = <AddressField, String>{};
  final _controllers = <AddressField, TextEditingController>{};

  // Sample list of countries - in a real app, you would use a complete list
  final _countries = const [
    {'code': 'US', 'name': 'United States'},
    {'code': 'CA', 'name': 'Canada'},
    {'code': 'GB', 'name': 'United Kingdom'},
    {'code': 'DE', 'name': 'Germany'},
    {'code': 'FR', 'name': 'France'},
    {'code': 'JP', 'name': 'Japan'},
    {'code': 'CN', 'name': 'China'},
    {'code': 'AU', 'name': 'Australia'},
  ];

  ValidationRules? _rules;
  List<List<AddressField>> _fieldOrder = [];
  Map<AddressField, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();

    // Initialize with US as the default country
    _updateCountry('US');

    // Initialize controllers for all known fields
    for (final field in AddressField.values) {
      _controllers[field] = TextEditingController();
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateCountry(String countryCode) {
    setState(() {
      _addressData.clear();
      _addressData[AddressField.countryCode] = countryCode;
      _rules = getValidationRules({AddressField.countryCode: countryCode});
      _fieldOrder = getFieldOrder({AddressField.countryCode: countryCode});
      _fieldErrors = {};
    });
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      try {
        final normalizedAddress = normalizeAddress(_addressData);
        widget.onSubmit?.call(normalizedAddress);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address validated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } on InvalidAddressError catch (e) {
        setState(() {
          _fieldErrors = e.errors;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Address validation failed: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onFieldChanged(AddressField field, String value) {
    setState(() {
      _addressData[field] = value;
      if (_fieldErrors.containsKey(field)) {
        _fieldErrors.remove(field);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Country selector
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Country',
              border: OutlineInputBorder(),
            ),
            value: _addressData['country_code'] ?? 'US',
            items:
                _countries
                    .map(
                      (country) => DropdownMenuItem(
                        value: country['code'],
                        child: Text(country['name']!),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              if (value != null) {
                _updateCountry(value);
              }
            },
          ),
          const SizedBox(height: 16),

          // Dynamic address fields based on country
          AddressFieldsBuilder(
            rules: _rules,
            fieldOrder: _fieldOrder,
            controllers: _controllers,
            addressData: _addressData,
            fieldErrors: _fieldErrors,
            onFieldChanged: _onFieldChanged,
          ),

          const SizedBox(height: 24),

          // Submit button
          ElevatedButton(onPressed: _submitForm, child: const Text('Submit')),
        ],
      ),
    );
  }
}

/// A widget that builds a single address field based on the field name and validation rules.
class AddressTextField extends StatelessWidget {
  const AddressTextField({
    super.key,
    required this.addressField,
    required this.rules,
    required this.controller,
    required this.addressData,
    required this.fieldErrors,
    required this.onChanged,
  });

  final AddressField addressField;
  final ValidationRules rules;
  final TextEditingController? controller;
  final Map<AddressField, String> addressData;
  final Map<AddressField, String> fieldErrors;
  final void Function(AddressField, String) onChanged;

  @override
  Widget build(BuildContext context) {
    final isRequired = rules.requiredFields.contains(addressField);
    final hasError = fieldErrors.containsKey(addressField);
    final errorText = hasError ? fieldErrors[addressField] : null;

    // Handle special cases for fields with choices
    if (addressField == AddressField.countryArea &&
        rules.countryAreaChoices.isNotEmpty) {
      return DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: _getReadableFieldName(addressField),
          border: const OutlineInputBorder(),
          errorText:
              errorText != null
                  ? 'This field is ${errorText == 'invalid' ? 'invalid' : 'required'}'
                  : null,
        ),
        value: addressData[addressField],
        items: [
          if (!isRequired)
            const DropdownMenuItem(value: '', child: Text('-- Select --')),
          ...rules.countryAreaChoices
              .groupFoldBy<String, ({String code, String name})>(
                (choice) => choice.code,
                (previous, element) {
                  if (previous == null) {
                    return element;
                  }
                  return (
                    code: previous.code,
                    name: '${previous.name}, ${element.name}',
                  );
                },
              )
              .entries
              .map(
                (entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value.name),
                ),
              ),
        ],
        onChanged: (value) {
          if (value != null) {
            onChanged(addressField, value);
          }
        },
        validator:
            isRequired
                ? (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null
                : null,
      );
    }

    // Regular text field for other fields
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: _getReadableFieldName(addressField),
        hintText: _getHintText(addressField),
        border: const OutlineInputBorder(),
        errorText:
            errorText != null
                ? 'This field is ${errorText == 'invalid' ? 'invalid' : 'required'}'
                : null,
      ),
      onChanged: (value) {
        onChanged(addressField, value);
      },
      validator:
          isRequired
              ? (value) => (value == null || value.isEmpty) ? 'Required' : null
              : null,
    );
  }

  String _getReadableFieldName(AddressField field) {
    switch (field) {
      case AddressField.countryCode:
        return 'Country';
      case AddressField.countryArea:
        return _countryAreaTypeLabel(rules.countryAreaType);
      case AddressField.city:
        return _cityTypeLabel(rules.cityType);
      case AddressField.cityArea:
        return _cityAreaTypeLabel(rules.cityAreaType);
      case AddressField.postalCode:
        return _postalCodeTypeLabel(rules.postalCodeType);
      case AddressField.streetAddress:
        return 'Street Address';
      case AddressField.sortingCode:
        return 'Sorting Code';
      case AddressField.name:
        return 'Full Name';
      case AddressField.companyName:
        return 'Company';
    }
  }

  String _countryAreaTypeLabel(CountryAreaType type) {
    switch (type) {
      case CountryAreaType.area:
        return 'Area';
      case CountryAreaType.county:
        return 'County';
      case CountryAreaType.department:
        return 'Department';
      case CountryAreaType.district:
        return 'District';
      case CountryAreaType.doOrSi:
        return 'Do/Si';
      case CountryAreaType.emirate:
        return 'Emirate';
      case CountryAreaType.island:
        return 'Island';
      case CountryAreaType.oblast:
        return 'Oblast';
      case CountryAreaType.parish:
        return 'Parish';
      case CountryAreaType.prefecture:
        return 'Prefecture';
      case CountryAreaType.province:
        return 'Province';
      case CountryAreaType.state:
        return 'State';
    }
  }

  String _cityTypeLabel(CityType type) {
    switch (type) {
      case CityType.city:
        return 'City';
      case CityType.district:
        return 'District';
      case CityType.postTown:
        return 'Post Town';
      case CityType.suburb:
        return 'Suburb';
    }
  }

  String _cityAreaTypeLabel(CityAreaType type) {
    switch (type) {
      case CityAreaType.district:
        return 'District';
      case CityAreaType.neighborhood:
        return 'Neighborhood';
      case CityAreaType.suburb:
        return 'Suburb';
      case CityAreaType.townland:
        return 'Townland';
      case CityAreaType.villageOrTownship:
        return 'Village/Township';
    }
  }

  String _postalCodeTypeLabel(PostalCodeType type) {
    switch (type) {
      case PostalCodeType.eircode:
        return 'Eircode';
      case PostalCodeType.pin:
        return 'PIN';
      case PostalCodeType.postal:
        return 'Postal Code';
      case PostalCodeType.zip:
        return 'ZIP Code';
    }
  }

  String _getHintText(AddressField field) {
    switch (field) {
      case AddressField.postalCode:
        return (rules.postalCodeExamples.isNotEmpty)
            ? 'Example: ${rules.postalCodeExamples.first}'
            : '';
      default:
        return '';
    }
  }
}

/// A widget that builds all address fields based on the field order and validation rules.
class AddressFieldsBuilder extends StatelessWidget {
  const AddressFieldsBuilder({
    super.key,
    required this.rules,
    required this.fieldOrder,
    required this.controllers,
    required this.addressData,
    required this.fieldErrors,
    required this.onFieldChanged,
  });

  final ValidationRules? rules;
  final List<List<AddressField>> fieldOrder;
  final Map<AddressField, TextEditingController> controllers;
  final Map<AddressField, String> addressData;
  final Map<AddressField, String> fieldErrors;
  final void Function(AddressField, String) onFieldChanged;

  @override
  Widget build(BuildContext context) {
    final fieldWidgets = <Widget>[];

    if (rules == null) {
      return Column(children: fieldWidgets);
    }

    // Build widgets based on field order
    for (final lineFields in fieldOrder) {
      if (lineFields.length == 1) {
        // Single field per line
        fieldWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AddressTextField(
              addressField: lineFields.first,
              rules: rules!,
              controller: controllers[lineFields.first],
              addressData: addressData,
              fieldErrors: fieldErrors,
              onChanged: onFieldChanged,
            ),
          ),
        );
      } else {
        // Multiple fields per line (e.g., postal code and city)
        fieldWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  lineFields
                      .map(
                        (field) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: field == lineFields.first ? 0 : 8,
                              right: field == lineFields.last ? 0 : 8,
                            ),
                            child: AddressTextField(
                              addressField: field,
                              rules: rules!,
                              controller: controllers[field],
                              addressData: addressData,
                              fieldErrors: fieldErrors,
                              onChanged: onFieldChanged,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        );
      }
    }

    return Column(children: fieldWidgets);
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

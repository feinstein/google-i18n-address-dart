import 'package:flutter/material.dart';
import 'package:google_i18n_address/google_i18n_address.dart';

/// A form widget that uses google_i18n_address to validate and format
/// address input according to the selected country.
class AddressForm extends StatefulWidget {
  const AddressForm({
    super.key,
    this.onSubmit,
  });

  final void Function(Map<String, String>)? onSubmit;

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final _formKey = GlobalKey<FormState>();
  final _addressData = <String, String>{};
  final _controllers = <String, TextEditingController>{};

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
  List<List<String>> _fieldOrder = [];
  Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();

    // Initialize with US as the default country
    _updateCountry('US');

    // Initialize controllers for all known fields
    for (final field in knownFields) {
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
      _addressData['country_code'] = countryCode;
      _rules = getValidationRules({'country_code': countryCode});
      _fieldOrder = getFieldOrder({'country_code': countryCode});
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

  void _onFieldChanged(String fieldName, String value) {
    setState(() {
      _addressData[fieldName] = value;
      if (_fieldErrors.containsKey(fieldName)) {
        _fieldErrors.remove(fieldName);
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
            items: _countries
                .map((country) => DropdownMenuItem(
                      value: country['code'],
                      child: Text(country['name']!),
                    ))
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
          ElevatedButton(
            onPressed: _submitForm,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

/// A widget that builds a single address field based on the field name and validation rules.
class AddressField extends StatelessWidget {
  const AddressField({
    super.key,
    required this.fieldName,
    required this.rules,
    required this.controller,
    required this.addressData,
    required this.fieldErrors,
    required this.onChanged,
  });

  final String fieldName;
  final ValidationRules rules;
  final TextEditingController? controller;
  final Map<String, String> addressData;
  final Map<String, String> fieldErrors;
  final void Function(String, String) onChanged;

  @override
  Widget build(BuildContext context) {
    final isRequired = rules.requiredFields.contains(fieldName);
    final hasError = fieldErrors.containsKey(fieldName);
    final errorText = hasError ? fieldErrors[fieldName] : null;

    // Handle special cases for fields with choices
    if (fieldName == 'country_area' && rules.countryAreaChoices.isNotEmpty) {
      return DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: _getReadableFieldName(fieldName),
          border: const OutlineInputBorder(),
          errorText: errorText != null
              ? 'This field is ${errorText == 'invalid' ? 'invalid' : 'required'}'
              : null,
        ),
        value: addressData[fieldName],
        items: [
          if (!isRequired)
            const DropdownMenuItem(
              value: '',
              child: Text('-- Select --'),
            ),
          ...rules.countryAreaChoices.map((choice) => DropdownMenuItem(
                value: choice[0],
                child: Text(choice[1]),
              )),
        ],
        onChanged: (value) {
          if (value != null) {
            onChanged(fieldName, value);
          }
        },
        validator: isRequired
            ? (value) => (value == null || value.isEmpty) ? 'Required' : null
            : null,
      );
    }

    // Regular text field for other fields
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: _getReadableFieldName(fieldName),
        hintText: _getHintText(fieldName),
        border: const OutlineInputBorder(),
        errorText: errorText != null
            ? 'This field is ${errorText == 'invalid' ? 'invalid' : 'required'}'
            : null,
      ),
      onChanged: (value) {
        onChanged(fieldName, value);
      },
      validator: isRequired
          ? (value) => (value == null || value.isEmpty) ? 'Required' : null
          : null,
    );
  }

  String _getReadableFieldName(String fieldName) {
    switch (fieldName) {
      case 'country_code':
        return 'Country';
      case 'country_area':
        return rules.countryAreaType.capitalize();
      case 'city':
        return rules.cityType.capitalize();
      case 'city_area':
        return rules.cityAreaType.capitalize();
      case 'postal_code':
        return rules.postalCodeType.capitalize();
      case 'street_address':
        return 'Street Address';
      case 'sorting_code':
        return 'Sorting Code';
      case 'name':
        return 'Full Name';
      case 'company_name':
        return 'Company';
      default:
        return fieldName.capitalize();
    }
  }

  String _getHintText(String fieldName) {
    switch (fieldName) {
      case 'postal_code':
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
  final List<List<String>> fieldOrder;
  final Map<String, TextEditingController> controllers;
  final Map<String, String> addressData;
  final Map<String, String> fieldErrors;
  final void Function(String, String) onFieldChanged;

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
            child: AddressField(
              fieldName: lineFields[0],
              rules: rules!,
              controller: controllers[lineFields[0]],
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
              children: lineFields
                  .map((field) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: field == lineFields.first ? 0 : 8,
                            right: field == lineFields.last ? 0 : 8,
                          ),
                          child: AddressField(
                            fieldName: field,
                            rules: rules!,
                            controller: controllers[field],
                            addressData: addressData,
                            fieldErrors: fieldErrors,
                            onChanged: onFieldChanged,
                          ),
                        ),
                      ))
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

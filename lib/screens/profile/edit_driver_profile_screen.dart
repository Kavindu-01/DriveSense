import 'package:flutter/material.dart';

import '../../models/driver_profile_model.dart';
import '../../services/mock_data_service.dart';
import '../../theme/app_theme.dart';

class EditDriverProfileScreen extends StatefulWidget {
  const EditDriverProfileScreen({super.key, required this.driver});

  final DriverProfileModel driver;

  @override
  State<EditDriverProfileScreen> createState() =>
      _EditDriverProfileScreenState();
}

class _EditDriverProfileScreenState extends State<EditDriverProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.driver.fullName);
  late final _email = TextEditingController(text: widget.driver.email);
  late final _phone = TextEditingController(text: widget.driver.phone);
  late final _vehicle = TextEditingController(text: widget.driver.vehicleModel);
  late final _plate = TextEditingController(text: widget.driver.licensePlate);
  late final _contactName = TextEditingController(
    text: widget.driver.emergencyContactName,
  );
  late final _contactPhone = TextEditingController(
    text: widget.driver.emergencyContactPhone,
  );

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _vehicle.dispose();
    _plate.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    MockDataService.updateDemoDriver(
      fullName: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      vehicleModel: _vehicle.text.trim(),
      licensePlate: _plate.text.trim(),
      emergencyContactName: _contactName.text.trim(),
      emergencyContactPhone: _contactPhone.text.trim(),
    );
    Navigator.of(context).pop(true);
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  String? _validEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'This field is required';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      validator: validator ?? _required,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.edit_outlined),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit driver profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppTheme.amberWarning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.amberWarning.withOpacity(0.35),
                  ),
                ),
                child: const Text(
                  'Changes apply to this demo session and are not synced to an account.',
                  style: TextStyle(color: AppTheme.amberWarning, fontSize: 12),
                ),
              ),
              _field('Full name', _name),
              _field(
                'Email address',
                _email,
                keyboardType: TextInputType.emailAddress,
                validator: _validEmail,
              ),
              _field('Driver phone', _phone, keyboardType: TextInputType.phone),
              _field('Vehicle model', _vehicle),
              _field('License plate', _plate),
              _field('Emergency contact name', _contactName),
              _field(
                'Emergency contact phone',
                _contactPhone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

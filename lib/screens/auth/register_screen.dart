import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../services/mock_data_service.dart';
import '../home_navigation_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _plateController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 700));

    if (mounted) {
      setState(() => _isLoading = false);
      MockDataService.registerDemoDriver(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        vehicleModel: _vehicleController.text.trim(),
        licensePlate: _plateController.text.trim(),
        emergencyContactName: _emergencyNameController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim(),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeNavigationScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _vehicleController.dispose();
    _plateController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Driver Registration")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Driver & Vehicle Telematics Profile",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Configure your identity, vehicle specifications, and automated emergency SOS contacts.",
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.amberWarning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.amberWarning.withOpacity(0.35),
                    ),
                  ),
                  child: const Text(
                    "Demo registration: your profile is kept in memory for this session. No account is created on a server.",
                    style: TextStyle(
                      color: AppTheme.amberWarning,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _buildField(
                  "Full Name",
                  Icons.person_outline,
                  _nameController,
                  required: true,
                ),
                const SizedBox(height: 14),
                _buildField(
                  "Email Address",
                  Icons.email_outlined,
                  _emailController,
                  type: TextInputType.emailAddress,
                  required: true,
                  email: true,
                ),
                const SizedBox(height: 14),
                _buildField(
                  "Vehicle Model (e.g. Honda Vezel 2021)",
                  Icons.directions_car_outlined,
                  _vehicleController,
                  required: true,
                ),
                const SizedBox(height: 14),
                _buildField(
                  "License Plate Number (e.g. WP CAC-1920)",
                  Icons.badge_outlined,
                  _plateController,
                  required: true,
                ),
                const SizedBox(height: 14),
                _buildField(
                  "Emergency Contact Name",
                  Icons.contact_phone_outlined,
                  _emergencyNameController,
                  required: true,
                ),
                const SizedBox(height: 14),
                _buildField(
                  "Emergency Contact Mobile (for SOS)",
                  Icons.phone_in_talk_outlined,
                  _emergencyPhoneController,
                  type: TextInputType.phone,
                  required: true,
                ),
                const SizedBox(height: 14),
                _buildField(
                  "Create Password",
                  Icons.lock_outline,
                  _passwordController,
                  obscure: true,
                  showPasswordToggle: true,
                  required: true,
                  minLength: 6,
                ),
                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text("ACTIVATE TELEMATICS ACCOUNT"),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    bool obscure = false,
    bool showPasswordToggle = false,
    bool required = false,
    bool email = false,
    int? minLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure && _obscurePassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.cyanAccent, size: 20),
        suffixIcon: showPasswordToggle
            ? IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.textMuted,
                ),
              )
            : null,
        filled: true,
        fillColor: AppTheme.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.cyanAccent, width: 2),
        ),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) return 'This field is required';
        if (email && (!text.contains('@') || !text.contains('.'))) {
          return 'Enter a valid email address';
        }
        if (minLength != null && text.length < minLength) {
          return 'Use at least $minLength characters';
        }
        return null;
      },
      style: const TextStyle(color: Colors.white),
    );
  }
}

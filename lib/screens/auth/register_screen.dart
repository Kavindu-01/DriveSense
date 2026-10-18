import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
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
  bool _isLoading = false;

  void _handleRegister() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 700));

    if (mounted) {
      setState(() => _isLoading = false);
      // TODO: Team Member: Create user in Firebase / backend DB
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
      appBar: AppBar(
        title: const Text("New Driver Registration"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
              const SizedBox(height: 24),

              _buildField("Full Name", Icons.person_outline, _nameController),
              const SizedBox(height: 14),
              _buildField("Email Address", Icons.email_outlined, _emailController,
                  type: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _buildField("Vehicle Model (e.g. Honda Vezel 2021)",
                  Icons.directions_car_outlined, _vehicleController),
              const SizedBox(height: 14),
              _buildField("License Plate Number (e.g. WP CAC-1920)",
                  Icons.badge_outlined, _plateController),
              const SizedBox(height: 14),
              _buildField("Emergency Contact Name",
                  Icons.contact_phone_outlined, _emergencyNameController),
              const SizedBox(height: 14),
              _buildField("Emergency Contact Mobile (for SOS)",
                  Icons.phone_in_talk_outlined, _emergencyPhoneController,
                  type: TextInputType.phone),
              const SizedBox(height: 14),
              _buildField("Create Password", Icons.lock_outline, _passwordController,
                  obscure: true),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text("ACTIVATE TELEMATICS ACCOUNT"),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, IconData icon, TextEditingController controller,
      {TextInputType type = TextInputType.text, bool obscure = false}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.cyanAccent, size: 20),
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
    );
  }
}

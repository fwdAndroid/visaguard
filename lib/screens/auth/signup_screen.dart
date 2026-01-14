import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:visaguard/services/auth_service.dart';
import 'package:visaguard/services/user_registration_service.dart';



class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _authService = FirebaseAuthService();
  final _registrationService = UserRegistrationService();

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passportController = TextEditingController();

  File? _selfie;
  bool _loading = false;

  Future<void> _pickSelfie() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() => _selfie = File(image.path));
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selfie is required')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // 1. Firebase Auth
      final credential = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = credential.user!.uid;

      // 2. Upload Selfie
      final selfieUrl = await _registrationService.uploadSelfie(
        uid: uid,
        selfie: _selfie!,
      );

      // 3. Save User Profile
      await _registrationService.saveUserProfile(
        uid: uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: '+91${_phoneController.text.trim()}',
        passportNumber: _passportController.text.trim(),
        selfieUrl: selfieUrl,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful. Await admin approval.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickSelfie,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      _selfie != null ? FileImage(_selfie!) : null,
                  child: _selfie == null
                      ? const Icon(Icons.camera_alt, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              _field(_nameController, 'Full Name'),
              _field(_emailController, 'Email',
                  keyboard: TextInputType.emailAddress),
              _field(_passwordController, 'Password', obscure: true),
              _field(
                _phoneController,
                'Phone Number',
                keyboard: TextInputType.phone,
                prefix: '+91 ',
              ),
              _field(_passportController, 'Passport Number'),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    String? prefix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

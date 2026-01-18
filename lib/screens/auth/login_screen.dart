import 'package:flutter/material.dart';
import 'package:visaguard/screens/auth/forgot_password_screen.dart';
import 'package:visaguard/screens/auth/signup_screen.dart';
import 'package:visaguard/screens/video_screen.dart';
import 'package:visaguard/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = FirebaseAuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);

    try {
      // Append @gmail.com automatically
      final emailInput = _emailController.text.trim();
      final email = '$emailInput@gmail.com';

      final credential = await _authService.signIn(
        email: email,
        password: _passwordController.text.trim(),
      );

      final uid = credential.user!.uid;
      final isApproved = await _authService.isUserApproved(uid);

      if (!isApproved) {
        await _authService.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account is still under admin approval.'),
          ),
        );
        setState(() => _loading = false);
        return;
      }

      // Approved → Open dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const VideoScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/logo.png', height: 160),
              const SizedBox(height: 24),
              
              // Email / Phone field (user only types numeric part)
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  hintText: 'Enter number (e.g., 91234)',
                ),
              ),
              const SizedBox(height: 12),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Enter Passport'),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen()),
                  ),
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 16),

              // Login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Login'),
                ),
              ),
              const SizedBox(height: 8),

              // Signup navigation
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupFlowScreen()),
                ),
                child: const Text("Don't have an account? Sign up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

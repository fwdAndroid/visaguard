import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visaguard/screens/auth/forgot_password_screen.dart';
import 'package:visaguard/screens/auth/signup_screen.dart';
import 'package:visaguard/screens/video_screen.dart';
import 'package:visaguard/screens/main/main_dashboard_screen.dart';
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
      // Phone → email format
      final emailInput = _emailController.text.trim();
      final email = '$emailInput@gmail.com';

      await _authService.signIn(
        email: email,
        password: _passwordController.text.trim(),
      );

      // Check local video flag
      final prefs = await SharedPreferences.getInstance();
      final hasWatchedVideos =
          prefs.getBool('hasWatchedVideos') ?? false;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              hasWatchedVideos ? const MainDashboardScreen() : const VideoScreen(),
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

              // Phone field
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
                decoration:
                    const InputDecoration(labelText: 'Enter Passport'),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  ),
                  child: const Text('Forgot Password?'),
                ),
              ),

              const SizedBox(height: 16),

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

              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SignupFlowScreen(),
                  ),
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

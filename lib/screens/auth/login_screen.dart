import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visaguard/provider/language_provider.dart';
import 'package:visaguard/screens/auth/forgot_password_screen.dart';
import 'package:visaguard/screens/auth/signup_screen.dart';
import 'package:visaguard/screens/video_screen.dart';
import 'package:visaguard/screens/main/main_dashboard_screen.dart';
import 'package:visaguard/services/auth_service.dart';
import 'package:visaguard/services/location_task_handle.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _authService = FirebaseAuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _emailController.text.isEmpty 
              ? 'Please enter your phone number' 
              : 'Please enter your passport',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final emailInput = _emailController.text.trim();
      final email = '$emailInput@gmail.com';

      await _authService.signIn(
        email: email,
        password: _passwordController.text.trim(),
      );

            final uid = FirebaseAuth.instance.currentUser!.uid;
      final pref = await SharedPreferences.getInstance();
      await pref.setString('current_uid', uid);

      await FlutterForegroundTask.saveData(key: 'uid', value: uid);
      await FlutterForegroundTask.startService(
        notificationTitle: 'VisaGuard Location Active',
        notificationText: 'Updating location every 10 minutes',
        callback: (){
          FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
        },
      );


      final prefs = await SharedPreferences.getInstance();
      final hasWatchedVideos = prefs.getBool('hasWatchedVideos') ?? false;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              hasWatchedVideos ? const MainDashboardScreen() : const VideoScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('INVALID_LOGIN_CREDENTIALS')
                ? 'Invalid phone number or passport'
                : 'Login failed. Please try again.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
        final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Logo and Welcome Section
                  Center(
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue[800]!,
                                Colors.blue[600]!,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Image.asset(
                            'assets/logo.png',
                            height: 100,
                            width: 100,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          languageProvider.localizedStrings['Welcome Back!'] ?? "Welcome Back!",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                        languageProvider.localizedStrings['Sign in to continue to Visa Guard'] ??   'Sign in to continue to Visa Guard',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Phone Input
                  Text(
                    languageProvider.localizedStrings['Phone Number'] ?? 'Phone Number',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[700] ?? Colors.grey : Colors.grey[200] ?? Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                   
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: languageProvider.localizedStrings['Enter 10-digit mobile number start with +91'] ??  'Enter 10-digit mobile number start with +91',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Password Input
                  Text(
                   languageProvider.localizedStrings['Passport Number'] ?? 'Passport Number',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[700] ?? Colors.grey : Colors.grey[200] ?? Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: languageProvider.localizedStrings['Enter your passport number'] ?? 'Enter your passport number',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                    ),
                  ),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                      ),
                      child: Text(
                        languageProvider.localizedStrings['Forgot Password?'] ?? 'Forgot Password?',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shadowColor: Colors.blue.withOpacity(0.3),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                              Text(
                                  languageProvider.localizedStrings['Login'] ?? 'Login',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                       languageProvider.localizedStrings['New to Visa Guard?'] ?? 'New to Visa Guard?',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignupFlowScreen(),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        side: BorderSide(
                          color: Colors.blue[700]!,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child:  Text(
                      languageProvider.localizedStrings['Create New Account'] ??  'Create New Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Terms and Conditions
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: languageProvider.localizedStrings['By continuing, you agree to our '] ??'By continuing, you agree to our ',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text:languageProvider.localizedStrings['Terms of Service'] ?? 'Terms of Service',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      
    );
  }
}
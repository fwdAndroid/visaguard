import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:country_picker/country_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:visaguard/model/sign_up_model.dart';
import 'package:visaguard/provider/language_provider.dart';
import 'package:visaguard/services/user_registration_service.dart';
import 'package:visaguard/utils/step_header.dart';
import 'package:visaguard/utils/ui_helpers.dart';

class SignupFlowScreen extends StatefulWidget {
  const SignupFlowScreen({super.key});

  @override
  State<SignupFlowScreen> createState() => _SignupFlowScreenState();
}

class _SignupFlowScreenState extends State<SignupFlowScreen>
    with SingleTickerProviderStateMixin {
  final PageController _page = PageController();
  final SignupData data = SignupData();

  int step = 0;
  bool loading = false;
  bool _isOtpSent = false;
  int _otpTimer = 60;

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final otpCtrl = TextEditingController();
  final passportCtrl = TextEditingController();

  String dialCode = '+91';
  String? verificationId;
  File? selfie;
  String? _locationStatus;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void next() {
    if (step < 4) {
      setState(() => step++);
      _page.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void previous() {
    if (step > 0) {
      setState(() => step--);
      _page.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<String> _getLocationSafe() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'Location services disabled';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return 'Location permission required';
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.locality ?? ''}, ${place.country ?? ''}'.trim();
      }
      return 'Location acquired';
    } catch (e) {
      return 'Unable to fetch location';
    }
  }

  void _startOtpTimer() {
    setState(() {
      _isOtpSent = true;
      _otpTimer = 60;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpTimer > 0) {
        setState(() => _otpTimer--);
      } else {
        timer.cancel();
        setState(() => _isOtpSent = false);
      }
    });
  }

  Widget _buildStepIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: index <= step ? Colors.deepPurple : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepLabel(int index, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: index <= step ? Colors.deepPurple : Colors.grey[300],
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: index <= step ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: index <= step ? Colors.deepPurple : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    final List<String> steps = ['Name', 'Phone', 'OTP', 'Passport', 'Selfie'];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[400]
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: steps.asMap().entries.map((entry) {
              return _buildStepLabel(entry.key, entry.value);
            }).toList(),
          ),
          _buildStepIndicator(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
            final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(languageProvider.localizedStrings['Create New Account'] ?? 'Create New Account'),
        backgroundColor: isDarkMode ? Colors.grey[400] : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.grey[900],
        elevation: 0,
        centerTitle: true,
      ),
      body: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          children: [
            _buildStepHeader(),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildNameStep(),
                  _buildPhoneStep(),
                  _buildOtpStep(),
                  _buildPassportStep(),
                  _buildSelfieStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameStep() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                final languageProvider = Provider.of<LanguageProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Iconsax.profile_circle,
                    size: 40,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    languageProvider.localizedStrings['Personal Information'] ?? 'Personal Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: isDarkMode ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    languageProvider.localizedStrings["Let's start with your basic details"] ?? "Let's start with your basic details",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildTextField(
                    controller: nameCtrl,
                    label: languageProvider.localizedStrings["Full Name"]  ?? 'Full Name',
                    hint: languageProvider.localizedStrings["Enter your full name"] ??'Enter your full name',
                    icon: Iconsax.user,
                    isRequired: true,
                  ),
                  const SizedBox(height: 24),
                  _buildInfoCard(
                    icon: Iconsax.shield_tick,
                    title: languageProvider.localizedStrings["Secure & Private"]  ??  'Secure & Private',
                    subtitle: languageProvider.localizedStrings["Your information is encrypted and secure"]  ?? 'Your information is encrypted and secure',
                  ),
                ],
              ),
            ),
          ),
          _buildNavigationButtons(
            onPrimary: () {
              if (nameCtrl.text.trim().isEmpty) {
                _showError('Please enter your name');
                return;
              }
              data.name = nameCtrl.text.trim();
              next();
            },
            primaryText:languageProvider.localizedStrings["Continue"]  ??  'Continue',
            showSecondary: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneStep() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                    final languageProvider = Provider.of<LanguageProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Iconsax.call,
                    size: 40,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    languageProvider.localizedStrings['Phone Verification'] ?? 'Phone Verification',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: isDarkMode ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    languageProvider.localizedStrings["We'll send an OTP to verify your number"] ?? "We'll send an OTP to verify your number",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildPhoneField(),
                  const SizedBox(height: 24),
                  _buildInfoCard(
                    icon: Iconsax.lock,
                    title: languageProvider.localizedStrings['Secure Verification'] ?? 'Secure Verification',
                    subtitle: languageProvider.localizedStrings['OTP ensures account security'] ?? 'OTP ensures account security',
                  ),
                ],
              ),
            ),
          ),
          _buildNavigationButtons(
            onPrimary: () async {
              if (phoneCtrl.text.trim().isEmpty) {
                _showError('Please enter your phone number');
                return;
              }
              
              setState(() => loading = true);
              final phone = '$dialCode${phoneCtrl.text.trim()}';
              data.phone = phone;
              data.email = '$phone@gmail.com';

              try {
                await FirebaseAuth.instance.verifyPhoneNumber(
                  phoneNumber: phone,
                  verificationCompleted: (_) {},
                  verificationFailed: (e) {
                    setState(() => loading = false);
                    _showError(e.message ?? 'Verification failed');
                  },
                  codeSent: (id, _) {
                    verificationId = id;
                    setState(() {
                      loading = false;
                      _isOtpSent = true;
                      _otpTimer = 60;
                    });
                    _startOtpTimer();
                    next();
                  },
                  codeAutoRetrievalTimeout: (_) {},
                );
              } catch (e) {
                setState(() => loading = false);
                _showError('Failed to send OTP');
              }
            },
            onSecondary: previous,
            primaryText: languageProvider.localizedStrings['Send OTP'] ??  'Send OTP',
            primaryLoading: loading,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[400]
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700] ?? Colors.grey
                  : Colors.grey[200] ?? Colors.grey,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding:  EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700] ?? Colors.grey
                      : Colors.grey[200] ?? Colors.grey,
                ),
              ),
            ),
            child: InkWell(
              onTap: () => showCountryPicker(
                context: context,
                countryListTheme: CountryListThemeData(
                  flagSize: 25,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  textStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.grey[900],
                  ),
                  bottomSheetHeight: 500,
                  borderRadius: BorderRadius.circular(20),
                ),
                onSelect: (country) {
                  setState(() => dialCode = '+${country.phoneCode}');
                },
              ),
              child: Row(
                children: [
                  Text(
                    dialCode,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Iconsax.arrow_down_2, size: 16),
                ],
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Enter phone number',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[500]
                      : Colors.grey[400],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                        final languageProvider = Provider.of<LanguageProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Iconsax.message,
                    size: 40,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    languageProvider.localizedStrings['Enter OTP'] ?? 'Enter OTP',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: isDarkMode ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter the 6-digit code sent to ${phoneCtrl.text}',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: otpCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                          maxLength: 6,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            counterText: '',
                            hintText: '000000',
                            hintStyle: TextStyle(
                              fontSize: 32,
                              color: Colors.grey,
                              letterSpacing: 8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isOtpSent)
                          Text(
                            'Resend OTP in $_otpTimer seconds',
                            style: const TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                ],
              ),
            ),
          ),
          _buildNavigationButtons(
            onPrimary: () async {
              if (otpCtrl.text.length != 6) {
                _showError('Please enter 6-digit OTP');
                return;
              }
              
              setState(() => loading = true);
              try {
                final cred = PhoneAuthProvider.credential(
                  verificationId: verificationId!,
                  smsCode: otpCtrl.text.trim(),
                );
                await FirebaseAuth.instance.signInWithCredential(cred);
                setState(() => loading = false);
                next();
              } catch (e) {
                setState(() => loading = false);
                _showError('Invalid OTP. Please try again.');
              }
            },
            onSecondary: previous,
            primaryText: languageProvider.localizedStrings['Verify OTP'] ?? 'Verify OTP',
            primaryLoading: loading,
          ),
        ],
      ),
    );
  }

  Widget _buildPassportStep() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                            final languageProvider = Provider.of<LanguageProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Iconsax.password_check,
                    size: 40,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    languageProvider.localizedStrings['Passport Details'] ?? 'Passport Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: isDarkMode ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    languageProvider.localizedStrings['Enter your passport number for verification'] ?? 'Enter your passport number for verification',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildTextField(
                    controller: passportCtrl,
                    label: languageProvider.localizedStrings['Passport Number'] ?? 'Passport Number',
                    hint: languageProvider.localizedStrings['Enter passport number'] ?? 'Enter passport number',
                    icon: Iconsax.card,
                    isRequired: true,
                  ),
                
                ], 
              ),
            ),
          ),
          _buildNavigationButtons(
            onPrimary: () {
              if (passportCtrl.text.trim().isEmpty) {
                _showError('Please enter passport number');
                return;
              }
              data.passport = passportCtrl.text.trim();
              next();
            },
            onSecondary: previous,
            primaryText: languageProvider.localizedStrings['Continue'] ?? 'Continue',
          ),
        ],
      ),
    );
  }

  Widget _buildSelfieStep() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final languageProvider =Provider.of<LanguageProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Iconsax.camera,
                    size: 40,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    languageProvider.localizedStrings['Selfie Verification'] ?? 'Selfie Verification',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: isDarkMode ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    languageProvider.localizedStrings['Take a clear selfie for identity verification'] ?? 'Take a clear selfie for identity verification',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: () async {
                      final image = await ImagePicker().pickImage(
                        source: ImageSource.camera,
                        imageQuality: 85,
                        preferredCameraDevice: CameraDevice.front,
                      );
                      if (image != null) {
                        setState(() => selfie = File(image.path));
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.deepPurple.withOpacity(0.3),
                          width: 2,
                          style: selfie == null ? BorderStyle.solid : BorderStyle.none,
                        ),
                        image: selfie != null
                            ? DecorationImage(
                                image: FileImage(selfie!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: selfie == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Iconsax.camera,
                                  size: 40,
                                  color: Colors.deepPurple.withOpacity(0.5),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                 languageProvider.localizedStrings['Tap to take selfie'] ?? 'Tap to take selfie',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  languageProvider.localizedStrings['Ensure good lighting and face visibility'] ?? 'Ensure good lighting and face visibility',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                
                ],
              ),
            ),
          ),
          _buildNavigationButtons(
            onPrimary: () async {
              if (selfie == null) {
                _showError('Please take a selfie');
                return;
              }

              final bool? proceed = await _showLocationConsentDialog();
              if (proceed != true) return;

              setState(() => loading = true);
              
              try {
                final auth = FirebaseAuth.instance;
                final reg = UserRegistrationService();
                final location = await _getLocationSafe();
                
                // Create Firebase Auth user
                final cred = await auth.createUserWithEmailAndPassword(
                  email: data.email!,
                  password: data.passport!,
                );

                // Upload selfie
                final selfieUrl = await reg.uploadSelfie(
                  uid: cred.user!.uid,
                  selfie: selfie!,
                );

                // Save user profile
                await reg.saveUserProfile(
                  uid: cred.user!.uid,
                  name: data.name!,
                  email: data.email!,
                  phone: data.phone!,
                  passportNumber: data.passport!,
                  selfieUrl: selfieUrl,
                );

                setState(() => loading = false);
                
                _showSuccessDialog();
              } catch (e) {
                setState(() => loading = false);
                _showError('Registration failed: $e');
              }
            },
            onSecondary: previous,
            primaryText: languageProvider.localizedStrings['Complete Registration'] ?? 'Complete Registration',
            primaryLoading: loading,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ${isRequired ? '*' : ''}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDarkMode ? Colors.grey[700] : Colors.grey[200]) ?? Colors.grey,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(icon, color: Colors.deepPurple),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[400] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons({
    required VoidCallback onPrimary,
    VoidCallback? onSecondary,
    required String primaryText,
    bool primaryLoading = false,
    bool showSecondary = true,
  }) {
    return Row(
      children: [
        if (showSecondary && onSecondary != null)
          Expanded(
            child: OutlinedButton(
              onPressed: onSecondary,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: Colors.deepPurple.withOpacity(0.3),
                ),
              ),
              child: const Text('Back'),
            ),
          ),
        if (showSecondary && onSecondary != null) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: primaryLoading ? null : onPrimary,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: primaryLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(primaryText),
          ),
        ),
      ],
    );
  }

  Future<bool?> _showLocationConsentDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Iconsax.location, color: Colors.deepPurple),
            const SizedBox(width: 12),
            const Text('Location Access'),
          ],
        ),
        content: const Text(
          'We use location information to enhance security and verify your application. This helps prevent fraud and ensures proper service delivery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Iconsax.tick_circle, color: Colors.green, size: 18),
            const SizedBox(width: 12),
            const Text('Registration Successful'),
          ],
        ),
        content: const Text(
          'Your account has been created successfully! Our team will review your application and you\'ll be notified once approved.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
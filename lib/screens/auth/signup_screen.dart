import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:country_picker/country_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:visaguard/model/sign_up_model.dart';
import 'package:visaguard/services/user_registration_service.dart';
import 'package:visaguard/utils/step_header.dart';
import 'package:visaguard/utils/ui_helpers.dart';

class SignupFlowScreen extends StatefulWidget {
  const SignupFlowScreen({super.key});

  @override
  State<SignupFlowScreen> createState() => _SignupFlowScreenState();
}

class _SignupFlowScreenState extends State<SignupFlowScreen> {
  final PageController _page = PageController();
  final SignupData data = SignupData();

  int step = 0;
  bool loading = false;

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final otpCtrl = TextEditingController();
  final passportCtrl = TextEditingController();

  String dialCode = '+91';
  String? verificationId;
  File? selfie;

  void next() {
    setState(() => step++);
    _page.nextPage(
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  /// ✅ SAFE LOCATION FETCH
  Future<String> _getLocationSafe() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return 'Location disabled';

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return 'Permission denied';
    }

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final placemarks =
        await placemarkFromCoordinates(pos.latitude, pos.longitude);
    final place = placemarks.first;
    return '${place.locality ?? ''}, ${place.country ?? ''}'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Column(
        children: [
          StepperHeader(step: step),
          Expanded(
            child: PageView(
              controller: _page,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                nameStep(),
                phoneStep(),
                otpStep(),
                passportStep(),
                selfieStep(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget nameStep() => stepWrap(
        Column(
          children: [
            appField('Full Name', nameCtrl),
            PrimaryButton('Next', () {
              data.name = nameCtrl.text.trim();
              next();
            }),
          ],
        ),
      );

  Widget phoneStep() => stepWrap(
        Column(
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () => showCountryPicker(
                    context: context,
                    onSelect: (c) => setState(() => dialCode = '+${c.phoneCode}'),
                  ),
                  child: Text(dialCode),
                ),
                Expanded(child: appField('Phone Number', phoneCtrl)),
              ],
            ),
            PrimaryButton('Send OTP', () async {
              loading = true;
              setState(() {});
              final phone = '$dialCode${phoneCtrl.text.trim()}';
              data.phone = phone;
              data.email = '$phone@gmail.com';

              await FirebaseAuth.instance.verifyPhoneNumber(
                phoneNumber: phone,
                verificationCompleted: (_) {},
                verificationFailed: (e) {
                  loading = false;
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message ?? e.toString())));
                },
                codeSent: (id, _) {
                  verificationId = id;
                  loading = false;
                  setState(() {});
                  next();
                },
                codeAutoRetrievalTimeout: (_) {},
              );
            }, loading: loading),
          ],
        ),
      );

  Widget otpStep() => stepWrap(
        Column(
          children: [
            appField('OTP Code', otpCtrl),
            PrimaryButton('Verify', () async {
              final cred = PhoneAuthProvider.credential(
                  verificationId: verificationId!, smsCode: otpCtrl.text.trim());
              await FirebaseAuth.instance.signInWithCredential(cred);
              next();
            }),
          ],
        ),
      );

  Widget passportStep() => stepWrap(
        Column(
          children: [
            appField('Passport Number', passportCtrl),
            PrimaryButton('Next', () {
              data.passport = passportCtrl.text.trim();
              next();
            }),
          ],
        ),
      );

  Widget selfieStep() => stepWrap(
        Column(
          children: [
            GestureDetector(
              onTap: () async {
                final img = await ImagePicker().pickImage(
                    source: ImageSource.camera, imageQuality: 70);
                if (img != null) setState(() => selfie = File(img.path));
              },
              child: CircleAvatar(
                radius: 55,
                backgroundImage: selfie != null ? FileImage(selfie!) : null,
                child:
                    selfie == null ? const Icon(Icons.camera_alt, size: 40) : null,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton('Register', () async {
              if (selfie == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please capture your selfie')));
                return;
              }

              loading = true;
              setState(() {});

              final auth = FirebaseAuth.instance;
              final reg = UserRegistrationService();

              /// 🔹 Show consent dialog for location
              await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Location Access'),
                  content: const Text(
                      'We use location to improve security. You can continue without it.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Continue'))
                  ],
                ),
              );

              /// 🔹 Create user in Firebase Auth
              final cred = await auth.createUserWithEmailAndPassword(
                  email: data.email!, password: data.passport!);

              /// 🔹 Safe location fetch
              final location = await _getLocationSafe();

              /// 🔹 Upload selfie
              final selfieUrl =
                  await reg.uploadSelfie(uid: cred.user!.uid, selfie: selfie!);

              /// 🔹 Save user profile with isApproved = false
              await reg.saveUserProfile(
                uid: cred.user!.uid,
                name: data.name!,
                email: data.email!,
                phone: data.phone!,
                passportNumber: data.passport!,
                selfieUrl: selfieUrl,
              );

              loading = false;
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Registration submitted')));
              Navigator.pop(context);
            }, loading: loading),
          ],
        ),
      );

  Widget stepWrap(Widget child) => Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: child),
      );
}

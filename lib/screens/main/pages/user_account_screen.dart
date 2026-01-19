import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visaguard/provider/language_provider.dart';
import 'package:visaguard/screens/auth/login_screen.dart';
import 'package:visaguard/screens/main/pages/change_language.dart';
import 'package:visaguard/screens/main/pages/profile_screen.dart';
import 'package:visaguard/services/auth_service.dart';

class UserAccountScreen extends StatelessWidget {
  const UserAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20,),
            Image.asset("assets/logo.png", height: 150),
            // Profile Image or Logo
            const SizedBox(height: 12),
            // Logout
            _tile(context, Icons.person, languageProvider.localizedStrings["Profile Settings"] ?? 'Profile Settings', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (builder) => ProfileScreen()),
              );
            }),

             _tile(context, Icons.language, languageProvider.localizedStrings["Change Language"] ?? 'Change Language', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (builder) => ChangeLangage()),
              );
            }),

            // Logout
            _tile(
              context,
              Icons.logout,
              languageProvider.localizedStrings["Log Out"] ?? "Log Out",
              () => _showLogoutDialog(context,languageProvider),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _tile(
  BuildContext context, 
  IconData icon,
  String title,
  VoidCallback onTap, {
  Color color = Colors.white,
}) {
  return ListTile(
    leading: Icon(icon, color: Colors.black),
    title: Text(title, style: TextStyle(color: Colors.black)),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    onTap: onTap,
  );
}

void _showLogoutDialog(BuildContext context,LanguageProvider languageProvider) {
  final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
  showCupertinoDialog(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: Text(languageProvider.localizedStrings["Logout"] ?? "Logout"),
      content:  Text(languageProvider.localizedStrings["Are you sure you want to logout?"] ?? "Are you sure you want to logout?"),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child:  Text(languageProvider.localizedStrings["Cancel"] ?? "Cancel"),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.pop(context);
            await FirebaseAuthService().signOut();

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          },
          child:  Text(languageProvider.localizedStrings["Logout"] ??  "Logout"),
        ),
      ],
    ),
  );
}

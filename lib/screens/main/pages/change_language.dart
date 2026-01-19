import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visaguard/provider/language_provider.dart';


class ChangeLangage extends StatefulWidget {
  const ChangeLangage({super.key});

  @override
  State<ChangeLangage> createState() => _ChangeLangageState();
}

class _ChangeLangageState extends State<ChangeLangage> {
  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
    ); // Access the provider

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        title: Text(
          languageProvider.localizedStrings['Language'] ?? "Language",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Image.asset("assets/logo.png", height: 150),
           

            // ListTile for English
            ListTile(
              onTap: () {
                languageProvider.changeLanguage('en'); // Change to English
              },
              trailing: Icon(
                languageProvider.currentLanguage == 'en'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: Colors.black,
                size: 20,
              ),
              title: Text(
                languageProvider.localizedStrings['English'] ?? "English",
                style: TextStyle(color: Colors.black),
              ),
            ),
            // ListTile for French
            ListTile(
              onTap: () {
                languageProvider.changeLanguage('hi'); // Change to Frenchs
              },
              trailing: Icon(
                languageProvider.currentLanguage == 'hi'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: Colors.black,
                size: 20,
              ),
              title: Text("Hindi", style: TextStyle(color: Colors.black)),
            ),

          
          ],
        ),
      ),
    );
  }
}

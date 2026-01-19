import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'en'; // Default language
  Map<String, dynamic> _localizedStrings = {};

  LanguageProvider() {
    _loadLanguage();
  }

  String get currentLanguage => _currentLanguage;

  Map<String, dynamic> get localizedStrings => _localizedStrings;

  Future<void> _loadLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'en';
    await _loadLocalizedStrings();
    notifyListeners();
  }

  Future<void> _loadLocalizedStrings() async {
    String jsonString = await rootBundle.loadString(
      'assets/lang/$_currentLanguage.json',
    );
    _localizedStrings = json.decode(jsonString);
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    _currentLanguage = languageCode;
    await _loadLocalizedStrings();
  }
}

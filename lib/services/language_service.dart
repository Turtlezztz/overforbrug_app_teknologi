import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  String _currentLanguage = 'Dansk';
  final Map<String, Map<String, String>> _translations = {
    'Dansk': {
      'home': 'Hjem',
      'timer': 'Timer',
      'settings': 'Indstillinger',
      'language': 'Sprog',
      'select_language': 'Vælg sprog',
      'timer_connection': 'Timer Forbindelse',
      'searching': 'Søger...',
      'search_timers': 'Søg efter Timere',
      'disconnect': 'Afbryd',
      'connected_to': 'Forbundet til',
      'searching_devices': 'Søger efter timer enheder...',
      'no_devices': 'Ingen timer enheder fundet. Tryk på søg for at scanne.',
      'connected': 'Forbundet',
      'connect': 'Forbind',
      'ai_feedback': 'AI Feedback',
      'ai_feedback_description': 'Vis AI-drevet forbrugsanalyse',
      'spending_overview': 'Forbrugsoversigt',
      'last_7_days': 'Sidste 7 dage',
      'last_30_days': 'Sidste 30 dage',
      'last_90_days': 'Sidste 90 dage',
      'time_interval': 'Tidsinterval',
      'recent_purchases': 'Seneste køb',
    },
    'English': {
      'home': 'Home',
      'timer': 'Timer',
      'settings': 'Settings',
      'language': 'Language',
      'select_language': 'Select language',
      'timer_connection': 'Timer Connection',
      'searching': 'Searching...',
      'search_timers': 'Search for Timers',
      'disconnect': 'Disconnect',
      'connected_to': 'Connected to',
      'searching_devices': 'Searching for timer devices...',
      'no_devices': 'No timer devices found. Press search to scan.',
      'connected': 'Connected',
      'connect': 'Connect',
      'ai_feedback': 'AI Feedback',
      'ai_feedback_description': 'Show AI-powered spending analysis',
      'spending_overview': 'Spending Overview',
      'last_7_days': 'Last 7 Days',
      'last_30_days': 'Last 30 Days',
      'last_90_days': 'Last 90 Days',
      'time_interval': 'Time Interval',
      'recent_purchases': 'Recent Purchases',
    },
  };

  List<String> get availableLanguages => _translations.keys.toList();

  String get currentLanguage => _currentLanguage;

  LanguageService._();

  static Future<LanguageService> initialize() async {
    final service = LanguageService._();
    final prefs = await SharedPreferences.getInstance();
    service._currentLanguage = prefs.getString(_languageKey) ?? 'Dansk';
    return service;
  }

  String translate(String key) {
    return _translations[_currentLanguage]?[key] ?? key;
  }

  Future<void> setLanguage(String language) async {
    if (_translations.containsKey(language) && language != _currentLanguage) {
      _currentLanguage = language;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language);
      notifyListeners();
    }
  }
} 
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _showAIFeedbackKey = 'show_ai_feedback';
  static const String _timeIntervalKey = 'time_interval';
  bool _showAIFeedback = true;
  int _timeInterval = 30; // Default to 30 days

  bool get showAIFeedback => _showAIFeedback;
  int get timeInterval => _timeInterval;

  SettingsService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _showAIFeedback = prefs.getBool(_showAIFeedbackKey) ?? true;
    _timeInterval = prefs.getInt(_timeIntervalKey) ?? 30;
    notifyListeners();
  }

  Future<void> toggleAIFeedback(bool value) async {
    _showAIFeedback = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showAIFeedbackKey, value);
    notifyListeners();
  }

  Future<void> setTimeInterval(int days) async {
    _timeInterval = days;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timeIntervalKey, days);
    notifyListeners();
  }
} 
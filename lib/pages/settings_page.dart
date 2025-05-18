import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<LanguageService>();
    final settingsService = context.watch<SettingsService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(languageService.translate('settings')),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Language Setting
          ListTile(
            title: Text(
              languageService.translate('language'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: DropdownButton<String>(
              value: languageService.currentLanguage,
              items: languageService.availableLanguages.map((String language) {
                return DropdownMenuItem<String>(
                  value: language,
                  child: Text(language),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  languageService.setLanguage(newValue);
                }
              },
            ),
          ),
          const Divider(),
          // Time Interval Setting
          ListTile(
            title: Text(
              languageService.translate('time_interval'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: DropdownButton<int>(
              value: settingsService.timeInterval,
              items: [
                DropdownMenuItem(
                  value: 7,
                  child: Text(languageService.translate('last_7_days')),
                ),
                DropdownMenuItem(
                  value: 30,
                  child: Text(languageService.translate('last_30_days')),
                ),
                DropdownMenuItem(
                  value: 90,
                  child: Text(languageService.translate('last_90_days')),
                ),
              ],
              onChanged: (int? newValue) {
                if (newValue != null) {
                  settingsService.setTimeInterval(newValue);
                }
              },
            ),
          ),
          const Divider(),
          // AI Feedback Toggle
          SwitchListTile(
            title: Text(
              languageService.translate('ai_feedback'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            value: settingsService.showAIFeedback,
            onChanged: (value) {
              settingsService.toggleAIFeedback(value);
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          const Divider(),
        ],
      ),
    );
  }
} 
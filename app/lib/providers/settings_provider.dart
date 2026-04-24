import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class AppSettings {
  final String? languageCode;

  AppSettings({this.languageCode});

  Locale? get locale =>
      languageCode != null ? Locale(languageCode!) : null;
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  static const _languageKey = 'language_code';

  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(languageCode: prefs.getString(_languageKey));
  }

  Future<void> setLanguage(String? languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    if (languageCode == null) {
      await prefs.remove(_languageKey);
    } else {
      await prefs.setString(_languageKey, languageCode);
    }
    state = AsyncData(AppSettings(languageCode: languageCode));
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

class ProfilePreferences {
  final bool darkMode;
  final bool notificationsEnabled;
  final String language;

  const ProfilePreferences({
    this.darkMode = false,
    this.notificationsEnabled = true,
    this.language = 'ar',
  });

  ProfilePreferences copyWith({
    bool? darkMode,
    bool? notificationsEnabled,
    String? language,
  }) {
    return ProfilePreferences(
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
    );
  }
}

class ProfilePreferencesNotifier
    extends AsyncNotifier<ProfilePreferences> {
  @override
  Future<ProfilePreferences> build() async {
    final prefs = await SharedPreferences.getInstance();
    return ProfilePreferences(
      darkMode: prefs.getBool(AppConstants.darkModeKey) ?? false,
      notificationsEnabled: prefs.getBool('notifications_enabled') ?? true,
      language: prefs.getString(AppConstants.languageKey) ?? 'ar',
    );
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.darkModeKey, value);
    state = AsyncData(state.value!.copyWith(darkMode: value));
  }

  Future<void> setNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    state = AsyncData(state.value!.copyWith(notificationsEnabled: value));
  }

  Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.languageKey, lang);
    state = AsyncData(state.value!.copyWith(language: lang));
  }
}

final profilePreferencesProvider =
    AsyncNotifierProvider<ProfilePreferencesNotifier, ProfilePreferences>(
  ProfilePreferencesNotifier.new,
);

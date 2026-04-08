import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/leaderboard/leaderboard_providers.dart';

const String appLocalePreferenceKey = 'app.locale';

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale>(
  AppLocaleNotifier.new,
);

class AppLocaleNotifier extends Notifier<Locale> {
  late final SharedPreferences _preferences;

  @override
  Locale build() {
    _preferences = ref.watch(sharedPreferencesProvider);

    final savedCode = _preferences.getString(appLocalePreferenceKey);
    if (savedCode != null && _isSupported(savedCode)) {
      return Locale(savedCode);
    }

    final systemCode = ui.PlatformDispatcher.instance.locale.languageCode;
    if (_isSupported(systemCode)) {
      return Locale(systemCode);
    }

    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    if (!_isSupported(locale.languageCode)) {
      return;
    }

    final normalizedLocale = Locale(locale.languageCode);
    if (state == normalizedLocale) {
      return;
    }

    state = normalizedLocale;
    await _preferences.setString(
      appLocalePreferenceKey,
      normalizedLocale.languageCode,
    );
  }

  bool _isSupported(String languageCode) =>
      languageCode == 'en' || languageCode == 'zh';
}

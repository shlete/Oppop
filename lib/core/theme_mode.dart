import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 설정 > 테마: 시스템 설정 따라가기 / 라이트 / 다크.
abstract final class AppThemeMode {
  static const key = 'settings.theme';

  /// 앱 시작 전에 [load]로 읽어 둔 값. 첫 화면부터 맞는 색으로 그린다.
  static ThemeMode initial = ThemeMode.system;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    initial = _parse(prefs.getString(key));
  }

  static ThemeMode _parse(String? name) => ThemeMode.values.firstWhere(
    (m) => m.name == name,
    orElse: () => ThemeMode.system,
  );
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => AppThemeMode.initial;

  Future<void> set(ThemeMode mode) async {
    state = mode;
    AppThemeMode.initial = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppThemeMode.key, mode.name);
  }
}

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 결과가 나올 때의 진동. 설정에서 끌 수 있다.
abstract final class AppHaptics {
  static bool enabled = true;

  static void light() {
    if (enabled) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  static const key = 'settings.haptics';

  /// 앱을 켤 때 저장된 설정을 읽어 둔다.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool(key) ?? true;
  }
}

final hapticsProvider = NotifierProvider<HapticsNotifier, bool>(
  HapticsNotifier.new,
);

class HapticsNotifier extends Notifier<bool> {
  @override
  bool build() => AppHaptics.enabled;

  Future<void> set(bool on) async {
    state = on;
    AppHaptics.enabled = on;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppHaptics.key, on);
  }
}

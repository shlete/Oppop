import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// 점괘 서버를 우리 앱만 부를 수 있게 하는 Firebase App Check.
/// 설정이 없거나 켜지지 않으면 토큰 없이 부르고, 서버가 받아 줄지 정한다.
class AppCheck {
  static bool _ready = false;

  /// 테스트용 빌드에 넣는 디버그 토큰 (GitHub 비밀값 APP_CHECK_DEBUG_TOKEN).
  static const _debugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

  static Future<void> init() async {
    final options = FirebaseConfig.current;
    if (options == null) return;
    try {
      await Firebase.initializeApp(options: options);
      // 개발 중이거나 테스트용 APK에는 디버그 토큰을 쓴다. 콘솔에 등록한 토큰이어야 통과한다.
      // 스토어로 받은 앱만 Play Integrity / App Attest로 확인할 수 있다.
      final debug = kDebugMode || _debugToken.isNotEmpty;
      final token = _debugToken.isEmpty ? null : _debugToken;
      await FirebaseAppCheck.instance.activate(
        providerAndroid: debug
            ? AndroidDebugProvider(debugToken: token)
            : const AndroidPlayIntegrityProvider(),
        providerApple: debug
            ? AppleDebugProvider(debugToken: token)
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
      _ready = true;
    } catch (e) {
      debugPrint('App Check를 켜지 못했어요: $e');
    }
  }

  /// 서버에 보낼 토큰. 못 받으면 null.
  static Future<String?> token() async {
    if (!_ready) return null;
    try {
      return await FirebaseAppCheck.instance.getToken().timeout(
        const Duration(seconds: 5),
      );
    } catch (_) {
      return null;
    }
  }
}

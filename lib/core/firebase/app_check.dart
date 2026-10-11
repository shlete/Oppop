import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// 점괘 서버를 우리 앱만 부를 수 있게 하는 Firebase App Check.
/// 설정이 없거나 켜지지 않으면 토큰 없이 부르고, 서버가 받아 줄지 정한다.
class AppCheck {
  static bool _ready = false;

  static Future<void> init() async {
    final options = FirebaseConfig.current;
    if (options == null) return;
    try {
      await Firebase.initializeApp(options: options);
      await FirebaseAppCheck.instance.activate(
        // 개발 중에는 디버그 토큰을 쓴다. 기기 로그에 나오는 토큰을 콘솔에 등록해야 통과한다.
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? const AppleDebugProvider()
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

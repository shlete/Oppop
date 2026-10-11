import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase 프로젝트 oppop-34243 앱 설정. 콘솔의 프로젝트 설정 > 내 앱에 나오는 값이다.
/// 이 값들은 앱 안에 그대로 들어가는 공개 정보라 저장소에 둬도 된다.
/// 아직 앱을 등록하지 않은 플랫폼은 null이고, 그러면 Firebase 없이 동작한다.
class FirebaseConfig {
  static FirebaseOptions? get current {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => null,
    };
  }

  static const FirebaseOptions? android = null;

  static const FirebaseOptions? ios = null;
}

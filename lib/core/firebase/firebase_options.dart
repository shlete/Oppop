import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase 프로젝트 oppop-34243 앱 설정. 콘솔의 프로젝트 설정 > 내 앱에 나오는 값이다.
/// 이 값들은 앱 안에 그대로 들어가는 공개 정보라 저장소에 둬도 된다.
/// 웹(미리보기)처럼 등록하지 않은 플랫폼은 null이고, 그러면 Firebase 없이 동작한다.
class FirebaseConfig {
  static FirebaseOptions? get current {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => null,
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCf9EDBIai5P31SU3_4QGV7089fgpWOR40',
    appId: '1:547675309284:android:19aecc529b342ab90e98f1',
    messagingSenderId: '547675309284',
    projectId: 'oppop-34243',
    storageBucket: 'oppop-34243.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA5WrgROiQ3kyjGSNg0EM_NFu2izGodAOc',
    appId: '1:547675309284:ios:d7837c0911907c940e98f1',
    messagingSenderId: '547675309284',
    projectId: 'oppop-34243',
    storageBucket: 'oppop-34243.firebasestorage.app',
    iosBundleId: 'com.shlete.oneulPpopgi',
  );
}

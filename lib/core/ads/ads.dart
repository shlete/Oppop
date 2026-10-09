import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob 설정. 지금은 구글이 제공하는 테스트 광고 ID를 사용한다.
/// 출시 전에 실제 광고 단위 ID로 교체해야 한다.
class Ads {
  /// 광고는 iOS/Android 실기기·에뮬레이터에서만 동작한다 (위젯 테스트 등에서는 꺼짐).
  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> init() async {
    if (!supported) return;
    await MobileAds.instance.initialize();
  }

  static String get bannerUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  static String get interstitialUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';
}

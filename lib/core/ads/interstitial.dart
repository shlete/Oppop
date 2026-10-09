import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads.dart';

/// 결과 직전에 띄우는 전면광고.
/// - 미리 하나를 받아두고, 준비가 안 됐으면 기다리지 않고 바로 넘어간다.
/// - 같은 사용자에게 [minGap] 안에 두 번 보여주지 않는다.
class InterstitialGate {
  InterstitialGate._();

  static final instance = InterstitialGate._();

  static const minGap = Duration(seconds: 60);

  InterstitialAd? _ad;
  bool _loading = false;
  DateTime? _lastShown;

  void preload() {
    if (!Ads.supported || _ad != null || _loading) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: Ads.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (_) => _loading = false,
      ),
    );
  }

  /// 광고를 보여줄 수 있으면 보여주고 닫힐 때까지 기다린다. 아니면 바로 끝난다.
  Future<void> show() async {
    final ad = _ad;
    final now = DateTime.now();
    final tooSoon = _lastShown != null && now.difference(_lastShown!) < minGap;
    if (ad == null || tooSoon) {
      preload();
      return;
    }
    _ad = null;
    _lastShown = now;
    final closed = Completer<void>();
    void finish(InterstitialAd ad) {
      ad.dispose();
      if (!closed.isCompleted) closed.complete();
      preload();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (ad, _) => finish(ad),
    );
    await ad.show();
    await closed.future;
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// true: Google'ın TEST reklamları. Play'e yüklemeden önce false yap ve
/// aşağıdaki gerçek kimlikleri doldur.
const bool kTestAds = true;

// Gerçek reklam birimi kimlikleri (AdMob panelinden):
const String _realBanner = 'ca-app-pub-XXXXXXXXXXXXXXXX/BBBBBBBBBB';
const String _realInterstitial = 'ca-app-pub-XXXXXXXXXXXXXXXX/IIIIIIIIII';

// Google'ın resmi test kimlikleri:
const String _testBanner = 'ca-app-pub-3940256099942544/6300978111';
const String _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';

String get bannerUnitId => kTestAds ? _testBanner : _realBanner;
String get interstitialUnitId =>
    kTestAds ? _testInterstitial : _realInterstitial;

class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _started = false;
  bool ready = false; // reklam istenebilir mi?
  InterstitialAd? _interstitial;
  int _turnsSinceAd = 0;

  /// Her kaç turda bir geçiş reklamı gösterilsin.
  static const int interstitialEvery = 3;

  /// Önce onay (GDPR/UMP) akışı, sonra reklam SDK'sı.
  Future<void> init() async {
    if (_started) return;
    _started = true;
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((FormError? e) {
          if (!done.isCompleted) done.complete();
        });
      },
      (FormError e) {
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future.timeout(const Duration(seconds: 30), onTimeout: () {});
    try {
      if (await ConsentInformation.instance.canRequestAds()) {
        await MobileAds.instance.initialize();
        ready = true;
        _loadInterstitial();
      }
    } catch (_) {}
  }

  void _loadInterstitial() {
    if (!ready || _interstitial != null) return;
    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Her [interstitialEvery] turda bir tam ekran reklam gösterir.
  /// Reklam kapanınca (ya da gösterilmezse hemen) tamamlanır.
  Future<void> maybeShowInterstitial() async {
    _turnsSinceAd++;
    final ad = _interstitial;
    if (!ready || ad == null || _turnsSinceAd < interstitialEvery) return;
    _turnsSinceAd = 0;
    _interstitial = null;
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadInterstitial();
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        a.dispose();
        _loadInterstitial();
        if (!done.isCompleted) done.complete();
      },
    );
    ad.show();
    await done.future.timeout(const Duration(minutes: 2), onTimeout: () {});
  }
}

/// Alt banner. Reklam yüklenmezse hiç yer kaplamaz.
class BannerSlot extends StatefulWidget {
  const BannerSlot({super.key});
  @override
  State<BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<BannerSlot> {
  BannerAd? _ad;
  bool _loaded = false;
  Timer? _retry;

  @override
  void initState() {
    super.initState();
    _tryLoad();
  }

  void _tryLoad() {
    if (!AdsService.instance.ready) {
      // SDK henüz hazır değil (onay formu sürüyor olabilir): biraz sonra dene.
      _retry = Timer(const Duration(seconds: 2), () {
        if (mounted) _tryLoad();
      });
      return;
    }
    final ad = BannerAd(
      adUnitId: bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _retry?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return Center(
      child: SizedBox(
        width: _ad!.size.width.toDouble(),
        height: _ad!.size.height.toDouble(),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}

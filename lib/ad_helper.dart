import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class AdHelper {
  static final bool _isAndroid =
      defaultTargetPlatform == TargetPlatform.android;
  static final bool _isIOS = defaultTargetPlatform == TargetPlatform.iOS;

  // Ad Unit IDs - Using test IDs for now
  static String get bannerAdUnitId {
    if (_isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Test ID for Android
    }
    if (_isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Test ID for iOS
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (_isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
    if (_isIOS) return 'ca-app-pub-3940256099942544/4411468910';
    throw UnsupportedError('Unsupported platform');
  }

  static String get rewardedAdUnitId {
    if (_isAndroid) return 'ca-app-pub-3940256099942544/5224354917';
    if (_isIOS) return 'ca-app-pub-3940256099942544/1712485313';
    throw UnsupportedError('Unsupported platform');
  }

  static String get nativeAdUnitId {
    if (_isAndroid) return 'ca-app-pub-3940256099942544/2247696110';
    if (_isIOS) return 'ca-app-pub-3940256099942544/3986624511';
    throw UnsupportedError('Unsupported platform');
  }

  // Check if ads should be shown (not for premium users or web platform)
  static bool shouldShowAds(BuildContext context) {
    if (kIsWeb) return false;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return userProvider.isLoggedIn &&
        userProvider.currentUser != null &&
        !userProvider.currentUser!.isPremiumActive();
  }

  // Banner Ad Widget
  static Widget bannerAdWidget(BuildContext context) {
    if (!shouldShowAds(context)) {
      return const SizedBox.shrink();
    }
    return _AdaptiveBannerAdWidget(context: context);
  }

  // Show Interstitial Ad
  static void showInterstitialAd(BuildContext context) {
    if (!shouldShowAds(context)) {
      return;
    }
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ Interstitial ad loaded');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('🛑 Interstitial ad dismissed');
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('❌ Interstitial failed to show: ${error.message}');
              ad.dispose();
            },
            onAdShowedFullScreenContent: (ad) {
              debugPrint('📺 Interstitial ad shown');
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Interstitial failed to load: ${error.message}');
        },
      ),
    );
  }

  // Show Rewarded Ad
  static void showRewardedAd({
    required BuildContext context,
    required void Function(RewardItem reward) onRewarded,
    void Function()? onAdDismissed,
    void Function(AdError)? onAdFailed,
  }) {
    if (!shouldShowAds(context)) {
      debugPrint('🛑 Skipping rewarded ad for premium user');
      onRewarded(RewardItem(0, 'none')); // Simulate reward for premium users
      return;
    }
    debugPrint('📢 Loading rewarded ad with unit ID: $rewardedAdUnitId');
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ Rewarded ad loaded');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('🛑 Rewarded ad dismissed');
              onAdDismissed?.call();
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('❌ Rewarded failed to show: ${error.message}');
              onAdFailed?.call(error);
              ad.dispose();
            },
            onAdShowedFullScreenContent: (ad) {
              debugPrint('📺 Rewarded ad shown');
            },
          );
          ad.show(
            onUserEarnedReward: (ad, reward) {
              debugPrint(
                '🎁 User earned reward: ${reward.amount} ${reward.type}',
              );
              onRewarded(reward);
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Rewarded failed to load: ${error.message}');
          onAdFailed?.call(AdError(error.code, error.message, error.domain));
        },
      ),
    );
  }

  // Native Ad Widget
  static Widget nativeAdWidget(BuildContext context) {
    if (!shouldShowAds(context)) {
      return const SizedBox.shrink();
    }
    if (_isAndroid) {
      return NativeAdWidget();
    }
    return const SizedBox.shrink();
  }
}

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  NativeAdWidgetState createState() => NativeAdWidgetState();
}

class NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;

  @override
  void initState() {
    super.initState();
    loadAd();
  }

  void loadAd() {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    _nativeAd = NativeAd(
      adUnitId: AdHelper.nativeAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('NativeAd loaded.');
          setState(() {
            _nativeAdIsLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('NativeAd failed to load: $error');
          ad.dispose();
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: colorScheme.surface,
        cornerRadius: 15.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          style: NativeTemplateFontStyle.normal,
          size: theme.textTheme.labelLarge?.fontSize ?? 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: colorScheme.onSurface,
          backgroundColor: colorScheme.surface,
          style: NativeTemplateFontStyle.bold,
          size: theme.textTheme.titleMedium?.fontSize ?? 18.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: colorScheme.onSurfaceVariant,
          backgroundColor: colorScheme.surface,
          style: NativeTemplateFontStyle.normal,
          size: theme.textTheme.bodyMedium?.fontSize ?? 16.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: colorScheme.onSurfaceVariant,
          backgroundColor: colorScheme.surface,
          style: NativeTemplateFontStyle.normal,
          size: theme.textTheme.bodySmall?.fontSize ?? 14.0,
        ),
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_nativeAdIsLoaded) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: GestureDetector(
        onTap: () {
          debugPrint('Native Ad clicked!');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 200, child: AdWidget(ad: _nativeAd!)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sponsored Ad',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check out this amazing offer!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }
}

class _AdaptiveBannerAdWidget extends StatefulWidget {
  final BuildContext context;
  const _AdaptiveBannerAdWidget({required this.context});

  @override
  State<_AdaptiveBannerAdWidget> createState() =>
      _AdaptiveBannerAdWidgetState();
}

class _AdaptiveBannerAdWidgetState extends State<_AdaptiveBannerAdWidget> {
  BannerAd? _ad;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    // Only attempt to load the ad on supported platforms (Android, iOS)
    if (AdHelper._isAndroid || AdHelper._isIOS) {
      final screenWidth = MediaQuery.of(widget.context).size.width.truncate();
      _loadAd(screenWidth);
    }
  }

  Future<void> _loadAd(int screenWidth) async {
    try {
      final size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            screenWidth,
          );

      if (size == null) {
        debugPrint('❌ Failed to get banner size');
        return;
      }

      _ad = BannerAd(
        adUnitId: AdHelper.bannerAdUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) => setState(() => _isLoaded = true),
          onAdFailedToLoad: (ad, error) {
            debugPrint('❌ Banner failed to load: ${error.message}');
            ad.dispose();
          },
        ),
      )..load();
    } catch (e) {
      debugPrint('❌ Error loading banner ad: $e');
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_isLoaded || _ad == null) return const SizedBox.shrink();
    return Card(
      elevation: 4, // Material 3 elevation for subtle shadow
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: _ad!.size.width.toDouble(),
        height: _ad!.size.height.toDouble(),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/pro_iap_service.dart';

const String _kProCachedKey = 'pro.cached';
const String _kTrialEndsAtKey = 'pro.trial_ends_at';
const String _kFreeBannerDismissedKey = 'pro.free_banner_dismissed';
const String _kDevProOverrideKey = 'pro.dev_override';
const int _kTrialDays = 7;

/// P0-F08: Pro durumu – satın alma, promo kodu (aynı IAP) veya yerel deneme ile isPro.
/// Provider ile sağlanır; uygulama açılışında restore, satın alma/geri yükle tetiklenir.
class ProState extends ChangeNotifier {
  ProState() {
    _subscription = _iap.purchaseStream.listen(_onPurchaseUpdates);
  }

  final ProIapService _iap = ProIapService();
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isPro = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _freeBannerDismissed = false;
  /// Sadece debug build'te kullanılır; release'de hiç set/load edilmez.
  bool _devProOverride = false;

  /// Ücretsiz kullanıcı banner'ı bir kez kapatıldıysa true; tekrar gösterilmez.
  bool get freeBannerDismissed => _freeBannerDismissed;

  /// Debug modda emülatör/cihazda Pro'yu test etmek için aç/kapa (sadece debug build'te kullanılır).
  bool get devProOverride => _devProOverride;

  /// Pro erişimi: satın alma, promo (IAP), deneme veya sadece debug'daki test override.
  bool get isPro => _isPro || _isTrialActive || _devProOverride;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DateTime? _trialEndsAt;

  bool get _isTrialActive {
    final endsAt = _trialEndsAt;
    if (endsAt == null) return false;
    return DateTime.now().isBefore(endsAt);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Ücretsiz sürüm banner'ını kapatır; bir daha gösterilmez.
  /// notifyListeners bir sonraki frame'de çağrılır; "Build scheduled during frame" hatasını önler.
  Future<void> dismissFreeBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFreeBannerDismissedKey, true);
    _freeBannerDismissed = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Uygulama açılışında veya Pro ekranına girildiğinde çağrılır.
  /// Önce cache ve trial okunur, sonra mağazadan restore tetiklenir.
  Future<void> loadProStatus() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      _freeBannerDismissed = prefs.getBool(_kFreeBannerDismissedKey) ?? false;
      _isPro = prefs.getBool(_kProCachedKey) ?? false;
      if (kDebugMode) {
        _devProOverride = prefs.getBool(_kDevProOverrideKey) ?? false;
      }
      final trialEndsAtMillis = prefs.getInt(_kTrialEndsAtKey);
      _trialEndsAt = trialEndsAtMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(trialEndsAtMillis)
          : null;

      final available = await _iap.isAvailable();
      if (!available) {
        _setLoading(false);
        notifyListeners();
        return;
      }

      if (!_isPro && _trialEndsAt == null) {
        _trialEndsAt = DateTime.now().add(const Duration(days: _kTrialDays));
        await prefs.setInt(
          _kTrialEndsAtKey,
          _trialEndsAt!.millisecondsSinceEpoch,
        );
      }

      await _iap.restorePurchases();
    } catch (e) {
      _errorMessage = 'Pro durumu yüklenemedi.';
      _setLoading(false);
      notifyListeners();
      return;
    }
    _setLoading(false);
    notifyListeners();
  }

  /// Satın alma akışını başlatır; sonuç purchase stream üzerinden gelir.
  Future<void> purchase() async {
    _errorMessage = null;
    _setLoading(true);
    notifyListeners();
    try {
      final available = await _iap.isAvailable();
      if (!available) {
        _errorMessage = 'Bu cihazda uygulama içi satın alma kullanılamıyor. Uygulamayı Google Play\'den indirdiyseniz sorun devam edebilir.';
        _setLoading(false);
        notifyListeners();
        return;
      }
      final ok = await _iap.startPurchase();
      if (!ok) {
        _errorMessage = 'Satın alma başlatılamadı.';
      }
    } catch (e) {
      _errorMessage = 'Satın alma başlatılamadı.';
    }
    _setLoading(false);
    notifyListeners();
  }

  /// Satın almaları geri yükler; sonuçlar purchase stream üzerinden gelir.
  /// Sonuç gelmezse (örn. satın alma yok) bir süre sonra loading kaldırılır.
  Future<void> restore() async {
    _errorMessage = null;
    _setLoading(true);
    notifyListeners();
    try {
      await _iap.restorePurchases();
      await Future<void>.delayed(const Duration(seconds: 3));
      if (_isLoading) {
        _setLoading(false);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Satın almalar geri yüklenemedi.';
      _setLoading(false);
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Sadece debug build'te: emülatörde Pro'yu test etmek için Pro'yu aç/kapa.
  /// Release build'te bu metod çağrılmaz (UI gösterilmez).
  Future<void> setDevProOverride(bool value) async {
    if (!kDebugMode || _devProOverride == value) return;
    _devProOverride = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDevProOverrideKey, value);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != kProProductId) continue;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _iap.completePurchase(purchase);
          _isPro = true;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_kProCachedKey, true);
          _setLoading(false);
          _errorMessage = null;
          notifyListeners();
          break;
        case PurchaseStatus.error:
          _errorMessage = purchase.error?.message ?? 'Satın alma hatası.';
          _setLoading(false);
          notifyListeners();
          break;
        case PurchaseStatus.canceled:
          _errorMessage = null;
          _setLoading(false);
          notifyListeners();
          break;
      }
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }
}

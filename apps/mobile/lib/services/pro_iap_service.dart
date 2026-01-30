import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

/// Pro in-app product id (Play Console'da tanımlı olmalı).
const String kProProductId = 'projectflow_pro';

/// P0-F08: IAP wrapper – satın alma, geri yükleme, purchase stream.
/// ProState bu servisi kullanır; Billing ile doğrudan konuşmaz.
class ProIapService {
  ProIapService() : _iap = InAppPurchase.instance;

  final InAppPurchase _iap;

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  Future<bool> isAvailable() => _iap.isAvailable();

  /// Tek seferlik Pro ürünü için satın alma başlatır.
  /// Sonuç [purchaseStream] üzerinden gelir.
  Future<bool> startPurchase() async {
    final available = await isAvailable();
    if (!available) return false;
    final response = await _iap.queryProductDetails({kProProductId});
    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      return false;
    }
    final product = response.productDetails.first;
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  /// Satın almaları geri yükler; sonuçlar [purchaseStream] üzerinden gelir.
  Future<void> restorePurchases() => _iap.restorePurchases();

  /// Satın almayı tamamlar (içerik teslim edildi olarak işaretlenir).
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);
}

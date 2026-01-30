/// Tarife kademeleri. Satış ve kullanımı artırmak için Pro "en çok tercih edilen" olarak sunulur.
/// Pro+ (veya Premium): Pro üstü kademe; ayrı IAP ürünü ile açılır.
enum PlanTier {
  /// Ücretsiz – temel özellikler.
  free,

  /// Pro – gelişmiş özellikler. UI'da "En çok tercih edilen" vurgulanır.
  pro,

  /// Pro+ – Pro üstü kademe (daha fazla özellik veya abonelik; ayrı IAP).
  proPlus,
}

extension PlanTierExtension on PlanTier {
  String get label {
    switch (this) {
      case PlanTier.free:
        return 'Ücretsiz';
      case PlanTier.pro:
        return 'Pro';
      case PlanTier.proPlus:
        return 'Pro+';
    }
  }

  /// Bu kademe UI'da "En çok tercih edilen" olarak gösterilsin mi?
  bool get isRecommended => this == PlanTier.pro;
}

/// Satış odaklı metinler – kullanıcıyı yönlendirmek için.
abstract final class PlanTierStrings {
  static const String recommendedBadge = 'En çok tercih edilen';
  static const String recommendedSubline = 'Kullanıcılarımızın çoğu Pro\'yu tercih ediyor.';
}

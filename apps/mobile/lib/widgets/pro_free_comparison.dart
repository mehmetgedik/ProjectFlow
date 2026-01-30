import 'package:flutter/material.dart';

import '../constants/plan_tiers.dart';

/// Pro ve Ücretsiz özellik karşılaştırması – uygulama içi ve mağaza metinleriyle uyumlu.
/// Karşılaştırma bir butonla açılan bottom sheet içinde gösterilir.
class ProFreeComparison {
  ProFreeComparison._();

  static const List<String> freeFeatures = [
    'Sunucuya bağlanma ve giriş',
    'Proje listesi ve proje seçimi',
    'Benim işlerim listesi ve detay',
    'Durum / atama hızlı güncelleme',
    'Yorum görüntüleme ve yeni yorum ekleme',
    'Bildirim listesi ve okundu işaretleme',
    'Zaman kaydı ekleme ve listeleme',
  ];

  static const List<String> proFeatures = [
    'İş paketi düzenleme (durum, atanan, bitiş, tür, üst iş)',
    'Zaman kayıtlarını düzenleme ve silme',
    'Zaman raporlama / haftalık özet',
    'Kayıtlı görünümler ve gelişmiş filtreleme',
    'Kolon ayarları (liste görünümü)',
    'Ek (dosya) yükleme ve gelişmiş görüntüleme',
    'İş paketi ilişkileri (parent/child/related)',
    'Gelişmiş bildirim deneyimi',
    'Gantt ve ileri görünümler',
  ];

  /// Karşılaştırmayı modal bottom sheet içinde açar.
  /// [onUpgradeTap] verilirse sheet altında "Pro'ya geç" butonu gösterilir; tıklanınca çağrılır ve sheet kapanır.
  static void showSheet(
    BuildContext context, {
    VoidCallback? onUpgradeTap,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _ComparisonSheetContent(
          scrollController: scrollController,
          onUpgradeTap: onUpgradeTap,
        ),
      ),
    );
  }
}

class _ComparisonSheetContent extends StatelessWidget {
  const _ComparisonSheetContent({
    required this.scrollController,
    this.onUpgradeTap,
  });

  final ScrollController scrollController;
  final VoidCallback? onUpgradeTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        const SizedBox(height: 8),
        Text(
          'Ücretsiz ve Pro karşılaştırması',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Hangi özelliklerin dahil olduğunu aşağıda görebilirsiniz. Pro tek seferlik satın almadır; ödeme Google Play üzerinden güvenle işlenir.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        _SectionCard(
          title: 'Ücretsiz',
          subtitle: 'Temel özellikler herkese açıktır',
          icon: Icons.person_outline_rounded,
          iconColor: colorScheme.outline,
          backgroundColor: colorScheme.surfaceContainerLow,
          items: ProFreeComparison.freeFeatures,
          itemColor: colorScheme.onSurface,
          checkColor: colorScheme.outline,
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Pro',
          subtitle: 'Tek seferlik satın alma – abonelik yok',
          icon: Icons.workspace_premium_rounded,
          iconColor: colorScheme.primary,
          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.6),
          items: ProFreeComparison.proFeatures,
          itemColor: colorScheme.onSurface,
          checkColor: colorScheme.primary,
          showRecommendedBadge: true,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ödeme Google Play üzerinden güvenle işlenir. Ödeme bilgileriniz bizimle paylaşılmaz.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        if (onUpgradeTap != null) ...[
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onUpgradeTap!();
            },
            icon: const Icon(Icons.workspace_premium_rounded, size: 20),
            label: const Text('Pro\'yu güvenle satın al'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.items,
    required this.itemColor,
    required this.checkColor,
    this.showRecommendedBadge = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final List<String> items;
  final Color itemColor;
  final Color checkColor;
  final bool showRecommendedBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 24, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: itemColor,
                              ),
                            ),
                          ),
                          if (showRecommendedBadge) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                PlanTierStrings.recommendedBadge,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: itemColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...items.map((text) => _FeatureRow(
                  text: text,
                  checkColor: checkColor,
                  textColor: itemColor,
                  theme: theme,
                )),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.text,
    required this.checkColor,
    required this.textColor,
    required this.theme,
  });

  final String text;
  final Color checkColor;
  final Color textColor;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 20, color: checkColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

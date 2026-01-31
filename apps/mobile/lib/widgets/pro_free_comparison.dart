import 'package:flutter/material.dart';

import '../constants/plan_tiers.dart';

/// Her özellik için (ikon, metin) çifti – renkli ve ikonlu karşılaştırma için.
class _FeatureItem {
  const _FeatureItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// Pro ve Ücretsiz özellik karşılaştırması – uygulama içi ve mağaza metinleriyle uyumlu.
/// Karşılaştırma renkli kartlar ve her özellik için ikonla bottom sheet içinde gösterilir.
class ProFreeComparison {
  ProFreeComparison._();

  static const List<_FeatureItem> freeFeatures = [
    _FeatureItem(Icons.link_rounded, 'Sunucuya bağlanma ve giriş'),
    _FeatureItem(Icons.folder_rounded, 'Proje listesi ve proje seçimi'),
    _FeatureItem(Icons.assignment_rounded, 'Benim işlerim listesi ve detay'),
    _FeatureItem(Icons.edit_note_rounded, 'Durum / atama hızlı güncelleme'),
    _FeatureItem(Icons.chat_bubble_outline_rounded, 'Yorum görüntüleme ve yeni yorum ekleme'),
    _FeatureItem(Icons.notifications_outlined, 'Bildirim listesi ve okundu işaretleme'),
    _FeatureItem(Icons.schedule_rounded, 'Zaman kaydı ekleme ve listeleme'),
  ];

  static const List<_FeatureItem> proFeatures = [
    _FeatureItem(Icons.dashboard_customize_rounded, 'İş paketi düzenleme (durum, atanan, bitiş, tür, üst iş)'),
    _FeatureItem(Icons.edit_calendar_rounded, 'Zaman kayıtlarını düzenleme ve silme'),
    _FeatureItem(Icons.bar_chart_rounded, 'Zaman raporlama / haftalık özet'),
    _FeatureItem(Icons.filter_list_rounded, 'Kayıtlı görünümler ve gelişmiş filtreleme'),
    _FeatureItem(Icons.view_column_rounded, 'Kolon ayarları (liste görünümü)'),
    _FeatureItem(Icons.attach_file_rounded, 'Ek (dosya) yükleme ve gelişmiş görüntüleme'),
    _FeatureItem(Icons.account_tree_rounded, 'İş paketi ilişkileri (parent/child/related)'),
    _FeatureItem(Icons.notifications_active_rounded, 'Gelişmiş bildirim deneyimi'),
    _FeatureItem(Icons.timeline_rounded, 'Gantt ve ileri görünümler'),
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
    final freeAccent = colorScheme.primary.withValues(alpha: 0.85);
    final proAccent = colorScheme.primary;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.compare_arrows_rounded, size: 28, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ücretsiz ve Pro karşılaştırması',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Hangi özelliklerin dahil olduğunu aşağıda görebilirsiniz. Pro tek seferlik satın almadır; ödeme Google Play üzerinden güvenle işlenir.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 28),
        _SectionCard(
          title: 'Ücretsiz',
          subtitle: 'Temel özellikler herkese açıktır',
          icon: Icons.person_outline_rounded,
          iconColor: freeAccent,
          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.35),
          borderColor: freeAccent.withValues(alpha: 0.4),
          featureItems: ProFreeComparison.freeFeatures,
          itemColor: colorScheme.onSurface,
          accentColor: freeAccent,
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Pro',
          subtitle: 'Tek seferlik satın alma – abonelik yok',
          icon: Icons.workspace_premium_rounded,
          iconColor: proAccent,
          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.55),
          borderColor: proAccent.withValues(alpha: 0.5),
          featureItems: ProFreeComparison.proFeatures,
          itemColor: colorScheme.onSurface,
          accentColor: proAccent,
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
    this.borderColor,
    required this.featureItems,
    required this.itemColor,
    required this.accentColor,
    this.showRecommendedBadge = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color? borderColor;
  final List<_FeatureItem> featureItems;
  final Color itemColor;
  final Color accentColor;
  final bool showRecommendedBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                    color: iconColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 26, color: iconColor),
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
            ...featureItems.map((item) => _FeatureRow(
                  icon: item.icon,
                  text: item.label,
                  accentColor: accentColor,
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
    required this.icon,
    required this.text,
    required this.accentColor,
    required this.textColor,
    required this.theme,
  });

  final IconData icon;
  final String text;
  final Color accentColor;
  final Color textColor;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_strings.dart';
import '../constants/plan_tiers.dart';
import '../state/pro_state.dart';
import '../widgets/pro_free_comparison.dart';
import '../widgets/small_loading_indicator.dart';

/// P0-F08: Pro hesap yönetimi – kurumsal, güven verici; satın al / geri yükle.
class ProUpgradeScreen extends StatelessWidget {
  const ProUpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pro Hesap Yönetimi'),
      ),
      body: Consumer<ProState>(
        builder: (context, pro, _) {
          if (pro.isLoading && !pro.isPro) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (pro.errorMessage != null) ...[
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              pro.errorMessage!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: pro.clearError,
                            tooltip: 'Kapat',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (pro.isPro) ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Pro aboneliğiniz aktif',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tüm Pro özelliklerine erişiminiz bulunmaktadır. Hesap Google Play üzerinden yönetilir.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Cihaz değişikliğinde veya uygulama yeniden yüklemeden sonra aşağıdaki "Satın almaları geri yükle" ile Pro erişiminizi aynı Google hesabıyla yeniden etkinleştirebilirsiniz.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
                if (!pro.isPro) ...[
                  Text(
                    'Pro ile daha verimli çalışın',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'İş paketlerini düzenleyin, zaman kayıtlarını raporlayın, görünüm ve filtreleri kişiselleştirin. Tek seferlik satın alma – abonelik yok.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _TrustRow(
                    icon: Icons.lock_outline_rounded,
                    text: 'Güvenli ödeme – Google Play üzerinden işlenir.',
                  ),
                  const SizedBox(height: 8),
                  _TrustRow(
                    icon: Icons.receipt_long_outlined,
                    text: 'Tek seferlik ödeme – abonelik veya gizli ücret yok.',
                  ),
                  const SizedBox(height: 8),
                  _TrustRow(
                    icon: Icons.phone_android_outlined,
                    text: 'Cihaz değişse bile aynı hesapla geri yükleyebilirsiniz.',
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          PlanTierStrings.recommendedBadge,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                OutlinedButton.icon(
                  onPressed: () => ProFreeComparison.showSheet(context),
                  icon: const Icon(Icons.table_chart_outlined, size: 20),
                  label: const Text('Ücretsiz ve Pro özellik karşılaştırması'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),
                if (kDebugMode) ...[
                  Card(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Geliştirme (sadece debug)',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            title: const Text('Pro\'yu aç (test – IAP atla)'),
                            subtitle: const Text(
                              'Emülatörde veya cihazda Pro özelliklerini test etmek için açın.',
                            ),
                            value: pro.devProOverride,
                            onChanged: (value) => pro.setDevProOverride(value),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                FilledButton.icon(
                  onPressed: pro.isLoading
                      ? null
                      : () async {
                          if (pro.isPro) {
                            await pro.restore();
                          } else {
                            await pro.purchase();
                          }
                        },
                  icon: pro.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: SmallLoadingIndicator(),
                        )
                      : Icon(pro.isPro ? Icons.restore_rounded : Icons.shopping_cart_rounded),
                  label: Text(
                    pro.isPro
                        ? AppStrings.proRestorePurchases
                        : 'Pro\'yu güvenle satın al',
                  ),
                ),
                if (!pro.isPro) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Google Play üzerinden tek seferlik ödeme. Ödeme bilgileriniz bizimle paylaşılmaz.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: pro.isLoading ? null : () => pro.restore(),
                    icon: const Icon(Icons.restore_rounded, size: 20),
                    label: const Text(AppStrings.proRestorePurchases),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Promosyon kodunuz varsa: Play Store\'da kodu kullandıktan sonra yukarıdaki "Satın almaları geri yükle" ile Pro\'yu etkinleştirin.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Güven verici kısa açıklama satırı – kurumsal ikon ve metin.
class _TrustRow extends StatelessWidget {
  const _TrustRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color.withValues(alpha: 0.9)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

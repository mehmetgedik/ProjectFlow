import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_navigation.dart';
import '../state/pro_state.dart';
import '../utils/haptic.dart';

/// Ücretsiz kullanıcıya hangi tarifede olduğunu gösterir ve Pro'ya yönlendirir.
/// Pro kullanıcıda hiçbir şey göstermez.
class FreePlanBanner extends StatelessWidget {
  const FreePlanBanner({super.key, this.compact = false});

  /// true ise tek satır, daha az yükseklik; false ise iki satır metin.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pro = context.watch<ProState>();
    if (pro.isPro || pro.freeBannerDismissed) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: compact ? 8 : 10,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  lightImpact();
                  pro.dismissFreeBanner();
                },
                tooltip: 'Banner\'ı kapat',
                icon: const Icon(Icons.close, size: 20),
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    lightImpact();
                    Navigator.of(context).pushNamed(AppRoutes.proUpgrade);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ücretsiz sürüm kullanıyorsunuz',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              if (!compact) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Pro ile daha fazlasına erişin.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            lightImpact();
                            Navigator.of(context).pushNamed(AppRoutes.proUpgrade);
                          },
                          icon: const Icon(Icons.star_rounded, size: 18),
                          label: const Text('Pro\'ya geç'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

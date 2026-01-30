import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_navigation.dart';
import '../constants/app_strings.dart';
import '../state/pro_state.dart';

/// P0-F08: Premium içerik kilidi – Pro yoksa kilit mesajı veya (teaser) içerik önizlemesi + "Pro'yu satın al"; Pro varsa [child] gösterilir.
///
/// [showTeaser] true ise Pro değilken [child] arkada soluk görünür, üzerinde "Kullanmak için Pro'yu satın alın" katmanı olur (merak uyandırır).
/// [showTeaser] false (varsayılan) ise Pro değilken sadece kilit mesajı ve Yükselt/Geri yükle gösterilir.
class ProGate extends StatelessWidget {
  const ProGate({
    super.key,
    required this.child,
    this.message,
    this.showTeaser = false,
  });

  final Widget child;
  final String? message;
  /// Pro değilken içeriği önizleme olarak göster (soluk + üstte Pro satın al CTA).
  final bool showTeaser;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProState>(
      builder: (context, pro, _) {
        if (pro.isPro) return child;
        if (showTeaser) {
          return _ProTeaserOverlay(
            message: message ?? 'Bu özellik Pro sürümünde. Kullanmak için Pro\'yu satın alın.',
            onUpgrade: () => Navigator.of(context).pushNamed(AppRoutes.proUpgrade),
            onRestore: () => pro.restore(),
            isLoading: pro.isLoading,
            child: child,
          );
        }
        return _ProLockedPlaceholder(
          message: message ?? AppStrings.proFeatureMessage,
          onUpgrade: () => Navigator.of(context).pushNamed(AppRoutes.proUpgrade),
          onRestore: () => pro.restore(),
          isLoading: pro.isLoading,
        );
      },
    );
  }
}

/// Pro değilken: [child] arkada soluk; üstte yarı saydam katman + "Pro'yu satın al" CTA.
class _ProTeaserOverlay extends StatelessWidget {
  const _ProTeaserOverlay({
    required this.child,
    required this.message,
    required this.onUpgrade,
    required this.onRestore,
    required this.isLoading,
  });

  final Widget child;
  final String message;
  final VoidCallback onUpgrade;
  final VoidCallback onRestore;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(
          child: Opacity(
            opacity: 0.4,
            child: child,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.titleSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: isLoading ? null : onUpgrade,
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text('Pro\'yu satın al'),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: isLoading ? null : onRestore,
                    icon: const Icon(Icons.restore, size: 20),
                    label: const Text(AppStrings.proRestorePurchases),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProLockedPlaceholder extends StatelessWidget {
  const _ProLockedPlaceholder({
    required this.message,
    required this.onUpgrade,
    required this.onRestore,
    required this.isLoading,
  });

  final String message;
  final VoidCallback onUpgrade;
  final VoidCallback onRestore;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: isLoading ? null : onUpgrade,
              icon: const Icon(Icons.arrow_upward),
              label: const Text(AppStrings.proUpgradeButton),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isLoading ? null : onRestore,
              icon: const Icon(Icons.restore),
              label: const Text(AppStrings.proRestorePurchases),
            ),
          ],
        ),
      ),
    );
  }
}

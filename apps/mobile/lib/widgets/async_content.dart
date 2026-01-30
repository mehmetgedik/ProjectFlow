import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import 'small_loading_indicator.dart';

/// Ortak loading / error / empty / content görünümü.
/// Ekranlarda tekrarlanan _loading ? Center(...) : _error != null ? ... : child bloklarını tekilleştirir.
/// [showEmpty] true ve [empty] verilmişse liste boş görünümü gösterilir; yoksa [child].
class AsyncContent extends StatelessWidget {
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;
  /// Hata kutusunda "Tekrar dene" butonunun altında gösterilecek ek widget (örn. "Varsayılan görünüme dön").
  final Widget? errorTrailing;
  /// Boş veri durumunda gösterilecek widget. [showEmpty] true olduğunda kullanılır.
  final Widget? empty;
  /// Boş durumda empty widget'ın altında gösterilecek ek widget (örn. "Varsayılan görünüme dön").
  final Widget? emptyTrailing;
  /// empty gösterilsin mi (örn. liste boş). true ise ve [empty] != null ise empty gösterilir.
  final bool showEmpty;
  final Widget child;

  const AsyncContent({
    super.key,
    required this.loading,
    this.error,
    this.onRetry,
    this.errorTrailing,
    this.empty,
    this.emptyTrailing,
    this.showEmpty = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: Semantics(
          label: AppStrings.labelLoading,
          child: const SmallLoadingIndicator(),
        ),
      );
    }
    if ((error ?? '').isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Semantics(
            container: true,
            liveRegion: true,
            label: error,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    button: true,
                    label: AppStrings.labelRetry,
                    child: FilledButton(
                      onPressed: onRetry,
                      child: const Text(AppStrings.labelRetry),
                    ),
                  ),
                ],
              if (errorTrailing != null) ...[
                const SizedBox(height: 8),
                errorTrailing!,
              ],
            ],
          ),
          ),
        ),
      );
    }
    if (showEmpty && empty != null) {
      return Center(
        child: Semantics(
          container: true,
          label: 'Liste boş. Gösterilecek öğe yok.',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              empty!,
              if (emptyTrailing != null) ...[
                const SizedBox(height: 16),
                emptyTrailing!,
              ],
            ],
          ),
        ),
      );
    }
    return child;
  }
}

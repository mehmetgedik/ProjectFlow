import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/time_entry.dart';
import '../models/work_package.dart';
import '../state/auth_state.dart';
import '../utils/date_formatters.dart';
import '../utils/haptic.dart';
import '../utils/snackbar_helpers.dart';

/// Zaman kaydı detay bottom sheet: iş başlığı, saat, tarih, açıklama; Düzenle, Sil, İşe git.
class TimeTrackingEntryDetailSheet extends StatelessWidget {
  final TimeEntry entry;
  final void Function(WorkPackage)? onOpenWorkPackage;
  final void Function()? onDeleted;
  final void Function(TimeEntry)? onEditRequested;

  const TimeTrackingEntryDetailSheet({
    super.key,
    required this.entry,
    this.onOpenWorkPackage,
    this.onDeleted,
    this.onEditRequested,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wpDisplay = (entry.workPackageSubject != null && entry.workPackageSubject!.trim().isNotEmpty)
        ? entry.workPackageSubject!.trim()
        : (entry.workPackageId != null ? 'İş #${entry.workPackageId}' : null);
    final wpFullTooltip = (entry.workPackageSubject != null && entry.workPackageSubject!.trim().isNotEmpty)
        ? entry.workPackageSubject!.trim()
        : (entry.workPackageId != null ? 'İş #${entry.workPackageId}' : null);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Zaman kaydı detayı',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              _DetailRow(icon: Icons.calendar_today, label: 'Tarih', value: DateFormatters.formatDate(entry.spentOn)),
              _DetailRow(icon: Icons.schedule, label: 'Saat', value: '${entry.hours.toStringAsFixed(2)} saat'),
              if ((entry.comment ?? '').isNotEmpty)
                _DetailRow(
                  icon: Icons.comment_outlined,
                  label: 'Yorum',
                  value: entry.comment!,
                ),
              if (wpDisplay != null)
                _DetailRow(
                  icon: Icons.work,
                  label: 'İş',
                  value: wpDisplay,
                  valueStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  tooltipOrLongPressMessage: wpFullTooltip,
                ),
              if ((entry.activityName ?? '').isNotEmpty)
                _DetailRow(
                  icon: Icons.category_outlined,
                  label: 'Kategori',
                  value: entry.activityName!,
                ),
              if ((entry.userName ?? '').isNotEmpty)
                _DetailRow(icon: Icons.person_outline, label: 'Kullanıcı', value: entry.userName!),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (onEditRequested != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          lightImpact();
                          Navigator.of(context).pop();
                          onEditRequested!(entry);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        label: const Text('Düzenle'),
                      ),
                    ),
                  if (onEditRequested != null) const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context),
                      icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                      label: Text('Sil', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (entry.workPackageId != null && onOpenWorkPackage != null)
                FilledButton.icon(
                  onPressed: () {
                    lightImpact();
                    Navigator.of(context).pop();
                    onOpenWorkPackage!(WorkPackage(
                      id: entry.workPackageId!,
                      subject: entry.workPackageSubject ?? '',
                      statusName: '',
                    ));
                  },
                  icon: const Icon(Icons.open_in_new, size: 20),
                  label: const Text('İşe git'),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kapat'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zaman kaydını sil'),
        content: const Text('Bu zaman kaydı kalıcı olarak silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    lightImpact();
    final client = context.read<AuthState>().client;
    if (client == null) return;
    try {
      await client.deleteTimeEntry(entry.id);
      if (!context.mounted) return;
      onDeleted?.call();
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      showErrorSnackBar(context, e, duration: const Duration(seconds: 5));
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final String? tooltipOrLongPressMessage;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
    this.tooltipOrLongPressMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget valueWidget = Text(
      value,
      style: valueStyle ?? theme.textTheme.bodyLarge,
      maxLines: 10,
      overflow: TextOverflow.ellipsis,
    );
    if (tooltipOrLongPressMessage != null && tooltipOrLongPressMessage!.isNotEmpty) {
      valueWidget = Tooltip(
        message: tooltipOrLongPressMessage!,
        child: GestureDetector(
          onLongPress: () {
            lightImpact();
            showAppSnackBar(context, tooltipOrLongPressMessage!, duration: const Duration(seconds: 3));
          },
          child: valueWidget,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: valueWidget,
          ),
        ],
      ),
    );
  }
}

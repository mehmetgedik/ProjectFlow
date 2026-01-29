import 'package:flutter/material.dart';

import '../models/time_entry.dart';
import '../models/work_package.dart';
import '../utils/haptic.dart';

/// Zaman kaydı detay bottom sheet: hangi iş, saat, tarih, açıklama; "İşe git" butonu.
class TimeTrackingEntryDetailSheet extends StatelessWidget {
  final TimeEntry entry;
  final void Function(WorkPackage)? onOpenWorkPackage;

  const TimeTrackingEntryDetailSheet({
    super.key,
    required this.entry,
    this.onOpenWorkPackage,
  });

  String _formatDate(DateTime d) {
    final dd = d.toLocal();
    return '${dd.day.toString().padLeft(2, '0')}.${dd.month.toString().padLeft(2, '0')}.${dd.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wpLabel = entry.workPackageId != null
        ? (entry.workPackageSubject != null
            ? '#${entry.workPackageId} · ${entry.workPackageSubject}'
            : '#${entry.workPackageId}')
        : null;

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
              _DetailRow(icon: Icons.calendar_today, label: 'Tarih', value: _formatDate(entry.spentOn)),
              _DetailRow(icon: Icons.schedule, label: 'Saat', value: '${entry.hours.toStringAsFixed(2)} saat'),
              if ((entry.comment ?? '').isNotEmpty)
                _DetailRow(
                  icon: Icons.comment_outlined,
                  label: 'Yorum',
                  value: entry.comment!,
                ),
              if (wpLabel != null)
                _DetailRow(
                  icon: Icons.work,
                  label: 'İş',
                  value: wpLabel,
                  valueStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
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
              if (entry.workPackageId != null && onOpenWorkPackage != null)
                FilledButton.icon(
                  onPressed: () {
                    lightImpact();
                    Navigator.of(context).pop();
                    onOpenWorkPackage!(WorkPackage(
                      id: entry.workPackageId!,
                      subject: entry.workPackageSubject ?? '#${entry.workPackageId}',
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
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            child: Text(
              value,
              style: valueStyle ?? theme.textTheme.bodyLarge,
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/work_package.dart';
import '../work_package_visuals.dart';

/// "Zaman eklemek için iş seçin" modal içeriği: iş paketi listesi; seçilince pop ile döner.
class AddTimeEntrySheet extends StatelessWidget {
  const AddTimeEntrySheet({
    super.key,
    required this.workPackages,
    this.title = 'Zaman eklemek için iş seçin',
  });

  final List<WorkPackage> workPackages;
  final String title;

  /// Modal'ı gösterir; seçilen iş paketini döndürür veya null.
  static Future<WorkPackage?> show(BuildContext context, List<WorkPackage> workPackages) {
    return showModalBottomSheet<WorkPackage>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.6,
          child: AddTimeEntrySheet(workPackages: workPackages),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, WorkPackage wp) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(wp);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: workPackages.length,
            itemBuilder: (context, index) {
              final wp = workPackages[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.work_rounded,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                title: Text(
                  '#${wp.id} · ${wp.subject}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      WorkPackageVisuals.statusChip(context, wp.statusName),
                      if ((wp.typeName ?? '').isNotEmpty)
                        WorkPackageVisuals.typeChip(context, wp.typeName!),
                      if ((wp.priorityName ?? '').isNotEmpty)
                        WorkPackageVisuals.priorityChip(context, wp.priorityName!),
                    ],
                  ),
                ),
                onTap: () => _onTap(context, wp),
              );
            },
          ),
        ),
      ],
    );
  }
}

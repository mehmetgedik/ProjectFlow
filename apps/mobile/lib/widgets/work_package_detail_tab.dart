import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_navigation.dart';
import '../constants/app_strings.dart';
import '../utils/app_logger.dart';
import '../models/work_package.dart';
import '../state/auth_state.dart';
import '../state/pro_state.dart';
import '../utils/date_formatters.dart';
import '../utils/snackbar_helpers.dart';
import 'letter_avatar.dart';
import 'work_package_visuals.dart';

/// İş paketi detay ekranında "Detay" sekmesi içeriği: durum, tür, atanan, bitiş tarihi, üst iş, açıklama.
class WorkPackageDetailTab extends StatelessWidget {
  const WorkPackageDetailTab({
    super.key,
    required this.workPackage,
    this.onRefresh,
  });

  final WorkPackage workPackage;
  final VoidCallback? onRefresh;

  Future<void> _updateStatus(BuildContext context) async {
    final client = context.read<AuthState>().client;
    if (client == null) return;
    List<Map<String, String>> statuses;
    try {
      statuses = await client.getStatuses();
    } catch (e) {
      if (kDebugMode) AppLogger.logError('Durumlar yüklenemedi', error: e);
      if (context.mounted) {
        showErrorSnackBar(context, AppStrings.errorStatusesLoadFailed);
      }
      return;
    }
    if (!context.mounted) return;
    final chosen = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'Durum seç',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ...statuses.map((s) {
                      final name = s['name'] ?? s['id'] ?? '';
                      final (bg, fg, icon) = WorkPackageVisuals.statusVisualsFromMap(context, s);
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 18, color: fg),
                              const SizedBox(width: 6),
                              Text(name, style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: fg)),
                            ],
                          ),
                        ),
                        title: Text(name),
                        selected: workPackage.statusId == s['id'],
                        onTap: () => Navigator.pop(ctx, s),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null) return;
    try {
      await client.patchWorkPackage(workPackage.id, statusId: chosen['id']);
      if (context.mounted) onRefresh?.call();
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, e, duration: const Duration(seconds: 5));
      }
    }
  }

  Future<void> _updateAssignee(BuildContext context) async {
    if (!context.read<ProState>().isPro) {
      Navigator.of(context).pushNamed(AppRoutes.proUpgrade);
      return;
    }
    final auth = context.read<AuthState>();
    final client = auth.client;
    final projectId = workPackage.projectId;
    if (client == null || projectId == null || projectId.isEmpty) return;
    List<Map<String, String>> members;
    try {
      members = await client.getProjectMembers(projectId);
    } catch (e) {
      if (kDebugMode) AppLogger.logError('Üyeler yüklenemedi', error: e);
      if (context.mounted) {
        showErrorSnackBar(context, AppStrings.errorMembersLoadFailed);
      }
      return;
    }
    if (!context.mounted) return;
    final apiBaseUrl = auth.instanceApiBaseUrl ?? '';
    final avatarHeaders = auth.authHeadersForInstanceImages;
    final chosen = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'Atanan seç',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ListTile(
                      leading: LetterAvatar(
                        displayName: 'Atanmamış',
                        imageUrl: null,
                        size: 40,
                      ),
                      title: const Text('(Atanmamış)'),
                      selected: workPackage.assigneeId == null || workPackage.assigneeId!.isEmpty,
                      onTap: () => Navigator.pop(ctx, <String, String>{'id': '', 'name': '(Atanmamış)'}),
                    ),
                    ...members.map((m) {
                      final memberId = m['id'];
                      final avatarUrl = (memberId != null && memberId.isNotEmpty && apiBaseUrl.isNotEmpty)
                          ? '$apiBaseUrl/users/$memberId/avatar'
                          : null;
                      return ListTile(
                        leading: LetterAvatar(
                          displayName: m['name'] ?? m['id'],
                          imageUrl: avatarUrl,
                          imageHeaders: avatarUrl != null ? avatarHeaders : null,
                          size: 40,
                        ),
                        title: Text(m['name'] ?? m['id'] ?? ''),
                        selected: workPackage.assigneeId == m['id'],
                        onTap: () => Navigator.pop(ctx, m),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null) return;
    try {
      final isUnassigned = chosen['id'] == null || chosen['id']!.isEmpty;
      await client.patchWorkPackage(
        workPackage.id,
        assigneeId: isUnassigned ? null : chosen['id'],
        clearAssignee: isUnassigned,
      );
      if (context.mounted) onRefresh?.call();
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, e, duration: const Duration(seconds: 5));
      }
    }
  }

  Future<void> _updateDueDate(BuildContext context) async {
    if (!context.read<ProState>().isPro) {
      Navigator.of(context).pushNamed(AppRoutes.proUpgrade);
      return;
    }
    final client = context.read<AuthState>().client;
    if (client == null) return;
    final initial = workPackage.dueDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    try {
      await client.patchWorkPackage(workPackage.id, dueDate: picked);
      if (context.mounted) onRefresh?.call();
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, e, duration: const Duration(seconds: 5));
      }
    }
  }

  Future<void> _updateType(BuildContext context) async {
    if (!context.read<ProState>().isPro) {
      Navigator.of(context).pushNamed(AppRoutes.proUpgrade);
      return;
    }
    final client = context.read<AuthState>().client;
    final projectId = workPackage.projectId;
    if (client == null || projectId == null || projectId.isEmpty) return;
    List<Map<String, String>> types;
    try {
      types = await client.getProjectTypes(projectId);
    } catch (e) {
      if (kDebugMode) AppLogger.logError('İş tipleri yüklenemedi', error: e);
      if (context.mounted) {
        showErrorSnackBar(context, AppStrings.errorTypesLoadFailed);
      }
      return;
    }
    if (!context.mounted) return;
    final chosen = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'İş tipi seç',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ...types.map((t) {
                      final name = t['name'] ?? t['id'] ?? '';
                      final (bg, fg, icon) = WorkPackageVisuals.typeVisualsFromMap(context, t);
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 18, color: fg),
                              const SizedBox(width: 6),
                              Text(name, style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: fg)),
                            ],
                          ),
                        ),
                        title: Text(name),
                        selected: workPackage.typeId == t['id'],
                        onTap: () => Navigator.pop(ctx, t),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null) return;
    try {
      await client.patchWorkPackage(workPackage.id, typeId: chosen['id']);
      if (context.mounted) onRefresh?.call();
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, e, duration: const Duration(seconds: 5));
      }
    }
  }

  Future<void> _updateParent(BuildContext context) async {
    if (!context.read<ProState>().isPro) {
      Navigator.of(context).pushNamed(AppRoutes.proUpgrade);
      return;
    }
    final client = context.read<AuthState>().client;
    if (client == null) return;
    final controller = TextEditingController(text: workPackage.parentId ?? '');
    final result = await showDialog<_ParentEditResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Üst iş'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Üst iş ID',
            hintText: 'Örn. 123',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, const _ParentEditResult(cancel: true)),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, const _ParentEditResult(clear: true)),
            child: const Text('Temizle'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, _ParentEditResult(parentId: controller.text.trim())),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    try {
      if (result == null || result.cancel) return;
      try {
        if (result.clear) {
          await client.patchWorkPackage(workPackage.id, clearParent: true);
        } else {
          final id = result.parentId?.trim() ?? '';
          await client.patchWorkPackage(workPackage.id, parentId: id);
        }
        if (context.mounted) onRefresh?.call();
      } catch (e) {
        if (context.mounted) {
          showErrorSnackBar(context, e, duration: const Duration(seconds: 5));
        }
      }
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<ProState>().isPro;
    final canEdit = onRefresh != null && isPro;
    final showProStar = onRefresh != null && !isPro;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onEditTap = onRefresh != null
        ? (isPro ? () => _updateStatus(context) : () => Navigator.of(context).pushNamed(AppRoutes.proUpgrade))
        : null;
    final onTypeTap = onRefresh != null
        ? (isPro ? () => _updateType(context) : () => Navigator.of(context).pushNamed(AppRoutes.proUpgrade))
        : null;
    final onAssigneeTap = onRefresh != null
        ? (isPro ? () => _updateAssignee(context) : () => Navigator.of(context).pushNamed(AppRoutes.proUpgrade))
        : null;
    final onParentTap = onRefresh != null
        ? (isPro ? () => _updateParent(context) : () => Navigator.of(context).pushNamed(AppRoutes.proUpgrade))
        : null;
    final onDueDateTap = onRefresh != null
        ? (isPro ? () => _updateDueDate(context) : () => Navigator.of(context).pushNamed(AppRoutes.proUpgrade))
        : null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            workPackage.subject,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InkWell(
                onTap: onEditTap,
                borderRadius: BorderRadius.circular(999),
                child: Chip(
                  backgroundColor: WorkPackageVisuals.statusVisuals(context, workPackage.statusName).$1,
                  labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: WorkPackageVisuals.statusVisuals(context, workPackage.statusName).$2,
                  ),
                  avatar: Icon(
                    WorkPackageVisuals.statusVisuals(context, workPackage.statusName).$3,
                    size: 18,
                    color: WorkPackageVisuals.statusVisuals(context, workPackage.statusName).$2,
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(workPackage.statusName),
                      if (onRefresh != null) const SizedBox(width: 4),
                      if (showProStar) Icon(Icons.star_rounded, size: 14, color: primaryColor),
                      if (canEdit) const Icon(Icons.edit, size: 14),
                    ],
                  ),
                ),
              ),
              if (workPackage.typeName != null && workPackage.typeName!.isNotEmpty)
                InkWell(
                  onTap: onTypeTap,
                  borderRadius: BorderRadius.circular(999),
                  child: Builder(
                    builder: (context) {
                      final (bg, fg, icon) = WorkPackageVisuals.typeVisuals(context, workPackage.typeName!);
                      return Chip(
                        backgroundColor: bg,
                        avatar: Icon(icon, size: 18, color: fg),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              workPackage.typeName!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: fg),
                            ),
                            if (onRefresh != null) const SizedBox(width: 4),
                            if (showProStar) Icon(Icons.star_rounded, size: 14, color: primaryColor),
                            if (canEdit) Icon(Icons.edit, size: 14, color: fg),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              if (workPackage.priorityName != null && workPackage.priorityName!.isNotEmpty)
                Builder(
                  builder: (ctx) {
                    final (bg, fg, icon) = WorkPackageVisuals.priorityVisuals(ctx, workPackage.priorityName!);
                    return Chip(
                      backgroundColor: bg,
                      avatar: Icon(icon, size: 18, color: fg),
                      labelStyle: Theme.of(ctx).textTheme.labelMedium?.copyWith(color: fg),
                      label: Text(workPackage.priorityName!),
                    );
                  },
                ),
              InkWell(
                onTap: onAssigneeTap,
                borderRadius: BorderRadius.circular(999),
                child: Builder(
                  builder: (ctx) {
                    final auth = ctx.read<AuthState>();
                    final assigneeId = workPackage.assigneeId;
                    final hasAssignee = assigneeId != null && assigneeId.isNotEmpty;
                    final apiBaseUrl = auth.instanceApiBaseUrl ?? '';
                    final avatarUrl = hasAssignee && apiBaseUrl.isNotEmpty
                        ? '$apiBaseUrl/users/$assigneeId/avatar'
                        : null;
                    return Chip(
                      avatar: hasAssignee && avatarUrl != null
                          ? LetterAvatar(
                              displayName: workPackage.assigneeName,
                              imageUrl: avatarUrl,
                              imageHeaders: auth.authHeadersForInstanceImages,
                              size: 24,
                            )
                          : const Icon(Icons.person, size: 16),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(workPackage.assigneeName ?? 'Atanmamış'),
                          if (onRefresh != null) const SizedBox(width: 4),
                          if (showProStar) Icon(Icons.star_rounded, size: 14, color: primaryColor),
                          if (canEdit) const Icon(Icons.edit, size: 14),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (workPackage.parentId != null && workPackage.parentId!.isNotEmpty) ...[
            InkWell(
              onTap: onParentTap,
              child: _DetailRow(
                label: 'Üst iş',
                value: '#${workPackage.parentId} ${workPackage.parentSubject ?? ''}'.trim(),
                trailing: onRefresh != null
                    ? (showProStar
                        ? Icon(Icons.star_rounded, size: 18, color: primaryColor)
                        : const Icon(Icons.chevron_right, size: 18))
                    : null,
              ),
            ),
            const SizedBox(height: 8),
          ],
          InkWell(
            onTap: onDueDateTap,
            child: _DetailRow(
              label: 'Bitiş tarihi',
              value: DateFormatters.formatDate(workPackage.dueDate),
              trailing: onRefresh != null
                  ? (showProStar
                      ? Icon(Icons.star_rounded, size: 18, color: primaryColor)
                      : const Icon(Icons.edit, size: 18))
                  : null,
            ),
          ),
          if (workPackage.description != null && workPackage.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Açıklama',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              workPackage.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class _ParentEditResult {
  const _ParentEditResult({this.clear = false, this.cancel = false, this.parentId});

  final bool clear;
  final bool cancel;
  final String? parentId;
}

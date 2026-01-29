import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/openproject_client.dart';
import '../models/work_package.dart';
import '../models/work_package_activity.dart';
import '../models/time_entry.dart';
import '../state/auth_state.dart';
import '../state/dashboard_prefs.dart';
import '../utils/app_logger.dart';
import '../utils/error_messages.dart';
import '../widgets/letter_avatar.dart';
import '../widgets/projectflow_logo_button.dart';

class WorkPackageDetailScreen extends StatefulWidget {
  final WorkPackage workPackage;

  const WorkPackageDetailScreen({super.key, required this.workPackage});

  @override
  State<WorkPackageDetailScreen> createState() => _WorkPackageDetailScreenState();
}

class _WorkPackageDetailScreenState extends State<WorkPackageDetailScreen> {
  WorkPackage? _wp;
  String? _loadError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    DashboardPrefs.addRecentlyOpened(widget.workPackage.id);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final client = context.read<AuthState>().client;
      if (client == null) throw Exception('Oturum bulunamadı.');
      final wp = await client.getWorkPackage(widget.workPackage.id);
      if (mounted) {
        setState(() {
          _wp = wp;
          _loading = false;
        });
      }
    } catch (e) {
      AppLogger.logError('İş detayı yüklenirken hata oluştu', error: e);
      if (mounted) {
        setState(() {
          _loadError = ErrorMessages.userFriendly(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('#${widget.workPackage.id}'),
          actions: const [ProjectFlowLogoButton()],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('#${widget.workPackage.id}'),
          actions: const [ProjectFlowLogoButton()],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loadError!.contains('bulunamadı') || _loadError!.contains('404')
                      ? 'İş bulunamadı veya silinmiş.'
                      : _loadError!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Geri dön'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final wp = _wp!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '#${widget.workPackage.id}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          actions: [
            const ProjectFlowLogoButton(),
            _NotificationBadge(),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Detay'),
              Tab(text: 'Aktivite'),
              Tab(text: 'Zaman'),
            ],
          ),
        ),
        body: TabBarView(
            children: [
            _DetailTab(workPackage: wp, onRefresh: _load),
            _ActivityTab(workPackageId: wp.id),
            _TimeTab(workPackageId: wp.id),
          ],
        ),
      ),
    );
  }
}

class _DetailTab extends StatelessWidget {
  final WorkPackage workPackage;
  final VoidCallback? onRefresh;

  const _DetailTab({required this.workPackage, this.onRefresh});

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  /// Duruma göre renk ve ikon (liste ekranı ile tutarlı).
  (Color bg, Color fg, IconData icon) _statusVisuals(BuildContext context, String status) {
    final theme = Theme.of(context);
    final s = status.toLowerCase();
    if (s.contains('yeni') || s.contains('new')) {
      return (theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer, Icons.fiber_new);
    }
    if (s.contains('devam') || s.contains('progress') || s.contains('in progress')) {
      return (theme.colorScheme.tertiaryContainer, theme.colorScheme.onTertiaryContainer, Icons.play_arrow);
    }
    if (s.contains('bekle') || s.contains('on hold') || s.contains('pending')) {
      return (theme.colorScheme.surfaceVariant, theme.colorScheme.onSurfaceVariant, Icons.pause_circle_filled);
    }
    if (s.contains('tamam') || s.contains('closed') || s.contains('done') || s.contains('çözüldü')) {
      return (theme.colorScheme.secondaryContainer, theme.colorScheme.onSecondaryContainer, Icons.check_circle);
    }
    if (s.contains('iptal') || s.contains('cancel')) {
      return (theme.colorScheme.errorContainer, theme.colorScheme.onErrorContainer, Icons.cancel);
    }
    return (theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer, Icons.adjust);
  }

  /// İş tipi için renk ve ikon.
  (Color bg, Color fg, IconData icon) _typeVisuals(BuildContext context, String type) {
    final theme = Theme.of(context);
    final t = type.toLowerCase();
    if (t.contains('bug') || t.contains('hata')) {
      return (theme.colorScheme.errorContainer, theme.colorScheme.onErrorContainer, Icons.bug_report);
    }
    if (t.contains('task') || t.contains('görev')) {
      return (theme.colorScheme.secondaryContainer, theme.colorScheme.onSecondaryContainer, Icons.checklist);
    }
    if (t.contains('feature') || t.contains('özellik')) {
      return (theme.colorScheme.tertiaryContainer, theme.colorScheme.onTertiaryContainer, Icons.auto_awesome);
    }
    if (t.contains('milestone') || t.contains('kilometre')) {
      return (theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer, Icons.flag);
    }
    return (theme.colorScheme.surfaceVariant, theme.colorScheme.onSurfaceVariant, Icons.label);
  }

  Future<void> _updateStatus(BuildContext context) async {
    final client = context.read<AuthState>().client;
    if (client == null) return;
    List<Map<String, String>> statuses;
    try {
      statuses = await client.getStatuses();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Durumlar yüklenemedi. Yetkinizi kontrol edin.')),
        );
      }
      return;
    }
    if (!context.mounted) return;
    final chosen = await showModalBottomSheet<Map<String, String>>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Durum seç')),
            ...statuses.map((s) => ListTile(
              title: Text(s['name'] ?? s['id'] ?? ''),
              selected: workPackage.statusId == s['id'],
              onTap: () => Navigator.pop(ctx, s),
            )),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    try {
      await client.patchWorkPackage(workPackage.id, statusId: chosen['id']);
      if (context.mounted) onRefresh?.call();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncellenemedi: $e')),
        );
      }
    }
  }

  Future<void> _updateAssignee(BuildContext context) async {
    final auth = context.read<AuthState>();
    final client = auth.client;
    final projectId = workPackage.projectId;
    if (client == null || projectId == null || projectId.isEmpty) return;
    List<Map<String, String>> members;
    try {
      members = await client.getProjectMembers(projectId);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Üyeler yüklenemedi. Yetkinizi kontrol edin.')),
        );
      }
      return;
    }
    if (!context.mounted) return;
    final apiBaseUrl = auth.instanceApiBaseUrl ?? '';
    final avatarHeaders = auth.authHeadersForInstanceImages;
    final chosen = await showModalBottomSheet<Map<String, String>>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Atanan seç')),
            ListTile(
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncellenemedi: $e')),
        );
      }
    }
  }

  Future<void> _updateDueDate(BuildContext context) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncellenemedi: $e')),
        );
      }
    }
  }

  Future<void> _updateType(BuildContext context) async {
    final client = context.read<AuthState>().client;
    final projectId = workPackage.projectId;
    if (client == null || projectId == null || projectId.isEmpty) return;
    List<Map<String, String>> types;
    try {
      types = await client.getProjectTypes(projectId);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İş tipleri yüklenemedi. Yetkinizi kontrol edin.')),
        );
      }
      return;
    }
    if (!context.mounted) return;
    final chosen = await showModalBottomSheet<Map<String, String>>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('İş tipi seç')),
            ...types.map((t) => ListTile(
                  title: Text(t['name'] ?? t['id'] ?? ''),
                  selected: workPackage.typeId == t['id'],
                  onTap: () => Navigator.pop(ctx, t),
                )),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    try {
      await client.patchWorkPackage(workPackage.id, typeId: chosen['id']);
      if (context.mounted) onRefresh?.call();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncellenemedi: $e')),
        );
      }
    }
  }

  Future<void> _updateParent(BuildContext context) async {
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
          decoration: const InputDecoration(
            labelText: 'Üst iş ID',
            hintText: 'Örn. 123',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncellenemedi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                onTap: onRefresh != null ? () => _updateStatus(context) : null,
                borderRadius: BorderRadius.circular(999),
                child: Chip(
                  backgroundColor: _statusVisuals(context, workPackage.statusName).$1,
                  labelStyle: TextStyle(
                    color: _statusVisuals(context, workPackage.statusName).$2,
                  ),
                  avatar: Icon(
                    _statusVisuals(context, workPackage.statusName).$3,
                    size: 18,
                    color: _statusVisuals(context, workPackage.statusName).$2,
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(workPackage.statusName),
                      if (onRefresh != null) const SizedBox(width: 4),
                      if (onRefresh != null) const Icon(Icons.edit, size: 14),
                    ],
                  ),
                ),
              ),
              if (workPackage.typeName != null && workPackage.typeName!.isNotEmpty)
                InkWell(
                  onTap: onRefresh != null ? () => _updateType(context) : null,
                  borderRadius: BorderRadius.circular(999),
                  child: Builder(
                    builder: (context) {
                      final (bg, fg, icon) = _typeVisuals(context, workPackage.typeName!);
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
                            if (onRefresh != null)
                              Icon(
                                Icons.edit,
                                size: 14,
                                color: fg,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              if (workPackage.priorityName != null && workPackage.priorityName!.isNotEmpty)
                Chip(
                  label: Text(workPackage.priorityName!),
                ),
              InkWell(
                onTap: onRefresh != null ? () => _updateAssignee(context) : null,
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
                          if (onRefresh != null) const Icon(Icons.edit, size: 14),
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
              onTap: onRefresh != null ? () => _updateParent(context) : null,
              child: _DetailRow(
                label: 'Üst iş',
                value: '#${workPackage.parentId} ${workPackage.parentSubject ?? ''}'.trim(),
                trailing: onRefresh != null ? const Icon(Icons.chevron_right, size: 18) : null,
              ),
            ),
            const SizedBox(height: 8),
          ],
          InkWell(
            onTap: onRefresh != null ? () => _updateDueDate(context) : null,
            child: _DetailRow(
              label: 'Bitiş tarihi',
              value: _formatDate(workPackage.dueDate),
              trailing: onRefresh != null ? const Icon(Icons.edit, size: 18) : null,
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
  final String label;
  final String value;
  final Widget? trailing;

  const _DetailRow({required this.label, required this.value, this.trailing});

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

class _ActivityTab extends StatefulWidget {
  final String workPackageId;

  const _ActivityTab({required this.workPackageId});

  @override
  State<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<_ActivityTab> {
  bool _loading = true;
  String? _error;
  List<WorkPackageActivity> _items = const [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  OpenProjectClient? _client(BuildContext context) => context.read<AuthState>().client;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = _client(context);
      if (client == null) throw Exception('Oturum bulunamadı.');
      _items = await client.getWorkPackageActivities(widget.workPackageId);
    } catch (e) {
      _error = ErrorMessages.userFriendly(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _error = null;
    });
    try {
      final client = _client(context);
      if (client == null) throw Exception('Oturum bulunamadı.');
      await client.addWorkPackageComment(workPackageId: widget.workPackageId, comment: text);
      _commentController.clear();
      await _load();
    } catch (e) {
      setState(() => _error = ErrorMessages.userFriendly(e));
    }
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.toLocal();
    final date = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _load,
                              child: const Text('Tekrar dene'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _items.isEmpty
                      ? const Center(child: Text('Henüz aktivite bulunmuyor.'))
                      : ListView.separated(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final a = _items[index];
                            final auth = context.read<AuthState>();
                            final apiBaseUrl = auth.instanceApiBaseUrl ?? '';
                            final hasAuthor = a.authorId != null && a.authorId!.isNotEmpty && apiBaseUrl.isNotEmpty;
                            final avatarUrl = hasAuthor ? '$apiBaseUrl/users/${a.authorId}/avatar' : null;
                            return ListTile(
                              leading: LetterAvatar(
                                displayName: a.authorName.isNotEmpty ? a.authorName : '?',
                                imageUrl: avatarUrl,
                                imageHeaders: avatarUrl != null ? auth.authHeadersForInstanceImages : null,
                                size: 40,
                              ),
                              title: Text(
                                a.authorName,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDateTime(a.createdAt),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                  if ((a.comment ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(a.comment!),
                                  ] else if (!a.isComment) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Durum / alan değişikliği',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Yorum yaz...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendComment,
                icon: const Icon(Icons.send),
                color: Theme.of(context).colorScheme.primary,
                tooltip: 'Yorumu gönder',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeTab extends StatefulWidget {
  final String workPackageId;

  const _TimeTab({required this.workPackageId});

  @override
  State<_TimeTab> createState() => _TimeTabState();
}

class _TimeTabState extends State<_TimeTab> {
  bool _loading = true;
  String? _error;
  List<TimeEntry> _items = const [];

  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  OpenProjectClient? _client(BuildContext context) => context.read<AuthState>().client;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = _client(context);
      if (client == null) throw Exception('Oturum bulunamadı.');
      _items = await client.getWorkPackageTimeEntries(widget.workPackageId);
    } catch (e) {
      _error = e.toString();
      AppLogger.logError('Zaman kayıtları yüklenirken hata oluştu', error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 1),
      lastDate: DateTime(_date.year + 1),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    final hoursText = _hoursController.text.trim().replaceAll(',', '.');
    final h = double.tryParse(hoursText);
    if (h == null || h <= 0) {
      setState(() => _error = 'Lütfen geçerli bir saat değeri girin (örn. 0.5, 1, 1.5).');
      return;
    }
    setState(() => _error = null);
    try {
      final client = _client(context);
      if (client == null) throw Exception('Oturum bulunamadı.');
      await client.createTimeEntry(
        workPackageId: widget.workPackageId,
        hours: h,
        spentOn: _date,
        comment: _commentController.text,
      );
      _hoursController.clear();
      _commentController.clear();
      await _load();
    } catch (e) {
      setState(() => _error = ErrorMessages.userFriendly(e));
      AppLogger.logError('Zaman kaydı oluşturulurken hata oluştu', error: e);
    }
  }

  String _formatDate(DateTime d) {
    final dd = d.toLocal();
    return '${dd.day.toString().padLeft(2, '0')}.${dd.month.toString().padLeft(2, '0')}.${dd.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Zaman kaydı ekle',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tarih',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_formatDate(_date)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _hoursController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Saat',
                        hintText: '1.0',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (isteğe bağlı)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? const Center(child: Text('Bu iş için kayıtlı zaman yok.'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final t = _items[index];
                        return ListTile(
                          title: Text('${t.hours.toStringAsFixed(2)} saat'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDate(t.spentOn),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                              if ((t.comment ?? '').isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(t.comment!),
                              ],
                              if ((t.activityName ?? '').isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  t.activityName!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final count = auth.unreadNotificationCount;
    final button = IconButton(
      onPressed: () {
        Navigator.of(context).pushNamed('/notifications').then((_) {
          auth.refreshUnreadNotificationCount();
        });
      },
      icon: const Icon(Icons.notifications_outlined),
      tooltip: 'Bildirimler',
    );
    if (count <= 0) return button;
    return Badge(
      offset: const Offset(-6, 4),
      label: Text(count > 99 ? '99+' : '$count'),
      child: button,
    );
  }
}

class _ParentEditResult {
  final bool clear;
  final bool cancel;
  final String? parentId;

  const _ParentEditResult({this.clear = false, this.cancel = false, this.parentId});
}


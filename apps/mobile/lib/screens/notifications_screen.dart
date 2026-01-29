import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/openproject_client.dart';
import '../models/notification_item.dart';
import '../models/work_package.dart';
import '../services/local_notification_service.dart';
import '../state/auth_state.dart';
import '../utils/app_logger.dart';
import '../utils/haptic.dart';
import '../widgets/letter_avatar.dart';
import '../widgets/projectflow_logo_button.dart';
import 'work_package_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  String? _error;
  /// Varsayılan: sadece okunmayanlar; zarf ikonu ile okunmuşlara da ulaşılır.
  bool _onlyUnread = true;
  bool _onlyActiveProject = false;
  List<NotificationItem> _items = const [];
  /// Bildirime konu iş paketleri (durum/tip chip'leri için). resourceId -> WorkPackage.
  Map<String, WorkPackage> _wpCache = const {};

  @override
  void initState() {
    super.initState();
    _load();
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    await LocalNotificationService().requestPermission();
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
      _items = await client.getNotifications(onlyUnread: _onlyUnread);
      _items.sort((a, b) {
        final ad = a.createdAt;
        final bd = b.createdAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad); // en yeni en üstte
      });
      // Bildirime konu iş paketlerini toplu çek (durum/tip chip'leri için).
      final wpIds = _items
          .where((n) => (n.resourceHref ?? '').contains('/work_packages/') && (n.resourceId ?? '').isNotEmpty)
          .map((n) => n.resourceId!)
          .toSet()
          .toList(growable: false);
      if (wpIds.isNotEmpty && mounted) {
        try {
          final wps = await client.getWorkPackagesByIds(wpIds);
          if (mounted) {
            setState(() {
              _wpCache = {for (final wp in wps) wp.id: wp};
            });
          }
        } catch (_) {
          if (mounted) setState(() => _wpCache = const {});
        }
      } else {
        setState(() => _wpCache = const {});
      }
    } catch (e) {
      _error = e.toString();
      AppLogger.logError('Bildirimler yüklenirken hata oluştu', error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<NotificationItem> _visibleItems(BuildContext context) {
    final auth = context.watch<AuthState>();
    final activeProjectName = auth.activeProject?.name;
    if (_onlyActiveProject && activeProjectName != null && activeProjectName.isNotEmpty) {
      return _items.where((n) => n.projectName == activeProjectName).toList(growable: false);
    }
    return _items;
  }

  Future<void> _toggleRead(NotificationItem item) async {
    try {
      final client = _client(context);
      if (client == null) throw Exception('Oturum bulunamadı.');
      if (!item.read) {
        await client.markNotificationRead(item.id);
        await _load();
      }
    } catch (e) {
      setState(() => _error = e.toString());
      AppLogger.logError('Bildirim okundu işaretlenirken hata oluştu', error: e);
    }
  }

  /// Tüm bildirimleri okundu yapar; sonra listeyi ve badge sayısını günceller.
  Future<void> _markAllRead() async {
    try {
      final client = _client(context);
      if (client == null) throw Exception('Oturum bulunamadı.');
      await client.markAllNotificationsRead();
      await _load();
      if (!mounted) return;
      await context.read<AuthState>().refreshUnreadNotificationCount();
    } catch (e) {
      setState(() => _error = e.toString());
      AppLogger.logError('Tümünü okundu yaparken hata oluştu', error: e);
    }
  }

  Future<void> _openResource(NotificationItem item) async {
    final href = item.resourceHref;
    if (href == null) return;
    // Örn: /api/v3/work_packages/123
    if (href.contains('/work_packages/')) {
      final id = href.split('/').last;
      try {
        final client = _client(context);
        if (client == null) throw Exception('Oturum bulunamadı.');
        final wp = await client.getWorkPackage(id);
        if (!mounted) return;
        await _toggleRead(item);
        // İş detay ekranına git
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkPackageDetailScreen(workPackage: wp),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _error = e.toString());
        AppLogger.logError('Bildirime bağlı kayıt açılırken hata oluştu', error: e);
      }
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    final d = dt.toLocal();
    final date = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  /// Web'deki gibi reason'ı kullanıcı dostu metne çevirir (API: mentioned, assigned, dateAlert, vb.).
  String _reasonLabel(String reason) {
    final r = reason.toLowerCase().trim();
    switch (r) {
      case 'mentioned':
        return 'Sizi andı';
      case 'assigned':
        return 'Size atandı';
      case 'datealert':
        return 'Tarih uyarısı';
      case 'created':
        return 'Oluşturuldu';
      case 'commented':
        return 'Yorum yapıldı';
      case 'responsible':
        return 'Sorumlu atandı';
      case 'watched':
        return 'İzleniyor';
      case 'subscribed':
        return 'Abone olundu';
      case 'prioritized':
        return 'Öncelik değişti';
      case 'processed':
        return 'İşlendi';
      case 'scheduled':
        return 'Planlandı';
      default:
        return reason.isNotEmpty ? reason : 'Bildirim';
    }
  }

  /// Satır başlığı: web'deki gibi "#123 · İş başlığı" veya sadece başlık.
  String _titleText(NotificationItem n) {
    final sub = n.subject.trim();
    if (n.resourceId != null && n.resourceId!.isNotEmpty) {
      return sub.isEmpty ? 'İş #${n.resourceId}' : '#${n.resourceId} · $sub';
    }
    return sub.isEmpty ? 'Bildirim' : sub;
  }

  /// Duruma göre renk ve ikon (liste/detay ekranları ile aynı kurallar).
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

  /// İş tipi için renk ve ikon (liste/detay ekranları ile aynı kurallar).
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

  Widget _buildStatusChip(BuildContext context, String status) {
    final (bg, fg, icon) = _statusVisuals(context, status);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            status,
            style: theme.textTheme.labelSmall?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context, String type) {
    final (bg, fg, icon) = _typeVisuals(context, type);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            type,
            style: theme.textTheme.labelSmall?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems(context);
    final hasUnread = _items.any((n) => !n.read);
    final theme = Theme.of(context);
    final auth = context.watch<AuthState>();
    final activeProjectName = auth.activeProject?.name ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          const ProjectFlowLogoButton(),
          // Sadece okunmayanlar / hepsini göster
          IconButton(
            onPressed: () {
              setState(() => _onlyUnread = !_onlyUnread);
              _load();
            },
            icon: Icon(
              _onlyUnread ? Icons.mark_email_unread : Icons.mark_email_read,
              size: 20,
            ),
            tooltip: _onlyUnread ? 'Okunmuşları da göster' : 'Sadece okunmayanlar',
          ),
          // Proje filtresi: yalnızca aktif proje / tüm projeler
          IconButton(
            onPressed: () => setState(() => _onlyActiveProject = !_onlyActiveProject),
            icon: Icon(
              _onlyActiveProject ? Icons.filter_alt : Icons.filter_alt_outlined,
              size: 20,
            ),
            tooltip: _onlyActiveProject
                ? 'Tüm projeleri göster'
                : (activeProjectName.isEmpty
                    ? 'Aktif proje yok; tüm bildirimler gösteriliyor'
                    : 'Sadece "$activeProjectName" projesinin bildirimlerini göster'),
          ),
          if (hasUnread)
            TextButton(
              onPressed: _loading ? null : _markAllRead,
              child: const Text('Tümünü okundu yap'),
            ),
        ],
      ),
      body: _loading
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
              : items.isEmpty
                  ? const Center(child: Text('Gösterilecek bildirim yok.'))
                  : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final n = items[index];
                                final isUnread = !n.read;
                                final auth = context.read<AuthState>();
                                final apiBaseUrl = (auth.instanceApiBaseUrl ?? '').trim();
                                final actorId = (n.actorId ?? '').trim();
                                final displayName = (n.actorName ?? actorId).trim();
                                final avatarUrl = (apiBaseUrl.isNotEmpty && actorId.isNotEmpty)
                                    ? '$apiBaseUrl/users/$actorId/avatar'
                                    : null;
                                return Material(
                                  color: isUnread
                                      ? theme.colorScheme.primaryContainer.withOpacity(0.25)
                                      : null,
                                  child: InkWell(
                                    onTap: () {
                                      lightImpact();
                                      _openResource(n);
                                    },
                                    child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        displayName.isNotEmpty
                                            ? LetterAvatar(
                                                displayName: displayName,
                                                imageUrl: avatarUrl,
                                                imageHeaders: avatarUrl != null ? auth.authHeadersForInstanceImages : null,
                                                size: 40,
                                              )
                                            : Icon(
                                                isUnread
                                                    ? Icons.notifications_active
                                                    : Icons.notifications_none,
                                                size: 22,
                                                color: isUnread
                                                    ? theme.colorScheme.primary
                                                    : theme.colorScheme.onSurfaceVariant,
                                              ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _titleText(n),
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  fontWeight:
                                                      isUnread ? FontWeight.w600 : FontWeight.w500,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              if (n.reason.trim().isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(bottom: 4),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: theme.colorScheme.primaryContainer,
                                                      borderRadius: BorderRadius.circular(999),
                                                    ),
                                                    child: Text(
                                                      _reasonLabel(n.reason),
                                                      style: theme.textTheme.labelSmall?.copyWith(
                                                        color: theme.colorScheme.onPrimaryContainer,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              if (n.resourceId != null) ...[
                                                Builder(
                                                  builder: (context) {
                                                    final wp = _wpCache[n.resourceId];
                                                    if (wp == null) return const SizedBox.shrink();
                                                    return Padding(
                                                      padding: const EdgeInsets.only(bottom: 6),
                                                      child: Wrap(
                                                        spacing: 6,
                                                        runSpacing: 4,
                                                        children: [
                                                          _buildStatusChip(context, wp.statusName),
                                                          if (wp.typeName != null && wp.typeName!.isNotEmpty)
                                                            _buildTypeChip(context, wp.typeName!),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (n.createdAt != null) ...[
                                          const SizedBox(width: 12),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              _formatDateTime(n.createdAt),
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: theme.colorScheme.outline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          child: SafeArea(
                            top: false,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${items.length} bildirim gösteriliyor'
                                '${_onlyUnread ? ' · sadece okunmayanlar' : ''}'
                                '${_onlyActiveProject ? (activeProjectName.isEmpty ? ' · yalnızca aktif proje' : ' · proje: $activeProjectName') : ''}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_navigation.dart';
import '../mixins/client_context_mixin.dart';
import '../mixins/loading_error_mixin.dart';
import '../models/notification_item.dart';
import '../models/work_package.dart';
import '../services/local_notification_service.dart';
import '../state/auth_state.dart';
import '../state/notification_prefs.dart';
import '../utils/app_logger.dart';
import '../utils/date_formatters.dart';
import '../utils/error_messages.dart';
import '../utils/haptic.dart';
import '../widgets/async_content.dart';
import '../widgets/letter_avatar.dart';
import '../widgets/projectflow_logo_button.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.isInsideShell = false});

  /// Alt navigasyon kabuğu içindeyse true (şu an AppBar değişmiyor).
  final bool isInsideShell;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with ClientContextMixin<NotificationsScreen>, LoadingErrorMixin<NotificationsScreen> {
  /// Varsayılan: sadece okunmayanlar; zarf ikonu ile okunmuşlara da ulaşılır.
  bool _onlyUnread = true;
  bool _onlyActiveProject = false;
  List<NotificationItem> _items = const [];
  /// Bildirime konu iş paketleri (durum/tip chip'leri için). resourceId -> WorkPackage.
  Map<String, WorkPackage> _wpCache = const {};
  /// Üstteki "OpenProject bildirim ayarları" bilgi banner'ı; tercih yüklenene kadar false, sonra kapatılmadıysa true.
  bool _showSettingsInfoBanner = false;

  @override
  void initState() {
    super.initState();
    loading = true;
    _load();
    _requestNotificationPermission();
    _loadSettingsInfoBannerVisibility();
  }

  Future<void> _loadSettingsInfoBannerVisibility() async {
    final dismissed = await NotificationPrefs.getNotificationSettingsInfoDismissed();
    if (mounted) setState(() => _showSettingsInfoBanner = !dismissed);
  }

  Future<void> _requestNotificationPermission() async {
    await LocalNotificationService().requestPermission();
  }

  Future<void> _load() async {
    await runLoad(() async {
      final c = client;
      if (c == null) throw Exception('Oturum bulunamadı.');
      // Bildirimlerle birlikte saat dilimi tercihini al; böylece saatler doğru gösterilir.
      final notifsFuture = c.getNotifications(onlyUnread: _onlyUnread);
      final prefsFuture = c.getMyPreferences().catchError((_) => <String, dynamic>{});
      final results = await Future.wait([notifsFuture, prefsFuture]);
      final list = results[0] as List<NotificationItem>;
      final prefs = results[1] as Map<String, dynamic>;
      final tzId = prefs['timeZone'] ?? prefs['time_zone'];
      if (tzId != null && tzId.toString().trim().isNotEmpty) {
        DateFormatters.preferredTimeZoneId = tzId.toString().trim();
      }
      _items = list;
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
          final wps = await c.getWorkPackagesByIds(wpIds);
          if (mounted) {
            setState(() {
              _wpCache = {for (final wp in wps) wp.id: wp};
            });
          }
        } catch (e) {
          if (kDebugMode) AppLogger.logError('Bildirim iş paketleri önbelleği yüklenemedi', error: e);
          if (mounted) setState(() => _wpCache = const {});
        }
      } else {
        setState(() => _wpCache = const {});
      }
    }, onError: (e) => AppLogger.logError('Bildirimler yüklenirken hata oluştu', error: e));
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
      final c = client;
      if (c == null) throw Exception('Oturum bulunamadı.');
      if (!item.read) {
        await c.markNotificationRead(item.id);
        await _load();
      }
    } catch (e) {
      setState(() => error = ErrorMessages.userFriendly(e));
      AppLogger.logError('Bildirim okundu işaretlenirken hata oluştu', error: e);
    }
  }

  /// Tüm bildirimleri okundu yapar; sonra listeyi ve badge sayısını günceller.
  Future<void> _markAllRead() async {
    try {
      final c = client;
      if (c == null) throw Exception('Oturum bulunamadı.');
      await c.markAllNotificationsRead();
      await _load();
      if (!mounted) return;
      await context.read<AuthState>().refreshUnreadNotificationCount();
    } catch (e) {
      setState(() => error = ErrorMessages.userFriendly(e));
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
        final c = client;
        if (c == null) throw Exception('Oturum bulunamadı.');
        final wp = await c.getWorkPackage(id);
        if (!mounted) return;
        await _toggleRead(item);
        if (!mounted) return;
        // İş detay ekranına git
        NavHelpers.toWorkPackageDetail(context, wp).then((_) {
          if (mounted) _load();
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => error = ErrorMessages.userFriendly(e));
        AppLogger.logError('Bildirime bağlı kayıt açılırken hata oluştu', error: e);
      }
    }
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
      return (theme.colorScheme.surfaceContainerHighest, theme.colorScheme.onSurfaceVariant, Icons.pause_circle_filled);
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
    return (theme.colorScheme.surfaceContainerHighest, theme.colorScheme.onSurfaceVariant, Icons.label);
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

  /// OpenProject e-posta ile mobil bildirim eşleşmesi hakkında bilgi ve ayar linki. Bir kez kapatılınca tekrar gösterilmez.
  Widget _buildNotificationSettingsInfo(BuildContext context, AuthState auth) {
    final theme = Theme.of(context);
    final settingsUrl = auth.instanceDisplayUrl != null
        ? '${auth.instanceDisplayUrl!.replaceAll(RegExp(r'/+$'), '')}/my/account'
        : null;
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mobil bildirimler OpenProject\'teki uygulama içi bildirimlere göre gelir. '
                    'E-posta ile aynı olaylarda mobil bildirim almak için OpenProject\'te '
                    'Bildirim ayarlarınızda ilgili olayları açmanız yeterli; aynı ayarlar hem e-postayı hem uygulama içi (ve mobil) bildirimleri besler.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () async {
                    await NotificationPrefs.setNotificationSettingsInfoDismissed(true);
                    if (mounted) setState(() => _showSettingsInfoBanner = false);
                  },
                  tooltip: 'Bilgi banner\'ını kapat',
                ),
              ],
            ),
            if (settingsUrl != null && settingsUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final uri = Uri.parse(settingsUrl);
                  try {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bu bağlantı açılamadı. Tarayıcı veya URL\'yi kontrol edin.')),
                        );
                      }
                    }
                  } catch (e, st) {
                    AppLogger.logError('OpenProject bildirim ayarları linki açılırken hata', error: e, stackTrace: st);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Bağlantı açılamadı: ${ErrorMessages.userFriendly(e)}')),
                      );
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Bildirim ayarlarını OpenProject\'te aç',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
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
          // Liste filtresi: sadece okunmayanlar ↔ okunmuşlar dahil hepsi
          IconButton(
            onPressed: () {
              setState(() => _onlyUnread = !_onlyUnread);
              _load();
            },
            tooltip: _onlyUnread ? 'Tüm bildirimleri göster' : 'Sadece okunmamışları göster',
            icon: Icon(
              _onlyUnread ? Icons.mark_email_unread : Icons.mark_email_read,
              size: 20,
            ),
          ),
          // Proje filtresi: tüm projeler ↔ sadece aktif proje
          IconButton(
            onPressed: () => setState(() => _onlyActiveProject = !_onlyActiveProject),
            tooltip: _onlyActiveProject ? 'Tüm projelerdeki bildirimler' : 'Sadece aktif projedeki bildirimler',
            icon: Icon(
              _onlyActiveProject ? Icons.filter_alt : Icons.filter_alt_outlined,
              size: 20,
            ),
          ),
          // Tüm bildirimleri okundu işaretle
          if (hasUnread)
            IconButton(
              onPressed: loading ? null : _markAllRead,
              icon: const Icon(Icons.done_all, size: 22),
              tooltip: 'Tüm bildirimleri okundu olarak işaretle',
            ),
        ],
      ),
      body: AsyncContent(
        loading: loading,
        error: error,
        onRetry: _load,
        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_showSettingsInfoBanner) _buildNotificationSettingsInfo(context, auth),
                        if (items.isEmpty)
                          Expanded(
                            child: Semantics(
                              label: 'Liste boş. Gösterilecek bildirim yok.',
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.notifications_none_outlined,
                                        size: 48,
                                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Gösterilecek bildirim yok.',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Bildirimler OpenProject\'teki işlemlere göre burada listelenir.',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          Expanded(
                          child: RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              cacheExtent: 300,
                              itemCount: items.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
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
                                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
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
                                              DateFormatters.formatDateTime(n.createdAt),
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
        ),
    );
  }
}


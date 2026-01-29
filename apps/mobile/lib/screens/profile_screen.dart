import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/openproject_client.dart';
import '../models/project.dart';
import '../state/auth_state.dart';
import '../state/theme_state.dart';
import '../state/notification_prefs.dart';
import '../state/time_tracking_reminder_prefs.dart';
import '../services/local_notification_service.dart';
import '../services/time_tracking_reminder_service.dart';
import '../utils/error_messages.dart';
import '../utils/haptic.dart';
import '../widgets/letter_avatar.dart';
import '../widgets/projectflow_logo_button.dart';

/// Avatar URL'si instance ile aynı host ise auth header döndürür (OpenProject özel avatar için).
Map<String, String>? _avatarHeaders(AuthState auth) {
  final url = auth.userAvatarUrl;
  if (url == null || url.isEmpty) return null;
  final origin = auth.instanceOrigin;
  if (origin == null) return null;
  final avatarHost = Uri.tryParse(url)?.host;
  if (avatarHost == null || avatarHost != origin.host) return null;
  return auth.authHeadersForInstanceImages;
}

/// P1-F01: Profil/hesap görünümü – ad, kullanıcı adı, instance; avatar; yetki varsa düzenleme.
/// [requireProjectSelection] true ise varsayılan proje seçimi zorunludur (ilk giriş / kayıt yok).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.requireProjectSelection = false});

  final bool requireProjectSelection;

  Future<void> _editDisplayName(BuildContext context, AuthState auth) async {
    final client = auth.client;
    if (client == null) return;
    Map<String, String> me;
    try {
      me = await client.getMe();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil bilgisi yüklenemedi.')),
        );
      }
      return;
    }
    if (!context.mounted) return;
    final firstController = TextEditingController(text: me['firstName'] ?? '');
    final lastController = TextEditingController(text: me['lastName'] ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Görünen adı düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstController,
              decoration: const InputDecoration(
                labelText: 'Ad',
                hintText: 'Ad',
              ),
              textCapitalization: TextCapitalization.words,
              maxLength: 30,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lastController,
              decoration: const InputDecoration(
                labelText: 'Soyad',
                hintText: 'Soyad',
              ),
              textCapitalization: TextCapitalization.words,
              maxLength: 30,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final firstName = firstController.text.trim();
    final lastName = lastController.text.trim();
    try {
      await client.patchMe(firstName: firstName, lastName: lastName);
      await auth.refreshUserProfile();
      LetterAvatar.clearFailedCache();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil güncellendi.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMessages.userFriendly(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final name = auth.userDisplayName ?? auth.userLogin ?? '-';
    final login = auth.userLogin;
    final instance = auth.instanceDisplayUrl ?? auth.storedInstanceBaseUrl ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profil',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        actions: const [ProjectFlowLogoButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: LetterAvatar(
              displayName: name,
              imageUrl: auth.userAvatarUrl,
              imageHeaders: _avatarHeaders(auth),
              size: 96,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          if (login != null && login.isNotEmpty)
            Center(
              child: Text(
                login,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ProfileRow(
                    label: 'Görünen ad',
                    value: name,
                  ),
                ),
                if (auth.client != null)
                  IconButton(
                    onPressed: () => _editDisplayName(context, auth),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Görünen adı düzenle',
                  ),
              ],
            ),
          ),
          if (login != null && login.isNotEmpty)
            _ProfileRow(
              label: 'Kullanıcı adı (login)',
              value: login,
            ),
          if (auth.userEmail != null && auth.userEmail!.isNotEmpty)
            _ProfileRow(
              label: 'E-posta',
              value: auth.userEmail!,
            ),
          _ProfileRow(
            label: 'Instance',
            value: instance,
          ),
          if (auth.client != null) ...[
            const SizedBox(height: 24),
            _DefaultProjectCard(requireSelection: requireProjectSelection),
          ],
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Görünüm',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          Consumer<ThemeState>(
            builder: (context, themeState, _) {
              return Card(
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('Açık tema'),
                      subtitle: const Text('Her zaman açık arka plan'),
                      value: ThemeMode.light,
                      groupValue: themeState.themeMode,
                      onChanged: (v) {
                        if (v != null) {
                          selectionClick();
                          themeState.setThemeMode(v);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<ThemeMode>(
                      title: const Text('Koyu tema'),
                      subtitle: const Text('Her zaman koyu arka plan'),
                      value: ThemeMode.dark,
                      groupValue: themeState.themeMode,
                      onChanged: (v) {
                        if (v != null) {
                          selectionClick();
                          themeState.setThemeMode(v);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<ThemeMode>(
                      title: const Text('Sistem varsayılanı'),
                      subtitle: const Text('Cihaz ayarına göre açık/koyu'),
                      value: ThemeMode.system,
                      groupValue: themeState.themeMode,
                      onChanged: (v) {
                        if (v != null) {
                          selectionClick();
                          themeState.setThemeMode(v);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          if (auth.client != null) ...[
            const SizedBox(height: 24),
            _NotificationSettingsCard(auth: auth),
            const SizedBox(height: 24),
            _UserPreferencesCard(auth: auth),
            const SizedBox(height: 24),
            _TimeTrackingReminderCard(auth: auth),
          ],
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FilledButton.icon(
              onPressed: () => auth.logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış yap'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bildirim ayarları: telefon bildirimi aç/kapa.
class _NotificationSettingsCard extends StatefulWidget {
  final AuthState auth;

  const _NotificationSettingsCard({required this.auth});

  @override
  State<_NotificationSettingsCard> createState() => _NotificationSettingsCardState();
}

class _NotificationSettingsCardState extends State<_NotificationSettingsCard> {
  bool? _mobileNotificationsEnabled;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final enabled = await NotificationPrefs.getMobileNotificationsEnabled();
    if (mounted) setState(() => _mobileNotificationsEnabled = enabled);
  }

  Future<void> _onMobileNotificationsChanged(bool value) async {
    await NotificationPrefs.setMobileNotificationsEnabled(value);
    setState(() => _mobileNotificationsEnabled = value);
    selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    if (_mobileNotificationsEnabled == null) {
      return const Card(
        child: ListTile(
          title: Text('Bildirim ayarları'),
          trailing: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Bildirim ayarları',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          SwitchListTile(
            title: const Text('Yeni bildirimde telefon bildirimi'),
            subtitle: const Text(
              'OpenProject\'te yeni bildirim oluştuğunda cihazda bildirim göster',
            ),
            value: _mobileNotificationsEnabled!,
            onChanged: _onMobileNotificationsChanged,
          ),
        ],
      ),
    );
  }
}

/// OpenProject hesap tercihleri: saat dilimi ve bildirim ayarları (API: my_preferences).
class _UserPreferencesCard extends StatefulWidget {
  final AuthState auth;

  const _UserPreferencesCard({required this.auth});

  @override
  State<_UserPreferencesCard> createState() => _UserPreferencesCardState();
}

class _UserPreferencesCardState extends State<_UserPreferencesCard> {
  bool _loading = true;
  String? _error;
  String? _timeZone;
  Map<String, bool> _notifications = const {};

  static const List<MapEntry<String, String>> _timeZoneList = [
    MapEntry('UTC', 'UTC'),
    MapEntry('Europe/Istanbul', 'İstanbul'),
    MapEntry('Europe/Berlin', 'Berlin'),
    MapEntry('Europe/London', 'Londra'),
    MapEntry('Europe/Paris', 'Paris'),
    MapEntry('Europe/Moscow', 'Moskova'),
    MapEntry('Europe/Amsterdam', 'Amsterdam'),
    MapEntry('Europe/Rome', 'Roma'),
    MapEntry('Europe/Athens', 'Atina'),
    MapEntry('America/New_York', 'New York'),
    MapEntry('America/Chicago', 'Chicago'),
    MapEntry('America/Denver', 'Denver'),
    MapEntry('America/Los_Angeles', 'Los Angeles'),
    MapEntry('Asia/Dubai', 'Dubai'),
    MapEntry('Asia/Singapore', 'Singapur'),
    MapEntry('Asia/Tokyo', 'Tokyo'),
    MapEntry('Australia/Sydney', 'Sidney'),
  ];

  static const Map<String, String> _notificationLabels = {
    'watched': 'İzlediğim öğeler',
    'involved': 'Atandığım / dahil olduğum',
    'mentioned': 'Beni andılar',
    'shared': 'Paylaşılan',
    'newsAdded': 'Haber eklendi',
    'newsCommented': 'Haber yorumu',
    'documentAdded': 'Belge eklendi',
    'forumMessages': 'Forum iletileri',
    'wikiPageAdded': 'Wiki sayfası eklendi',
    'wikiPageUpdated': 'Wiki sayfası güncellendi',
    'membershipAdded': 'Üyelik eklendi',
    'membershipUpdated': 'Üyelik güncellendi',
    'workPackageCommented': 'İş paketi yorumu',
    'workPackageProcessed': 'İş paketi işlendi',
    'workPackagePrioritized': 'İş paketi önceliklendi',
    'workPackageScheduled': 'İş paketi planlandı',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = widget.auth.client;
    if (client == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await client.getMyPreferences();
      if (!mounted) return;
      final tz = data['timeZone']?.toString();
      final notifRaw = data['notifications'];
      Map<String, bool> notif = {};
      if (notifRaw is Map) {
        for (final e in notifRaw.entries) {
          if (e.key is! String) continue;
          final k = e.key as String;
          bool v = false;
          if (e.value == true) {
            v = true;
          } else if (e.value == false) {
            v = false;
          } else if (e.value is String) {
            v = (e.value as String).toLowerCase() == 'true';
          }
          notif[k] = v;
        }
      }
      setState(() {
        _timeZone = tz;
        _notifications = notif;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorMessages.userFriendly(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _setTimeZone(String? value) async {
    if (value == null || value == _timeZone) return;
    final client = widget.auth.client;
    if (client == null) return;
    selectionClick();
    try {
      await client.patchMyPreferences({'timeZone': value});
      if (mounted) setState(() => _timeZone = value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saat dilimi güncellendi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMessages.userFriendly(e))),
        );
      }
    }
  }

  Future<void> _setNotification(String key, bool value) async {
    final client = widget.auth.client;
    if (client == null) return;
    selectionClick();
    final next = Map<String, bool>.from(_notifications)..[key] = value;
    try {
      await client.patchMyPreferences({'notifications': next});
      if (mounted) setState(() => _notifications = next);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMessages.userFriendly(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: ListTile(
          title: Text('Hesap tercihleri (OpenProject)'),
          trailing: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hesap tercihleri (OpenProject)', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(_error!),
              const SizedBox(height: 8),
              TextButton(onPressed: _load, child: const Text('Tekrar dene')),
            ],
          ),
        ),
      );
    }

    String currentTzLabel = 'Seçin';
    if (_timeZone != null) {
      final match = _timeZoneList.where((e) => e.key == _timeZone);
      currentTzLabel = match.isEmpty ? _timeZone! : match.first.value;
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Hesap tercihleri (OpenProject)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ListTile(
            title: const Text('Saat dilimi'),
            subtitle: Text(currentTzLabel),
            trailing: const Icon(Icons.schedule, size: 20),
            onTap: () async {
              final chosen = await showDialog<String>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('Saat dilimi'),
                  children: [
                    for (final e in _timeZoneList)
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, e.key),
                        child: Text(e.value),
                      ),
                    if (_timeZone != null &&
                        !_timeZoneList.any((e) => e.key == _timeZone))
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, _timeZone),
                        child: Text(_timeZone!),
                      ),
                  ],
                ),
              );
              if (chosen != null) await _setTimeZone(chosen);
            },
          ),
          const Divider(height: 1),
          ExpansionTile(
            title: const Text('Bildirim tercihleri'),
            subtitle: const Text('Hangi olaylarda bildirim alacağınızı seçin'),
            children: [
              for (final e in _notificationLabels.entries)
                SwitchListTile(
                  title: Text(e.value, style: Theme.of(context).textTheme.bodyMedium),
                  value: _notifications[e.key] ?? false,
                  onChanged: (v) => _setNotification(e.key, v),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Varsayılan proje listesi; seçim kayıt altına alınır (AuthState + secure storage).
class _DefaultProjectCard extends StatefulWidget {
  const _DefaultProjectCard({required this.requireSelection});

  final bool requireSelection;

  @override
  State<_DefaultProjectCard> createState() => _DefaultProjectCardState();
}

class _DefaultProjectCardState extends State<_DefaultProjectCard> {
  bool _loading = true;
  String? _error;
  List<Project> _projects = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthState>();
    final client = auth.client;
    if (client == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await client.getProjects();
      if (mounted) setState(() {
        _projects = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = ErrorMessages.userFriendly(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final selectedId = auth.activeProject?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Varsayılan proje',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ),
        if (widget.requireSelection && selectedId == null && !_loading && _error == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Zorunlu: Aşağıdan bir proje seçin.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        if (_loading)
          const Card(
            child: ListTile(
              title: Text('Projeler yükleniyor…'),
              trailing: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_error != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_error!),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _load,
                    child: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                ...List.generate(_projects.length, (i) {
                  final p = _projects[i];
                  final selected = p.id == selectedId;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        title: Text(
                          p.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: selected ? FontWeight.w600 : null,
                              ),
                        ),
                        subtitle: Text(
                          p.identifier,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: selected
                            ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                            : null,
                        onTap: () {
                          selectionClick();
                          auth.setActiveProject(p);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Varsayılan proje kaydedildi.')),
                            );
                          }
                        },
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

/// Zaman takibi hatırlatması: aç/kapa ve mesai bitiş saati (P1-F03).
class _TimeTrackingReminderCard extends StatefulWidget {
  final AuthState auth;

  const _TimeTrackingReminderCard({required this.auth});

  @override
  State<_TimeTrackingReminderCard> createState() => _TimeTrackingReminderCardState();
}

class _TimeTrackingReminderCardState extends State<_TimeTrackingReminderCard> {
  bool? _enabled;
  int? _endHour;
  int? _endMinute;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final enabled = await TimeTrackingReminderPrefs.getEnabled();
    final endHour = await TimeTrackingReminderPrefs.getEndHour();
    final endMinute = await TimeTrackingReminderPrefs.getEndMinute();
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _endHour = endHour;
        _endMinute = endMinute;
      });
    }
  }

  Future<void> _onEnabledChanged(bool value) async {
    await TimeTrackingReminderPrefs.setEnabled(value);
    setState(() => _enabled = value);
    selectionClick();
    await TimeTrackingReminderService().scheduleFromPrefs(widget.auth.client);
  }

  Future<void> _pickEndTime() async {
    final hour = _endHour ?? 17;
    final minute = _endMinute ?? 0;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (time == null || !mounted) return;
    await TimeTrackingReminderPrefs.setEndHour(time.hour);
    await TimeTrackingReminderPrefs.setEndMinute(time.minute);
    setState(() {
      _endHour = time.hour;
      _endMinute = time.minute;
    });
    selectionClick();
    await TimeTrackingReminderService().scheduleFromPrefs(widget.auth.client);
  }

  @override
  Widget build(BuildContext context) {
    if (_enabled == null) {
      return const Card(
        child: ListTile(
          title: Text('Zaman takibi hatırlatması'),
          trailing: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final endTimeStr = _endHour != null && _endMinute != null
        ? '${_endHour!.toString().padLeft(2, '0')}:${_endMinute!.toString().padLeft(2, '0')}'
        : '17:00';

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Zaman takibi hatırlatması'),
            subtitle: const Text(
              'Çalışma günü mesai bitimine yakın zaman kaydı hatırlatması',
            ),
            value: _enabled!,
            onChanged: _onEnabledChanged,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Mesai bitiş saati'),
            subtitle: Text(
              'Hatırlatma bitişten $kReminderMinutesBeforeEnd dk önce',
            ),
            trailing: Text(endTimeStr),
            onTap: _enabled! ? _pickEndTime : null,
          ),
        ],
      ),
    );
  }
}

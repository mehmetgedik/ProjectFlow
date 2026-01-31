import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_strings.dart';
import '../models/project.dart';
import '../state/auth_state.dart';
import '../utils/date_formatters.dart';
import '../utils/error_messages.dart';
import '../utils/haptic.dart';
import '../widgets/small_loading_indicator.dart';
import 'connect_settings_screen.dart';
import 'main_shell_screen.dart';

/// Giriş sonrası: projeleri yükler; varsayılan proje varsa Dashboard, yoksa Profil (proje seçimi zorunlu) gösterir.
class AuthenticatedGateScreen extends StatefulWidget {
  const AuthenticatedGateScreen({super.key});

  @override
  State<AuthenticatedGateScreen> createState() => _AuthenticatedGateScreenState();
}

class _AuthenticatedGateScreenState extends State<AuthenticatedGateScreen> {
  bool _resolved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final auth = context.read<AuthState>();
    final client = auth.client;
    if (client == null) return;
    setState(() {
      _resolved = false;
      _error = null;
    });
    try {
      // Projelerle birlikte hesap tercihini (saat dilimi) al; bildirim/aktivite saatleri doğru gösterilsin.
      final projectsFuture = client.getProjects();
      final prefsFuture = client.getMyPreferences().catchError((_) => <String, dynamic>{});
      final results = await Future.wait([projectsFuture, prefsFuture]);
      final projects = results[0] as List<Project>;
      final prefs = results[1] as Map<String, dynamic>;
      final tzId = prefs['timeZone'] ?? prefs['time_zone'];
      if (tzId != null && tzId.toString().trim().isNotEmpty) {
        DateFormatters.preferredTimeZoneId = tzId.toString().trim();
      }
      if (!mounted) return;
      final savedId = auth.activeProjectId;
      if (savedId != null && projects.any((p) => p.id == savedId)) {
        final match = projects.firstWhere((p) => p.id == savedId);
        auth.setActiveProject(match);
      } else if (projects.length == 1) {
        // Tek proje varsa kullanıcıdan seçim istemeden onu seç
        auth.setActiveProject(projects.first);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _resolved = true;
          _error = ErrorMessages.userFriendly(e);
        });
      }
      return;
    }
    if (mounted) setState(() => _resolved = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (!_resolved) {
      return Scaffold(
        body: Center(
          child: _error != null
              ? Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Semantics(
                          button: true,
                          label: '${AppStrings.labelRetry}. Projeleri yeniden yüklemeyi dene',
                          child: FilledButton(
                            onPressed: () {
                              lightImpact();
                              _resolve();
                            },
                            child: const Text(AppStrings.labelRetry),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Semantics(
                          button: true,
                          label: 'Bağlantı ayarlarına git. Instance URL ve API key düzenlenebilir',
                          child: OutlinedButton(
                            onPressed: () {
                              lightImpact();
                              final auth = context.read<AuthState>();
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (ctx) => ConnectSettingsScreen(
                                    initialInstanceUrl: auth.storedInstanceBaseUrl,
                                  ),
                                ),
                              ).then((_) {
                                if (mounted) _resolve();
                              });
                            },
                            child: const Text('Bağlantı ayarlarına git'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Semantics(
                  label: AppStrings.labelLoadingProjects,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SmallLoadingIndicator(),
                      const SizedBox(height: 16),
                      ExcludeSemantics(
                        child: Text(
                          '${AppStrings.labelLoadingProjects}…',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }
    final initialIndex = auth.activeProject != null ? 0 : 4;
    return MainShellScreen(initialIndex: initialIndex);
  }
}

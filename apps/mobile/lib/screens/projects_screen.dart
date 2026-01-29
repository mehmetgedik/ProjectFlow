import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../state/auth_state.dart';
import '../utils/error_messages.dart';
import '../utils/haptic.dart';
import '../widgets/letter_avatar.dart';
import '../widgets/projectflow_logo_button.dart';

Widget _buildNotificationAction(BuildContext context, AuthState auth) {
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

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  bool _loading = true;
  String? _error;
  List<Project> _projects = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthState>();
      final client = auth.client;
      if (client == null) throw Exception('Oturum bulunamadı.');
      _projects = await client.getProjects();
      if (!mounted) return;
      // Tek aktif proje varsa veya önceden seçilmiş proje varsa otomatik devam et (P0-F02)
      if (auth.activeProject == null) {
        if (_projects.length == 1) {
          auth.setActiveProject(_projects.first);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pushNamed('/dashboard');
          });
          return;
        }
        if (auth.activeProjectId != null) {
          final match = _projects.where((p) => p.id == auth.activeProjectId).toList();
          if (match.isNotEmpty) {
            auth.setActiveProject(match.first);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.of(context).pushNamed('/dashboard');
            });
            return;
          }
        }
      }
    } catch (e) {
      _error = ErrorMessages.userFriendly(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(
        leading: const ProjectFlowLogoButton(),
        title: InkWell(
          onTap: () => Navigator.of(context).pushNamed('/profile'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LetterAvatar(
                displayName: auth.userDisplayName ?? auth.userLogin,
                imageUrl: auth.userAvatarUrl,
                imageHeaders: _avatarHeaders(auth),
                size: 32,
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Projeler',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (auth.userDisplayName != null && auth.userDisplayName!.isNotEmpty)
                    Text(
                      auth.userDisplayName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          _buildNotificationAction(context, auth),
          IconButton(
            onPressed: () => auth.logout(),
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış',
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
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _projects.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final p = _projects[i];
                            return ListTile(
                              title: Text(
                                p.name,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              subtitle: Text(
                                p.identifier,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              onTap: () {
                                lightImpact();
                                auth.setActiveProject(p);
                                Navigator.of(context).pushNamed('/dashboard');
                              },
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
                            '${_projects.length} proje',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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


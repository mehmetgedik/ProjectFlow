import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../state/auth_state.dart';
import '../utils/error_messages.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';

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
      final projects = await client.getProjects();
      if (!mounted) return;
      final savedId = auth.activeProjectId;
      if (savedId != null && projects.any((p) => p.id == savedId)) {
        final match = projects.firstWhere((p) => p.id == savedId);
        auth.setActiveProject(match);
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
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _resolve,
                        child: const Text('Tekrar dene'),
                      ),
                    ],
                  ),
                )
              : const CircularProgressIndicator(),
        ),
      );
    }
    if (auth.activeProject != null) {
      return const DashboardScreen();
    }
    return const ProfileScreen(requireProjectSelection: true);
  }
}

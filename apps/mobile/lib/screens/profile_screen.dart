import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/openproject_client.dart';
import '../state/auth_state.dart';
import '../state/theme_state.dart';
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
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
        final msg = e.toString().contains('403') || e.toString().contains('Yetkisiz')
            ? 'Profil güncelleme yetkiniz yok.'
            : 'Güncellenemedi: $e';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
          _ProfileRow(
            label: 'Instance',
            value: instance,
          ),
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

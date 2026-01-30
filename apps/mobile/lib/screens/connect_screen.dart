import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../utils/error_messages.dart';
import '../utils/haptic.dart';
import '../utils/snackbar_helpers.dart';
import '../widgets/letter_avatar.dart';
import '../widgets/small_loading_indicator.dart';
import 'connect_settings_screen.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _instanceController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _instanceFocusNode = FocusNode();
  final _apiKeyFocusNode = FocusNode();

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;
  bool _obscureApiKey = true;

  @override
  void dispose() {
    _instanceController.dispose();
    _apiKeyController.dispose();
    _instanceFocusNode.dispose();
    _apiKeyFocusNode.dispose();
    super.dispose();
  }

  void _openSettings(BuildContext context) {
    final auth = context.read<AuthState>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ConnectSettingsScreen(
          initialInstanceUrl: auth.storedInstanceBaseUrl ?? _instanceController.text,
          initialApiKey: auth.storedApiKey ?? _apiKeyController.text,
        ),
      ),
    );
  }

  Future<void> _connect() async {
    if (_loading) return;
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context.read<AuthState>().connect(
            instanceBaseUrl: _instanceController.text.trim(),
            apiKey: _apiKeyController.text,
          );
      LetterAvatar.clearFailedCache();
    } catch (e) {
      setState(() => _error = ErrorMessages.userFriendly(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Kayıtlı değerleri alanlara yansıt (kullanıcı temizlemedikçe kalıcı)
    final storedInstance = auth.storedInstanceBaseUrl;
    final storedKey = auth.storedApiKey;
    if (storedInstance != null &&
        storedInstance.isNotEmpty &&
        _instanceController.text != storedInstance) {
      _instanceController.text = storedInstance;
    }
    if (storedKey != null &&
        storedKey.isNotEmpty &&
        _apiKeyController.text.isEmpty) {
      _apiKeyController.text = storedKey;
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.4),
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverAppBar(
                title: const Text('ProjectFlow'),
                centerTitle: true,
                backgroundColor: colorScheme.surface,
                elevation: 0,
                scrolledUnderElevation: 2,
                floating: true,
                snap: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_rounded),
                    onPressed: () {
                      mediumImpact();
                      _openSettings(context);
                    },
                    tooltip: 'Bağlantı ayarları',
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            // Logo / marka alanı
                            Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.shadow.withValues(alpha: 0.08),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    _LogoSection(theme: theme),
                                    const SizedBox(height: 8),
                                    Text(
                                      'OpenProject hesabına bağlan',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Instance adresini ve kişisel API anahtarını gir. Ayarlar cihazda saklanır; uygulama otomatik temizlemez (yalnızca kullanıcı çıkış yaparsa temizlenir).',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),
                              // Form alanları
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.shadow.withValues(alpha: 0.06),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    TextFormField(
                                      controller: _instanceController,
                                      focusNode: _instanceFocusNode,
                                      decoration: InputDecoration(
                                        labelText: 'Instance URL',
                                        hintText: 'https://openproject.example.com',
                                        prefixIcon: const Icon(Icons.link_rounded),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.mic_outlined),
                                          onPressed: () {
                                            _instanceFocusNode.requestFocus();
                                            if (mounted) {
                                              showAppSnackBar(context, 'Klavyede mikrofon ile sesli yazabilirsiniz.');
                                            }
                                          },
                                          tooltip: 'Sesle yazmak için alana odaklan',
                                        ),
                                      ),
                                      autofillHints: const [AutofillHints.url],
                                      keyboardType: TextInputType.url,
                                      textInputAction: TextInputAction.next,
                                      enableInteractiveSelection: true,
                                      autocorrect: false,
                                      enableSuggestions: true,
                                      validator: (value) {
                                        final v = value?.trim() ?? '';
                                        if (v.isEmpty) return 'Instance adresi zorunlu.';
                                        if (!v.startsWith('http://') &&
                                            !v.startsWith('https://')) {
                                          return 'http:// veya https:// ile başlamalı.';
                                        }
                                        if (kReleaseMode && v.startsWith('http://')) {
                                          return 'Güvenlik için sadece https:// kullanın.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _apiKeyController,
                                      focusNode: _apiKeyFocusNode,
                                      decoration: InputDecoration(
                                        labelText: 'API key',
                                        prefixIcon: const Icon(Icons.key_rounded),
                                        suffixIcon: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.mic_outlined),
                                              onPressed: () {
                                                _apiKeyFocusNode.requestFocus();
                                                if (mounted) {
                                                  showAppSnackBar(context, 'Klavyede mikrofon ile sesli yazabilirsiniz.');
                                                }
                                              },
                                              tooltip: 'Sesle yazmak için alana odaklan',
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                _obscureApiKey
                                                    ? Icons.visibility_off_rounded
                                                    : Icons.visibility_rounded,
                                              ),
                                              onPressed: () {
                                                setState(
                                                    () => _obscureApiKey =
                                                        !_obscureApiKey);
                                              },
                                              tooltip:
                                                  _obscureApiKey ? 'Göster' : 'Gizle',
                                            ),
                                          ],
                                        ),
                                      ),
                                      autofillHints: const [AutofillHints.password],
                                      obscureText: _obscureApiKey,
                                      enableSuggestions: false,
                                      autocorrect: false,
                                      enableInteractiveSelection: true,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _connect(),
                                      validator: (value) {
                                        if ((value ?? '').isEmpty) {
                                          return 'API key zorunlu.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'OpenProject’te Kullanıcı menüsü → Hesabım → API erişimi bölümünden kişisel API anahtarını alabilirsin.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.outline,
                                      ),
                                    ),
                                    if (_error != null) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: colorScheme.errorContainer,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline_rounded,
                                              color: colorScheme.onErrorContainer,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _error!,
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  color: colorScheme.onErrorContainer,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 20),
                                    Semantics(
                                      label: 'OpenProject hesabına bağlan',
                                      button: true,
                                      child: FilledButton(
                                        onPressed: () {
                                          mediumImpact();
                                          _connect();
                                        },
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                        ),
                                        child: _loading
                                            ? const SizedBox(
                                              height: 22,
                                              child: Center(
                                                child: SmallLoadingIndicator(size: 22),
                                              ),
                                            )
                                          : const Text('Bağlan'),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Semantics(
                                      button: true,
                                      label: 'Saklanan ayarları sil',
                                      child: TextButton.icon(
                                      onPressed: (auth.storedInstanceBaseUrl != null &&
                                                  auth.storedInstanceBaseUrl!.isNotEmpty) ||
                                              (auth.storedApiKey != null &&
                                                  auth.storedApiKey!.isNotEmpty)
                                          ? () async {
                                              mediumImpact();
                                              final authState = context.read<AuthState>();
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('Saklanan ayarları sil'),
                                                  content: const Text(
                                                    'Cihazda saklanan instance adresi, API key ve aktif proje bilgisi silinecek. Devam etmek istiyor musun?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(ctx).pop(false),
                                                      child: const Text('İptal'),
                                                    ),
                                                    Semantics(
                                                      label: 'Saklanan ayarları sil ve onayla',
                                                      button: true,
                                                      child: FilledButton(
                                                        onPressed: () =>
                                                            Navigator.of(ctx).pop(true),
                                                        style: FilledButton.styleFrom(
                                                          backgroundColor: Theme.of(ctx).colorScheme.error,
                                                          foregroundColor: Theme.of(ctx).colorScheme.onError,
                                                        ),
                                                        child: const Text('Sil'),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (!mounted || confirm != true) return;
                                              await authState.clearStoredSettings();
                                              if (!mounted) return;
                                              _instanceController.clear();
                                              _apiKeyController.clear();
                                              setState(() => _error = null);
                                            }
                                          : null,
                                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                      label: const Text('Saklanan ayarları sil'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    ),
                            const SizedBox(height: 32),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Semantics(
        label: 'ProjectFlow logosu',
        child: Image.asset(
          'assets/icon/app_icon_transpara.png',
          width: 220,
          height: 120,
          fit: BoxFit.contain,
          isAntiAlias: true,
        ),
      ),
    );
  }
}

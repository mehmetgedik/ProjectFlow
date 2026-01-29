import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../utils/haptic.dart';
import '../widgets/letter_avatar.dart';
import 'connect_settings_screen.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _instanceController = TextEditingController(text: 'https://openproject.uyumsoft.com');
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
    if (!_formKey.currentState!.validate()) return;

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
      setState(() => _error = e.toString());
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
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 2,
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
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
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
                                          onPressed: () =>
                                              _instanceFocusNode.requestFocus(),
                                          tooltip:
                                              'Sesle yazmak için alana odaklan',
                                        ),
                                      ),
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
                                              onPressed: () =>
                                                  _apiKeyFocusNode.requestFocus(),
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
                                                style: TextStyle(
                                                  color: colorScheme.onErrorContainer,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 20),
                                    FilledButton(
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
                                                child: SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : const Text('Bağlan'),
                                    ),
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
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        // Logo dışında kalan alan: koyu temada siyah, açık temada beyaz.
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Image.asset(
        'assets/brand/projectflow_lockup.png',
        width: 220,
        height: 120,
        fit: BoxFit.contain,
      ),
    );
  }
}

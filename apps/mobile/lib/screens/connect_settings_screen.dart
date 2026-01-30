import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../app_navigation.dart';
import '../constants/app_strings.dart';
import '../state/auth_state.dart';
import '../utils/error_messages.dart';
import '../utils/haptic.dart';
import '../widgets/small_loading_indicator.dart';

/// Tam ekran bağlantı ayarları sayfası.
/// Klavye ve yapıştırma (paste) düzgün çalışır; ayarlar kalıcıdır (uygulama otomatik silmez, kullanıcı çıkış yaparsa temizlenir).
class ConnectSettingsScreen extends StatefulWidget {
  const ConnectSettingsScreen({
    super.key,
    this.initialInstanceUrl,
    this.initialApiKey,
  });

  final String? initialInstanceUrl;
  final String? initialApiKey;

  @override
  State<ConnectSettingsScreen> createState() => _ConnectSettingsScreenState();
}

class _ConnectSettingsScreenState extends State<ConnectSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _instanceController;
  late final TextEditingController _apiKeyController;
  bool _loading = false;
  String? _error;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _instanceController = TextEditingController(
      text: widget.initialInstanceUrl ?? '',
    );
    _apiKeyController = TextEditingController(
      text: widget.initialApiKey ?? '',
    );
  }

  @override
  void dispose() {
    _instanceController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
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
      if (mounted) {
        mediumImpact();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) setState(() => _error = ErrorMessages.userFriendly(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverAppBar(
              title: const Text('Bağlantı ayarları'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Geri',
              ),
              floating: true,
              snap: true,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                  'Instance, API key ve varsayılan projeni burada ayarlayabilirsin. Ayarlar cihazda güvenli şekilde saklanır; uygulama otomatik temizlemez (yalnızca kullanıcı çıkış yaparsa temizlenir).',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _instanceController,
                  decoration: const InputDecoration(
                    labelText: 'Instance URL',
                    hintText: 'https://openproject.example.com',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                  autofillHints: const [AutofillHints.url],
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: true,
                  enableInteractiveSelection: true,
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
                  decoration: InputDecoration(
                    labelText: 'API key',
                    prefixIcon: const Icon(Icons.key_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureApiKey
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      onPressed: () {
                        setState(() => _obscureApiKey = !_obscureApiKey);
                      },
                      tooltip: _obscureApiKey ? 'Göster' : 'Gizle',
                    ),
                  ),
                  autofillHints: const [AutofillHints.password],
                  obscureText: _obscureApiKey,
                  enableSuggestions: false,
                  autocorrect: false,
                  enableInteractiveSelection: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  validator: (value) {
                    if ((value ?? '').isEmpty) return 'API key zorunlu.';
                    return null;
                  },
                ),
                if (auth.activeProject != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder_rounded,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Son seçilen proje',
                                style: theme.textTheme.labelSmall,
                              ),
                              Text(
                                auth.activeProject!.name,
                                style: theme.textTheme.titleSmall,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.home,
                              (route) => false,
                            );
                          },
                          child: const Text('Projeyi değiştir'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: theme.colorScheme.onErrorContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Semantics(
                  label: _loading ? AppStrings.labelConnecting : 'Bağlantı ayarlarını kaydet',
                  button: true,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _save,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: SmallLoadingIndicator(),
                          )
                        : const Icon(Icons.check_rounded, size: 20),
                    label: Text(_loading ? AppStrings.labelConnectingShort : 'Kaydet'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                      const SizedBox(height: 32),
                    ],
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

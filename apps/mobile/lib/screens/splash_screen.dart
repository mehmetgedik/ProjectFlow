import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants/app_strings.dart';
import '../state/auth_state.dart';
import '../widgets/small_loading_indicator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Theme.of(context) initState içinde kullanılamaz; ilk frame sonrasında uygula.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Theme.of(context).colorScheme.surface,
        ),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthState>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.35),
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Semantics(
                  label: AppStrings.labelProjectFlowLogo,
                  child: SizedBox(
                    width: 280,
                    height: 180,
                    child: Image.asset(
                      'assets/icon/app_icon_transpara.png',
                      fit: BoxFit.contain,
                      isAntiAlias: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ProjectFlow',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Semantics(
                label: AppStrings.labelLoading,
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: SmallLoadingIndicator(),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

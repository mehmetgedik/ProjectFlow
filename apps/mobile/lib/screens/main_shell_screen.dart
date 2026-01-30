import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../state/pro_state.dart';
import '../utils/haptic.dart';
import '../widgets/free_plan_banner.dart';
import '../widgets/letter_avatar.dart';
import 'dashboard_screen.dart';
import 'my_work_packages_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'time_tracking_screen.dart';

/// Ana navigasyon kabuğu: alt sekmeli gezinme ile Dashboard, Benim işlerim, Bildirimler, Zaman takibi, Profil.
/// [initialIndex] proje seçimi zorunluysa 4 (Profil), yoksa 0 (Dashboard).
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProState>().loadProStatus();
    });
  }

  void _onProjectSelected() {
    setState(() => _currentIndex = 0);
  }

  /// Profil sekmesi: Kullanıcı avatarı (rozetsiz).
  NavigationDestination _profileNavDestination(BuildContext context) {
    final auth = context.watch<AuthState>();
    final displayName = (auth.userDisplayName ?? auth.userLogin ?? '').trim();
    final avatar = LetterAvatar(
      displayName: displayName.isEmpty ? '?' : displayName,
      imageUrl: auth.userAvatarUrl,
      imageHeaders: auth.authHeadersForInstanceImages,
      size: 24,
    );
    return NavigationDestination(
      icon: avatar,
      selectedIcon: avatar,
      label: 'Profil',
    );
  }

  /// Zaman takibi sekmesi: Pro değilse ikon üzerinde yıldız rozeti (Pro'da olduğunu gösterir).
  NavigationDestination _timeNavDestination(BuildContext context) {
    final isPro = context.watch<ProState>().isPro;
    final theme = Theme.of(context);
    final iconOutlined = const Icon(Icons.schedule_outlined);
    final iconFilled = const Icon(Icons.schedule);
    return NavigationDestination(
      icon: !isPro
          ? Badge(
              label: Icon(Icons.star_rounded, size: 10, color: theme.colorScheme.onPrimary),
              backgroundColor: theme.colorScheme.primary,
              smallSize: 16,
              child: iconOutlined,
            )
          : iconOutlined,
      selectedIcon: !isPro
          ? Badge(
              label: Icon(Icons.star_rounded, size: 10, color: theme.colorScheme.onPrimary),
              backgroundColor: theme.colorScheme.primary,
              smallSize: 16,
              child: iconFilled,
            )
          : iconFilled,
      label: 'Zaman',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FreePlanBanner(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                const DashboardScreen(isInsideShell: true),
                const MyWorkPackagesScreen(isInsideShell: true),
                const NotificationsScreen(isInsideShell: true),
                const TimeTrackingScreen(),
                ProfileScreen(
                  requireProjectSelection: context.watch<AuthState>().activeProject == null,
                  isInsideShell: true,
                  onProjectSelected: _onProjectSelected,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Semantics(
        label: 'Alt gezinme: Dashboard, Benim işlerim, Bildirimler, Zaman, Profil',
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (int index) {
            if (_currentIndex == index) return;
            lightImpact();
            setState(() => _currentIndex = index);
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            const NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: 'Benim işlerim',
            ),
            const NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Bildirimler',
            ),
            _timeNavDestination(context),
            _profileNavDestination(context),
          ],
        ),
      ),
    );
  }
}

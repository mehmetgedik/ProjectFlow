import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_navigation.dart';
import '../constants/app_strings.dart';
import '../state/auth_state.dart';

/// AppBar'da kullanılan bildirim ikonu; okunmamış sayı varsa rozet gösterir.
/// Tıklanınca bildirimler sayfasına gider ve dönüşte sayıyı yeniler.
class NotificationBadgeButton extends StatelessWidget {
  /// İkon boyutu (varsayılan 24; my_work listesinde 22 kullanılabilir).
  final double iconSize;

  const NotificationBadgeButton({super.key, this.iconSize = 24});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final count = auth.unreadNotificationCount;
    final button = Tooltip(
      message: AppStrings.labelOpenNotifications,
      waitDuration: const Duration(milliseconds: 500),
      showDuration: const Duration(seconds: 2),
      child: IconButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.notifications).then((_) {
            auth.refreshUnreadNotificationCount();
          });
        },
        tooltip: AppStrings.labelOpenNotifications,
        icon: Icon(Icons.notifications_outlined, size: iconSize),
      ),
    );
    if (count <= 0) return button;
    final theme = Theme.of(context);
    return Badge(
      offset: const Offset(-6, 4),
      label: Text(
        count > 99 ? '99+' : '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onError,
        ),
      ),
      child: button,
    );
  }
}

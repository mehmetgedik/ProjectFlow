import 'package:flutter/material.dart';

import 'error_messages.dart';

/// Bilgi veya başarı mesajını tema ile uyumlu SnackBar olarak gösterir.
void showAppSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.inverseSurface,
    ),
  );
}

/// Hata mesajını kullanıcı dostu metne çevirip SnackBar olarak gösterir.
void showErrorSnackBar(
  BuildContext context,
  dynamic error, {
  Duration? duration,
}) {
  final message = ErrorMessages.userFriendly(error);
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
      duration: duration ?? const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.inverseSurface,
    ),
  );
}

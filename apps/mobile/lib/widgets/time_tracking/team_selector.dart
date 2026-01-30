import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';
import '../letter_avatar.dart';

/// Zaman takibi ekranında ekip modu açıkken kullanıcı seçici (PopupMenuButton).
class TimeTrackingTeamSelector extends StatelessWidget {
  const TimeTrackingTeamSelector({
    super.key,
    required this.projectMembers,
    required this.selectedUserId,
    required this.onSelected,
  });

  final List<Map<String, String>> projectMembers;
  final String? selectedUserId;
  final void Function(String?) onSelected;

  @override
  Widget build(BuildContext context) {
    if (projectMembers.isEmpty) return const SizedBox.shrink();
    final auth = context.read<AuthState>();
    final theme = Theme.of(context);
    final selectedMember = projectMembers
        .cast<Map<String, String>?>()
        .whereType<Map<String, String>>()
        .where((m) => m['id'] == selectedUserId)
        .toList();
    final displayName = selectedMember.isEmpty
        ? null
        : (selectedMember.first['name'] ?? selectedMember.first['id']);
    final avatarUrl = auth.instanceApiBaseUrl != null &&
            selectedUserId != null &&
            selectedUserId!.isNotEmpty
        ? '${auth.instanceApiBaseUrl!.replaceAll(RegExp(r'/+$'), '')}/users/$selectedUserId/avatar'
        : null;

    return PopupMenuButton<String>(
      icon: LetterAvatar(
        displayName: displayName,
        imageUrl: avatarUrl,
        imageHeaders: auth.authHeadersForInstanceImages,
        size: 32,
      ),
      tooltip: 'Kullanıcı seç',
      padding: EdgeInsets.zero,
      onSelected: (v) {
        HapticFeedback.lightImpact();
        onSelected(v);
      },
      itemBuilder: (ctx) {
        final authInner = context.read<AuthState>();
        final apiBaseUrl = authInner.instanceApiBaseUrl ?? '';
        return projectMembers
            .cast<Map<String, String>?>()
            .whereType<Map<String, String>>()
            .map((m) {
              final id = m['id'] ?? '';
              final name = m['name'] ?? id;
              final memberAvatarUrl =
                  (apiBaseUrl.isNotEmpty && id.isNotEmpty)
                      ? '$apiBaseUrl/users/$id/avatar'
                      : null;
              return PopupMenuItem<String>(
                value: id,
                child: Row(
                  children: [
                    if (selectedUserId == id)
                      Icon(Icons.check, size: 20, color: theme.colorScheme.primary),
                    if (selectedUserId == id) const SizedBox(width: 8),
                    LetterAvatar(
                      displayName: name,
                      imageUrl: memberAvatarUrl,
                      imageHeaders: authInner.authHeadersForInstanceImages,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(name, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              );
            })
            .toList();
      },
    );
  }
}

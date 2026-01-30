import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../mixins/client_context_mixin.dart';
import '../models/work_package_activity.dart';
import '../state/auth_state.dart';
import '../utils/date_formatters.dart';
import '../utils/error_messages.dart';
import '../widgets/async_content.dart';
import '../widgets/letter_avatar.dart';

/// İş paketi detay ekranında aktivite (yorumlar) sekmesi.
class WorkPackageActivityTab extends StatefulWidget {
  final String workPackageId;

  const WorkPackageActivityTab({super.key, required this.workPackageId});

  @override
  State<WorkPackageActivityTab> createState() => _WorkPackageActivityTabState();
}

class _WorkPackageActivityTabState extends State<WorkPackageActivityTab>
    with ClientContextMixin<WorkPackageActivityTab> {
  bool _loading = true;
  String? _error;
  List<WorkPackageActivity> _items = const [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = client;
      if (c == null) throw Exception('Oturum bulunamadı.');
      _items = await c.getWorkPackageActivities(widget.workPackageId);
    } catch (e) {
      _error = ErrorMessages.userFriendly(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _error = null;
    });
    try {
      final c = client;
      if (c == null) throw Exception('Oturum bulunamadı.');
      await c.addWorkPackageComment(workPackageId: widget.workPackageId, comment: text);
      _commentController.clear();
      await _load();
    } catch (e) {
      setState(() => _error = ErrorMessages.userFriendly(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AsyncContent(
            loading: _loading,
            error: _error,
            onRetry: _load,
            showEmpty: _items.isEmpty,
            empty: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Henüz aktivite bulunmuyor.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            child: ListView.separated(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final a = _items[index];
                            final auth = context.read<AuthState>();
                            final apiBaseUrl = auth.instanceApiBaseUrl ?? '';
                            final hasAuthor = a.authorId != null && a.authorId!.isNotEmpty && apiBaseUrl.isNotEmpty;
                            final avatarUrl = hasAuthor ? '$apiBaseUrl/users/${a.authorId}/avatar' : null;
                            return ListTile(
                              leading: LetterAvatar(
                                displayName: a.authorName.isNotEmpty ? a.authorName : '?',
                                imageUrl: avatarUrl,
                                imageHeaders: avatarUrl != null ? auth.authHeadersForInstanceImages : null,
                                size: 40,
                              ),
                              title: Text(
                                a.authorName,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormatters.formatDateTime(a.createdAt),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                  if ((a.comment ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(a.comment!),
                                  ] else if (!a.isComment) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Durum / alan değişikliği',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Yorum yaz...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendComment,
                icon: const Icon(Icons.send),
                color: Theme.of(context).colorScheme.primary,
                tooltip: 'Yorumu gönder',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import '../utils/date_formatters.dart';

class NotificationItem {
  final String id;
  /// Bildirimin konusu (iş paketi başlığı). API'de bazen _links.resource.title'dan gelir (web ile uyumlu).
  final String subject;
  final String reason;
  final bool read;
  final DateTime? createdAt;
  final String? projectName;
  final String? resourceHref;
  /// İlişkili iş paketi ID (resource href'ten; web'de #123 gibi gösterim için).
  final String? resourceId;
  /// Bildirimi tetikleyen kullanıcı ID (avatar için; _links.actor.href'ten).
  final String? actorId;
  /// Bildirimi tetikleyen kullanıcı adı (_links.actor.title).
  final String? actorName;

  const NotificationItem({
    required this.id,
    required this.subject,
    required this.reason,
    required this.read,
    this.createdAt,
    this.projectName,
    this.resourceHref,
    this.resourceId,
    this.actorId,
    this.actorName,
  });

  static bool _readFromJson(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    return s == 'true' || s == 't' || s == '1';
  }

  static String? _idFromHref(dynamic href) {
    if (href == null) return null;
    final s = href.toString().trim();
    if (s.isEmpty) return null;
    final parts = s.split('/');
    return parts.isEmpty ? null : parts.last.split('?').first;
  }

  factory NotificationItem.fromJson(Map json) {
    final links = json['_links'] as Map<String, dynamic>? ?? const {};
    final project = links['project'] as Map<String, dynamic>?;
    final resource = links['resource'] as Map<String, dynamic>?;
    final actor = links['actor'] as Map<String, dynamic>?;
    final resourceHref = resource?['href']?.toString();
    final resourceId = _idFromHref(resourceHref);
    final actorHref = actor?['href']?.toString();
    final actorId = actorHref != null && actorHref.contains('/users/')
        ? actorHref.split('/users/').last.split('/').first.trim()
        : null;
    // Web'deki gibi: subject bazen kökte yok, _links.resource.title'dan alınır.
    final subject = (json['subject']?.toString() ?? resource?['title']?.toString() ?? '').trim();

    final createdRaw = (json['createdAt'] ?? json['created_at']) as String?;
    final created = DateFormatters.parseApiDateTime(createdRaw);

    return NotificationItem(
      id: (json['id'] ?? '').toString(),
      subject: subject,
      reason: (json['reason'] ?? '').toString(),
      read: _readFromJson(json['readIAN']),
      createdAt: created,
      projectName: project?['title']?.toString(),
      resourceHref: resourceHref?.isEmpty == true ? null : resourceHref,
      resourceId: resourceId?.isEmpty == true ? null : resourceId,
      actorId: actorId?.isEmpty == true ? null : actorId,
      actorName: actor?['title']?.toString(),
    );
  }
}


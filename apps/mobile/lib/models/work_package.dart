import '../utils/date_formatters.dart';

class WorkPackage {
  final String id;
  final String subject;
  final String statusName;
  final String? assigneeName;
  final DateTime? startDate;
  final DateTime? dueDate;
  final String? description;
  final String? priorityName;
  final String? typeName;
  final DateTime? updatedAt;
  final String? projectId;
  final String? statusId;
  final String? assigneeId;
  final String? typeId;
  final String? parentId;
  final String? parentSubject;
  final String? versionId;
  final String? versionName;

  const WorkPackage({
    required this.id,
    required this.subject,
    required this.statusName,
    this.assigneeName,
    this.startDate,
    this.dueDate,
    this.description,
    this.priorityName,
    this.typeName,
    this.updatedAt,
    this.projectId,
    this.statusId,
    this.assigneeId,
    this.typeId,
    this.parentId,
    this.parentSubject,
    this.versionId,
    this.versionName,
  });

  static String? _idFromHref(dynamic href) {
    if (href == null) return null;
    final s = href.toString().trim();
    if (s.isEmpty) return null;
    final parts = s.split('/');
    return parts.isEmpty ? null : parts.last.split('?').first;
  }

  factory WorkPackage.fromJson(Map json) {
    final links = json['_links'] as Map<String, dynamic>? ?? const {};
    final status = links['status'] as Map<String, dynamic>?;
    final assignee = links['assignee'] as Map<String, dynamic>?;
    final priority = links['priority'] as Map<String, dynamic>?;
    final type = links['type'] as Map<String, dynamic>?;
    final project = links['project'] as Map<String, dynamic>?;
    final parent = links['parent'] as Map<String, dynamic>?;
    final version = links['version'] as Map<String, dynamic>?;
    final start = json['startDate'] as String?;
    final due = json['dueDate'] as String?;
    final updated = json['updatedAt'] as String?;
    final desc = json['description'] as Map<String, dynamic>?;
    final rawDesc = desc?['raw']?.toString();

    return WorkPackage(
      id: (json['id'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      statusName: (status?['title'] ?? '').toString(),
      assigneeName: assignee?['title']?.toString(),
      startDate: DateFormatters.parseApiDateTime(start),
      dueDate: DateFormatters.parseApiDateTime(due),
      description: rawDesc != null && rawDesc.isNotEmpty ? rawDesc : null,
      priorityName: priority?['title']?.toString(),
      typeName: type?['title']?.toString(),
      updatedAt: DateFormatters.parseApiDateTime(updated),
      projectId: _idFromHref(project?['href']),
      statusId: _idFromHref(status?['href']),
      assigneeId: _idFromHref(assignee?['href']),
      typeId: _idFromHref(type?['href']),
      parentId: _idFromHref(parent?['href']),
      parentSubject: parent?['title']?.toString(),
      versionId: _idFromHref(version?['href']),
      versionName: version?['title']?.toString(),
    );
  }
}


import 'package:flutter/foundation.dart';

class TimeEntry {
  final String id;
  final DateTime spentOn;
  final double hours;
  final String? comment;
  final String? activityName;
  /// Aktivite ID (düzenleme formunda seçili göstermek için; _links.activity.href).
  final String? activityId;
  /// İş paketi ID (zaman kaydı listesinde hangi işe ait olduğunu göstermek için).
  final String? workPackageId;
  final String? workPackageSubject;
  /// Ekip görünümünde gösterilmek üzere kullanıcı adı (_links.user.title).
  final String? userName;
  /// Zaman kaydını giren kullanıcı ID (profil resmi URL için; _links.user.href).
  final String? userId;
  /// Zaman kaydının oluşturulma tarihi (sıralama için; API createdAt).
  final DateTime? createdAt;

  const TimeEntry({
    required this.id,
    required this.spentOn,
    required this.hours,
    this.comment,
    this.activityName,
    this.activityId,
    this.workPackageId,
    this.workPackageSubject,
    this.userName,
    this.userId,
    this.createdAt,
  });

  factory TimeEntry.fromJson(Map json) {
    final spentOnRaw = json['spentOn'] as String?;
    final hoursRaw = json['hours']?.toString();

    double parsedHours = 0;
    if (hoursRaw != null && hoursRaw.isNotEmpty) {
      // hours can be ISO 8601 duration (e.g. PT1H, PT1.5H, PT30M) or a plain decimal string
      if (hoursRaw.startsWith('PT')) {
        final value = hoursRaw.substring(2);
        if (value.endsWith('H')) {
          final v = value.substring(0, value.length - 1);
          parsedHours = double.tryParse(v) ?? 0;
        } else if (value.endsWith('M')) {
          final v = value.substring(0, value.length - 1);
          final minutes = double.tryParse(v) ?? 0;
          parsedHours = minutes / 60.0;
        }
      } else {
        parsedHours = double.tryParse(hoursRaw) ?? 0;
      }
    }

    DateTime spent;
    try {
      spent = spentOnRaw != null ? DateTime.parse(spentOnRaw) : DateTime.now();
    } catch (e) {
      if (kDebugMode) debugPrint('TimeEntry spentOn parse: $e');
      spent = DateTime.now();
    }

    DateTime? createdAt;
    try {
      final raw = json['createdAt']?.toString();
      if (raw != null && raw.isNotEmpty) createdAt = DateTime.parse(raw);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        debugPrint('TimeEntry createdAt parse: $e');
      }
    }

    final links = json['_links'] as Map<String, dynamic>? ?? const {};
    final activity = links['activity'] as Map<String, dynamic>?;
    String? activityId;
    if (activity != null) {
      final href = activity['href']?.toString() ?? '';
      final match = RegExp(r'/time_entries/activities/(\d+)$').firstMatch(href);
      if (match != null) activityId = match.group(1);
    }
    final userLink = links['user'] as Map<String, dynamic>?;
    final userName = userLink?['title']?.toString();
    String? userId;
    if (userLink != null) {
      final href = userLink['href']?.toString() ?? '';
      final match = RegExp(r'/users/(\d+)(?:/|$)').firstMatch(href);
      if (match != null) userId = match.group(1);
    }
    final workPackageLink = links['workPackage'] ?? links['entity'];
    String? wpId;
    String? wpSubject;
    if (workPackageLink is Map) {
      final href = workPackageLink['href']?.toString() ?? '';
      final match = RegExp(r'/work_packages/(\d+)$').firstMatch(href);
      if (match != null) wpId = match.group(1);
      // API list response: iş başlığı _links.entity.title veya _links.workPackage.title içinde gelir.
      wpSubject = workPackageLink['title']?.toString();
    }
    if (wpSubject == null || wpSubject.trim().isEmpty) {
      final embedded = json['_embedded'] as Map<String, dynamic>?;
      final wpEmbedded = embedded?['workPackage'] as Map<String, dynamic>? ?? embedded?['entity'] as Map<String, dynamic>?;
      wpSubject = wpEmbedded?['subject']?.toString();
    }

    return TimeEntry(
      id: (json['id'] ?? '').toString(),
      spentOn: spent,
      hours: parsedHours,
      activityName: activity?['title']?.toString(),
      activityId: activityId,
      comment: (json['comment']?['raw'] ?? '').toString(),
      workPackageId: wpId,
      workPackageSubject: wpSubject,
      userName: userName,
      userId: userId,
      createdAt: createdAt,
    );
  }
}


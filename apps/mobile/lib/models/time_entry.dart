class TimeEntry {
  final String id;
  final DateTime spentOn;
  final double hours;
  final String? comment;
  final String? activityName;
  /// İş paketi ID (zaman kaydı listesinde hangi işe ait olduğunu göstermek için).
  final String? workPackageId;
  final String? workPackageSubject;
  /// Ekip görünümünde gösterilmek üzere kullanıcı adı (_links.user.title).
  final String? userName;

  const TimeEntry({
    required this.id,
    required this.spentOn,
    required this.hours,
    this.comment,
    this.activityName,
    this.workPackageId,
    this.workPackageSubject,
    this.userName,
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
    } catch (_) {
      spent = DateTime.now();
    }

    final links = json['_links'] as Map<String, dynamic>? ?? const {};
    final activity = links['activity'] as Map<String, dynamic>?;
    final userLink = links['user'] as Map<String, dynamic>?;
    final userName = userLink?['title']?.toString();
    final workPackageLink = links['workPackage'] ?? links['entity'];
    String? wpId;
    if (workPackageLink is Map) {
      final href = workPackageLink['href']?.toString() ?? '';
      final match = RegExp(r'/work_packages/(\d+)$').firstMatch(href);
      if (match != null) wpId = match.group(1);
    }
    final embedded = json['_embedded'] as Map<String, dynamic>?;
    final wpEmbedded = embedded?['workPackage'] as Map<String, dynamic>?;
    final wpSubject = wpEmbedded?['subject']?.toString();

    return TimeEntry(
      id: (json['id'] ?? '').toString(),
      spentOn: spent,
      hours: parsedHours,
      activityName: activity?['title']?.toString(),
      comment: (json['comment']?['raw'] ?? '').toString(),
      workPackageId: wpId,
      workPackageSubject: wpSubject,
      userName: userName,
    );
  }
}


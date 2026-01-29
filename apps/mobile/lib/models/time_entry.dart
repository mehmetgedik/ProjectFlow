class TimeEntry {
  final String id;
  final DateTime spentOn;
  final double hours;
  final String? comment;
  final String? activityName;

  const TimeEntry({
    required this.id,
    required this.spentOn,
    required this.hours,
    this.comment,
    this.activityName,
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

    return TimeEntry(
      id: (json['id'] ?? '').toString(),
      spentOn: spent,
      hours: parsedHours,
      activityName: activity?['title']?.toString(),
      comment: (json['comment']?['raw'] ?? '').toString(),
    );
  }
}


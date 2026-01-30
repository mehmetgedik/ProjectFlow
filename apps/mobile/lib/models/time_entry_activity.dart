/// Zaman kaydı kategorisi (OpenProject TimeEntriesActivity).
class TimeEntryActivity {
  final String id;
  final String name;
  final bool isDefault;

  const TimeEntryActivity({
    required this.id,
    required this.name,
    this.isDefault = false,
  });

  factory TimeEntryActivity.fromJson(Map json) {
    return TimeEntryActivity(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['_links']?['self']?['title'] ?? '').toString(),
      isDefault: json['default'] == true,
    );
  }
}

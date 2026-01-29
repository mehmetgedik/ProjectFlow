/// OpenProject Work Schedule: haftanın bir günü (1 = Pazartesi, 7 = Pazar).
class WeekDay {
  final int day;
  final String name;
  final bool working;

  const WeekDay({
    required this.day,
    required this.name,
    required this.working,
  });

  static WeekDay fromJson(Map<String, dynamic> json) {
    final day = json['day'];
    final name = json['name']?.toString() ?? '';
    final working = json['working'] == true;
    return WeekDay(
      day: day is int ? day : int.tryParse(day?.toString() ?? '') ?? 1,
      name: name,
      working: working,
    );
  }
}

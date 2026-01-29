/// OpenProject versiyon/sprint: iş paketleri bu versiyona atanabilir.
/// status: 'open' | 'closed' | 'finished' — aynı anda tek bir açık sprint aktif kabul edilir.
class Version {
  final int id;
  final String name;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;

  const Version({
    required this.id,
    required this.name,
    required this.status,
    this.startDate,
    this.endDate,
  });

  bool get isOpen => status.toLowerCase() == 'open';

  factory Version.fromJson(Map<String, dynamic> json) {
    final start = json['startDate']?.toString();
    final end = json['endDate']?.toString();
    return Version(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? '').toString(),
      status: (json['status'] ?? 'closed').toString().toLowerCase(),
      startDate: start != null && start.isNotEmpty ? DateTime.tryParse(start) : null,
      endDate: end != null && end.isNotEmpty ? DateTime.tryParse(end) : null,
    );
  }
}

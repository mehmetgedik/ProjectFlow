/// İş listesi ekranı için sabitler: kolonlar, filtre alanları, operatörler, sayfa boyutu.
abstract final class MyWorkPackagesConstants {
  MyWorkPackagesConstants._();

  /// Listede kullanılabilecek kolon id'leri (API QueryColumn id ile eşleşir).
  static const List<String> kColumnIds = [
    'id',
    'subject',
    'type',
    'status',
    'priority',
    'dueDate',
    'updated_at',
  ];

  static const Map<String, String> kColumnLabels = {
    'id': 'ID',
    'subject': 'Başlık',
    'type': 'Tür',
    'status': 'Durum',
    'priority': 'Öncelik',
    'dueDate': 'Bitiş tarihi',
    'updated_at': 'Güncellenme',
  };

  /// Filtre formu: OpenProject work_packages destekli alanlar (API filter name).
  static const List<String> kFilterFieldIds = [
    'status',
    'type',
    'assignee',
    'project',
    'priority',
    'dueDate',
    'author',
    'subjectOrId',
    'createdAt',
    'updatedAt',
    'responsible',
  ];

  static const Map<String, String> kFilterFieldLabels = {
    'status': 'Durum',
    'type': 'Tür',
    'assignee': 'Atanan',
    'project': 'Proje',
    'priority': 'Öncelik',
    'dueDate': 'Bitiş tarihi',
    'author': 'Yazar',
    'subjectOrId': 'Başlık/ID',
    'createdAt': 'Oluşturulma',
    'updatedAt': 'Güncellenme',
    'responsible': 'Sorumlu',
  };

  /// Filtre operatörleri (OpenProject API symbol -> kısa açıklama).
  static const List<(String, String)> kFilterOperatorList = [
    ('=', 'eşittir'),
    ('!', 'eşit değil'),
    ('*', 'dolu (değer var)'),
    ('!*', 'boş'),
    ('**', 'içerir (aranan)'),
    ('o', 'açık (durum)'),
    ('c', 'kapalı (durum)'),
    ('t', 'bugün'),
    ('w', 'bu hafta'),
    ('>=', 'büyük eşit'),
    ('<=', 'küçük eşit'),
    ('t+', 'gelecek X gün'),
    ('t-', 'geçmiş X gün'),
    ('=d', 'tarih eşit'),
    ('<>d', 'tarih aralığı'),
  ];

  /// Varsayılan görünümde bir sayfada yüklenecek kayıt sayısı (P0-F03).
  static const int kDefaultPageSize = 20;

  /// Operatör değer gerektiriyor mu? (boş values kabul edenler: *, !*, o, c, t, w)
  static bool operatorNeedsValues(String op) {
    return !['*', '!*', 'o', 'c', 't', 'w'].contains(op);
  }
}

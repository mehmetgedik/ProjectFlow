import 'package:flutter_test/flutter_test.dart';

import 'package:openproject_mobile/utils/date_formatters.dart';

void main() {
  group('DateFormatters', () {
    test('formatDate null returns -', () {
      expect(DateFormatters.formatDate(null), '-');
    });

    test('formatDate returns gg.aa.yyyy', () {
      expect(
        DateFormatters.formatDate(DateTime(2024, 1, 15)),
        '15.01.2024',
      );
      expect(
        DateFormatters.formatDate(DateTime(2024, 12, 3)),
        '03.12.2024',
      );
    });

    test('formatDateTime null returns -', () {
      expect(DateFormatters.formatDateTime(null), '-');
    });

    test('formatDateTime returns gg.aa.yyyy HH:mm', () {
      expect(
        DateFormatters.formatDateTime(DateTime(2024, 6, 10, 14, 30)),
        '10.06.2024 14:30',
      );
    });

    test('formatDateKey returns yyyy-MM-dd', () {
      expect(
        DateFormatters.formatDateKey(DateTime(2024, 3, 5)),
        '2024-03-05',
      );
    });
  });
}

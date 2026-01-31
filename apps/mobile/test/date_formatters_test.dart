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

    test('parseApiDateTime with Z returns UTC', () {
      final dt = DateFormatters.parseApiDateTime('2025-01-31T14:00:00Z');
      expect(dt, isNotNull);
      expect(dt!.isUtc, true);
      expect(dt.hour, 14);
    });

    test('parseApiDateTime without timezone treats as UTC', () {
      final dt = DateFormatters.parseApiDateTime('2025-01-31T14:00:00');
      expect(dt, isNotNull);
      expect(dt!.isUtc, true);
      expect(dt.hour, 14);
    });

    test('parseApiDateTime date-only (no T) parses as-is', () {
      final dt = DateFormatters.parseApiDateTime('2025-01-31');
      expect(dt, isNotNull);
      expect(dt!.year, 2025);
      expect(dt.month, 1);
      expect(dt.day, 31);
    });

    test('parseApiDateTime null or empty returns null', () {
      expect(DateFormatters.parseApiDateTime(null), isNull);
      expect(DateFormatters.parseApiDateTime(''), isNull);
    });
  });
}

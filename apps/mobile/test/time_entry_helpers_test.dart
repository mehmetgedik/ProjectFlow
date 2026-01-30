import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:openproject_mobile/utils/time_entry_helpers.dart';

void main() {
  group('addHoursToTimeOfDay', () {
    test('adds hours within same day', () {
      final t = TimeOfDay(hour: 10, minute: 0);
      final r = addHoursToTimeOfDay(t, 2);
      expect(r.hour, 12);
      expect(r.minute, 0);
    });

    test('wraps past midnight', () {
      final t = TimeOfDay(hour: 23, minute: 0);
      final r = addHoursToTimeOfDay(t, 2);
      expect(r.hour, 1);
      expect(r.minute, 0);
    });
  });

  group('timeOfDayDiffHours', () {
    test('same day end >= start', () {
      expect(
        timeOfDayDiffHours(TimeOfDay(hour: 9, minute: 0), TimeOfDay(hour: 12, minute: 30)),
        3.5,
      );
    });

    test('same time returns 0', () {
      expect(
        timeOfDayDiffHours(TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 10, minute: 0)),
        0.0,
      );
    });
  });

  group('formatTimeOfDay', () {
    test('formats HH:mm', () {
      expect(formatTimeOfDay(TimeOfDay(hour: 9, minute: 5)), '09:05');
      expect(formatTimeOfDay(TimeOfDay(hour: 14, minute: 30)), '14:30');
    });
  });
}

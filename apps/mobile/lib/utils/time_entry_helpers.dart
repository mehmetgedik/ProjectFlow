import 'package:flutter/material.dart';

/// Başlangıç + saat ekleyip yeni TimeOfDay döner (24h taşması normalize).
TimeOfDay addHoursToTimeOfDay(TimeOfDay t, double hours) {
  int totalMinutes = t.hour * 60 + t.minute + (hours * 60).round();
  totalMinutes = totalMinutes % (24 * 60);
  if (totalMinutes < 0) totalMinutes += 24 * 60;
  return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
}

/// İki saat arasındaki süre (saat cinsinden). end >= start varsayılır (aynı gün).
double timeOfDayDiffHours(TimeOfDay start, TimeOfDay end) {
  final startM = start.hour * 60 + start.minute;
  final endM = end.hour * 60 + end.minute;
  if (endM >= startM) return (endM - startM) / 60;
  return (24 * 60 - startM + endM) / 60;
}

String formatTimeOfDay(TimeOfDay t) {
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

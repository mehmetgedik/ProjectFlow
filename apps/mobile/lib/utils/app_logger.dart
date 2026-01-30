import 'package:flutter/foundation.dart';

import 'error_messages.dart';

/// Basit uygulama içi log sistemi.
///
/// Şimdilik:
/// - Hataları `debugPrint` ile konsola yazar
/// - Bellekte küçük bir geçmiş listesinde tutar (son 100 kayıt)
class AppLogEntry {
  final DateTime timestamp;
  final String level;
  final String message;
  final Object? error;

  AppLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
  });
}

class AppLogger {
  static final List<AppLogEntry> _entries = <AppLogEntry>[];
  static const int _maxEntries = 100;

  static List<AppLogEntry> get entries => List.unmodifiable(_entries);

  static void logError(String message, {Object? error}) {
    final entry = AppLogEntry(
      timestamp: DateTime.now(),
      level: 'ERROR',
      message: message,
      error: error,
    );
    _entries.add(entry);
    if (_entries.length > _maxEntries) {
      _entries.removeAt(0);
    }
    if (kDebugMode) {
      final safeError = error != null ? ErrorMessages.userFriendly(error) : '';
      debugPrint('[${entry.timestamp.toIso8601String()}] [${entry.level}] $message $safeError');
    }
  }
}


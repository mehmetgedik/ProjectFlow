import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'error_messages.dart';

/// Basit uygulama içi log sistemi.
///
/// - Hataları her zaman konsola yazar (debug ve release)
/// - Bellekte son 100 kayıt tutar
/// - İsteğe bağlı olarak uygulama belgeler dizinine dosyaya yazar (paylaşım için)
class AppLogEntry {
  final DateTime timestamp;
  final String level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  AppLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });
}

class AppLogger {
  static final List<AppLogEntry> _entries = <AppLogEntry>[];
  static const int _maxEntries = 100;

  /// Son hata kayıtları (paylaşım / kopyalama için).
  static List<AppLogEntry> get entries => List.unmodifiable(_entries);

  /// Tüm kayıtları metin olarak döner; hatayı paylaşmak için kullanılabilir.
  static String getLogsAsText() {
    final buffer = StringBuffer();
    for (final e in _entries) {
      buffer.writeln('[${e.timestamp.toIso8601String()}] [${e.level}] ${e.message}');
      if (e.error != null) buffer.writeln('  error: ${e.error}');
      if (e.stackTrace != null) buffer.writeln(e.stackTrace);
      buffer.writeln();
    }
    return buffer.toString();
  }

  static void logError(String message, {Object? error, StackTrace? stackTrace}) {
    final entry = AppLogEntry(
      timestamp: DateTime.now(),
      level: 'ERROR',
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
    _entries.add(entry);
    if (_entries.length > _maxEntries) {
      _entries.removeAt(0);
    }
    // Her zaman konsola yaz (debug ve release) — hatayı iletmek için
    final safeError = error != null ? ErrorMessages.userFriendly(error) : '';
    debugPrint('[${entry.timestamp.toIso8601String()}] [${entry.level}] $message $safeError');
    if (error != null) print('[ProjectFlow ERROR] $message — $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
      print(stackTrace.toString());
    }
    // Dosyaya yaz (asenkron, hata yakalama ile)
    _writeToFile(entry);
  }

  static Future<void> _writeToFile(AppLogEntry entry) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/projectflow_errors.log');
      final line = '[${entry.timestamp.toIso8601String()}] [${entry.level}] ${entry.message}'
          '${entry.error != null ? ' — ${entry.error}' : ''}\n'
          '${entry.stackTrace != null ? '${entry.stackTrace}\n' : ''}';
      await file.writeAsString(line, mode: FileMode.append);
    } catch (_) {
      // Dosya yazma hatası sessizce yutulur
    }
  }
}


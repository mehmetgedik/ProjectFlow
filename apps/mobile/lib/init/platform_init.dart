import 'dart:async';

import 'package:workmanager/workmanager.dart';

import '../services/local_notification_service.dart';
import '../services/notification_background_service.dart';

final Completer<void> _platformInitCompleter = Completer<void>();

/// Platform (Workmanager, notifications) hazır olana kadar beklenir.
/// AuthState.initialize() bu Future'ı bekleyerek registerBackgroundNotificationCheck
/// çağrısını platform hazır olduktan sonra yapar.
Future<void> get platformInitFuture => _platformInitCompleter.future;

/// Workmanager ve LocalNotificationService init. main.dart ilk frame sonrası çağırır.
Future<void> runPlatformInit() async {
  await Workmanager().initialize(callbackDispatcher);
  await LocalNotificationService().initialize();
}

/// Init bittikten sonra main.dart tarafından çağrılır (callback ve SystemChrome ayarları yapıldıktan sonra).
void completePlatformInit() {
  if (!_platformInitCompleter.isCompleted) {
    _platformInitCompleter.complete();
  }
}

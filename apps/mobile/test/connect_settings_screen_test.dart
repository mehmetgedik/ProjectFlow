import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:openproject_mobile/screens/connect_settings_screen.dart';
import 'package:openproject_mobile/state/auth_state.dart';

void main() {
  testWidgets('ConnectSettingsScreen shows form with title and Kaydet button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthState>(
          create: (_) => AuthState(),
          child: const ConnectSettingsScreen(),
        ),
      ),
    );

    expect(find.text('Bağlantı ayarları'), findsOneWidget);
    expect(find.text('Instance URL'), findsOneWidget);
    expect(find.text('API key'), findsOneWidget);
    expect(find.text('Kaydet'), findsOneWidget);
  });
}

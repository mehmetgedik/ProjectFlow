import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:openproject_mobile/screens/connect_screen.dart';
import 'package:openproject_mobile/state/auth_state.dart';

void main() {
  testWidgets('ConnectScreen shows form with Instance URL, API key and Bağlan button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthState>(
          create: (_) => AuthState(),
          child: const ConnectScreen(),
        ),
      ),
    );

    expect(find.text('Bağlan'), findsOneWidget);
    expect(find.text('Instance URL'), findsOneWidget);
    expect(find.text('API key'), findsOneWidget);
    expect(find.bySemanticsLabel('OpenProject hesabına bağlan'), findsAtLeast(1));
  });

  testWidgets('ConnectScreen shows Bağlantı ayarları in app bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthState>(
          create: (_) => AuthState(),
          child: const ConnectScreen(),
        ),
      ),
    );

    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
  });
}

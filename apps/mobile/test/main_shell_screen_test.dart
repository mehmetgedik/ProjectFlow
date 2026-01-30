import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:openproject_mobile/screens/main_shell_screen.dart';
import 'package:openproject_mobile/state/auth_state.dart';
import 'package:openproject_mobile/state/pro_state.dart';
import 'package:openproject_mobile/state/theme_state.dart';

void main() {
  testWidgets('MainShellScreen shows NavigationBar with 5 destinations', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthState>(create: (_) => AuthState()),
            ChangeNotifierProvider<ProState>(create: (_) => ProState()),
            ChangeNotifierProvider<ThemeState>(create: (_) => ThemeState()),
          ],
          child: const MainShellScreen(),
        ),
      ),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Dashboard'), findsAtLeast(1));
    expect(find.text('Benim işlerim'), findsAtLeast(1));
    expect(find.text('Bildirimler'), findsAtLeast(1));
    expect(find.text('Zaman'), findsAtLeast(1));
    expect(find.text('Profil'), findsAtLeast(1));
  });

  testWidgets('MainShellScreen has semantics for bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthState>(create: (_) => AuthState()),
            ChangeNotifierProvider<ProState>(create: (_) => ProState()),
            ChangeNotifierProvider<ThemeState>(create: (_) => ThemeState()),
          ],
          child: const MainShellScreen(),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Alt gezinme: Dashboard, Benim işlerim, Bildirimler, Zaman, Profil'),
      findsAtLeast(1),
    );
  });
}

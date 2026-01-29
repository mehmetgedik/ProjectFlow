// ProjectFlow (OpenProject Mobile) smoke test.
// Uygulama ayağa kalkar ve başlangıç ekranı (splash veya connect) render edilir.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:openproject_mobile/main.dart';
import 'package:openproject_mobile/state/auth_state.dart';
import 'package:openproject_mobile/state/theme_state.dart';

void main() {
  testWidgets('App pumps without error and shows initial screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthState()),
          ChangeNotifierProvider(create: (_) => ThemeState()),
        ],
        child: const ProjectFlowApp(),
      ),
    );

    // AuthState henüz initialize edilmediği için RootRouter SplashScreen gösterecek.
    // En azından MaterialApp içinde bir şey render edilmiş olmalı.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

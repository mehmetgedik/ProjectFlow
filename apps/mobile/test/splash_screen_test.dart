import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:openproject_mobile/constants/app_strings.dart';
import 'package:openproject_mobile/screens/splash_screen.dart';
import 'package:openproject_mobile/state/auth_state.dart';

void main() {
  testWidgets('SplashScreen shows ProjectFlow text and loading semantics', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthState>(
          create: (_) => AuthState(),
          child: const SplashScreen(),
        ),
      ),
    );

    expect(find.text('ProjectFlow'), findsOneWidget);
    expect(find.bySemanticsLabel(AppStrings.labelLoading), findsOneWidget);
  });
}

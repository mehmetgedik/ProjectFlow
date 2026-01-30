import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:openproject_mobile/screens/pro_upgrade_screen.dart';
import 'package:openproject_mobile/state/pro_state.dart';

void main() {
  testWidgets('ProUpgradeScreen shows Pro title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ProState>(
          create: (_) => ProState(),
          child: const ProUpgradeScreen(),
        ),
      ),
    );

    expect(find.text('Pro Hesap Yönetimi'), findsOneWidget);
  });
}

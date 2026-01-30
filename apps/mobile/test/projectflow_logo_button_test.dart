import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:openproject_mobile/widgets/projectflow_logo_button.dart';

void main() {
  testWidgets('ProjectFlowLogoButton shows and has semantics', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Test'),
            actions: const [ProjectFlowLogoButton()],
          ),
        ),
      ),
    );

    expect(find.byType(ProjectFlowLogoButton), findsOneWidget);
    expect(find.bySemanticsLabel('Ana ekrana dön'), findsOneWidget);
  });
}

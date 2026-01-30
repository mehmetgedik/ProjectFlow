import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:openproject_mobile/widgets/small_loading_indicator.dart';

void main() {
  testWidgets('SmallLoadingIndicator shows CircularProgressIndicator', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: SmallLoadingIndicator()),
        ),
      ),
    );

    expect(find.byType(SmallLoadingIndicator), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

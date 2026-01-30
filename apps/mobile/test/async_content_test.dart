import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:openproject_mobile/constants/app_strings.dart';
import 'package:openproject_mobile/widgets/async_content.dart';
import 'package:openproject_mobile/widgets/small_loading_indicator.dart';

void main() {
  testWidgets('AsyncContent shows loading indicator when loading', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AsyncContent(
          loading: true,
          child: SizedBox(),
        ),
      ),
    );

    expect(find.byType(SmallLoadingIndicator), findsOneWidget);
    expect(find.bySemanticsLabel(AppStrings.labelLoading), findsOneWidget);
  });

  testWidgets('AsyncContent shows error and retry button when error and onRetry set', (WidgetTester tester) async {
    var retryCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AsyncContent(
          loading: false,
          error: 'Test hata mesajı',
          onRetry: () => retryCount++,
          child: const SizedBox(),
        ),
      ),
    );

    expect(find.text('Test hata mesajı'), findsOneWidget);
    expect(find.text(AppStrings.labelRetry), findsOneWidget);
    expect(find.bySemanticsLabel(AppStrings.labelRetry), findsOneWidget);

    await tester.tap(find.text(AppStrings.labelRetry));
    await tester.pump();
    expect(retryCount, 1);
  });

  testWidgets('AsyncContent shows empty widget when showEmpty and empty set', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AsyncContent(
          loading: false,
          showEmpty: true,
          empty: Text('Liste boş'),
          child: SizedBox(),
        ),
      ),
    );

    expect(find.text('Liste boş'), findsOneWidget);
  });

  testWidgets('AsyncContent shows child when not loading, no error, not empty', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AsyncContent(
          loading: false,
          child: Text('İçerik'),
        ),
      ),
    );

    expect(find.text('İçerik'), findsOneWidget);
  });
}

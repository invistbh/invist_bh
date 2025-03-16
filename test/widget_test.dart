import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invist_bh/main.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: InvistBhApp(),
      ),
    );

    // Verify that the app title is displayed
    expect(find.text('INVIST.BH'), findsOneWidget);
  });
}

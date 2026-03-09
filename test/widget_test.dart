import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenit/main.dart';

void main() {
  testWidgets('App loads dashboard shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PersonalOrganizerApp()));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

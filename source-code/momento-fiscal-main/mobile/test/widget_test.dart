import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momentofiscal/pages/login/auth_page.dart';

void main() {
  testWidgets('DashboardPage renderiza corretamente',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthPage()));
    expect(find.byType(Scaffold), findsOneWidget);
  });
}

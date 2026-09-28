import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_pbp/main.dart';

void main() {
  testWidgets('App smoke test - verifies app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
  });
}

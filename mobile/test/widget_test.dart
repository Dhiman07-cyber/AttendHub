import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendhub/app/app.dart';

void main() {
  testWidgets('AttendHubApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AttendHubApp()));
    expect(find.byType(AttendHubApp), findsOneWidget);
  });
}

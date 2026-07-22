import 'package:flutter_test/flutter_test.dart';
import 'package:wellqueueuser/main.dart';

void main() {
  testWidgets('WellQueueApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WellQueueApp());
    expect(find.text('Welcome to WellQueue'), findsOneWidget);
  });
}

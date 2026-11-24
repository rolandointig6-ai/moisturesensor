import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_firebase/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PlantMonitorApp());
    expect(find.text('Soil Moisture Monitor'), findsOneWidget);
  });
}
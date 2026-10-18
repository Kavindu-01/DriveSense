import 'package:flutter_test/flutter_test.dart';
import 'package:drivesense_app/main.dart';

void main() {
  testWidgets('DriveSense App smoke test and authentication flow',
      (WidgetTester tester) async {
    // 1. Launch App
    await tester.pumpWidget(const DriveSenseApp());

    // 2. Verify Login Screen renders
    expect(find.text('DriveSense'), findsOneWidget);
    expect(find.text('ACCESS DRIVER PORTAL'), findsOneWidget);

    // 3. Tap Login
    await tester.tap(find.text('ACCESS DRIVER PORTAL'));
    await tester.pumpAndSettle();

    // 4. Verify Home Navigation Bottom Bar renders all 5 modules
    expect(find.text('Live HUD'), findsOneWidget);
    expect(find.text('Drowsiness'), findsOneWidget);
    expect(find.text('Hotspots'), findsOneWidget);
    expect(find.text('Eco-Drive'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}

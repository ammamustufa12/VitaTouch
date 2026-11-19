import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_health_monitor/main.dart';
import 'package:smart_health_monitor/screens/home/scan_station.dart';
import 'package:smart_health_monitor/screens/scanning/scanning_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('splash opens the home dashboard', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(await buildSmartHealthApp(preferences: preferences));

    expect(find.text('Smart Health Monitor'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Touch to load'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pump();

    expect(find.text('Not provided'), findsWidgets);
    expect(find.text('Person name'), findsOneWidget);
  });

  testWidgets('holding the scanner stores a demo reading', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      await buildSmartHealthApp(
        preferences: preferences,
        home: const ScanningScreen(scanDuration: Duration(milliseconds: 200)),
      ),
    );

    expect(
      find.text('Place your finger on the screen.'),
      findsOneWidget,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(ScanningScreen.touchKey)),
    );
    await tester.pump(const Duration(milliseconds: 280));
    await tester.pump();

    expect(find.text('Demo scan complete.'), findsOneWidget);
    expect(find.textContaining('DEMO DATA'), findsWidgets);

    await gesture.up();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('two fingers reveal the next demo detail', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      await buildSmartHealthApp(
        preferences: preferences,
        home: const ScanningScreen(scanDuration: Duration(milliseconds: 200)),
      ),
    );

    final point = tester.getCenter(find.byKey(ScanningScreen.touchKey));
    final first = await tester.startGesture(point);
    final second = await tester.startGesture(point.translate(24, 12));
    await tester.pump();

    expect(find.text('2 fingers detected'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 280));
    await tester.pump();

    expect(find.textContaining('Heart rate'), findsOneWidget);
    expect(find.textContaining('SpO2'), findsOneWidget);
    expect(find.textContaining('Pulse'), findsNothing);

    await first.up();
    await second.up();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('wide scan shows numbers before details', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      await buildSmartHealthApp(
        preferences: preferences,
        home: const ScanStation(scanDuration: Duration(milliseconds: 200)),
      ),
    );

    expect(find.text('Ready to scan'), findsOneWidget);

    await tester.tap(find.byKey(ScanStation.touchKey));
    await tester.pump(const Duration(milliseconds: 280));
    await tester.pump();

    expect(find.text('Heart rate'), findsOneWidget);
    expect(find.text('Pulse'), findsNothing);

    await tester.pump(const Duration(milliseconds: 700));

    expect(find.textContaining('Pulse'), findsOneWidget);
    expect(find.text('DEMO DATA'), findsOneWidget);
  });
}

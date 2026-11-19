import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_health_monitor/main.dart';
import 'package:smart_health_monitor/screens/touch/touch_point_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('one to five fingers change color and the circle follows', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      await buildSmartHealthApp(
        preferences: preferences,
        home: const TouchPointScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Touch. Check. Care.'), findsOneWidget);
    expect(find.text('Place 1 to 5 fingers'), findsNothing);
    expect(find.text('LOADING'), findsNothing);
    expect(find.text('Heart Rate'), findsNothing);

    expect(find.byKey(TouchPointScreen.circleKey), findsNothing);

    const touch = Offset(220, 520);
    final fingers = <TestGesture>[];
    const tones = [
      Color(0xFF3DDC84),
      Color(0xFF3D8BFF),
      Color(0xFFFFD84A),
      Color(0xFFB06CFF),
      Color(0xFFFF4D5A),
    ];
    for (var count = 1; count <= 5; count++) {
      fingers.add(await tester.startGesture(touch.translate(count * 28, count * 12)));
      await tester.pump();
      expect(find.byKey(TouchPointScreen.circleKey), findsOneWidget);
      expect(find.text('LOADING'), findsNothing);
      expect(find.text('$count finger${count == 1 ? '' : 's'}'), findsNothing);
      expect(find.text('Green'), findsNothing);
      expect(find.text('Blue'), findsNothing);
      expect(_cardIcon(tester), tones[count - 1]);
    }

    final circleAtTouch = tester.getCenter(find.byKey(TouchPointScreen.circleKey));
    expect((circleAtTouch - const Offset(248, 532)).distance, lessThan(20));

    final beforeCircle = circleAtTouch;
    final beforeCard = tester.getCenter(find.text('Heart Rate'));
    await fingers.first.moveBy(const Offset(80, -30));
    await tester.pump();
    final circleMoved = tester.getCenter(find.byKey(TouchPointScreen.circleKey)) - beforeCircle;
    final cardMoved = tester.getCenter(find.text('Heart Rate')) - beforeCard;
    expect(circleMoved.dx, greaterThan(20));
    expect(circleMoved.dy, lessThan(-8));
    expect((cardMoved - circleMoved).distance, lessThan(2));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(_opacity(tester, find.text('Heart Rate')), 1);
    final circle = tester.getCenter(find.byKey(TouchPointScreen.circleKey));
    final heart = tester.getCenter(find.text('Heart Rate'));
    final oxygen = tester.getCenter(find.text('Blood Oxygen'));
    final temp = tester.getCenter(find.text('Body Temperature'));
    final sugar = tester.getCenter(find.text('Blood Sugar'));
    expect(heart.dx, lessThan(circle.dx));
    expect(heart.dy, lessThan(circle.dy));
    expect(oxygen.dx, greaterThan(circle.dx));
    expect(oxygen.dy, lessThan(circle.dy));
    expect(temp.dx, lessThan(circle.dx));
    expect(temp.dy, greaterThan(circle.dy));
    expect(sugar.dx, greaterThan(circle.dx));
    expect(sugar.dy, greaterThan(circle.dy));

    for (final finger in fingers.reversed) {
      await finger.up();
      await tester.pump();
    }

    expect(find.text('Touch. Check. Care.'), findsOneWidget);
    expect(find.byKey(TouchPointScreen.circleKey), findsNothing);
    expect(find.text('Heart Rate'), findsNothing);
  });
}

double _opacity(WidgetTester tester, Finder target) {
  final finder = find.ancestor(of: target, matching: find.byType(Opacity)).first;
  return tester.widget<Opacity>(finder).opacity;
}

Color? _cardIcon(WidgetTester tester) {
  final card = find
      .ancestor(of: find.text('Heart Rate'), matching: find.byType(AnimatedContainer))
      .first;
  final icon = find.descendant(of: card, matching: find.byIcon(Icons.favorite));
  return tester.widget<Icon>(icon).color;
}

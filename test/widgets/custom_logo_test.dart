import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_pbp/widgets/mwl_logo.dart';

void main() {
  group('MwlLogo Widget & CustomPainter Tests', () {
    testWidgets('MwlLogo merender dengan ukuran dan warna kustom', (tester) async {
      const double customSize = 60.0;
      const Color customColor = Colors.white;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MwlLogo(size: customSize, customColor: customColor),
            ),
          ),
        ),
      );

      final logoFinder = find.byType(MwlLogo);
      expect(logoFinder, findsOneWidget);

      final MwlLogo logoWidget = tester.widget(logoFinder);
      expect(logoWidget.size, customSize);
      expect(logoWidget.customColor, customColor);
      expect(logoWidget.animationProgress, 1.0);

      expect(
        find.descendant(
          of: logoFinder,
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.width == customSize && w.height == customSize,
          ),
        ),
        findsOneWidget,
      );

      final CustomPaint customPaint = tester.widget(
        find.descendant(of: logoFinder, matching: find.byType(CustomPaint)),
      );
      expect(customPaint.painter, isA<MwlLogoPainter>());
      final painter = customPaint.painter as MwlLogoPainter;
      expect(painter.elementColor, customColor);
    });

    testWidgets('Dark Mode memakai lingkaran biru + glow, elemen putih', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(body: Center(child: MwlLogo())),
        ),
      );

      final CustomPaint cp = tester.widget(
        find.descendant(of: find.byType(MwlLogo), matching: find.byType(CustomPaint)),
      );
      final painter = cp.painter as MwlLogoPainter;
      expect(painter.elementColor, Colors.white);
      expect(painter.glowColor, isNotNull);
      expect(painter.backgroundEnd, const Color(0xFF0072DB));
    });

    testWidgets('Light Mode memakai lingkaran putih, elemen hitam #0D0D0D', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(body: Center(child: MwlLogo())),
        ),
      );

      final CustomPaint cp = tester.widget(
        find.descendant(of: find.byType(MwlLogo), matching: find.byType(CustomPaint)),
      );
      final painter = cp.painter as MwlLogoPainter;
      expect(painter.elementColor, MwlLogo.ink);
      expect(painter.backgroundStart, Colors.white);
      expect(painter.glowColor, isNull);
    });

    test('Geometri: 4 busur sabit & 3 huruf monogram valid', () {
      expect(MwlLogoPainter.arcPaths.length, 4);
      expect(MwlLogoPainter.monogramPaths.length, 3);
      for (final path in [...MwlLogoPainter.arcPaths, ...MwlLogoPainter.monogramPaths]) {
        expect(path.computeMetrics().isNotEmpty, isTrue);
      }
      // Busur atas berada di atas garis tengah, busur bawah di bawahnya.
      expect(MwlLogoPainter.arcPaths[0].getBounds().bottom, lessThanOrEqualTo(50));
      expect(MwlLogoPainter.arcPaths[2].getBounds().top, greaterThanOrEqualTo(50));
    });

    test('MwlLogoPainter shouldRepaint bekerja dengan benar', () {
      final p1 = MwlLogoPainter.themed(isDark: true, progress: 0.5);
      final p2 = MwlLogoPainter.themed(isDark: true, progress: 0.5);
      final p3 = MwlLogoPainter.themed(isDark: true, progress: 0.8);
      final p4 = MwlLogoPainter.themed(isDark: false, progress: 0.5);

      expect(p1.shouldRepaint(p2), isFalse);
      expect(p1.shouldRepaint(p3), isTrue);
      expect(p1.shouldRepaint(p4), isTrue);
    });

    testWidgets('MwlLogo dapat dirender pada setiap tahap animasi tanpa error', (tester) async {
      for (final progress in [0.0, 0.1, 0.35, 0.6, 0.8, 1.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(child: MwlLogo(animationProgress: progress)),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_pbp/screens/splash_screen.dart';
import 'package:tugas_pbp/widgets/mwl_logo.dart';

void main() {
  group('Minimalist Line Draw SplashScreen Tests', () {
    testWidgets('SplashScreen default parameter mengarah ke LoginPage secara internal', (tester) async {
      const splash = SplashScreen();
      expect(splash.nextScreen, isNull);
    });

    testWidgets('SplashScreen menampilkan background biru penuh menyatu dengan logo dan logo MwlLogo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      // Verifikasi scaffold dan warna latar belakang biru penuh
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);
      final Scaffold scaffold = tester.widget(scaffoldFinder);
      expect(scaffold.backgroundColor, SplashScreen.splashBlue);

      // Verifikasi logo MWL dengan MwlLogoPainter terpasang
      expect(find.byType(MwlLogo), findsOneWidget);
      final customPaints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
      expect(customPaints.any((cp) => cp.painter is MwlLogoPainter), isTrue);

      // Verifikasi teks 'MyWatchList' ada di widget tree
      expect(find.text('MyWatchList'), findsOneWidget);
    });

    testWidgets('Progres logo mengikuti fase animasi (busur -> MWL -> slide teks)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(nextScreen: Scaffold(body: Text('Next'))),
        ),
      );

      MwlLogo logo() => tester.widget(find.byType(MwlLogo));

      // Awal: logo kosong
      expect(logo().animationProgress, 0.0);

      // Fase 1 (~0.2 = 600ms): busur sedang digambar
      await tester.pump(const Duration(milliseconds: 600));
      expect(logo().animationProgress, closeTo(0.333, 0.01));

      // Akhir Fase 2 (0.6 = 1800ms): logo utuh
      await tester.pump(const Duration(milliseconds: 1200));
      expect(logo().animationProgress, closeTo(1.0, 0.001));

      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();
    });

    testWidgets('SplashScreen menampilkan teks MyWatchList warna putih tegas dan letterSpacing geometris', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const SplashScreen(nextScreen: Scaffold(body: Text('Next'))),
        ),
      );
      Text text = tester.widget(find.text('MyWatchList'));
      expect(text.style?.color, Colors.white);
      expect(text.style?.fontWeight, FontWeight.w900);
      expect(text.style?.letterSpacing, 2.0);

      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('light'),
          theme: ThemeData.light(),
          home: const SplashScreen(nextScreen: Scaffold(body: Text('Next'))),
        ),
      );
      text = tester.widget(find.text('MyWatchList'));
      expect(text.style?.color, Colors.white);
      expect(text.style?.fontWeight, FontWeight.w900);
      expect(text.style?.letterSpacing, 2.0);

      await tester.pump(const Duration(milliseconds: 3100));
      await tester.pumpAndSettle();
    });

    testWidgets('SplashScreen otomatis berpindah ke halaman tujuan setelah 3 detik (animasi + stabil) selesai', (tester) async {
      const mockLogin = Scaffold(body: Text('Halaman Login Mock'));

      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(nextScreen: mockLogin),
        ),
      );

      // Di awal (0.0s) masih di SplashScreen
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Halaman Login Mock'), findsNothing);

      // Pada 1.5s (sedang reveal) masih di SplashScreen
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Halaman Login Mock'), findsNothing);

      // Pada 2.5s (fase D: logo stabil 1.8s - 3.0s) masih di SplashScreen
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Halaman Login Mock'), findsNothing);

      // Majukan hingga melewati 3000ms
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Verifikasi telah berpindah ke halaman login mock
      expect(find.text('Halaman Login Mock'), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    });

    testWidgets('Mengetuk layar saat splash screen mempercepat transisi ke halaman tujuan', (tester) async {
      const mockLogin = Scaffold(body: Text('Halaman Login Mock'));

      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(nextScreen: mockLogin),
        ),
      );

      expect(find.text('Halaman Login Mock'), findsNothing);

      // Ketuk layar untuk skip
      await tester.tap(find.byKey(const Key('splash_gesture')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 550));

      // Verifikasi langsung berpindah ke halaman tujuan
      expect(find.text('Halaman Login Mock'), findsOneWidget);
    });

    testWidgets('Reduced motion (disableAnimations) langsung menavigasi ke halaman tujuan', (tester) async {
      const mockLogin = Scaffold(body: Text('Halaman Login Mock'));

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return const MediaQuery(
                data: MediaQueryData(disableAnimations: true),
                child: SplashScreen(nextScreen: mockLogin),
              );
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 550));

      // Verifikasi langsung berpindah tanpa menunggu animasi penuh
      expect(find.text('Halaman Login Mock'), findsOneWidget);
    });
  });
}

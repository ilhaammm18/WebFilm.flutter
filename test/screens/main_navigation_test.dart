import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_pbp/screens/main_navigation.dart';

void main() {
  const dummyPages = [
    Center(child: Text('Halaman Jelajahi Dummy')),
    Center(child: Text('Halaman Daftar Dummy')),
    Center(child: Text('Halaman Peringkat Dummy')),
    Center(child: Text('Halaman Profil Dummy')),
  ];

  setUp(() {
    globalNavIndex.value = 0;
  });

  group('MainNavigation BottomNavigationBar Styling Tests', () {
    testWidgets('Light Mode: unselectedItemColor, selectedItemColor, backgroundColor, dan elevation sesuai spesifikasi', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          ),
          themeMode: ThemeMode.light,
          home: const MainNavigation(pages: dummyPages),
        ),
      );

      final bottomNavBarFinder = find.byType(BottomNavigationBar);
      expect(bottomNavBarFinder, findsOneWidget);

      final BottomNavigationBar bottomNavBar = tester.widget(bottomNavBarFinder);

      // 1. Kontras unselectedItemColor lebih gelap pada mode terang (grey.shade600)
      expect(bottomNavBar.unselectedItemColor, Colors.grey.shade600);

      // 2. Selected item color tetap biru (#0094FF)
      expect(bottomNavBar.selectedItemColor, const Color(0xFF0094FF));

      // 3. Background color solid putih pada Light Mode
      expect(bottomNavBar.backgroundColor, Colors.white);

      // 4. Elevation 8 untuk mempertegas batas navigasi
      expect(bottomNavBar.elevation, 8);

      // 5. Container pembungkus memiliki border atas tipis dan warna pembatas abu-abu terang
      final containerFinder = find.ancestor(
        of: bottomNavBarFinder,
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);

      final Container container = tester.widget(containerFinder.first);
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      expect(decoration.border?.top.color, Colors.grey.shade300);
      expect(decoration.border?.top.width, 1.0);

      // Verifikasi tab items
      expect(find.text('Jelajahi'), findsOneWidget);
      expect(find.text('Daftar'), findsOneWidget);
      expect(find.text('Peringkat'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);

      // Coba pindah ke tab Profil
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      expect(find.text('Halaman Profil Dummy'), findsOneWidget);
    });

    testWidgets('Dark Mode: unselectedItemColor, selectedItemColor, backgroundColor, dan border atas adaptif', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF15171E),
          ),
          themeMode: ThemeMode.dark,
          home: const MainNavigation(pages: dummyPages),
        ),
      );

      final bottomNavBarFinder = find.byType(BottomNavigationBar);
      expect(bottomNavBarFinder, findsOneWidget);

      final BottomNavigationBar bottomNavBar = tester.widget(bottomNavBarFinder);

      // 1. UnselectedItemColor pada dark mode (grey.shade400)
      expect(bottomNavBar.unselectedItemColor, Colors.grey.shade400);

      // 2. Selected item color tetap biru (#0094FF)
      expect(bottomNavBar.selectedItemColor, const Color(0xFF0094FF));

      // 3. Background color solid gelap menyesuaikan tema
      expect(bottomNavBar.backgroundColor, const Color(0xFF15171E));

      // 4. Elevation 8
      expect(bottomNavBar.elevation, 8);

      // 5. Container pembungkus memiliki border atas gelap
      final containerFinder = find.ancestor(
        of: bottomNavBarFinder,
        matching: find.byType(Container),
      );
      final Container container = tester.widget(containerFinder.first);
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      expect(decoration.border?.top.color, const Color(0xFF2A2E39));
      expect(decoration.border?.top.width, 1.0);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_pbp/widgets/app_drawer.dart';
import 'package:tugas_pbp/main.dart';
import 'package:tugas_pbp/screens/main_navigation.dart';

void main() {
  testWidgets('AppDrawer menampilkan seluruh menu dengan urutan dan ikon yang benar', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: const AppDrawer(),
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              child: const Text('Buka Drawer'),
            ),
          ),
        ),
      ),
    );

    // Buka drawer
    await tester.tap(find.text('Buka Drawer'));
    await tester.pumpAndSettle();

    // Header Profil
    expect(find.text('Muhammad Nur Ilham'), findsOneWidget);
    expect(find.text('NIM : 25051204433'), findsOneWidget);

    // 1. Edit Profil
    expect(find.text('Edit Profil'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

    // 2. Mode Gelap dengan switch
    expect(find.text('Mode Gelap'), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);

    // 3. Jadwal Tayang
    expect(find.text('Jadwal Tayang'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);

    // 4. Favorit
    expect(find.text('Favorit'), findsOneWidget);
    expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);

    // 5. Teman
    expect(find.text('Teman'), findsOneWidget);
    expect(find.byIcon(Icons.people_alt_outlined), findsOneWidget);

    // Divider pemisah utama dengan color Colors.white24
    final dividers = tester.widgetList<Divider>(find.byType(Divider)).toList();
    expect(dividers.any((d) => d.color == Colors.white24), isTrue);

    // 5. Pengaturan
    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    // 6. Customer Service
    expect(find.text('Customer Service'), findsOneWidget);
    expect(find.byIcon(Icons.support_agent), findsOneWidget);

    // 7. Tentang
    expect(find.text('Tentang'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);

    // Keluar
    expect(find.text('Keluar'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);

    // Memastikan tombol Keluar memiliki warna merah
    final keluarText = tester.widget<Text>(find.text('Keluar'));
    expect(keluarText.style?.color, Colors.redAccent);

    // Memastikan terdapat Expanded untuk mendorong tombol Keluar ke bawah
    expect(find.byType(Expanded), findsOneWidget);
  });

  testWidgets('Mengetuk Jadwal Tayang memunculkan SnackBar pemberitahuan', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: const AppDrawer(),
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              child: const Text('Buka Drawer'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka Drawer'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jadwal Tayang'));
    await tester.pump();
    expect(find.text('Halaman Jadwal Tayang sedang dikembangkan'), findsOneWidget);
  });

  testWidgets('Mengetuk Favorit memunculkan SnackBar pemberitahuan', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: const AppDrawer(),
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              child: const Text('Buka Drawer'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka Drawer'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Favorit'));
    await tester.pump();
    expect(find.text('Halaman Favorit sedang dikembangkan'), findsOneWidget);
  });

  testWidgets('Mengetuk Tentang memunculkan SnackBar pemberitahuan', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: const AppDrawer(),
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              child: const Text('Buka Drawer'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka Drawer'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tentang'));
    await tester.pump();
    expect(find.text('Halaman Tentang sedang dikembangkan'), findsOneWidget);
  });

  testWidgets('Mengetuk Pengaturan membuka halaman Pengaturan', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: const AppDrawer(),
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              child: const Text('Buka Drawer'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka Drawer'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pengaturan'));
    await tester.pumpAndSettle();
    expect(find.text('Notifikasi Pembaruan'), findsOneWidget);
  });

  testWidgets('Mengetuk Edit Profil dari Drawer membuka halaman Edit Profil', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: const AppDrawer(),
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              child: const Text('Buka Drawer'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka Drawer'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Simpan Perubahan'), findsOneWidget);

    // Kembali dari Edit Profil (menekan tombol back AppBar)
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Drawer masih dalam keadaan terbuka
    expect(find.text('Muhammad Nur Ilham'), findsOneWidget);
    expect(find.text('Edit Profil'), findsOneWidget);
  });

  testWidgets('Mengetuk Customer Service dari Drawer membuka halaman Customer Service', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: const AppDrawer(),
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              child: const Text('Buka Drawer'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka Drawer'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Customer Service'));
    await tester.pumpAndSettle();

    expect(find.text('Pusat Bantuan & Layanan Pengguna'), findsOneWidget);
    expect(find.text('Masukan Via WA'), findsOneWidget);
  });

  testWidgets('Mengetuk Header Profil mengupdate globalNavIndex ke Tab Profil', (tester) async {
    globalNavIndex.value = 0;
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: const AppDrawer(),
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              child: const Text('Buka Drawer'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka Drawer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Muhammad Nur Ilham'));
    await tester.pumpAndSettle();

    expect(globalNavIndex.value, 3);
  });

  testWidgets('Switch Mode Gelap mengubah MyApp.themeNotifier', (tester) async {
    MyApp.themeNotifier.value = ThemeMode.dark;
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData.dark(),
        home: Scaffold(
          drawer: const AppDrawer(),
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              child: const Text('Buka Drawer'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka Drawer'));
    await tester.pumpAndSettle();

    // Toggle switch
    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(MyApp.themeNotifier.value, ThemeMode.light);
  });

  testWidgets('Mengetuk Teman dari Drawer membuka FriendsPage dengan 3 tab', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: const AppDrawer(),
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              child: const Text('Buka Drawer'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka Drawer'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Teman'));
    await tester.pumpAndSettle();

    // Memastikan TabBar dan 3 tab muncul
    expect(find.text('Teman'), findsWidgets);
    expect(find.text('Mengikuti'), findsOneWidget);
    expect(find.text('Cari'), findsOneWidget);
    expect(find.text('Belum ada teman saat ini.'), findsOneWidget);

    // Kembali menekan back, drawer masih terbuka
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Muhammad Nur Ilham'), findsOneWidget);
    expect(find.text('Teman'), findsOneWidget);
  });
}

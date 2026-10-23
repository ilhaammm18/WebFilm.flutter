import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_pbp/data/shared_data.dart';
import 'package:tugas_pbp/screens/edit_profile_page.dart';
import 'package:tugas_pbp/widgets/app_drawer.dart';
import 'package:tugas_pbp/main.dart';

void main() {
  setUp(() {
    SharedData.userProfileNotifier.value = const UserProfileData(
      fullName: 'Muhammad Nur Ilham',
      username: '25051204433',
    );
  });

  testWidgets('AppDrawer menampilkan seluruh menu dengan urutan dan ikon yang benar (tanpa menu Favorit, Edit Profil, dan Keluar)', (tester) async {
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
    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    // Edit Profil telah dihapus dari Drawer (dipindah ke Pengaturan)
    expect(find.text('Edit Profil'), findsNothing);

    // 1. Mode Gelap dengan switch
    expect(find.text('Mode Gelap'), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);

    // 2. Jadwal Tayang
    expect(find.text('Jadwal Tayang'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);

    // Menu Favorit telah dihapus
    expect(find.text('Favorit'), findsNothing);

    // 3. Teman
    expect(find.text('Teman'), findsOneWidget);
    expect(find.byIcon(Icons.people_alt_outlined), findsOneWidget);

    // Divider pemisah utama dengan color Colors.white24
    final dividers = tester.widgetList<Divider>(find.byType(Divider)).toList();
    expect(dividers.any((d) => d.color == Colors.white24), isTrue);

    // 4. Pengaturan
    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    // 5. Customer Service
    expect(find.text('Customer Service'), findsOneWidget);
    expect(find.byIcon(Icons.support_agent), findsOneWidget);

    // 6. Tentang
    expect(find.text('Tentang'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);

    // Keluar telah dihapus dari Drawer
    expect(find.text('Keluar'), findsNothing);
    expect(find.byIcon(Icons.logout), findsNothing);

    // Memastikan terdapat Expanded
    expect(find.byType(Expanded), findsOneWidget);
  });

  testWidgets('Mengetuk Jadwal Tayang dari Drawer membuka ReleaseSchedulePage dengan 2 tab', (tester) async {
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
    await tester.pumpAndSettle();

    expect(find.text('Sedang Tayang'), findsOneWidget);
    expect(find.text('Segera Hadir'), findsOneWidget);
  });

  testWidgets('Mengetuk Tentang dari Drawer membuka AboutAppPage dengan identitas developer', (tester) async {
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
    await tester.pumpAndSettle();

    expect(find.text('MyWatchList'), findsOneWidget);
    expect(find.text('Versi 1.0.0'), findsOneWidget);
    expect(find.text('Muhammad Nur Ilham'), findsWidgets);
    expect(find.text('NIM : 25051204433'), findsOneWidget);
    expect(find.text('The Movie Database (TMDB) API'), findsNothing);
    expect(find.text('Supabase Backend'), findsNothing);
  });

  testWidgets('Mengetuk Pengaturan membuka halaman Pengaturan dengan Ubah Kata Sandi & Hapus Riwayat', (tester) async {
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

    expect(find.text('Edit Profil'), findsOneWidget);
    expect(find.text('Notifikasi Pembaruan'), findsOneWidget);
    expect(find.text('Ubah Kata Sandi'), findsOneWidget);
    expect(find.text('Hapus Riwayat Pencarian'), findsNothing);
    expect(find.widgetWithText(ElevatedButton, 'Keluar'), findsOneWidget);
  });

  testWidgets('Mengetuk Edit Profil dari Pengaturan membuka halaman Edit Profil', (tester) async {
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

    expect(find.text('Edit Profil'), findsOneWidget);
    await tester.tap(find.text('Edit Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Simpan Perubahan'), findsOneWidget);

    // Kembali dari Edit Profil (menekan tombol back AppBar)
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Kembali berada di halaman Pengaturan
    expect(find.text('Pengaturan'), findsOneWidget);
  });

  testWidgets('Mengetuk Customer Service dari Drawer membuka CustomerServicePage dengan FAQ & Form Masukan', (tester) async {
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
    expect(find.text('Pertanyaan Umum (FAQ)'), findsOneWidget);
    expect(find.text('Kirim Masukan & Lapor Bug'), findsOneWidget);
  });

  testWidgets('Mengetuk Header Profil membuka halaman Edit Profil', (tester) async {
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

    expect(find.byType(EditProfilePage), findsOneWidget);
    expect(find.text('Edit Profil'), findsOneWidget);
    expect(find.text('Nama Lengkap'), findsOneWidget);
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

  testWidgets('Mengetuk Teman dari Drawer membuka FriendsPage dengan 2 tab dan search bar', (tester) async {
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

    // Memastikan TabBar dan 2 tab (Mengikuti & Pengikut) muncul
    expect(find.text('Mengikuti'), findsOneWidget);
    expect(find.text('Pengikut'), findsOneWidget);
    expect(find.text('Belum Mengikuti Siapa Pun'), findsOneWidget);

    // Kembali menekan back, drawer masih terbuka
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Muhammad Nur Ilham'), findsOneWidget);
    expect(find.text('Teman'), findsOneWidget);
  });
}

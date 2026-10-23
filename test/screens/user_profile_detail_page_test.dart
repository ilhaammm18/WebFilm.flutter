import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_pbp/screens/user_profile_detail_page.dart';

void main() {
  testWidgets('UserProfileDetailPage menampilkan profil teman, follow stats, waktu tonton, dan watchlist', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const testProfile = {
      'id': 'user-123',
      'username': 'moviefreak',
      'full_name': 'Rian Pratama',
      'bio': 'Pecinta film sci-fi dan thriller psikologis.',
      'avatar_url': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
    };

    await tester.pumpWidget(
      const MaterialApp(
        home: UserProfileDetailPage(
          userId: 'user-123',
          initialProfile: testProfile,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi Header Profil
    expect(find.text('@moviefreak'), findsWidgets);
    expect(find.text('Rian Pratama'), findsOneWidget);
    expect(find.text('Pecinta film sci-fi dan thriller psikologis.'), findsOneWidget);

    // Verifikasi Tombol Ikuti
    expect(find.text('Ikuti'), findsOneWidget);

    // Verifikasi Statistik Follow
    expect(find.text('Pengikut'), findsOneWidget);
    expect(find.text('Mengikuti'), findsOneWidget);
    expect(find.text('Tontonan'), findsOneWidget);

    // Verifikasi 4 Kartu Statistik Waktu Tonton
    expect(find.text('Statistik Waktu Tonton'), findsOneWidget);
    expect(find.text('Total Waktu Tonton'), findsOneWidget);
    expect(find.text('Total Tontonan'), findsOneWidget);
    expect(find.text('Total Episode'), findsOneWidget);
    expect(find.text('Rasio Film & Drama'), findsOneWidget);

    // Verifikasi Bagian Watchlist
    expect(find.text('Daftar Tontonan (0)'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('Sedang Menonton'), findsOneWidget);
    expect(find.text('Rencana Ditonton'), findsOneWidget);

    // Tap tombol Ikuti (dalam mode offline / tanpa supabase auth login)
    await tester.tap(find.text('Ikuti'));
    await tester.pumpAndSettle();
  });
}

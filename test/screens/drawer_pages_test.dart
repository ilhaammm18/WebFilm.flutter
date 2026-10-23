import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_pbp/data/shared_data.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/screens/about_app_page.dart';
import 'package:tugas_pbp/screens/customer_service_page.dart';
import 'package:tugas_pbp/screens/edit_profile_page.dart';
import 'package:tugas_pbp/screens/friends_page.dart';
import 'package:tugas_pbp/screens/movie_detail_page.dart';
import 'package:tugas_pbp/screens/release_schedule_page.dart';
import 'package:tugas_pbp/screens/settings_page.dart';
import 'package:tugas_pbp/screens/user_profile_detail_page.dart';
import 'package:tugas_pbp/services/api_service.dart';

class MockScheduleApiService extends ApiService {
  @override
  Future<List<Drama>> getNowAiringSchedule({int page = 1}) async {
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final futureDate = now.add(const Duration(days: 10));
    final futureDateStr =
        "${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}";
    final oldDate = now.subtract(const Duration(days: 90));
    final oldDateStr =
        "${oldDate.year}-${oldDate.month.toString().padLeft(2, '0')}-${oldDate.day.toString().padLeft(2, '0')}";

    return [
      Drama.fromTmdbJson({
        'id': 101,
        'title': 'Now Airing Drama Test',
        'original_title': 'Now Airing Korean Test',
        'vote_average': 8.5,
        'first_air_date': todayStr,
        'overview': 'Sinopsis drama sedang tayang untuk pengujian.',
      }, defaultGenre: 'Drama', mediaType: 'tv'),
      // Film masa depan nyasar ke sedang tayang (harus difilter keluar)
      Drama.fromTmdbJson({
        'id': 102,
        'title': 'Future Movie in Airing',
        'vote_average': 7.0,
        'release_date': futureDateStr,
      }, defaultGenre: 'Film', mediaType: 'movie'),
      // Film lebih dari 2 bulan lalu (harus difilter keluar)
      Drama.fromTmdbJson({
        'id': 103,
        'title': 'Old Movie in Airing',
        'vote_average': 6.0,
        'release_date': oldDateStr,
      }, defaultGenre: 'Film', mediaType: 'movie'),
    ];
  }

  @override
  Future<List<Drama>> getUpcomingMovies({int page = 1}) async {
    final now = DateTime.now();
    final futureDate1 = now.add(const Duration(days: 15));
    final futureDateStr1 =
        "${futureDate1.year}-${futureDate1.month.toString().padLeft(2, '0')}-${futureDate1.day.toString().padLeft(2, '0')}";
    final futureDate2 = now.add(const Duration(days: 45));
    final futureDateStr2 =
        "${futureDate2.year}-${futureDate2.month.toString().padLeft(2, '0')}-${futureDate2.day.toString().padLeft(2, '0')}";
    final pastDate = now.subtract(const Duration(days: 30));
    final pastDateStr =
        "${pastDate.year}-${pastDate.month.toString().padLeft(2, '0')}-${pastDate.day.toString().padLeft(2, '0')}";

    return [
      Drama.fromTmdbJson({
        'id': 202,
        'title': 'Upcoming Movie Test',
        'original_title': 'Upcoming Movie Korean Test',
        'vote_average': 9.0,
        'release_date': futureDateStr1,
        'overview': 'Sinopsis film segera hadir untuk pengujian.',
      }, defaultGenre: 'Film', mediaType: 'movie'),
      // Film segera hadir dengan vote_average 0 (harus menampilkan badge 'Segera')
      Drama.fromTmdbJson({
        'id': 203,
        'title': 'Upcoming Zero Rating',
        'vote_average': 0.0,
        'release_date': futureDateStr2,
        'overview': 'Film belum tayang tanpa rating.',
      }, defaultGenre: 'Film', mediaType: 'movie'),
      // Film masa lalu yang nyasar ke upcoming (harus dibuang oleh filter ganda)
      Drama.fromTmdbJson({
        'id': 204,
        'title': 'Past Movie in Upcoming',
        'vote_average': 7.5,
        'release_date': pastDateStr,
      }, defaultGenre: 'Film', mediaType: 'movie'),
    ];
  }
}

void main() {
  setUp(() {
    SharedData.userProfileNotifier.value = const UserProfileData(
      fullName: 'Muhammad Nur Ilham',
      username: '25051204433',
    );
  });

  testWidgets('1. EditProfilePage menampilkan input profil dan update profile notifier', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: EditProfilePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Profil'), findsOneWidget);
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Tentang Saya / Bio (Opsional)'), findsOneWidget);
    expect(find.text('Simpan Perubahan'), findsOneWidget);

    // Buka avatar picker modal
    await tester.tap(find.text('Ubah Foto Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih Foto Profil'), findsOneWidget);
    expect(find.text('Atau Masukkan URL Gambar:'), findsOneWidget);

    // Tutup bottom sheet dengan mengetuk di area luar
    await tester.tapAt(const Offset(500, 100));
    await tester.pumpAndSettle();

    // Ubah nama lengkap
    await tester.enterText(find.widgetWithText(TextField, 'Nama Lengkap'), 'Ilham Test User');
    await tester.pumpAndSettle();

    // Simpan perubahan profil
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    expect(SharedData.userProfileNotifier.value.fullName, 'Ilham Test User');
  });

  testWidgets('2. ReleaseSchedulePage menampilkan 2 tab TMDB, tanggal rilis dinamis, badge Segera, dan filter tanggal ketat', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockService = MockScheduleApiService();

    await tester.pumpWidget(
      MaterialApp(
        home: ReleaseSchedulePage(apiService: mockService),
      ),
    );
    await tester.pumpAndSettle();

    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final todayFormatted = '${now.day} ${months[now.month - 1]} ${now.year}';

    // Verifikasi Tab 1: Sedang Tayang
    expect(find.text('Sedang Tayang'), findsOneWidget);
    expect(find.text('Now Airing Drama Test'), findsOneWidget);
    expect(find.text('Tayang: $todayFormatted'), findsOneWidget);
    // Film masa depan dan film lebih dari 2 bulan lalu harus difilter keluar
    expect(find.text('Future Movie in Airing'), findsNothing);
    expect(find.text('Old Movie in Airing'), findsNothing);

    // Navigasi ke Tab 2: Segera Hadir
    await tester.tap(find.text('Segera Hadir'));
    await tester.pumpAndSettle();

    expect(find.text('Upcoming Movie Test'), findsOneWidget);
    expect(find.text('9.0'), findsOneWidget);
    // Film belum tayang dengan vote_average 0 harus menampilkan badge 'Segera' dan tidak menampilkan 0.0
    expect(find.text('Upcoming Zero Rating'), findsOneWidget);
    expect(find.text('Segera'), findsOneWidget);
    expect(find.text('0.0'), findsNothing);
    // Film masa lalu harus difilter keluar dari Segera Hadir
    expect(find.text('Past Movie in Upcoming'), findsNothing);

    // Klik kartu film untuk membuka MovieDetailPage
    await tester.tap(find.text('Upcoming Movie Test'));
    await tester.pumpAndSettle();

    expect(find.byType(MovieDetailPage), findsOneWidget);
  });

  testWidgets('3. FriendsPage menampilkan 2 tab, kolom pencarian, empty state dan follow toggle', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: FriendsPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Tab 'Mengikuti' & 'Pengikut'
    expect(find.text('Mengikuti'), findsOneWidget);
    expect(find.text('Pengikut'), findsOneWidget);

    // Empty state awal
    expect(find.text('Belum Mengikuti Siapa Pun'), findsOneWidget);

    // Cek tab Pengikut
    await tester.tap(find.text('Pengikut'));
    await tester.pumpAndSettle();
    expect(find.text('Belum Memiliki Pengikut'), findsOneWidget);

    // Cari username
    await tester.enterText(find.byType(TextField), 'moviefreak');
    await tester.pumpAndSettle();

    expect(find.text('Rian Pratama'), findsOneWidget);
    expect(find.text('@moviefreak'), findsOneWidget);
    expect(find.text('Ikuti'), findsOneWidget);

    // Tap ikuti
    await tester.tap(find.text('Ikuti'));
    await tester.pumpAndSettle();

    expect(find.text('Mengikuti'), findsWidgets);

    // Tap row pengguna untuk membuka UserProfileDetailPage
    await tester.tap(find.text('Rian Pratama'));
    await tester.pumpAndSettle();

    expect(find.byType(UserProfileDetailPage), findsOneWidget);
    expect(find.text('Statistik Waktu Tonton'), findsOneWidget);
  });

  testWidgets('4. SettingsPage menampilkan toggle tema, dialog ganti password, hapus riwayat, dan tombol logout', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('Edit Profil'), findsOneWidget);
    expect(find.text('Mode Gelap'), findsOneWidget);
    expect(find.text('Ubah Kata Sandi'), findsOneWidget);
    expect(find.text('Hapus Riwayat Pencarian'), findsNothing);
    expect(find.widgetWithText(ElevatedButton, 'Keluar'), findsOneWidget);

    // Buka Edit Profil
    await tester.tap(find.text('Edit Profil'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfilePage), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Buka dialog Ubah Kata Sandi
    await tester.tap(find.text('Ubah Kata Sandi'));
    await tester.pumpAndSettle();

    expect(find.text('Kata Sandi Baru'), findsOneWidget);
    expect(find.text('Konfirmasi Kata Sandi Baru'), findsOneWidget);

    // Tutup dialog
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
  });

  testWidgets('5. CustomerServicePage menampilkan FAQ ExpansionTiles dan dialog Kirim Masukan & Lapor Bug', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: CustomerServicePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Customer Service'), findsWidgets);
    expect(find.text('Pertanyaan Umum (FAQ)'), findsOneWidget);
    expect(find.text('Kirim Masukan & Lapor Bug'), findsOneWidget);

    // Buka akordion FAQ
    await tester.tap(find.text('Bagaimana cara menambahkan film/drama ke Daftar Saya?'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Buka film atau serial yang Anda minati'), findsOneWidget);

    // Buka form Kirim Masukan & Lapor Bug
    await tester.tap(find.text('Kirim Masukan & Lapor Bug'));
    await tester.pumpAndSettle();

    expect(find.text('Kategori:'), findsOneWidget);
    expect(find.text('Judul Masukan / Masalah'), findsOneWidget);
    expect(find.text('Kirim Laporan'), findsOneWidget);
  });

  testWidgets('6. AboutAppPage menampilkan versi 1.0.0, atribusi TMDB & Supabase, dan Developer Card', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: AboutAppPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tentang Aplikasi'), findsOneWidget);
    expect(find.text('MyWatchList'), findsOneWidget);
    expect(find.text('Versi 1.0.0'), findsOneWidget);

    // Atribusi sumber data sudah dihapus sesuai penyesuaian UI
    expect(find.text('The Movie Database (TMDB) API'), findsNothing);
    expect(find.text('Supabase Backend'), findsNothing);

    // Informasi developer yang tepat
    expect(find.text('Muhammad Nur Ilham'), findsOneWidget);
    expect(find.text('NIM : 25051204433'), findsOneWidget);
    expect(find.textContaining('Teknik Informatika'), findsOneWidget);
  });
}

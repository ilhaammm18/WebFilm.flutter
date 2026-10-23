import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_pbp/screens/detail_page.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/data/shared_data.dart';

Drama createSampleDrama({
  required int id,
  required String title,
  required String status,
  int episodes = 1,
  int watchedEpisodes = 0,
  double rating = 8.5,
  double? myRating,
  double? userRating,
}) {
  return Drama(
    id: id,
    title: title,
    koreanTitle: title,
    genre: 'Film',
    rating: rating,
    myRating: myRating ?? userRating,
    episodes: episodes,
    watchedEpisodes: watchedEpisodes,
    status: status,
    priority: 'Sedang',
    startDate: '',
    endDate: '',
    date: '2026',
    image: 'https://example.com/poster.jpg',
    rank: '#1',
    popularity: '100',
    watchers: '10K',
    synopsis: 'Sinopsis film $title.',
    aired: '2026',
    duration: '120 menit',
    contentRating: '13+',
    genresList: const ['Action', 'Drama'],
    tagsList: const ['Popular'],
  );
}

void main() {
  setUp(() {
    SharedData.dramaListNotifier.value = [];
  });

  group('MovieDetailPage Dynamic FloatingActionButton & Watchlist Sync Tests', () {
    testWidgets(
        '1. FAB menampilkan ikon tambah (Icons.add) jika film BELUM ada di Daftar Saya atau status Belum Ditonton',
        (tester) async {
      final unsavedMovie = createSampleDrama(
        id: 101,
        title: 'Inception',
        status: 'Belum Ditonton',
      );

      // SharedData kosong -> belum ada di Daftar Saya
      SharedData.dramaListNotifier.value = [];

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailPage(movie: unsavedMovie),
        ),
      );
      await tester.pump();

      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      // Verifikasi ikon adalah Icons.add warna putih
      final iconFinder = find.descendant(of: fabFinder, matching: find.byType(Icon));
      expect(iconFinder, findsOneWidget);
      final Icon iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.icon, Icons.add);
      expect(iconWidget.color, Colors.white);

      // Verifikasi backgroundColor tetap biru
      final FloatingActionButton fabWidget = tester.widget<FloatingActionButton>(fabFinder);
      expect(fabWidget.backgroundColor, const Color(0xFF0094FF));
    });

    testWidgets(
        '2. FAB menampilkan ikon pensil (Icons.edit) jika film SUDAH ada di Daftar Saya (Rencana Ditonton, Sedang Menonton, atau Selesai)',
        (tester) async {
      final savedDrama = createSampleDrama(
        id: 202,
        title: 'Interstellar',
        status: 'Sedang Menonton',
        watchedEpisodes: 1,
        myRating: 9.0,
      );

      // Simulasikan film sudah ada di Daftar Saya user di Supabase / SharedData
      SharedData.dramaListNotifier.value = [savedDrama];

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailPage(movie: savedDrama),
        ),
      );
      await tester.pump();

      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      // Verifikasi child FAB berubah menjadi ikon pensil (Icons.edit) warna putih
      final iconFinder = find.descendant(of: fabFinder, matching: find.byType(Icon));
      expect(iconFinder, findsOneWidget);
      final Icon iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.icon, Icons.edit);
      expect(iconWidget.color, Colors.white);

      // Verifikasi backgroundColor tetap biru
      final FloatingActionButton fabWidget = tester.widget<FloatingActionButton>(fabFinder);
      expect(fabWidget.backgroundColor, const Color(0xFF0094FF));
    });

    testWidgets(
        '3. Ketika tombol pensil diklik, form BottomSheet otomatis menampilkan data terakhir yang tersimpan (status, episode, rating)',
        (tester) async {
      final savedDrama = createSampleDrama(
        id: 303,
        title: 'The Dark Knight',
        status: 'Sedang Menonton',
        episodes: 16,
        watchedEpisodes: 8,
        myRating: 9.5,
        userRating: 9.5,
      );

      SharedData.dramaListNotifier.value = [savedDrama];

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailPage(movie: savedDrama),
        ),
      );
      await tester.pump();

      // Klik FAB berikon pensil
      final fabFinder = find.byType(FloatingActionButton);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Modal BottomSheet EditDramaModal terbuka
      expect(find.byType(EditDramaModal), findsOneWidget);

      // Status yang terpilih harus 'Sedang Menonton', BUKAN 'Belum Ditonton'
      expect(find.text('Sedang Menonton'), findsWidgets);

      // Progres episode yang tersimpan (8 episode) muncul di form
      expect(find.textContaining('8'), findsWidgets);

      // Rating user yang tersimpan (9.5) muncul di slider/form
      expect(find.textContaining('9.5'), findsWidgets);
    });

    testWidgets(
        '4. Real-time Update: Setelah Simpan Perubahan di BottomSheet, FAB langsung berubah dari + menjadi pensil tanpa keluar halaman',
        (tester) async {
      final newMovie = createSampleDrama(
        id: 404,
        title: 'Avatar',
        status: 'Belum Ditonton',
      );

      // Awalnya belum ada di Daftar Saya
      SharedData.dramaListNotifier.value = [];

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailPage(movie: newMovie),
        ),
      );
      await tester.pump();

      // Pastikan awalnya ikon adalah Icons.add (+)
      final fabFinder = find.byType(FloatingActionButton);
      Icon fabIcon = tester.widget<Icon>(
        find.descendant(of: fabFinder, matching: find.byType(Icon)),
      );
      expect(fabIcon.icon, Icons.add);

      // Klik FAB untuk membuka modal
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      expect(find.byType(EditDramaModal), findsOneWidget);

      // Ubah status dari Belum Ditonton ke Sedang Menonton di dropdown
      await tester.tap(find.text('Belum Ditonton'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sedang Menonton').last);
      await tester.pumpAndSettle();

      // Tekan tombol Simpan / Tambah ke Daftar pada modal
      final saveBtnFinder = find.descendant(
        of: find.byType(EditDramaModal),
        matching: find.byType(ElevatedButton),
      );
      expect(saveBtnFinder, findsOneWidget);
      await tester.tap(saveBtnFinder);
      await tester.pumpAndSettle();

      // Modal tertutup
      expect(find.byType(EditDramaModal), findsNothing);

      // Verifikasi bahwa ikon FAB langsung berubah menjadi Icons.edit (pensil) secara real-time!
      fabIcon = tester.widget<Icon>(
        find.descendant(of: fabFinder, matching: find.byType(Icon)),
      );
      expect(fabIcon.icon, Icons.edit);
      expect(fabIcon.color, Colors.white);
    });

    testWidgets(
        '5. Real-time Update: Jika status diubah kembali ke Belum Ditonton, FAB berubah kembali menjadi ikon tambah (+)',
        (tester) async {
      final savedDrama = createSampleDrama(
        id: 505,
        title: 'Oppenheimer',
        status: 'Selesai',
        watchedEpisodes: 1,
      );

      SharedData.dramaListNotifier.value = [savedDrama];

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailPage(movie: savedDrama),
        ),
      );
      await tester.pump();

      final fabFinder = find.byType(FloatingActionButton);
      // Ikon awal adalah pensil
      Icon fabIcon = tester.widget<Icon>(
        find.descendant(of: fabFinder, matching: find.byType(Icon)),
      );
      expect(fabIcon.icon, Icons.edit);

      // Buka modal
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Ubah status dari Selesai ke Belum Ditonton
      await tester.tap(find.text('Selesai').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Belum Ditonton').last);
      await tester.pumpAndSettle();

      // Tekan tombol Simpan Perubahan pada modal
      final saveBtnFinder = find.descendant(
        of: find.byType(EditDramaModal),
        matching: find.byType(ElevatedButton),
      );
      expect(saveBtnFinder, findsOneWidget);
      await tester.tap(saveBtnFinder);
      await tester.pumpAndSettle();

      // Ikon FAB kembali menjadi Icons.add (+)
      fabIcon = tester.widget<Icon>(
        find.descendant(of: fabFinder, matching: find.byType(Icon)),
      );
      expect(fabIcon.icon, Icons.add);
    });
  });
}

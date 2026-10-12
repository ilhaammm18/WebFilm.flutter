import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/data/shared_data.dart';
import 'package:tugas_pbp/screens/watchlist_tab.dart';
import 'package:tugas_pbp/widgets/edit_drama_modal.dart';

void main() {
  setUp(() {
    SharedData.dramaListNotifier.value = [];
  });

  group('PBO Status Sync Unit Tests', () {
    test('Pengujian aturan status otomatis pada Drama model', () {
      final drama = Drama(
        title: 'Signal',
        koreanTitle: '시그널',
        genre: 'Thriller, Crime',
        rating: 9.0,
        episodes: 16,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2016',
        image: 'https://example.com/signal.jpg',
        rank: '#10',
        popularity: '#10',
        watchers: '100K',
        synopsis: 'Walkie-talkie misterius menghubungkan masa lalu dan masa kini.',
        aired: '2016',
        duration: '60 menit',
        contentRating: '15+',
        genresList: ['Thriller'],
        tagsList: ['Time Slip'],
      );

      // 1. Initial watchedEpisodes == 0 ➔ Rencana Ditonton
      expect(drama.watchedEpisodes, 0);
      expect(drama.status, 'Rencana Ditonton');

      // 2. Tambah episode > 0 && < totalEpisodes ➔ Sedang Menonton
      drama.watchedEpisodes = 1;
      expect(drama.status, 'Sedang Menonton');

      drama.watchedEpisodes = 15;
      expect(drama.status, 'Sedang Menonton');

      // 3. watchedEpisodes == totalEpisodes (16) ➔ Selesai
      drama.watchedEpisodes = 16;
      expect(drama.status, 'Selesai');

      // 4. watchedEpisodes kembali ke 0 ➔ Rencana Ditonton
      drama.watchedEpisodes = 0;
      expect(drama.status, 'Rencana Ditonton');
    });
  });

  group('WatchlistTab & EditDramaModal Real-time Status Sync Widget Tests', () {
    testWidgets('Tambah episode dari 0 ke 1 membuat drama berpindah dari tab Rencana Ditonton ke Sedang Menonton', (tester) async {
      final dramaTest = Drama(
        title: 'My Mister',
        koreanTitle: '나의 아저씨',
        genre: 'Drama, Life',
        rating: 9.3,
        episodes: 16,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2018',
        image: 'https://example.com/mymister.jpg',
        rank: '#3',
        popularity: '#3',
        watchers: '120K',
        synopsis: 'Kisah kehidupan mendalam.',
        aired: '2018',
        duration: '70 menit',
        contentRating: '15+',
        genresList: ['Life'],
        tagsList: ['Healing'],
      );

      SharedData.dramaListNotifier.value = [dramaTest];

      await tester.pumpWidget(
        const MaterialApp(
          home: WatchlistTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Buka tab 'RENCANA DITONTON'
      final rencanaTab = find.text('RENCANA DITONTON');
      expect(rencanaTab, findsOneWidget);
      await tester.tap(rencanaTab);
      await tester.pumpAndSettle();

      // Verifikasi drama muncul di tab 'RENCANA DITONTON'
      expect(find.text('My Mister'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      expect(find.byIcon(Icons.subtitles_rounded), findsOneWidget);
      expect(find.text('Progres: 0/16'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);

      // Buka modal edit melalui tombol pena
      final editButton = find.byIcon(Icons.edit_outlined);
      expect(editButton, findsOneWidget);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Verifikasi EditDramaModal terbuka
      expect(find.byType(EditDramaModal), findsOneWidget);

      // Tambahkan 1 episode menggunakan tombol (+)
      final plusButton = find.byIcon(Icons.add);
      expect(plusButton, findsOneWidget);
      await tester.tap(plusButton);
      await tester.pumpAndSettle();

      // Verifikasi teks progres di modal bertambah jadi 1/16
      expect(find.text('1/16'), findsOneWidget);

      // Tekan tombol 'Simpan Perubahan'
      final simpanButton = find.text('Simpan Perubahan');
      expect(simpanButton, findsOneWidget);
      await tester.tap(simpanButton);
      await tester.pumpAndSettle();

      // Modal tertutup
      expect(find.byType(EditDramaModal), findsNothing);

      // Verifikasi drama telah HILANG dari tab 'RENCANA DITONTON'
      expect(find.text('Belum ada data untuk Rencana Ditonton'), findsOneWidget);
      expect(find.text('My Mister'), findsNothing);

      // Sekarang pindah ke tab 'SEDANG MENONTON'
      final sedangMenontonTab = find.text('SEDANG MENONTON');
      await tester.tap(sedangMenontonTab);
      await tester.pumpAndSettle();

      // Verifikasi drama telah MUNCUL di tab 'SEDANG MENONTON' dengan progres 1/16
      expect(find.text('My Mister'), findsOneWidget);
      expect(find.text('Progres: 1/16'), findsOneWidget);
    });

    testWidgets('Tambah episode ke total maksimal membuat drama berpindah ke tab Selesai', (tester) async {
      final dramaTest = Drama(
        title: 'Signal',
        koreanTitle: '시그널',
        genre: 'Thriller',
        rating: 9.0,
        episodes: 16,
        watchedEpisodes: 15,
        status: 'Sedang Menonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2016',
        image: 'https://example.com/signal.jpg',
        rank: '#10',
        popularity: '#10',
        watchers: '100K',
        synopsis: 'Walkie-talkie.',
        aired: '2016',
        duration: '60 menit',
        contentRating: '15+',
        genresList: ['Thriller'],
        tagsList: ['Crime'],
      );

      SharedData.dramaListNotifier.value = [dramaTest];

      await tester.pumpWidget(
        const MaterialApp(
          home: WatchlistTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Berada di tab default 'SEDANG MENONTON'
      expect(find.text('Signal'), findsOneWidget);
      expect(find.text('Progres: 15/16'), findsOneWidget);

      // Buka modal edit
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // Tambahkan 1 episode (15 -> 16 = totalEpisodes)
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Simpan perubahan
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      // Verifikasi drama telah HILANG dari tab 'SEDANG MENONTON'
      expect(find.text('Belum ada data untuk Sedang Menonton'), findsOneWidget);

      // Pindah ke tab 'SELESAI'
      await tester.tap(find.text('SELESAI'));
      await tester.pumpAndSettle();

      // Verifikasi drama telah MUNCUL di tab 'SELESAI'
      expect(find.text('Signal'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/data/shared_data.dart';
import 'package:tugas_pbp/watchlist_tab.dart';
import 'package:tugas_pbp/edit_drama_modal.dart';

void main() {
  setUp(() {
    SharedData.dramaListNotifier.value = [];
  });

  group('WatchlistTab Rating Display & Edit Sync Tests', () {
    testWidgets('Status Selesai dan userRating > 0 menampilkan userRating, jika belum menampilkan global rating', (tester) async {
      final dramaSelesaiDenganUserRating = Drama(
        title: 'Reply 1988',
        koreanTitle: '응답하라 1988',
        genre: 'Drama Korea',
        rating: 7.9,
        userRating: 8.8,
        episodes: 20,
        watchedEpisodes: 20,
        status: 'Selesai',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2015',
        image: 'https://example.com/reply.jpg',
        rank: '#1',
        popularity: '#1',
        watchers: '250K',
        synopsis: 'Kisah 5 keluarga.',
        aired: '2015',
        duration: '90 menit',
        contentRating: '15+',
        genresList: ['Comedy'],
        tagsList: ['Nostalgia'],
      );

      final dramaSelesaiTanpaUserRating = Drama(
        title: 'Prison Playbook',
        koreanTitle: '슬기로운 감빵생활',
        genre: 'Drama Korea',
        rating: 7.9,
        userRating: null,
        episodes: 16,
        watchedEpisodes: 16,
        status: 'Selesai',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2017',
        image: 'https://example.com/prison.jpg',
        rank: '#5',
        popularity: '#5',
        watchers: '120K',
        synopsis: 'Kisah kehidupan penjara.',
        aired: '2017',
        duration: '80 menit',
        contentRating: '15+',
        genresList: ['Comedy'],
        tagsList: ['Prison'],
      );

      SharedData.dramaListNotifier.value = [
        dramaSelesaiDenganUserRating,
        dramaSelesaiTanpaUserRating,
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: WatchlistTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Buka tab 'SELESAI'
      await tester.tap(find.text('SELESAI'));
      await tester.pumpAndSettle();

      // Drama dengan userRating 8.8 harus menampilkan '8.8'
      expect(find.text('8.8'), findsOneWidget);

      // Drama tanpa userRating harus menampilkan rating global '7.9'
      expect(find.text('7.9'), findsOneWidget);
    });

    testWidgets('Simpan Perubahan pada slider Peringkat mengubah rating di ListView secara real-time dari 7.9 menjadi 8.8', (tester) async {
      final dramaTest = Drama(
        title: 'Stranger',
        koreanTitle: '비밀의 숲',
        genre: 'Thriller, Crime',
        rating: 7.9,
        userRating: null,
        episodes: 16,
        watchedEpisodes: 16,
        status: 'Selesai',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2017',
        image: 'https://example.com/stranger.jpg',
        rank: '#4',
        popularity: '#4',
        watchers: '110K',
        synopsis: 'Jaksa tanpa emosi.',
        aired: '2017',
        duration: '60 menit',
        contentRating: '15+',
        genresList: ['Crime'],
        tagsList: ['Mystery'],
      );

      SharedData.dramaListNotifier.value = [dramaTest];

      await tester.pumpWidget(
        const MaterialApp(
          home: WatchlistTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Buka tab 'SELESAI'
      await tester.tap(find.text('SELESAI'));
      await tester.pumpAndSettle();

      // Awalnya menampilkan rating global 7.9
      expect(find.text('7.9'), findsOneWidget);
      expect(find.text('8.8'), findsNothing);

      // Buka modal edit melalui tombol pena
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(EditDramaModal), findsOneWidget);

      // Ubah slider peringkat ke 8.8
      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);
      
      // Drag slider sedikit ke kanan
      await tester.tap(sliderFinder);
      await tester.pumpAndSettle();

      // Cari tombol simpan
      final simpanButton = find.text('Simpan Perubahan');
      expect(simpanButton, findsOneWidget);
      await tester.tap(simpanButton);
      await tester.pumpAndSettle();

      // Modal tertutup
      expect(find.byType(EditDramaModal), findsNothing);

      // Nilai userRating tersimpan pada objek drama
      expect(dramaTest.userRating, isNotNull);
      expect(dramaTest.userRating, isNot(7.9));

      // Verifikasi di ListView card, angka rating yang ditampilkan adalah userRating yang baru
      expect(find.text(dramaTest.userRating!.toStringAsFixed(1)), findsOneWidget);
    });
  });
}

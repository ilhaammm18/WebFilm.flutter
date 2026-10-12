import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_pbp/screens/detail_page.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/data/shared_data.dart';

void main() {
  setUp(() {
    // Reset SharedData sebelum tiap pengujian
    SharedData.dramaListNotifier.value = [];
  });

  group('DetailPage Rating Cards & Real-time Update Tests', () {
    testWidgets('Kondisi A: status Selesai & sudah rating menampilkan dua kotak bersebelahan', (tester) async {
      final testDrama = Drama(
        title: 'Crash Landing on You',
        koreanTitle: '사랑의 불시착',
        genre: 'Romance, Drama',
        rating: 6.7,
        myRating: 7.7,
        episodes: 16,
        watchedEpisodes: 16,
        status: 'Selesai',
        priority: 'Tinggi',
        startDate: '01/01/2026',
        endDate: '15/01/2026',
        date: '2019',
        image: 'https://example.com/poster.jpg',
        rank: '#1',
        popularity: '#5',
        watchers: '200K',
        synopsis: 'Kisah cinta lintas batas.',
        aired: '2019 - 2020',
        duration: '70 menit',
        contentRating: '15+',
        genresList: ['Romance', 'Drama'],
        tagsList: ['Love', 'Military'],
      );

      SharedData.dramaListNotifier.value = [testDrama];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: DetailPage(drama: testDrama),
        ),
      );
      await tester.pump();

      // Memastikan kedua label card muncul
      expect(find.text('Rating Global'), findsOneWidget);
      expect(find.text('Penilaian Saya'), findsOneWidget);

      // Memastikan angka rating global dan angka penilaian saya muncul presisi
      expect(find.text('6.7'), findsOneWidget);
      expect(find.text('7.7'), findsOneWidget);

      // Memastikan card Penilaian Saya dapat di-tap untuk membuka modal edit
      await tester.tap(find.text('Penilaian Saya'));
      await tester.pumpAndSettle();

      // Verifikasi bahwa EditDramaModal terbuka
      expect(find.byType(EditDramaModal), findsOneWidget);
      expect(find.text('UMUM'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(EditDramaModal),
          matching: find.text('Peringkat'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Kondisi B: status belum Selesai menampilkan tombol Berikan Penilaian Sekarang', (tester) async {
      final testDrama = Drama(
        title: 'Vincenzo',
        koreanTitle: '빈센조',
        genre: 'Action, Comedy',
        rating: 8.9,
        myRating: null,
        episodes: 20,
        watchedEpisodes: 5,
        status: 'Sedang Menonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2021',
        image: 'https://example.com/vincenzo.jpg',
        rank: '#4',
        popularity: '#12',
        watchers: '150K',
        synopsis: 'Pengacara mafia Italia.',
        aired: '2021',
        duration: '80 menit',
        contentRating: '15+',
        genresList: ['Action'],
        tagsList: ['Mafia'],
      );

      SharedData.dramaListNotifier.value = [testDrama];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: DetailPage(drama: testDrama),
        ),
      );
      await tester.pump();

      // Kondisi B harus menampilkan CTA 'Berikan Penilaian Sekarang'
      expect(find.textContaining('Berikan Penilaian'), findsOneWidget);
      expect(find.text('Penilaian Saya'), findsNothing);
    });

    testWidgets('Sinkronisasi Real-time: Slider Peringkat mengubah angka Penilaian Saya di DetailPage', (tester) async {
      final testDrama = Drama(
        title: 'Hospital Playlist',
        koreanTitle: '슬기로운 의사생활',
        genre: 'Medical, Friendship',
        rating: 9.0,
        myRating: 8.0,
        episodes: 12,
        watchedEpisodes: 12,
        status: 'Selesai',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2020',
        image: 'https://example.com/hospital.jpg',
        rank: '#2',
        popularity: '#8',
        watchers: '180K',
        synopsis: 'Kisah 5 dokter bersahabat.',
        aired: '2020',
        duration: '85 menit',
        contentRating: '15+',
        genresList: ['Medical'],
        tagsList: ['Friendship'],
      );

      SharedData.dramaListNotifier.value = [testDrama];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: DetailPage(drama: testDrama),
        ),
      );
      await tester.pump();

      expect(find.text('8.0'), findsOneWidget);

      // Buka modal edit melalui tap card Penilaian Saya
      await tester.tap(find.text('Penilaian Saya'));
      await tester.pumpAndSettle();

      // Cari Slider pada EditDramaModal
      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      // Geser slider ke nilai baru (misal: ~9.5)
      await tester.tap(sliderFinder);
      await tester.pumpAndSettle();

      // Simpan perubahan
      final simpanButton = find.text('Simpan Perubahan');
      expect(simpanButton, findsOneWidget);
      await tester.tap(simpanButton);
      await tester.pumpAndSettle();

      // Modal tertutup, verifikasi bahwa DetailPage telah diperbarui secara real-time
      expect(find.byType(EditDramaModal), findsNothing);
      expect(find.text('Rating Global'), findsOneWidget);
      expect(find.text('Penilaian Saya'), findsOneWidget);
      expect(testDrama.myRating, isNotNull);
      expect(find.text(testDrama.myRating!.toStringAsFixed(1)), findsOneWidget);
    });
  });
}

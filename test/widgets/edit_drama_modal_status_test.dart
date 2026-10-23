import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_pbp/data/shared_data.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/widgets/edit_drama_modal.dart';

Drama _buildDrama(String status, {int watched = 5}) => Drama(
      id: 1,
      title: 'Crash Landing on You',
      koreanTitle: '사랑의 불시착',
      mediaType: 'tv',
      genre: 'Drama',
      rating: 8.5,
      episodes: 16,
      watchedEpisodes: watched,
      status: status,
      priority: 'Sedang',
      startDate: '',
      endDate: '',
      date: '2019',
      image: '',
      rank: '#1',
      popularity: '#5',
      watchers: '200K',
      synopsis: 'Kisah cinta lintas batas.',
      aired: '2019',
      duration: '70 menit',
      contentRating: '15+',
      genresList: ['Romance'],
      tagsList: [],
    );

Future<void> _pumpModal(WidgetTester tester, Drama drama) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: EditDramaModal(drama: drama)),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _selectStatus(WidgetTester tester, String from, String to) async {
  await tester.tap(find.text(from));
  await tester.pumpAndSettle();
  await tester.tap(find.text(to).last);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedData.dramaListNotifier.value = [];
  });

  group('EditDramaModal - logika kondisional Status', () {
    testWidgets('Status Rencana Ditonton menyembunyikan Episode & Peringkat',
        (tester) async {
      await _pumpModal(tester, _buildDrama('Rencana Ditonton', watched: 0));

      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Episode'), findsNothing);
      expect(find.text('Peringkat'), findsNothing);
      expect(find.byType(Slider), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('Status Sedang Menonton menampilkan Episode & Peringkat',
        (tester) async {
      await _pumpModal(tester, _buildDrama('Sedang Menonton'));

      expect(find.text('Episode'), findsOneWidget);
      expect(find.text('5/16'), findsWidgets);
      expect(find.text('Peringkat'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('Mengganti dropdown ke Rencana Ditonton lalu ke Selesai',
        (tester) async {
      await _pumpModal(tester, _buildDrama('Sedang Menonton'));
      expect(find.text('Peringkat'), findsOneWidget);

      // Pilih 'Rencana Ditonton' -> komponen tersembunyi
      await _selectStatus(tester, 'Sedang Menonton', 'Rencana Ditonton');
      expect(find.text('Episode'), findsNothing);
      expect(find.text('Peringkat'), findsNothing);
      expect(find.byType(Slider), findsNothing);

      // Pilih 'Selesai' -> komponen tampil kembali
      await _selectStatus(tester, 'Rencana Ditonton', 'Selesai');
      expect(find.text('Episode'), findsOneWidget);
      expect(find.text('16/16'), findsOneWidget);
      expect(find.text('Peringkat'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });
    testWidgets('Status Belum Ditonton menyembunyikan Episode & Peringkat',
        (tester) async {
      await _pumpModal(tester, _buildDrama('Belum Ditonton', watched: 0));

      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Episode'), findsNothing);
      expect(find.text('Peringkat'), findsNothing);
      expect(find.byType(Slider), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('Mengganti dropdown ke Belum Ditonton lalu ke Sedang Menonton',
        (tester) async {
      await _pumpModal(tester, _buildDrama('Sedang Menonton'));
      expect(find.text('Peringkat'), findsOneWidget);

      // Pilih 'Belum Ditonton' -> komponen tersembunyi
      await _selectStatus(tester, 'Sedang Menonton', 'Belum Ditonton');
      expect(find.text('Episode'), findsNothing);
      expect(find.text('Peringkat'), findsNothing);
      expect(find.byType(Slider), findsNothing);

      // Pilih 'Sedang Menonton' -> komponen tampil kembali
      await _selectStatus(tester, 'Belum Ditonton', 'Sedang Menonton');
      expect(find.text('Episode'), findsOneWidget);
      expect(find.text('Peringkat'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets(
        'Initial value rating diset ke 0.0 saat modal ditambahkan, tidak mewarisi vote_average TMDB',
        (tester) async {
      // Drama dari TMDB memiliki rating 8.5 dan userRating null
      final tmdbDrama = _buildDrama('Belum Ditonton', watched: 0);
      expect(tmdbDrama.rating, 8.5);
      expect(tmdbDrama.userRating, isNull);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EditDramaModal(
                drama: tmdbDrama,
                initialStatus: 'Belum Ditonton',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pilih status 'Sedang Menonton' agar slider Peringkat muncul
      await _selectStatus(tester, 'Belum Ditonton', 'Sedang Menonton');

      // Nilai slider rating harus 0.0 (tidak mewarisi 8.5 dari TMDB)
      expect(find.text('0.0'), findsOneWidget);
      expect(find.text('8.5'), findsNothing);
    });

    testWidgets(
        'Dropdown Status: memilih "Sedang Menonton" atau "Selesai" mengatur rating menjadi 0.0',
        (tester) async {
      final drama = _buildDrama('Belum Ditonton', watched: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EditDramaModal(
                drama: drama,
                initialStatus: 'Belum Ditonton',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Pilih 'Sedang Menonton' -> rating diatur menjadi 0.0
      await _selectStatus(tester, 'Belum Ditonton', 'Sedang Menonton');
      expect(find.text('0.0'), findsOneWidget);

      // Ubah slider ke nilai lain dengan tap slider
      final sliderFinder = find.byType(Slider);
      await tester.tap(sliderFinder);
      await tester.pumpAndSettle();
      // Pastikan sekarang rating berubah (bukan 0.0 lagi)
      expect(find.text('0.0'), findsNothing);

      // 2. Ganti dropdown ke 'Selesai' -> rating kembali diatur menjadi 0.0
      await _selectStatus(tester, 'Sedang Menonton', 'Selesai');
      expect(find.text('0.0'), findsOneWidget);
    });
  });
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tugas_pbp/data/shared_data.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/screens/search_page.dart';
import 'package:tugas_pbp/services/api_service.dart';

void main() {
  setUp(() {
    SharedData.dramaListNotifier.value = [];
  });

  group('Fix Bug Watchlist Duplicate Title Matching by ID', () {
    testWidgets(
      'Hanya film dengan ID yang cocok di Watchlist yang menampilkan ikon edit; film lain dengan judul sama tetap menampilkan ikon tambah (+)',
      (tester) async {
        // Film 1: ID 801, judul "Pinocchio", tersimpan di Watchlist
        final savedDrama = Drama(
          id: 801,
          title: 'Pinocchio',
          koreanTitle: '',
          genre: 'Film Animasi',
          rating: 8.5,
          episodes: 1,
          watchedEpisodes: 1,
          status: 'Selesai',
          priority: 'Sedang',
          startDate: '',
          endDate: '',
          date: '2022',
          image: '',
          rank: '#1',
          popularity: '100',
          watchers: '10K',
          synopsis: 'Versi Guillermo del Toro',
          aired: '2022',
          duration: '117 menit',
          contentRating: 'PG',
          genresList: const ['Animation'],
          tagsList: const [],
        );

        // Pasang drama 801 ke SharedData watchlist
        SharedData.dramaListNotifier.value = [savedDrama];

        // Mock API mengembalikan 2 film berbeda yang kebetulan memiliki judul SAMA ("Pinocchio"):
        // Film A: ID 801 (tersimpan di watchlist)
        // Film B: ID 802 (film baru/berbeda, BELUM tersimpan di watchlist)
        final mockClient = MockClient((request) async {
          return http.Response(
            json.encode({
              'page': 1,
              'results': [
                {
                  'id': 801,
                  'title': 'Pinocchio',
                  'release_date': '2022-11-09',
                  'vote_average': 8.5,
                  'media_type': 'movie',
                  'original_language': 'en',
                },
                {
                  'id': 802,
                  'title': 'Pinocchio',
                  'release_date': '2022-09-08',
                  'vote_average': 6.5,
                  'media_type': 'movie',
                  'original_language': 'en',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final apiService = ApiService(client: mockClient);

        await tester.pumpWidget(
          MaterialApp(
            home: SearchPage(apiService: apiService),
          ),
        );
        await tester.pumpAndSettle();

        // Verifikasi kedua film berjuluk "Pinocchio" tampil di hasil pencarian
        expect(find.text('Pinocchio'), findsNWidgets(2));

        // Verifikasi savedMovieIds hanya berisi ID 801
        expect(SharedData.savedMovieIds, contains(801));
        expect(SharedData.savedMovieIds.contains(802), isFalse);

        // Ikon edit_outlined HANYA muncul 1 kali (khusus film 801)
        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

        // Ikon add (+) HANYA muncul 1 kali (khusus film 802 yang belum ada di watchlist)
        expect(find.byIcon(Icons.add), findsOneWidget);
      },
    );

    test('Drama.fromSupabase memetakan tmdb_id menjadi id numerik', () {
      final drama = Drama.fromSupabase({
        'tmdb_id': 9999,
        'title': 'Same Title Film',
        'status': 'Sedang Menonton',
      });

      expect(drama.id, equals(9999));
    });

    test('SharedData.mapSavedMovieIdsFromSupabase mengekstrak daftar tmdb_id numerik', () {
      final rows = [
        {'tmdb_id': 100, 'title': 'Movie 100'},
        {'tmdb_id': 200, 'title': 'Movie 200'},
        {'tmdb_id': '300', 'title': 'Movie 300'},
      ];

      final savedIds = SharedData.mapSavedMovieIdsFromSupabase(rows);
      expect(savedIds, equals([100, 200, 300]));
    });
  });
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tugas_pbp/data/shared_data.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/screens/ranking_tab.dart';
import 'package:tugas_pbp/screens/detail_page.dart';
import 'package:tugas_pbp/services/api_service.dart';

void main() {
  setUp(() {
    SharedData.dramaListNotifier.value = [];
  });

  group('LeaderboardPage / RankingTab Unit & Widget Tests', () {
    test('ApiService getLeaderboardMedia parameter validation', () async {
      final List<Uri> requestedUris = [];

      final mockClient = MockClient((request) async {
        requestedUris.add(request.url);
        final responsePayload = {
          'results': [
            {
              'id': 101,
              'title': 'Gadis Kretek',
              'poster_path': '/kretek.jpg',
              'vote_average': 8.9,
              'vote_count': 50,
              'popularity': 45.0,
              'release_date': '2023-11-02',
              'original_language': 'id',
              'overview': 'Kisah cinta dan industri rokok kretek',
            }
          ]
        };
        return http.Response(json.encode(responsePayload), 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      final apiService = ApiService(client: mockClient);

      // 1. Film Indonesia pada Rating Tertinggi harus vote_count.gte=15
      await apiService.getLeaderboardMedia(
        category: 'Film Indonesia',
        genre: 'Drama',
        isTopRated: true,
      );

      expect(requestedUris.isNotEmpty, isTrue);
      final lastUri = requestedUris.last;
      expect(lastUri.path, contains('/discover/movie'));
      expect(lastUri.queryParameters['sort_by'], equals('vote_average.desc'));
      expect(lastUri.queryParameters['vote_count.gte'], equals('15'));
      expect(lastUri.queryParameters['with_original_language'], equals('id'));
      expect(lastUri.queryParameters['with_genres'], equals('18'));

      // 2. Global / Drama Korea pada Rating Tertinggi harus vote_count.gte=200
      requestedUris.clear();
      await apiService.getLeaderboardMedia(
        category: 'Drama Korea',
        genre: 'Komedi',
        isTopRated: true,
      );

      expect(requestedUris.isNotEmpty, isTrue);
      final drakorUri = requestedUris.last;
      expect(drakorUri.path, contains('/discover/tv'));
      expect(drakorUri.queryParameters['sort_by'], equals('vote_average.desc'));
      expect(drakorUri.queryParameters['vote_count.gte'], equals('200'));
      expect(drakorUri.queryParameters['with_original_language'], equals('ko'));
      expect(drakorUri.queryParameters['with_genres'], equals('35'));

      // 3. Tab Sedang Tren harus sort_by=popularity.desc dan vote_count.gte=10
      requestedUris.clear();
      await apiService.getLeaderboardMedia(
        category: 'Anime',
        genre: 'Aksi',
        isTopRated: false,
      );

      expect(requestedUris.isNotEmpty, isTrue);
      final animeUri = requestedUris.last;
      expect(animeUri.path, contains('/discover/tv'));
      expect(animeUri.queryParameters['sort_by'], equals('popularity.desc'));
      expect(animeUri.queryParameters['vote_count.gte'], equals('10'));
      expect(animeUri.queryParameters['with_original_language'], equals('ja'));
      // Anime memiliki with_genres=16 dan aksi TV=10759
      expect(animeUri.queryParameters['with_genres'], contains('16'));
      expect(animeUri.queryParameters['with_genres'], contains('10759'));
    });

    testWidgets('Menampilkan Tab, 2 Baris Filter (Kategori & Genre), dan data peringkat berurutan',
        (tester) async {
      final mockClient = MockClient((request) async {
        final isMovie = request.url.path.contains('/movie');
        final responsePayload = {
          'results': [
            {
              'id': isMovie ? 1 : 10,
              'title': isMovie ? 'Parasite' : 'Reply 1988',
              'name': isMovie ? null : 'Reply 1988',
              'poster_path': '/poster1.jpg',
              'vote_average': 9.5,
              'vote_count': 1500,
              'popularity': 120.0,
              'release_date': '2019-05-30',
              'first_air_date': '2015-11-06',
              'original_language': 'ko',
              'overview': 'Sinopsis film/drama Korea',
            },
            {
              'id': isMovie ? 2 : 20,
              'title': isMovie ? 'The Dark Knight' : 'Breaking Bad',
              'name': isMovie ? null : 'Breaking Bad',
              'poster_path': '/poster2.jpg',
              'vote_average': 9.0,
              'vote_count': 3000,
              'popularity': 110.0,
              'release_date': '2008-07-18',
              'first_air_date': '2008-01-20',
              'original_language': 'en',
              'overview': 'Sinopsis film/drama Barat',
            },
            {
              'id': isMovie ? 3 : 30,
              'title': isMovie ? 'Spirited Away' : 'Attack on Titan',
              'name': isMovie ? null : 'Attack on Titan',
              'poster_path': '/poster3.jpg',
              'vote_average': 8.8,
              'vote_count': 1200,
              'popularity': 95.0,
              'release_date': '2001-07-20',
              'first_air_date': '2013-04-07',
              'original_language': 'ja',
              'genre_ids': [16],
              'overview': 'Sinopsis Anime',
            },
            {
              'id': isMovie ? 4 : 40,
              'title': isMovie ? 'Laskar Pelangi' : 'Gadis Kretek',
              'name': isMovie ? null : 'Gadis Kretek',
              'poster_path': '/poster4.jpg',
              'vote_average': 8.5,
              'vote_count': 250,
              'popularity': 80.0,
              'release_date': '2008-09-26',
              'first_air_date': '2023-11-02',
              'original_language': 'id',
              'overview': 'Sinopsis Indonesia',
            },
          ]
        };

        return http.Response(json.encode(responsePayload), 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: RankingTab(apiService: apiService),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verifikasi Tab 'Rating Tertinggi' & 'Sedang Tren'
      expect(find.text('Rating Tertinggi'), findsOneWidget);
      expect(find.text('Sedang Tren'), findsOneWidget);

      // 2. Verifikasi Baris Filter 1 (Kategori & Negara)
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Semua Film'), findsOneWidget);
      expect(find.text('Semua Drama'), findsOneWidget);
      expect(find.text('Anime'), findsOneWidget);
      expect(find.text('Film Indonesia'), findsOneWidget);

      // 3. Verifikasi Baris Filter 2 (Genre)
      expect(find.text('Semua Genre'), findsOneWidget);
      expect(find.text('Aksi'), findsOneWidget);
      expect(find.text('Drama'), findsWidgets); // Bisa muncul di filter dan subtitle
      expect(find.text('Komedi'), findsOneWidget);

      // 4. Verifikasi Medali / Piala Desain Peringkat
      // Rank 1: Icons.emoji_events_rounded
      expect(find.byIcon(Icons.emoji_events_rounded), findsWidgets);
      // Rank 2 & 3: Icons.military_tech_rounded
      expect(find.byIcon(Icons.military_tech_rounded), findsWidgets);

      // 5. Verifikasi Format Subtitle 'Tahun • Kategori'
      // Misal: 2019 • Film Korea atau 2015 • Drama Korea
      expect(find.textContaining(' • Film Korea'), findsWidgets);
      expect(find.textContaining(' • Film Barat'), findsWidgets);

      // 6. Verifikasi Tombol Kotak Aksi (+ / pensil)
      expect(find.byIcon(Icons.add), findsWidgets);

      // 7. Navigasi ke MovieDetailPage saat kartu diklik
      await tester.tap(find.text('Parasite').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DetailPage), findsOneWidget);
    });

    testWidgets('Tombol aksi kotak (+ / pensil) tersinkron dengan status Watchlist Supabase',
        (tester) async {
      final mockClient = MockClient((request) async {
        final responsePayload = {
          'results': [
            {
              'id': 999,
              'title': 'Hospital Playlist',
              'name': 'Hospital Playlist',
              'poster_path': '/hp.jpg',
              'vote_average': 9.2,
              'vote_count': 500,
              'popularity': 90.0,
              'first_air_date': '2020-03-12',
              'original_language': 'ko',
            }
          ]
        };
        return http.Response(json.encode(responsePayload), 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: LeaderboardPage(apiService: apiService),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Sebelum masuk Watchlist: tombol menampilkan ikon + (Icons.add)
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);

      // Simulasikan film ditambahkan ke Watchlist Supabase via SharedData notifier
      SharedData.dramaListNotifier.value = [
        Drama(
          id: 999,
          title: 'Hospital Playlist',
          koreanTitle: '슬기로운 의사생활',
          genre: 'Drama Korea',
          rating: 9.2,
          episodes: 12,
          watchedEpisodes: 5,
          status: 'Sedang Menonton',
          priority: 'Tinggi',
          startDate: '2020-03-12',
          endDate: '',
          date: '2020',
          image: '',
          rank: '#1',
          popularity: '90',
          watchers: '100K',
          synopsis: 'Dokter',
          aired: '2020',
          duration: '60 menit',
          contentRating: '15+',
          genresList: ['Drama', 'Medical'],
          tagsList: [],
        ),
      ];

      await tester.pump();

      // Sesudah masuk Watchlist: tombol otomatis berubah menjadi ikon pensil (Icons.edit_outlined)
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing);

      // Saat tombol pensil diklik, membuka EditDramaModal bottom sheet
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(EditDramaModal), findsOneWidget);
    });
  });
}

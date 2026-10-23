import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/data/shared_data.dart';
import 'package:tugas_pbp/screens/search_page.dart';
import 'package:tugas_pbp/services/api_service.dart';

void main() {
  setUp(() {
    SharedData.dramaListNotifier.value = [];
  });

  group('Pemberantasan Bug Tampilan Kartu di SearchPage', () {
    testWidgets('1. Hapus angka episode default 16 saat data episode dari TMDB null', (tester) async {
      // TV Series dari TMDB tanpa number_of_episodes (data null)
      final tvNoEpisodes = Drama.fromTmdbJson({
        'id': 1001,
        'name': 'Trending Drama No Ep',
        'first_air_date': '2024-01-01',
        'vote_average': 8.5,
        'media_type': 'tv',
        'original_language': 'ko',
      });

      // TV Series dengan episode asli (misal: 24 episode)
      final tvWithEpisodes = Drama.fromTmdbJson({
        'id': 1002,
        'name': 'Drama With Real Ep',
        'first_air_date': '2024-01-01',
        'vote_average': 8.7,
        'media_type': 'tv',
        'original_language': 'ko',
        'number_of_episodes': 24,
      });

      expect(tvNoEpisodes.episodes, equals(0), reason: 'Default episodes harus 0 bukan 16');
      expect(tvWithEpisodes.episodes, equals(24));

      SharedData.dramaListNotifier.value = [];

      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'page': 1,
            'results': [
              {
                'id': 1001,
                'name': 'Trending Drama No Ep',
                'first_air_date': '2024-01-01',
                'vote_average': 8.5,
                'media_type': 'tv',
                'original_language': 'ko',
              },
              {
                'id': 1002,
                'name': 'Drama With Real Ep',
                'first_air_date': '2024-01-01',
                'vote_average': 8.7,
                'media_type': 'tv',
                'original_language': 'ko',
                'number_of_episodes': 24,
              },
            ]
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final mockApi = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: SearchPage(apiService: mockApi),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan kedua judul tampil
      expect(find.text('Trending Drama No Ep'), findsOneWidget);
      expect(find.text('Drama With Real Ep'), findsOneWidget);

      // Angka '16' TIDAK boleh muncul sama sekali
      expect(find.text('16'), findsNothing);

      // Angka '24' muncul untuk drama yang benar-benar memiliki data episode
      expect(find.text('24'), findsOneWidget);

      // Ikon list_alt hanya muncul 1 kali (untuk yang ada episode aslinya)
      expect(find.byIcon(Icons.list_alt), findsOneWidget);
    });

    test('2. Perbaiki label kategori sesuai format Kategori • Tahun dari TMDB metadata', () {
      // A. Anime (genre 16 + ja)
      final anime = Drama.fromTmdbJson({
        'id': 2001,
        'name': 'Jujutsu Kaisen',
        'first_air_date': '2023-10-01',
        'genre_ids': [16, 28],
        'original_language': 'ja',
        'media_type': 'tv',
      });
      expect(Drama.getCategoryLabel(drama: anime), equals('Anime'));

      // B. Animasi (genre 16 + non-Jepang)
      final animasiEn = Drama.fromTmdbJson({
        'id': 2002,
        'title': 'Spider-Man: Across the Spider-Verse',
        'release_date': '2023-06-02',
        'genre_ids': [16, 12],
        'original_language': 'en',
        'media_type': 'movie',
      });
      expect(Drama.getCategoryLabel(drama: animasiEn), equals('Animasi'));

      // C. TV / Serial:
      // ko -> Drama Korea
      final kdrama = Drama.fromTmdbJson({
        'id': 2003,
        'name': 'Queen of Tears',
        'first_air_date': '2024-03-09',
        'original_language': 'ko',
        'media_type': 'tv',
      });
      expect(Drama.getCategoryLabel(drama: kdrama), equals('Drama Korea'));

      // zh -> Drama China
      final cdrama = Drama.fromTmdbJson({
        'id': 2004,
        'name': 'Hidden Love',
        'first_air_date': '2023-06-20',
        'original_language': 'zh',
        'media_type': 'tv',
      });
      expect(Drama.getCategoryLabel(drama: cdrama), equals('Drama China'));

      // ja (non-animasi) -> Drama Jepang
      final jdrama = Drama.fromTmdbJson({
        'id': 2005,
        'name': 'Alice in Borderland',
        'first_air_date': '2020-12-10',
        'original_language': 'ja',
        'media_type': 'tv',
      });
      expect(Drama.getCategoryLabel(drama: jdrama), equals('Drama Jepang'));

      // en -> Drama Barat
      final wdrama = Drama.fromTmdbJson({
        'id': 2006,
        'name': 'Succession',
        'first_air_date': '2018-06-03',
        'original_language': 'en',
        'media_type': 'tv',
      });
      expect(Drama.getCategoryLabel(drama: wdrama), equals('Drama Barat'));

      // Lainnya -> Serial TV
      final otherTv = Drama.fromTmdbJson({
        'id': 2007,
        'name': 'Dark',
        'first_air_date': '2017-12-01',
        'original_language': 'de',
        'media_type': 'tv',
      });
      expect(Drama.getCategoryLabel(drama: otherTv), equals('Serial TV'));

      // D. Film:
      // ko -> Film Korea
      final kmovie = Drama.fromTmdbJson({
        'id': 2008,
        'title': 'Exhuma',
        'release_date': '2024-02-22',
        'original_language': 'ko',
        'media_type': 'movie',
      });
      expect(Drama.getCategoryLabel(drama: kmovie), equals('Film Korea'));

      // id -> Film Indonesia
      final idmovie = Drama.fromTmdbJson({
        'id': 2009,
        'title': 'Agak Laen',
        'release_date': '2024-02-01',
        'original_language': 'id',
        'media_type': 'movie',
      });
      expect(Drama.getCategoryLabel(drama: idmovie), equals('Film Indonesia'));

      // ja -> Film Jepang
      final jmovie = Drama.fromTmdbJson({
        'id': 2010,
        'title': 'Godzilla Minus One',
        'release_date': '2023-11-03',
        'original_language': 'ja',
        'media_type': 'movie',
      });
      expect(Drama.getCategoryLabel(drama: jmovie), equals('Film Jepang'));

      // en -> Film Barat
      final wmovie = Drama.fromTmdbJson({
        'id': 2011,
        'title': 'Oppenheimer',
        'release_date': '2023-07-21',
        'original_language': 'en',
        'media_type': 'movie',
      });
      expect(Drama.getCategoryLabel(drama: wmovie), equals('Film Barat'));

      // Lainnya -> Film
      final otherMovie = Drama.fromTmdbJson({
        'id': 2012,
        'title': 'Anatomy of a Fall',
        'release_date': '2023-08-23',
        'original_language': 'fr',
        'media_type': 'movie',
      });
      expect(Drama.getCategoryLabel(drama: otherMovie), equals('Film'));
    });

    testWidgets('2. Subtitle kartu di SearchPage menampilkan format Kategori • Tahun secara akurat', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'page': 1,
            'results': [
              {
                'id': 3001,
                'name': 'Demon Slayer',
                'first_air_date': '2019-04-06',
                'genre_ids': [16],
                'original_language': 'ja',
                'media_type': 'tv',
                'vote_average': 8.7,
              },
              {
                'id': 3002,
                'name': 'Squid Game',
                'first_air_date': '2021-09-17',
                'genre_ids': [18],
                'original_language': 'ko',
                'media_type': 'tv',
                'vote_average': 8.5,
              },
              {
                'id': 3003,
                'title': 'The Raid',
                'release_date': '2011-09-08',
                'genre_ids': [28],
                'original_language': 'id',
                'media_type': 'movie',
                'vote_average': 7.5,
              },
            ]
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final mockApi = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: SearchPage(apiService: mockApi),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi format Kategori • Tahun
      expect(find.text('Anime • 2019'), findsOneWidget);
      expect(find.text('Drama Korea • 2021'), findsOneWidget);
      expect(find.text('Film Indonesia • 2011'), findsOneWidget);
    });

    testWidgets('3. Ikon tombol aksi berubah dinamis: Icons.edit_outlined saat ada di Watchlist dan Icons.add saat belum', (tester) async {
      // Simulasikan drama di Watchlist user dengan ID 4001
      final savedWatchlistDrama = Drama(
        id: 4001,
        title: 'Already Saved Drama',
        koreanTitle: '',
        genre: 'Drama Korea',
        rating: 9.0,
        episodes: 16,
        watchedEpisodes: 8,
        status: 'Sedang Menonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2023',
        image: '',
        rank: '#1',
        popularity: '100',
        watchers: '10K',
        synopsis: '',
        aired: '2023',
        duration: '60 menit',
        contentRating: '15+',
        genresList: [],
        tagsList: [],
      );

      SharedData.dramaListNotifier.value = [savedWatchlistDrama];

      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'page': 1,
            'results': [
              {
                'id': 4001, // SUDAH ADA di watchlist (id cocok)
                'name': 'Already Saved Drama',
                'first_air_date': '2023-01-01',
                'vote_average': 9.0,
                'media_type': 'tv',
                'original_language': 'ko',
              },
              {
                'id': 4002, // BELUM ADA di watchlist
                'name': 'New Unsaved Drama',
                'first_air_date': '2024-01-01',
                'vote_average': 8.0,
                'media_type': 'tv',
                'original_language': 'ko',
              },
            ]
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final mockApi = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: SearchPage(apiService: mockApi),
        ),
      );
      await tester.pumpAndSettle();

      // Ikon pensil untuk film yang sudah ada di Watchlist
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      // Ikon tambah (+) untuk film yang belum ada di Watchlist
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    test('3b. Drama.fromSupabase memetakan drama_id / tmdb_id bertipe num maupun String dengan aman', () {
      final fromInt = Drama.fromSupabase({
        'drama_id': 5001,
        'title': 'Int ID Drama',
        'status': 'Sedang Menonton',
      });
      expect(fromInt.id, equals(5001));

      final fromString = Drama.fromSupabase({
        'drama_id': '5002',
        'title': 'String ID Drama',
        'status': 'Sedang Menonton',
      });
      expect(fromString.id, equals(5002));

      final fromTmdbId = Drama.fromSupabase({
        'tmdb_id': 5003,
        'title': 'Tmdb ID Drama',
        'status': 'Sedang Menonton',
      });
      expect(fromTmdbId.id, equals(5003));
    });
  });
}

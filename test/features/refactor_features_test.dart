import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tugas_pbp/services/api_service.dart';
import 'package:tugas_pbp/screens/detail_page.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/screens/search_page.dart';
import 'package:tugas_pbp/data/shared_data.dart';

void main() {
  group('1. Pemisahan Logika Film (Movie) dan Drama (TV)', () {
    test('Model Drama menyimpan dan membedakan mediaType movie vs tv', () {
      final movie = Drama(
        title: 'Parasite',
        koreanTitle: '기생충',
        genre: 'Film, Thriller',
        rating: 8.6,
        episodes: 1,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2019',
        image: 'https://example.com/parasite.jpg',
        rank: '#1',
        popularity: '#1',
        watchers: '500K',
        synopsis: 'Kisah keluarga Kim.',
        aired: '2019',
        duration: '132m',
        contentRating: '18+',
        genresList: ['Thriller'],
        tagsList: ['Award Winning'],
        mediaType: 'movie',
      );

      final tv = Drama(
        title: 'Goblin',
        koreanTitle: '도깨비',
        genre: 'Drama, Fantasy',
        rating: 8.8,
        episodes: 16,
        watchedEpisodes: 4,
        status: 'Sedang Menonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2016',
        image: 'https://example.com/goblin.jpg',
        rank: '#2',
        popularity: '#3',
        watchers: '400K',
        synopsis: 'Kisah Goblin abadi.',
        aired: '2016',
        duration: '75m',
        contentRating: '15+',
        genresList: ['Fantasy'],
        tagsList: ['Romance'],
        mediaType: 'tv',
      );

      expect(movie.mediaType, 'movie');
      expect(movie.isMovie, isTrue);

      expect(tv.mediaType, 'tv');
      expect(tv.isMovie, isFalse);
    });

    testWidgets('EditDramaModal menyembunyikan input episode jika mediaType == movie',
        (tester) async {
      final movie = Drama(
        title: 'Interstellar',
        koreanTitle: '',
        genre: 'Film, Sci-Fi',
        rating: 8.7,
        episodes: 1,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2014',
        image: '',
        rank: '#3',
        popularity: '#2',
        watchers: '800K',
        synopsis: 'Perjalanan luar angkasa.',
        aired: '2014',
        duration: '169m',
        contentRating: '13+',
        genresList: ['Sci-Fi'],
        tagsList: ['Space'],
        mediaType: 'movie',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditDramaModal(drama: movie),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Episode stepper (+ / -) dan teks EPISODE tidak boleh muncul untuk Film
      expect(find.text('EPISODE'), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byIcon(Icons.remove), findsNothing);

      // Tab UMUM dan Slider rating tetap muncul
      expect(find.text('UMUM'), findsOneWidget);
      expect(find.text('Peringkat'), findsOneWidget);
    });
  });

  group('2. Warna Kotak Rating Dinamis (Dynamic Colors)', () {
    test('getRatingColor mengembalikan palet warna sesuai spesifikasi', () {
      expect(getRatingColor(9.0), Colors.green.shade700);
      expect(getRatingColor(8.5), Colors.green.shade700);

      expect(getRatingColor(8.0), const Color(0xFF0094FF));
      expect(getRatingColor(7.5), const Color(0xFF0094FF));

      expect(getRatingColor(7.0), const Color(0xFFF57C00));
      expect(getRatingColor(6.0), const Color(0xFFF57C00));

      expect(getRatingColor(5.9), const Color(0xFFD32F2F));
      expect(getRatingColor(3.2), const Color(0xFFD32F2F));
    });
  });

  group('3. Perluasan ApiService (Filter Kategori & Negara)', () {
    test('ApiService memanggil endpoint kategori dan membatasi jumlah item',
        () async {
      final mockClient = MockClient((request) async {
        final path = request.url.path;
        final query = request.url.queryParameters;

        if (path.contains('/trending/all/day')) {
          return http.Response(
            json.encode({
              'page': 1,
              'results': List.generate(
                10,
                (i) => {
                  'id': 1000 + i,
                  'title': 'Trending $i',
                  'media_type': 'movie',
                  'vote_average': 8.0,
                },
              ),
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (path.contains('/discover/movie') &&
            query['with_original_language'] == 'ko') {
          return http.Response(
            json.encode({
              'page': 1,
              'results': List.generate(
                15,
                (i) => {
                  'id': 2000 + i,
                  'title': 'Korean Movie $i',
                  'vote_average': 8.2,
                },
              ),
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (path.contains('/movie/999/credits')) {
          return http.Response(
            json.encode({
              'id': 999,
              'cast': [
                {
                  'id': 501,
                  'name': 'Song Kang-ho',
                  'character': 'Kim Ki-taek',
                  'profile_path': '/song.jpg',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        return http.Response(
          json.encode({'page': 1, 'results': []}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = ApiService(client: mockClient);

      // getTrendingAllMix dibatasi maksimal 20 item (pada mock 10 item)
      final mix = await service.getTrendingAllMix();
      expect(mix.length, 10);

      // getKoreanMovies dibatasi maksimal 20 item (pada mock 15 item)
      final koreanMovies = await service.getKoreanMovies();
      expect(koreanMovies.length, 15);
      expect(koreanMovies.first.genre, 'Film Korea');

      // getMediaCredits mengambil daftar aktor
      final cast = await service.getMediaCredits(999, mediaType: 'movie');
      expect(cast.length, 1);
      expect(cast.first.title, 'Song Kang-ho');
      expect(cast.first.character, 'Kim Ki-taek');
    });
  });

  group('4 & 6. Sorting Fitur Dropdown di SearchPage', () {
    testWidgets('Dropdown sorting mengurutkan daftar secara lokal',
        (tester) async {
      final d1 = Drama(
        title: 'Drama Rendah',
        koreanTitle: '',
        genre: 'Drama',
        rating: 5.0,
        episodes: 16,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Rendah',
        startDate: '',
        endDate: '',
        date: '2020',
        image: '',
        rank: '#10',
        popularity: '#50',
        watchers: '10K',
        synopsis: '',
        aired: '',
        duration: '',
        contentRating: '',
        genresList: [],
        tagsList: [],
      );

      final d2 = Drama(
        title: 'Drama Tinggi',
        koreanTitle: '',
        genre: 'Drama',
        rating: 9.5,
        episodes: 16,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2022',
        image: '',
        rank: '#1',
        popularity: '#2',
        watchers: '900K',
        synopsis: '',
        aired: '',
        duration: '',
        contentRating: '',
        genresList: [],
        tagsList: [],
      );

      SharedData.dramaListNotifier.value = [d1, d2];

      final mockService = ApiService(
        client: MockClient(
          (req) async => http.Response(
            json.encode({'page': 1, 'results': []}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SearchPage(apiService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      final finderTinggi = find.text('Drama Tinggi');
      final finderRendah = find.text('Drama Rendah');
      expect(finderTinggi, findsOneWidget);
      expect(finderRendah, findsOneWidget);

      // Buka modal bottom sheet sorting menggunakan Icons.swap_vert
      await tester.tap(find.byIcon(Icons.swap_vert).first);
      await tester.pumpAndSettle();

      expect(find.text('Urutkan Berdasarkan'), findsOneWidget);
      expect(find.text('Paling Populer'), findsOneWidget);
      expect(find.text('Peringkat Teratas'), findsOneWidget);
      expect(find.text('Tahun Rilis'), findsOneWidget);

      // Pilih 'Peringkat Teratas'
      await tester.tap(find.text('Peringkat Teratas'));
      await tester.pumpAndSettle();

      // Klik 'Terapkan'
      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();

      // Setelah 'Peringkat Teratas' diterapkan, Drama Tinggi (rating 9.5) harus di atas Drama Rendah (rating 5.0)
      final tinggiTopAfter = tester.getTopLeft(finderTinggi).dy;
      final rendahTopAfter = tester.getTopLeft(finderRendah).dy;
      expect(tinggiTopAfter < rendahTopAfter, isTrue);
    });

    testWidgets('Filter kategori via Icons.tune menyaring daftar sesuai kategori yang dipilih',
        (tester) async {
      final dMovie = Drama(
        title: 'Film A',
        koreanTitle: '',
        genre: 'Film',
        rating: 8.0,
        episodes: 1,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2023',
        image: '',
        rank: '#1',
        popularity: '#1',
        watchers: '100K',
        synopsis: '',
        aired: '',
        duration: '',
        contentRating: '',
        genresList: [],
        tagsList: [],
        mediaType: 'movie',
      );

      final dDrama = Drama(
        title: 'Drama B',
        koreanTitle: '',
        genre: 'Drama Korea',
        rating: 8.5,
        episodes: 16,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2023',
        image: '',
        rank: '#2',
        popularity: '#2',
        watchers: '200K',
        synopsis: '',
        aired: '',
        duration: '',
        contentRating: '',
        genresList: [],
        tagsList: [],
        mediaType: 'tv',
      );

      SharedData.dramaListNotifier.value = [dMovie, dDrama];

      final mockService = ApiService(
        client: MockClient(
          (req) async => http.Response(
            json.encode({'page': 1, 'results': []}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SearchPage(apiService: mockService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Film A'), findsOneWidget);
      expect(find.text('Drama B'), findsOneWidget);

      // Buka modal bottom sheet filter kategori menggunakan Icons.tune
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Kategori'), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Film'), findsOneWidget);
      expect(find.text('Drama'), findsOneWidget);
      expect(find.text('Anime'), findsOneWidget);

      // Pilih 'Film'
      await tester.tap(find.text('Film'));
      await tester.pumpAndSettle();

      // Klik 'Terapkan'
      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();

      // Hanya Film A yang tampil, Drama B disaring keluar
      expect(find.text('Film A'), findsOneWidget);
      expect(find.text('Drama B'), findsNothing);
    });
  });
}

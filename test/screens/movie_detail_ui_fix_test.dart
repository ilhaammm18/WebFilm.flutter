import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tugas_pbp/data/shared_data.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/screens/detail_page.dart';
import 'package:tugas_pbp/services/api_service.dart';

void main() {
  setUp(() {
    SharedData.dramaListNotifier.value = [];
  });

  group('DetailPage / MovieDetailPage Revamped UI Tests', () {
    testWidgets('Subtitle HANYA genre, 3 kolom statistik, Tempat Menonton, Pemeran, Tim, dan FAB', (tester) async {
      final sampleMovie = Drama(
        id: 999,
        title: 'Superman',
        koreanTitle: 'Superman',
        mediaType: 'movie',
        genre: 'Film',
        date: '2026-07-29',
        rating: 8.5,
        episodes: 1,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Sedang',
        startDate: '',
        endDate: '',
        image: '',
        rank: '#1',
        popularity: '500',
        watchers: '1200',
        synopsis: 'Kisah manusia baja yang berjuang demi kebenaran dan keadilan.',
        aired: '2026-07-29',
        duration: '130 menit',
        runtime: 130,
        contentRating: '13+',
        genresList: ['Action', 'Sci-Fi'],
        tagsList: ['Superhero'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DetailPage(
            movie: sampleMovie,
          ),
        ),
      );
      await tester.pump();

      // 1. Verifikasi judul utama
      final titleFinder = find.text('Superman');
      expect(titleFinder, findsOneWidget);

      // 2. Verifikasi subtitle: HANYA menampilkan nama genre/kategori filmnya
      expect(find.text('Action, Sci-Fi'), findsOneWidget);

      // 3. Verifikasi 3 Kotak Statistik:
      // a. Kolom 1 (Kiri): 'Tanggal Rilis' dengan ikon kalender
      expect(find.text('Tanggal Rilis'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.text('2026-07-29'), findsOneWidget);

      // b. Kolom 2 (Tengah): 'Durasi' dengan ikon jam dan format jam & menit
      expect(find.text('Durasi'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
      expect(find.text('2j 10m'), findsOneWidget);

      // c. Kolom 3 (Kanan): 'Kepopuleran' dengan nilai popularity murni
      expect(find.text('Kepopuleran'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.text('500'), findsOneWidget);

      // 4. Verifikasi Sinopsis
      expect(find.text('Sinopsis'), findsOneWidget);
      expect(
        find.text('Kisah manusia baja yang berjuang demi kebenaran dan keadilan.'),
        findsOneWidget,
      );

      // 5. Verifikasi Bagian Bawah:
      // a. Tempat Menonton
      expect(find.text('Tempat Menonton'), findsOneWidget);

      // b. Pemeran dengan badge 'Peran Utama'
      expect(find.text('Pemeran'), findsWidgets);
      expect(find.text('Peran Utama'), findsWidgets);

      // c. Tim dengan badge pekerjaan
      expect(find.text('Tim'), findsWidgets);

      // d. Tombol 'Lihat Semua' pada header Pemeran & Tim
      expect(find.text('Lihat Semua'), findsNWidgets(2));

      // e. Keterangan tipe platform di card Tempat Menonton (dummy = flatrate)
      expect(find.text('Langganan'), findsWidgets);

      // 6. Verifikasi Floating Action Button (ikon plus)
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);
      expect(
        find.descendant(of: fabFinder, matching: find.byIcon(Icons.add)),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.bookmark_add), findsNothing);
      final FloatingActionButton fab = tester.widget(fabFinder);
      expect(fab.backgroundColor, const Color(0xFF0094FF));
    });

    testWidgets('Integrasi API TMDB (fetchMovieDetails) memanggil 3 endpoint sekaligus', (tester) async {
      bool detailsCalled = false;
      bool creditsCalled = false;
      bool providersCalled = false;

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        if (path.contains('/movie/550/watch/providers')) {
          providersCalled = true;
          return http.Response(
            json.encode({
              'id': 550,
              'results': {
                'ID': {
                  'flatrate': [
                    {
                      'provider_id': 8,
                      'provider_name': 'Netflix',
                      'logo_path': null,
                    }
                  ],
                  'free': [
                    {
                      'provider_id': 999,
                      'provider_name': 'Plex',
                      'logo_path': null,
                    }
                  ]
                }
              }
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (path.contains('/movie/550/credits')) {
          creditsCalled = true;
          return http.Response(
            json.encode({
              'id': 550,
              'cast': [
                {
                  'id': 101,
                  'name': 'Edward Norton',
                  'character': 'The Narrator',
                  'profile_path': null,
                }
              ],
              'crew': [
                {
                  'id': 202,
                  'name': 'David Fincher',
                  'job': 'Sutradara',
                  'department': 'Directing',
                  'profile_path': null,
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (path.contains('/movie/550')) {
          detailsCalled = true;
          return http.Response(
            json.encode({
              'id': 550,
              'title': 'Fight Club',
              'overview': 'A ticking-time-bomb insomniac and a slippery soap salesman...',
              'runtime': 139,
              'release_date': '1999-10-15',
              'vote_average': 8.4,
              'genres': [
                {'id': 18, 'name': 'Action'}
              ]
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final mockApiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: DetailPage(
            movieId: 550,
            apiService: mockApiService,
          ),
        ),
      );

      // Loading state awal menampilkan CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Memastikan 3 endpoint terpanggil
      expect(detailsCalled, isTrue);
      expect(creditsCalled, isTrue);
      expect(providersCalled, isTrue);

      // Data dari TMDB tampil di layar
      expect(find.text('Fight Club'), findsOneWidget);
      expect(find.text('Action'), findsWidgets);
      expect(find.text('1999-10-15'), findsOneWidget);
      expect(find.text('2j 19m'), findsOneWidget);
      expect(find.text('Edward Norton'), findsOneWidget);
      expect(find.text('The Narrator'), findsOneWidget);
      expect(find.text('David Fincher'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Langganan'), findsOneWidget);
      expect(find.text('Plex'), findsOneWidget);
      expect(find.text('Gratis'), findsOneWidget);

      // 'Lihat Semua' pada Tim membuka FullCreditsPage daftar lengkap
      await tester.ensureVisible(find.text('Lihat Semua').last);
      await tester.tap(find.text('Lihat Semua').last);
      await tester.pumpAndSettle();
      expect(find.text('Semua Tim Kru'), findsOneWidget);
      expect(find.text('David Fincher'), findsOneWidget);
    });

    testWidgets('Kondisi error menampilkan pesan error dan tombol coba lagi', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final mockApiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: DetailPage(
            movieId: 12345,
            apiService: mockApiService,
          ),
        ),
      );

      // Awalnya loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Menampilkan pesan error dan tombol coba lagi
      expect(find.text('Gagal memuat detail film'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('Tempat Menonton card dan teks responsif terhadap Light Mode dan Dark Mode', (tester) async {
      final sampleDrama = Drama(
        id: 777,
        title: 'Sample Movie',
        koreanTitle: '',
        genre: 'Action',
        date: '2023',
        rating: 8.5,
        episodes: 1,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Sedang',
        startDate: '',
        endDate: '',
        image: 'https://image.tmdb.org/t/p/w500/sample.jpg',
        rank: '#1',
        popularity: '100',
        watchers: '500',
        synopsis: 'Deskripsi sample movie',
        aired: '2023',
        duration: '120m',
        contentRating: '13+',
        genresList: ['Action'],
        tagsList: ['TMDB'],
      );

      // 1. Light Mode
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.light,
            cardColor: const Color(0xFFFFFFFF),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Color(0xFF111111)),
              bodySmall: TextStyle(color: Color(0xFF777777)),
            ),
          ),
          home: DetailPage(
            movie: sampleDrama,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Card Tempat Menonton di Light Mode
      final Material netflixCard = tester.widget<Material>(
        find.ancestor(
          of: find.text('Netflix'),
          matching: find.byType(Material),
        ).first,
      );
      expect(netflixCard.color, equals(const Color(0xFFFFFFFF)));

      final Text netflixText = tester.widget(find.text('Netflix'));
      expect(netflixText.style?.color, equals(const Color(0xFF111111)));

      // 2. Dark Mode
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            cardColor: const Color(0xFF1B2335),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Color(0xFFEEEEEE)),
              bodySmall: TextStyle(color: Color(0xFF888888)),
            ),
          ),
          home: DetailPage(
            key: const Key('dark_detail'),
            movie: sampleDrama,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final Material netflixCardDark = tester.widget<Material>(
        find.ancestor(
          of: find.text('Netflix'),
          matching: find.byType(Material),
        ).first,
      );
      expect(netflixCardDark.color, equals(const Color(0xFF1B2335)));

      final Text netflixTextDark = tester.widget(find.text('Netflix'));
      expect(netflixTextDark.style?.color, equals(const Color(0xFFEEEEEE)));
    });
  });
}

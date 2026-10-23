import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tugas_pbp/screens/decade_explore_page.dart';
import 'package:tugas_pbp/screens/explore_tab.dart';
import 'package:tugas_pbp/services/api_service.dart';

void main() {
  group('Filter Berdasarkan Tahun Spesifik & Genre Carousels Tests', () {
    test('getMoviesByYear memanggil /discover/movie dengan parameter primary_release_year', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/3/discover/movie');
        expect(request.url.queryParameters['primary_release_year'], '2025');
        return http.Response(
          json.encode({
            'page': 1,
            'results': [
              {
                'id': 20251,
                'title': 'Film Rilis 2025',
                'release_date': '2025-06-15',
                'vote_average': 8.3,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final movies = await apiService.getMoviesByYear(year: 2025);

      expect(movies.length, 1);
      expect(movies.first.title, 'Film Rilis 2025');
      expect(movies.first.releaseDate, '2025-06-15');
    });

    test('getTvShowsByYear memanggil /discover/tv dengan parameter first_air_date_year', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/3/discover/tv');
        expect(request.url.queryParameters['first_air_date_year'], '2024');
        return http.Response(
          json.encode({
            'page': 1,
            'results': [
              {
                'id': 20242,
                'name': 'Serial TV 2024',
                'first_air_date': '2024-04-10',
                'vote_average': 8.6,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final tvShows = await apiService.getTvShowsByYear(year: 2024);

      expect(tvShows.length, 1);
      expect(tvShows.first.title, 'Serial TV 2024');
      expect(tvShows.first.genre, 'Drama');
    });

    test('getPopularHorrorMovies memanggil /discover/movie dengan with_genres=27', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/3/discover/movie');
        expect(request.url.queryParameters['with_genres'], '27');
        return http.Response(
          json.encode({
            'page': 1,
            'results': [
              {
                'id': 2701,
                'title': 'The Conjuring Test',
                'vote_average': 7.8,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final movies = await apiService.getPopularHorrorMovies();

      expect(movies.length, 1);
      expect(movies.first.title, 'The Conjuring Test');
      expect(movies.first.genre, 'Horor');
    });

    test('getPopularThrillerMovies memanggil /discover/movie dengan with_genres=53', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/3/discover/movie');
        expect(request.url.queryParameters['with_genres'], '53');
        return http.Response(
          json.encode({
            'page': 1,
            'results': [
              {
                'id': 5301,
                'title': 'Se7en Test',
                'vote_average': 8.6,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final movies = await apiService.getPopularThrillerMovies();

      expect(movies.length, 1);
      expect(movies.first.title, 'Se7en Test');
      expect(movies.first.genre, 'Thriller');
    });

    test('getPopularSciFiMovies memanggil /discover/movie dengan with_genres=878', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/3/discover/movie');
        expect(request.url.queryParameters['with_genres'], '878');
        return http.Response(
          json.encode({
            'page': 1,
            'results': [
              {
                'id': 8781,
                'title': 'Interstellar Test',
                'vote_average': 8.9,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final movies = await apiService.getPopularSciFiMovies();

      expect(movies.length, 1);
      expect(movies.first.title, 'Interstellar Test');
      expect(movies.first.genre, 'Sci-Fi');
    });

    test('getPopularHorrorMovies memanggil /discover/movie dengan with_genres=27 dan primary_release_year jika year diberikan', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/3/discover/movie');
        expect(request.url.queryParameters['with_genres'], '27');
        expect(request.url.queryParameters['primary_release_year'], '2024');
        return http.Response(
          json.encode({
            'page': 1,
            'results': [
              {
                'id': 2702,
                'title': 'Horror 2024',
                'vote_average': 7.9,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final movies = await apiService.getPopularHorrorMovies(year: 2024);

      expect(movies.length, 1);
      expect(movies.first.title, 'Horror 2024');
    });

    testWidgets('ExploreTab bersih dari genre carousels, Segera Hadir di atas Dekade, dan Genre Carousels berada di DecadeExplorePage', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/discover/movie')) {
          final genres = request.url.queryParameters['with_genres'];
          final year = request.url.queryParameters['primary_release_year'];

          if (genres == '27') {
            return http.Response(
              json.encode({
                'page': 1,
                'results': [
                  {
                    'id': 1001,
                    'title': 'Film Horor Seram',
                    'poster_path': '/horror.jpg',
                    'vote_average': 8.0,
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          } else if (genres == '53') {
            return http.Response(
              json.encode({
                'page': 1,
                'results': [
                  {
                    'id': 1002,
                    'title': 'Film Thriller Menegangkan',
                    'poster_path': '/thriller.jpg',
                    'vote_average': 8.4,
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          } else if (genres == '878') {
            return http.Response(
              json.encode({
                'page': 1,
                'results': [
                  {
                    'id': 1003,
                    'title': 'Film Sci-Fi Masa Depan',
                    'poster_path': '/scifi.jpg',
                    'vote_average': 8.8,
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          } else if (genres == null && year == '2023') {
            return http.Response(
              json.encode({
                'page': 1,
                'results': [
                  {
                    'id': 1004,
                    'title': 'Film Rilis 2023',
                    'poster_path': '/2023.jpg',
                    'vote_average': 8.5,
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
        }

        if (request.url.path.contains('/movie/upcoming') ||
            (request.url.path.contains('/discover/movie') &&
                request.url.queryParameters['sort_by'] == 'primary_release_date.asc')) {
          return http.Response(
            json.encode({
              'page': 1,
              'results': [
                {
                  'id': 20261,
                  'title': 'Upcoming Film 2026',
                  'release_date': '2026-12-01',
                  'vote_average': 0.0,
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

      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExploreTab(apiService: apiService),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verifikasi judul seksi dekade dan posisi Segera Hadir di atas Jelajahi Berdasarkan Dekade
      expect(find.text('Segera Hadir'), findsOneWidget);
      expect(find.text('Jelajahi Berdasarkan Dekade'), findsOneWidget);

      final segeraHadirY = tester.getTopLeft(find.text('Segera Hadir')).dy;
      final dekadeY = tester.getTopLeft(find.text('Jelajahi Berdasarkan Dekade')).dy;
      expect(segeraHadirY < dekadeY, isTrue);

      // 2. Verifikasi genre carousels TIDAK ADA di ExploreTab
      expect(find.text('Populer di Horor'), findsNothing);
      expect(find.text('Populer di Thriller'), findsNothing);
      expect(find.text('Sci-Fi & Fantasi'), findsNothing);

      // 3. Verifikasi deretan tombol chip dekade TANPA ikon kalender
      expect(find.text('2020s'), findsOneWidget);
      expect(find.text('2010s'), findsOneWidget);
      expect(find.text('2000s'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_rounded), findsNothing);

      // 4. Buka DecadeExplorePage dengan mengetuk chip dekade 2020s
      await tester.tap(find.text('2020s'));
      await tester.pumpAndSettle();

      expect(find.byType(DecadeExplorePage), findsOneWidget);
      expect(find.text('Film Dekade 2020s'), findsOneWidget);

      // 5. Verifikasi baris 'Populer di [Tahun]' berada di posisi paling atas dan genre carousels
      expect(find.text('Populer di 2020s'), findsOneWidget);
      expect(find.text('Populer di Horor'), findsOneWidget);
      expect(find.text('Populer di Thriller'), findsOneWidget);
      expect(find.text('Sci-Fi & Fantasi'), findsOneWidget);

      // Verifikasi item film genre muncul di UI DecadeExplorePage
      expect(find.text('Film Horor Seram'), findsOneWidget);
      expect(find.text('Film Thriller Menegangkan'), findsOneWidget);
      expect(find.text('Film Sci-Fi Masa Depan'), findsOneWidget);

      // 6. Verifikasi HAPUS Grid 'Semua Film' vertikal (murni hanya deretan carousel horizontal)
      expect(find.textContaining('Semua Film'), findsNothing);
      expect(find.byType(GridView), findsNothing);

      // 7. Verifikasi horizontal list tahun-tahun spesifik di dalam DecadeExplorePage (2026, 2025... 2020)
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('2025'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
      expect(find.text('2023'), findsOneWidget);
      expect(find.text('2020'), findsWidgets);

      // 8. Klik tahun spesifik 2023 memicu fetch dengan parameter primary_release_year dan judul dinamis 'Populer di 2023'
      await tester.tap(find.text('2023'));
      await tester.pumpAndSettle();

      expect(find.text('Populer di 2023'), findsOneWidget);
      expect(find.text('Film Rilis 2023'), findsOneWidget);
    });
  });
}

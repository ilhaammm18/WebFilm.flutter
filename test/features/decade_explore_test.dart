import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:tugas_pbp/screens/decade_explore_page.dart';
import 'package:tugas_pbp/screens/explore_tab.dart';
import 'package:tugas_pbp/services/api_service.dart';

void main() {
  group('ApiService Decade & New Endpoints Tests', () {
    test('getTrendingAllWeek memanggil /trending/all/week', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/3/trending/all/week');
        return http.Response(
          json.encode({
            'page': 1,
            'results': [
              {
                'id': 101,
                'title': 'Weekly Movie',
                'media_type': 'movie',
                'vote_average': 8.8,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final movies = await apiService.getTrendingAllWeek();
      expect(movies.length, 1);
      expect(movies.first.title, 'Weekly Movie');
      expect(movies.first.rating, 8.8);
    });

    test('getTopRatedMovies memanggil /movie/top_rated tanpa genreId', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/3/movie/top_rated');
        return http.Response(
          json.encode({
            'page': 1,
            'results': [
              {
                'id': 201,
                'title': 'Top Rated Film',
                'vote_average': 9.3,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final movies = await apiService.getTopRatedMovies();
      expect(movies.length, 1);
      expect(movies.first.title, 'Top Rated Film');
      expect(movies.first.rating, 9.3);
    });

    test('getTopRatedMovies memanggil /discover/movie jika ada genreId', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/3/discover/movie');
        expect(request.url.queryParameters['with_genres'], '28');
        expect(request.url.queryParameters['sort_by'], 'vote_average.desc');
        return http.Response(
          json.encode({
            'page': 1,
            'results': [
              {
                'id': 202,
                'title': 'Top Action Film',
                'vote_average': 9.1,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final movies = await apiService.getTopRatedMovies(genreId: 28);
      expect(movies.length, 1);
      expect(movies.first.title, 'Top Action Film');
    });

    test('getMovieUpcoming memanggil /discover/movie', () async {
      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/3/discover/movie');
        expect(request.url.queryParameters['primary_release_date.gte'], todayStr);
        expect(request.url.queryParameters['sort_by'], 'primary_release_date.asc');
        return http.Response(
          json.encode({
            'page': 1,
            'results': [
              {
                'id': 301,
                'title': 'Upcoming Film 2027',
                'release_date': '2027-05-10',
                'vote_average': 0.0,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final movies = await apiService.getMovieUpcoming();
      expect(movies.length, 1);
      expect(movies.first.title, 'Upcoming Film 2027');
      expect(movies.first.releaseDate, '2027-05-10');
    });

    test('getMoviesByDecade memanggil /discover/movie dengan primary_release_date.gte dan lte', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/3/discover/movie');
        expect(request.url.queryParameters['primary_release_date.gte'], '1990-01-01');
        expect(request.url.queryParameters['primary_release_date.lte'], '1999-12-31');
        return http.Response(
          json.encode({
            'page': 1,
            'results': [
              {
                'id': 901,
                'title': 'Pulp Fiction',
                'release_date': '1994-10-14',
                'vote_average': 8.5,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final movies = await apiService.getMoviesByDecade(decade: '1990s');
      expect(movies.length, 1);
      expect(movies.first.title, 'Pulp Fiction');
      expect(movies.first.releaseDate, '1994-10-14');
    });
  });

  group('DecadeExplorePage Widget Tests', () {
    testWidgets('DecadeExplorePage menampilkan judul dekade, rentang tanggal, dan grid film', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/discover/movie')) {
          if (request.url.queryParameters.containsKey('with_genres')) {
            return http.Response(json.encode({'page': 1, 'results': []}), 200);
          }
          expect(request.url.queryParameters['primary_release_date.gte'], '1980-01-01');
          expect(request.url.queryParameters['primary_release_date.lte'], '1989-12-31');
          return http.Response(
            json.encode({
              'page': 1,
              'results': [
                {
                  'id': 801,
                  'title': 'The Shining',
                  'poster_path': '/shining.jpg',
                  'vote_average': 8.2,
                  'release_date': '1980-05-23',
                },
                {
                  'id': 802,
                  'title': 'Blade Runner',
                  'poster_path': '/bladerunner.jpg',
                  'vote_average': 8.1,
                  'release_date': '1982-06-25',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(json.encode({'page': 1, 'results': []}), 200);
      });

      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: DecadeExplorePage(
            decade: '1980s',
            apiService: apiService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memeriksa AppBar title dan rentang tanggal
      expect(find.text('Film Dekade 1980s'), findsOneWidget);
      expect(find.text('1980-01-01 s/d 1989-12-31'), findsOneWidget);

      // Memeriksa film dalam grid
      expect(find.text('The Shining'), findsOneWidget);
      expect(find.text('Blade Runner'), findsOneWidget);
      expect(find.text('8.2'), findsOneWidget);
      expect(find.text('8.1'), findsOneWidget);
      expect(find.text('1980'), findsWidgets);
      expect(find.text('1982'), findsWidgets);
    });

    testWidgets('ExploreTab: Mengetuk tombol chip dekade mengarahkan ke DecadeExplorePage dengan horizontal list tahun', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/discover/movie')) {
          if (request.url.queryParameters.containsKey('with_genres')) {
            return http.Response(json.encode({'page': 1, 'results': []}), 200);
          }
          final year = request.url.queryParameters['primary_release_year'];
          if (year == '2024') {
            return http.Response(
              json.encode({
                'page': 1,
                'results': [
                  {
                    'id': 20241,
                    'title': 'Dune: Part Two',
                    'poster_path': '/dune2.jpg',
                    'vote_average': 8.7,
                    'release_date': '2024-03-01',
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }

          return http.Response(
            json.encode({
              'page': 1,
              'results': [
                {
                  'id': 20201,
                  'title': 'Film Rilis 2020s Awal',
                  'poster_path': '/2020s.jpg',
                  'vote_average': 8.0,
                  'release_date': '2020-05-10',
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

      // 1. Verifikasi seksi dekade di ExploreTab
      expect(find.text('Jelajahi Berdasarkan Dekade'), findsOneWidget);
      expect(find.text('2020s'), findsOneWidget);

      // 2. Mengetuk chip dekade 2020s via Navigator.push
      await tester.tap(find.text('2020s'));
      await tester.pumpAndSettle();

      // 3. Terbuka DecadeExplorePage
      expect(find.byType(DecadeExplorePage), findsOneWidget);
      expect(find.text('Film Dekade 2020s'), findsOneWidget);

      // 4. Verifikasi horizontal list tahun-tahun spesifik di dalam DecadeExplorePage (Gaya Plex: 2026, 2025, 2024... 2020)
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('2025'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
      expect(find.text('2020'), findsWidgets);

      // 5. Mengetuk tahun spesifik 2024 untuk memanggil primary_release_year
      await tester.tap(find.text('2024'));
      await tester.pumpAndSettle();

      expect(find.text('Rilis Tahun 2024'), findsOneWidget);
      expect(find.text('Dune: Part Two'), findsOneWidget);
    });
  });
}

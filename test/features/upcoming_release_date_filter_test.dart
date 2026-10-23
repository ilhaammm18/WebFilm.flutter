import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tugas_pbp/screens/explore_tab.dart';
import 'package:tugas_pbp/services/api_service.dart';

void main() {
  group('TMDB Upcoming Release Date Filtering Tests', () {
    test('getMovieUpcoming memanggil /discover/movie dengan primary_release_date.gte dan sort_by primary_release_date.asc tanpa filtering manual', () async {
      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final futureDate = now.add(const Duration(days: 10));
      final futureStr =
          "${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}";

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/3/discover/movie');
        expect(request.url.queryParameters['primary_release_date.gte'], todayStr);
        expect(request.url.queryParameters['sort_by'], 'primary_release_date.asc');
        return http.Response(
          json.encode({
            'page': 1,
            'results': List.generate(
              20,
              (index) => {
                'id': 100 + index,
                'title': 'Upcoming Film $index',
                'release_date': futureStr,
                'vote_average': 8.0,
              },
            ),
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final movies = await apiService.getMovieUpcoming();

      // Memastikan 20 item dikembalikan secara utuh tanpa pemotongan manual di Dart
      expect(movies.length, 20);
      expect(movies.first.title, 'Upcoming Film 0');
      expect(movies.last.title, 'Upcoming Film 19');
    });

    test('getMovieUpcoming dengan useDiscover: true menyertakan parameter primary_release_date.gte tanggal hari ini dan sort_by primary_release_date.asc', () async {
      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final futureDate = now.add(const Duration(days: 14));
      final futureStr =
          "${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}";

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/3/discover/movie');
        expect(request.url.queryParameters['primary_release_date.gte'], todayStr);
        expect(request.url.queryParameters['sort_by'], 'primary_release_date.asc');
        return http.Response(
          json.encode({
            'page': 1,
            'results': [
              {
                'id': 201,
                'title': 'Discover Upcoming Film',
                'release_date': futureStr,
                'vote_average': 7.9,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final movies = await apiService.getMovieUpcoming(useDiscover: true);

      expect(movies.length, 1);
      expect(movies.first.title, 'Discover Upcoming Film');
      expect(movies.first.releaseDate, futureStr);
    });

    test('getUpcomingMovies menyertakan primary_release_date.gte dan first_air_date.gte tanggal hari ini pada /discover', () async {
      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final futureDate = now.add(const Duration(days: 20));
      final futureStr =
          "${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}";

      final mockClient = MockClient((request) async {
        if (request.url.path == '/3/discover/movie') {
          expect(request.url.queryParameters['primary_release_date.gte'], todayStr);
          return http.Response(
            json.encode({
              'page': 1,
              'results': [
                {
                  'id': 301,
                  'title': 'Upcoming Movie Discover',
                  'release_date': futureStr,
                  'vote_average': 8.1,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (request.url.path == '/3/discover/tv') {
          expect(request.url.queryParameters['first_air_date.gte'], todayStr);
          return http.Response(
            json.encode({
              'page': 1,
              'results': [
                {
                  'id': 302,
                  'name': 'Upcoming Drama TV',
                  'first_air_date': futureStr,
                  'vote_average': 8.3,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient);
      final upcoming = await apiService.getUpcomingMovies();

      expect(upcoming.length, 2);
      expect(upcoming.any((d) => d.title == 'Upcoming Movie Discover'), isTrue);
      expect(upcoming.any((d) => d.title == 'Upcoming Drama TV'), isTrue);
    });

    testWidgets('UI Segera Hadir pada ExploreTab menampilkan hasil dari discover/movie dengan daftar utuh', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final futureDate = now.add(const Duration(days: 30));
      final futureStr =
          "${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}";

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/discover/movie') &&
            request.url.queryParameters.containsKey('primary_release_date.gte')) {
          expect(request.url.queryParameters['primary_release_date.gte'], todayStr);
          expect(request.url.queryParameters['sort_by'], 'primary_release_date.asc');
          return http.Response(
            json.encode({
              'page': 1,
              'results': [
                {
                  'id': 702,
                  'title': 'Film Rilis Hari Ini',
                  'poster_path': '/today.jpg',
                  'release_date': todayStr,
                  'vote_average': 8.0,
                },
                {
                  'id': 703,
                  'title': 'Film Rilis Masa Depan',
                  'poster_path': '/future.jpg',
                  'release_date': futureStr,
                  'vote_average': 8.8,
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
          home: ExploreTab(apiService: apiService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Segera Hadir'), findsOneWidget);

      // Pastikan film rilis hari ini & masa depan ditampilkan di UI
      expect(find.text('Film Rilis Hari Ini'), findsOneWidget);
      expect(find.text(todayStr), findsOneWidget);
      expect(find.text('Film Rilis Masa Depan'), findsOneWidget);
      expect(find.text(futureStr), findsOneWidget);
    });
  });
}

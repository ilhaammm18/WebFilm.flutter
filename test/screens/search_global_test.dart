import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tugas_pbp/services/api_service.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/models/actor.dart';
import 'package:tugas_pbp/screens/search_page.dart';

void main() {
  group('Global TMDB Search API Tests (api_service.dart)', () {
    test('searchMovies memanggil /search/movie dengan query ter-encode dan tanpa filter wilayah/bahasa/genre', () async {
      String? calledUrl;
      final mockClient = MockClient((request) async {
        calledUrl = request.url.toString();
        final mockResults = {
          'page': 1,
          'results': [
            {
              'id': 671,
              'title': "Harry Potter and the Philosopher's Stone",
              'poster_path': '/harry.jpg',
              'release_date': '2001-11-16',
              'vote_average': 7.9,
            },
          ],
        };
        return http.Response(
          json.encode(mockResults),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final api = ApiService(client: mockClient);
      final List<Drama> results = await api.searchMovies('Harry Potter');

      expect(calledUrl, isNotNull);
      expect(calledUrl, contains('/search/movie'));
      expect(calledUrl, contains('query=Harry%20Potter'));
      expect(calledUrl, contains('language=en-US'));
      expect(calledUrl, contains('page=1'));
      expect(calledUrl, contains('include_adult=false'));

      // Memastikan TIDAK ADA filter pembatas
      expect(calledUrl, isNot(contains('with_original_language')));
      expect(calledUrl, isNot(contains('region')));
      expect(calledUrl, isNot(contains('with_genres')));

      expect(results.length, 1);
      expect(results[0].title, "Harry Potter and the Philosopher's Stone");
      expect(results[0].mediaType, 'movie');
    });

    test('searchTvShows memanggil /search/tv dengan query ter-encode dan tanpa filter wilayah/bahasa/genre', () async {
      String? calledUrl;
      final mockClient = MockClient((request) async {
        calledUrl = request.url.toString();
        final mockResults = {
          'page': 1,
          'results': [
            {
              'id': 93405,
              'name': 'Squid Game',
              'poster_path': '/squid.jpg',
              'first_air_date': '2021-09-17',
              'vote_average': 7.8,
            },
          ],
        };
        return http.Response(
          json.encode(mockResults),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final api = ApiService(client: mockClient);
      final List<Drama> results = await api.searchTvShows('Squid Game');

      expect(calledUrl, isNotNull);
      expect(calledUrl, contains('/search/tv'));
      expect(calledUrl, contains('query=Squid%20Game'));
      expect(calledUrl, contains('language=en-US'));
      expect(calledUrl, contains('page=1'));
      expect(calledUrl, contains('include_adult=false'));

      // Memastikan TIDAK ADA filter pembatas
      expect(calledUrl, isNot(contains('with_original_language')));
      expect(calledUrl, isNot(contains('region')));
      expect(calledUrl, isNot(contains('with_genres')));

      expect(results.length, 1);
      expect(results[0].title, 'Squid Game');
      expect(results[0].mediaType, 'tv');
    });

    test('searchActors memanggil /search/person dengan query ter-encode dan tanpa filter wilayah/bahasa/genre', () async {
      String? calledUrl;
      final mockClient = MockClient((request) async {
        calledUrl = request.url.toString();
        final mockResults = {
          'page': 1,
          'results': [
            {
              'id': 500,
              'name': 'Tom Cruise',
              'profile_path': '/tom.jpg',
              'popularity': 45.2,
              'known_for_department': 'Acting',
            },
          ],
        };
        return http.Response(
          json.encode(mockResults),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final api = ApiService(client: mockClient);
      final List<Actor> results = await api.searchActors('Tom Cruise');

      expect(calledUrl, isNotNull);
      expect(calledUrl, contains('/search/person'));
      expect(calledUrl, contains('query=Tom%20Cruise'));
      expect(calledUrl, contains('language=en-US'));
      expect(calledUrl, contains('page=1'));
      expect(calledUrl, contains('include_adult=false'));

      // Memastikan TIDAK ADA filter pembatas
      expect(calledUrl, isNot(contains('with_original_language')));
      expect(calledUrl, isNot(contains('region')));

      expect(results.length, 1);
      expect(results[0].name, 'Tom Cruise');
    });

    test('query kosong atau spasi mengembalikan list kosong tanpa melakukan request', () async {
      bool called = false;
      final mockClient = MockClient((request) async {
        called = true;
        return http.Response('{}', 200);
      });

      final api = ApiService(client: mockClient);
      expect(await api.searchMovies('   '), isEmpty);
      expect(await api.searchTvShows(''), isEmpty);
      expect(await api.searchActors(' '), isEmpty);
      expect(called, isFalse);
    });
  });

  group('SearchPage Online Global Integration Tests', () {
    testWidgets('Mengetik di search TextField memicu pencarian online dan menampilkan hasil global', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/search/movie')) {
          final mockResults = {
            'page': 1,
            'results': [
              {
                'id': 9991,
                'title': 'Oppenheimer',
                'poster_path': '/oppen.jpg',
                'release_date': '2023-07-21',
                'vote_average': 8.1,
              },
            ],
          };
          return http.Response(
            json.encode(mockResults),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (request.url.path.contains('/search/tv')) {
          return http.Response(
            json.encode({'page': 1, 'results': []}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (request.url.path.contains('/search/person')) {
          final mockActors = {
            'page': 1,
            'results': [
              {
                'id': 203,
                'name': 'Cillian Murphy',
                'profile_path': '/cillian.jpg',
                'popularity': 60.5,
              },
            ],
          };
          return http.Response(
            json.encode(mockActors),
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

      final mockApi = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: SearchPage(apiService: mockApi),
        ),
      );
      await tester.pumpAndSettle();

      // Ketik 'Oppenheimer' pada kolom pencarian
      await tester.enterText(find.byType(TextField), 'Oppenheimer');
      await tester.pumpAndSettle();

      // Memeriksa hasil film Oppenheimer muncul di Tab Judul (selain teks input)
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data == 'Oppenheimer'),
        findsOneWidget,
      );

      // Pindah ke Tab AKTOR
      await tester.tap(find.text('AKTOR'));
      await tester.pumpAndSettle();

      // Memeriksa aktor hasil pencarian muncul
      expect(find.text('Cillian Murphy'), findsOneWidget);

      // Memeriksa subtitle menampilkan profesi 'Aktor / Pemeran' dan BUKAN teks hardcode 'South Korean'
      expect(find.text('Aktor / Pemeran'), findsWidgets);
      expect(find.text('South Korean'), findsNothing);
    });
  });
}

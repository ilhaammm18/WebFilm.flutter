import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tugas_pbp/models/actor.dart';
import 'package:tugas_pbp/screens/actor_detail_page.dart';
import 'package:tugas_pbp/screens/search_page.dart';
import 'package:tugas_pbp/services/api_service.dart';

void main() {
  group('Actor Model & TMDB JSON Mapping Tests', () {
    test('Pengujian instansiasi Actor manual', () {
      final actor = Actor(
        id: 101,
        name: 'Lee Jong Suk',
        profilePath: '/lee_jong_suk.jpg',
        koreanName: '이종석',
        nationality: 'Korea Selatan',
        birthDate: '14 September 1989',
        age: 35,
        flowers: 15000,
        likes: 45000,
        rank: '#1',
      );

      expect(actor.id, 101);
      expect(actor.name, 'Lee Jong Suk');
      expect(actor.profile_path, '/lee_jong_suk.jpg');
      expect(actor.imageUrl, 'https://image.tmdb.org/t/p/w500/lee_jong_suk.jpg');
      expect(actor.familyName, 'Lee');
      expect(actor.firstName, 'Jong Suk');
      expect(actor.koreanName, '이종석');
    });

    test('Pengujian Actor.fromJson dengan respon JSON TMDB', () {
      final tmdbJson = {
        'id': 974169,
        'name': 'Jenna Ortega',
        'original_name': 'Jenna Ortega',
        'popularity': 87.264,
        'profile_path': '/q1NRxR02gc4b78vJWVGw41Z1cpm.jpg',
        'known_for_department': 'Acting',
        'birthday': '2002-09-27',
        'place_of_birth': 'Coachella, California, USA',
      };

      final actor = Actor.fromJson(tmdbJson);

      expect(actor.id, 974169);
      expect(actor.name, 'Jenna Ortega');
      expect(actor.profile_path, '/q1NRxR02gc4b78vJWVGw41Z1cpm.jpg');
      expect(actor.imageUrl, 'https://image.tmdb.org/t/p/w500/q1NRxR02gc4b78vJWVGw41Z1cpm.jpg');
      expect(actor.popularity, 87.264);
      expect(actor.birthday, '2002-09-27');
      expect(actor.placeOfBirth, 'Coachella, California, USA');
      expect(actor.place_of_birth, 'Coachella, California, USA');
      expect(actor.knownForDepartment, 'Acting');
      expect(actor.known_for_department, 'Acting');
    });

    test('dummyActors memuat aktor-aktor populer', () {
      expect(dummyActors.isNotEmpty, true);
      final names = dummyActors.map((a) => a.name).toList();
      expect(names.any((n) => n.contains('Lee Jong Suk')), true);
      expect(names.any((n) => n.contains('IU')), true);
    });
  });

  group('ApiService TMDB Tests', () {
    test('getPopularActors berhasil memetakan JSON 200 menjadi List<Actor>', () async {
      final mockClient = MockClient((request) async {
        final mockResponse = {
          'page': 1,
          'results': [
            {
              'id': 12345,
              'name': 'Tom Cruise',
              'profile_path': '/tom.jpg',
              'popularity': 75.5,
              'known_for_department': 'Acting',
            },
            {
              'id': 67890,
              'name': 'Scarlett Johansson',
              'profile_path': '/scarlett.jpg',
              'popularity': 90.0,
              'known_for_department': 'Acting',
            }
          ],
        };
        return http.Response(json.encode(mockResponse), 200);
      });

      final apiService = ApiService(client: mockClient);
      final actors = await apiService.getPopularActors();

      expect(actors.length, 2);
      expect(actors[0].name, 'Tom Cruise');
      expect(actors[0].profile_path, '/tom.jpg');
      expect(actors[1].name, 'Scarlett Johansson');
    });

    test('getCuratedActors berhasil memetakan pencarian VIP actors secara paralel', () async {
      final requestedQueries = <String>[];
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/search/person')) {
          final query = request.url.queryParameters['query'] ?? '';
          requestedQueries.add(query);
          return http.Response(
            json.encode({
              'page': 1,
              'results': [
                {
                  'id': query.hashCode.abs(),
                  'name': query,
                  'profile_path': '/$query.jpg',
                  'known_for_department': 'Acting',
                  'known_for': [
                    {'original_language': 'ko'}
                  ],
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient);
      final actors = await apiService.getCuratedActors();

      expect(actors.length, ApiService.vipActors.length);
      expect(requestedQueries.contains('Ji Chang Wook'), isTrue);
      expect(requestedQueries.contains('Yamazaki Kento'), isTrue);
      expect(actors.any((a) => a.name == 'Ji Chang Wook'), isTrue);
    });

    test('getActorCredits berhasil memetakan credits aktor dari TMDB API', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/3/person/135622/combined_credits');
        final mockCredits = {
          'cast': [
            {
              'id': 1001,
              'title': 'Big Mouth',
              'poster_path': '/bigmouth.jpg',
              'release_date': '2022-07-29',
              'character': 'Park Chang-ho',
              'vote_average': 8.4,
              'media_type': 'tv',
            },
            {
              'id': 1002,
              'name': 'W: Two Worlds',
              'poster_path': '/w.jpg',
              'first_air_date': '2016-07-20',
              'character': 'Kang Chul',
              'vote_average': 8.2,
              'media_type': 'tv',
            },
          ]
        };
        return http.Response(
          json.encode(mockCredits),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final credits = await apiService.getActorCredits(135622);

      expect(credits.length, 2);
      expect(credits[0].title, 'Big Mouth');
      expect(credits[0].character, 'Park Chang-ho');
      expect(credits[0].releaseYear, '2022');
      expect(credits[0].posterUrl, 'https://image.tmdb.org/t/p/w500/bigmouth.jpg');
      expect(credits[1].title, 'W: Two Worlds');
      expect(credits[1].character, 'Kang Chul');
      expect(credits[1].releaseYear, '2016');
    });
  });

  group('ActorDetailPage Widget Tests', () {
    testWidgets('Menampilkan komponen detail aktor dengan desain bersih, biodata, dan filmografi', (tester) async {
      final testActor = dummyActors.first; // Lee Jong Suk

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/combined_credits')) {
          final mockCredits = {
            'cast': [
              {
                'id': 1001,
                'title': 'Big Mouth',
                'poster_path': '/bigmouth.jpg',
                'release_date': '2022-07-29',
                'character': 'Park Chang-ho',
              },
            ]
          };
          return http.Response(
            json.encode(mockCredits),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final mockApiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: ActorDetailPage(testActor, apiService: mockApiService),
        ),
      );
      await tester.pumpAndSettle();

      // Memeriksa header nama & title serta baris Nama Asli di Biodata
      expect(find.text('Profil Aktor'), findsOneWidget);
      expect(find.text(testActor.name), findsNWidgets(2)); // Header & baris Nama Asli

      // Memeriksa biodata list tile sederhana baru
      expect(find.text('Biodata'), findsOneWidget);
      expect(find.text('Nama Asli'), findsOneWidget);
      expect(find.text('Profesi'), findsOneWidget);
      expect(find.text('Aktor / Pemeran'), findsOneWidget);
      expect(find.text('Tempat Lahir'), findsOneWidget);
      expect(find.text(testActor.placeOfBirth!), findsOneWidget);
      expect(find.text('Tanggal Lahir'), findsOneWidget);
      expect(find.text('14 September 1989'), findsOneWidget);
      expect(find.text('Usia'), findsOneWidget);
      expect(find.text('Nama Depan'), findsNothing);
      expect(find.text('Nama Keluarga'), findsNothing);
      expect(find.text('Kebangsaan'), findsNothing);

      // Memeriksa section Drama / Filmografi & data kredit film
      expect(find.text('Drama / Filmografi'), findsOneWidget);
      expect(find.text('Big Mouth'), findsOneWidget);
      expect(find.text('2022'), findsOneWidget);
      expect(find.text('Park Chang-ho'), findsOneWidget);
    });
  });

  group('SearchPage Tab Aktor Widget Tests', () {
    testWidgets('Memilih tab AKTOR merender FutureBuilder dan daftar kartu aktor dari TMDB', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/combined_credits')) {
          return http.Response(
            json.encode({
              'cast': [
                {
                  'id': 1001,
                  'title': 'Big Mouth',
                  'poster_path': '/bigmouth.jpg',
                  'release_date': '2022-07-29',
                  'character': 'Park Chang-ho',
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        final mockResponse = {
          'page': 1,
          'results': [
            {
              'id': 1,
              'name': 'Lee Jong Suk',
              'original_name': '이종석',
              'profile_path': '/lee.jpg',
              'popularity': 88.5,
              'known_for_department': 'Acting',
            },
          ],
        };
        return http.Response(
          json.encode(mockResponse),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final mockApiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: SearchPage(apiService: mockApiService),
        ),
      );
      await tester.pumpAndSettle();

      // Klik tab AKTOR
      await tester.tap(find.text('AKTOR'));
      await tester.pumpAndSettle();

      // Memeriksa kartu aktor tampil dari hasil TMDB
      expect(find.text('Lee Jong Suk'), findsOneWidget);
      expect(find.text('이종석'), findsOneWidget);

      // Klik kartu aktor Lee Jong Suk untuk navigasi ke ActorDetailPage
      await tester.tap(find.text('Lee Jong Suk'));
      await tester.pumpAndSettle();

      // Memeriksa bahwa ActorDetailPage telah terbuka dengan struktur baru
      expect(find.text('Profil Aktor'), findsOneWidget);
      expect(find.text('Biodata'), findsOneWidget);
      expect(find.text('Drama / Filmografi'), findsOneWidget);
    });
  });
}

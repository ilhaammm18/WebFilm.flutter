import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:tugas_pbp/data/shared_data.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/screens/movie_detail_page.dart';
import 'package:tugas_pbp/services/api_service.dart';

class MockUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  String? launchedUrl;
  PreferredLaunchMode? launchMode;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrl = url;
    launchMode = options.mode;
    return true;
  }
}

void main() {
  late MockUrlLauncherPlatform mockLauncher;

  setUp(() {
    SharedData.dramaListNotifier.value = [];
    mockLauncher = MockUrlLauncherPlatform();
    UrlLauncherPlatform.instance = mockLauncher;
  });

  group('TMDB Videos API & Trailer Extraction Tests (api_service.dart)', () {
    test('1. getMovieTrailerKey memanggil /movie/{id}/videos dengan language=en-US dan mengutamakan type Trailer', () async {
      String? calledUrl;
      final mockClient = MockClient((request) async {
        calledUrl = request.url.toString();
        if (request.url.path.contains('/videos')) {
          return http.Response(
            json.encode({
              'id': 550,
              'results': [
                {
                  'site': 'YouTube',
                  'type': 'Teaser',
                  'key': 'teaser_key_123',
                },
                {
                  'site': 'YouTube',
                  'type': 'Trailer',
                  'key': 'trailer_key_777',
                },
                {
                  'site': 'YouTube',
                  'type': 'Behind the Scenes',
                  'key': 'bts_key_999',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('{}', 404);
      });

      final api = ApiService(client: mockClient);
      final key = await api.getMovieTrailerKey(550, mediaType: 'movie');

      expect(calledUrl, isNotNull);
      expect(calledUrl, contains('/movie/550/videos'));
      expect(calledUrl, contains('language=en-US'));
      // Mengutamakan type == 'Trailer'
      expect(key, 'trailer_key_777');
    });

    test('2. getMovieTrailerKey fallback ke Teaser atau video YouTube pertama jika Trailer tidak ada', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'id': 100,
            'results': [
              {
                'site': 'Vimeo',
                'type': 'Trailer',
                'key': 'vimeo_123',
              },
              {
                'site': 'YouTube',
                'type': 'Teaser',
                'key': 'teaser_fallback_key',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final api = ApiService(client: mockClient);
      final key = await api.getMovieTrailerKey(100, mediaType: 'tv');

      expect(key, 'teaser_fallback_key');
    });

    test('3. getMovieTrailerKey fallback memanggil endpoint tanpa bahasa jika en-US kosong', () async {
      final List<String> requestedUrls = [];
      final mockClient = MockClient((request) async {
        requestedUrls.add(request.url.toString());
        if (request.url.queryParameters.containsKey('language')) {
          // en-US kosong
          return http.Response(
            json.encode({'id': 200, 'results': []}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else {
          // Request tanpa bahasa mengembalikan video
          return http.Response(
            json.encode({
              'id': 200,
              'results': [
                {
                  'site': 'YouTube',
                  'type': 'Trailer',
                  'key': 'global_video_key',
                }
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
      });

      final api = ApiService(client: mockClient);
      final key = await api.getMovieTrailerKey(200);

      expect(requestedUrls.length, 2);
      expect(requestedUrls[0], contains('language=en-US'));
      expect(requestedUrls[1], isNot(contains('language=')));
      expect(key, 'global_video_key');
    });

    test('4. getMovieTrailerKey mengembalikan null jika tidak ada video YouTube yang ditemukan', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'id': 300,
            'results': [
              {
                'site': 'Vimeo',
                'type': 'Trailer',
                'key': 'vimeo_only',
              }
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final api = ApiService(client: mockClient);
      final key = await api.getMovieTrailerKey(300);

      expect(key, isNull);
    });
  });

  group('MovieDetailPage Trailer Button & Statistic Box Tests', () {
    testWidgets('1. Klik tombol Trailer saat video ada membuka link YouTube via url_launcher', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/credits')) {
          return http.Response('{"cast": [], "crew": []}', 200);
        }
        if (request.url.path.contains('/watch/providers')) {
          return http.Response('{"results": {}}', 200);
        }
        if (request.url.path.contains('/videos')) {
          return http.Response(
            json.encode({
              'id': 999,
              'results': [
                {
                  'site': 'YouTube',
                  'type': 'Trailer',
                  'key': 'yt_superman_trailer',
                }
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path.contains('/movie/999')) {
          return http.Response(
            json.encode({
              'id': 999,
              'title': 'Superman Legacy',
              'overview': 'Kisah manusia baja.',
              'vote_average': 8.7,
              'vote_count': 3500,
              'popularity': 750.8,
              'runtime': 140,
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('{}', 404);
      });

      final mockApi = ApiService(client: mockClient);

      final sampleMovie = Drama(
        id: 999,
        title: 'Superman Legacy',
        koreanTitle: '',
        genre: 'Action',
        date: '2025-07-11',
        rating: 8.7,
        episodes: 1,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Sedang',
        startDate: '',
        endDate: '',
        image: '',
        rank: '#1',
        popularity: '751',
        watchers: '3500',
        synopsis: 'Kisah manusia baja.',
        aired: '2025',
        duration: '140 menit',
        contentRating: '13+',
        genresList: ['Action'],
        tagsList: ['TMDB'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailPage(
            movie: sampleMovie,
            apiService: mockApi,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi tombol Trailer ada
      final trailerBtn = find.widgetWithText(ElevatedButton, 'Trailer');
      expect(trailerBtn, findsOneWidget);

      // Klik tombol Trailer
      await tester.tap(trailerBtn);
      await tester.pumpAndSettle();

      // Verifikasi url_launcher terpanggil dengan link YouTube yang benar dan mode externalApplication
      expect(mockLauncher.launchedUrl, 'https://www.youtube.com/watch?v=yt_superman_trailer');
      expect(mockLauncher.launchMode, PreferredLaunchMode.externalApplication);
    });

    testWidgets('2. Klik tombol Trailer saat video tidak ada menampilkan SnackBar pesan maaf', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/credits')) {
          return http.Response('{"cast": [], "crew": []}', 200);
        }
        if (request.url.path.contains('/watch/providers')) {
          return http.Response('{"results": {}}', 200);
        }
        if (request.url.path.contains('/videos')) {
          // Tidak ada video
          return http.Response(
            json.encode({'id': 111, 'results': []}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('{}', 404);
      });

      final mockApi = ApiService(client: mockClient);

      final sampleMovie = Drama(
        id: 111,
        title: 'Film Misteri',
        koreanTitle: '',
        genre: 'Misteri',
        date: '2025-01-01',
        rating: 7.0,
        episodes: 1,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Sedang',
        startDate: '',
        endDate: '',
        image: '',
        rank: '#1',
        popularity: '120',
        watchers: '80',
        synopsis: 'Deskripsi film misteri.',
        aired: '2025',
        duration: '90 menit',
        contentRating: '13+',
        genresList: ['Misteri'],
        tagsList: ['TMDB'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailPage(
            movie: sampleMovie,
            apiService: mockApi,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final trailerBtn = find.widgetWithText(ElevatedButton, 'Trailer');
      await tester.tap(trailerBtn);
      await tester.pump();

      // Memastikan SnackBar muncul dengan teks sesuai spesifikasi
      expect(
        find.text('Maaf, trailer belum tersedia untuk tayangan ini.'),
        findsOneWidget,
      );
    });

    testWidgets('3. Kotak statistik kolom ke-3 menampilkan Kepopuleran dengan nilai popularity murni (.round())', (tester) async {
      final sampleMovie = Drama(
        id: 222,
        title: 'Popular Film',
        koreanTitle: '',
        genre: 'Action',
        date: '2025-05-05',
        rating: 9.0,
        episodes: 1,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Sedang',
        startDate: '',
        endDate: '',
        image: '',
        rank: '#1',
        popularity: '850.4',
        watchers: '12500',
        synopsis: 'Film paling populer.',
        aired: '2025',
        duration: '110 menit',
        contentRating: '13+',
        genresList: ['Action'],
        tagsList: ['TMDB'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailPage(
            movie: sampleMovie,
          ),
        ),
      );
      await tester.pump();

      // Kolom 3 menampilkan label 'Kepopuleran' dan nilai dibulatkan (850)
      expect(find.text('Kepopuleran'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.text('850'), findsOneWidget);

      // Angka watchers/vote_count tetap ditampilkan di kotak rating tanpa manipulasi
      expect(find.text('dari 12500 pengguna'), findsOneWidget);
    });
  });
}

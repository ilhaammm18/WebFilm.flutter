import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/data/shared_data.dart';
import 'package:tugas_pbp/services/api_service.dart';
import 'package:tugas_pbp/screens/explore_tab.dart';

void main() {
  setUp(() {
    SharedData.dramaListNotifier.value = [];
  });
  group('TMDB Movie Model & ApiService Tests', () {
    test('Drama.fromTmdbJson memetakan JSON TMDB dengan poster_path dan fallback null', () {
      final jsonWithPoster = {
        'id': 101,
        'title': 'Deadpool & Wolverine',
        'original_title': 'Deadpool & Wolverine',
        'poster_path': '/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
        'vote_average': 7.7,
        'release_date': '2024-07-24',
        'overview': 'Sinopsis film Deadpool & Wolverine',
        'popularity': 2341.2,
        'vote_count': 4500,
      };

      final movie1 = Drama.fromTmdbJson(jsonWithPoster);
      expect(movie1.title, 'Deadpool & Wolverine');
      expect(movie1.rating, 7.7);
      expect(movie1.image, 'https://image.tmdb.org/t/p/w500/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg');
      expect(movie1.genre, 'Film');

      // Test fallback saat poster_path null
      final jsonWithoutPoster = {
        'id': 102,
        'title': 'Movie Tanpa Poster',
        'poster_path': null,
        'vote_average': 6.5,
      };

      final movie2 = Drama.fromTmdbJson(jsonWithoutPoster);
      expect(movie2.title, 'Movie Tanpa Poster');
      expect(movie2.image, '');
    });

    test('getTrendingMovies() dan getNowPlayingMovies() memanggil endpoint TMDB yang sesuai', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/trending/movie/day')) {
          final mockTrending = {
            'page': 1,
            'results': [
              {
                'id': 201,
                'title': 'Trending Film 1',
                'poster_path': '/trending1.jpg',
                'vote_average': 8.2,
              },
            ],
          };
          return http.Response(
            json.encode(mockTrending),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (request.url.path.contains('/movie/now_playing')) {
          final mockNowPlaying = {
            'page': 1,
            'results': [
              {
                'id': 301,
                'title': 'Now Playing Film 1',
                'poster_path': '/nowplaying1.jpg',
                'vote_average': 7.9,
              },
            ],
          };
          return http.Response(
            json.encode(mockNowPlaying),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient);

      final trendingList = await apiService.getTrendingMovies();
      expect(trendingList.length, 1);
      expect(trendingList[0].title, 'Trending Film 1');
      expect(trendingList[0].image, 'https://image.tmdb.org/t/p/w500/trending1.jpg');

      final nowPlayingList = await apiService.getNowPlayingMovies();
      expect(nowPlayingList.length, 1);
      expect(nowPlayingList[0].title, 'Now Playing Film 1');
      expect(nowPlayingList[0].image, 'https://image.tmdb.org/t/p/w500/nowplaying1.jpg');
    });

    test('getMovies(), getDramas(), and getAnimes() memanggil endpoint TMDB yang sesuai', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/movie/popular')) {
          return http.Response(
            json.encode({
              'page': 1,
              'results': [
                {
                  'id': 101,
                  'title': 'Popular Movie 1',
                  'poster_path': '/pop_movie.jpg',
                  'vote_average': 8.0,
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (request.url.path.contains('/tv/popular')) {
          return http.Response(
            json.encode({
              'page': 1,
              'results': [
                {
                  'id': 201,
                  'name': 'Popular TV Drama 1',
                  'poster_path': '/pop_drama.jpg',
                  'vote_average': 8.5,
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (request.url.path.contains('/discover/tv')) {
          return http.Response(
            json.encode({
              'page': 1,
              'results': [
                {
                  'id': 301,
                  'name': 'Popular Anime 1',
                  'poster_path': '/pop_anime.jpg',
                  'vote_average': 9.0,
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

      final movies = await apiService.getMovies();
      expect(movies.length, 1);
      expect(movies.first.title, 'Popular Movie 1');
      expect(movies.first.genre, 'Film');

      final dramas = await apiService.getDramas();
      expect(dramas.length, 1);
      expect(dramas.first.title, 'Popular TV Drama 1');
      expect(dramas.first.genre, 'Drama');

      final animes = await apiService.getAnimes();
      expect(animes.length, 1);
      expect(animes.first.title, 'Popular Anime 1');
      expect(animes.first.genre, 'Anime');
    });
  });

  group('ExploreTab FutureBuilder Tests', () {
    testWidgets('ExploreTab menampilkan data TMDB pada Direkomendasikan dan Sedang Ditonton', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/trending/movie/day')) {
          return http.Response(
            json.encode({
              'page': 1,
              'results': [
                {
                  'id': 501,
                  'title': 'Film Trending Hari Ini',
                  'poster_path': '/trend.jpg',
                  'vote_average': 9.7,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path.contains('/movie/now_playing')) {
          return http.Response(
            json.encode({
              'page': 1,
              'results': [
                {
                  'id': 601,
                  'title': 'Film Tayang Bioskop',
                  'poster_path': '/now.jpg',
                  'vote_average': 8.1,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path.contains('/tv/popular')) {
          return http.Response(
            json.encode({
              'page': 1,
              'results': [
                {
                  'id': 701,
                  'name': 'Drama Populer TV',
                  'poster_path': '/tvpop.jpg',
                  'vote_average': 8.6,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path.contains('/movie/popular')) {
          return http.Response(
            json.encode({
              'page': 1,
              'results': [
                {
                  'id': 801,
                  'title': 'Film Bioskop Populer',
                  'poster_path': '/moviepop.jpg',
                  'vote_average': 8.3,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path.contains('/discover/tv')) {
          return http.Response(
            json.encode({
              'page': 1,
              'results': [
                {
                  'id': 901,
                  'name': 'Anime Populer',
                  'poster_path': '/animepop.jpg',
                  'vote_average': 8.9,
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

      final mockApiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: ExploreTab(apiService: mockApiService),
        ),
      );
      await tester.pumpAndSettle();

      // Memeriksa header section
      expect(find.text('Direkomendasikan Untuk Anda'), findsOneWidget);
      expect(find.text('Sedang Ditonton Sekarang'), findsOneWidget);

      // Memeriksa judul film dari hasil TMDB API muncul di UI
      expect(find.text('Film Trending Hari Ini'), findsOneWidget);
      expect(find.text('Film Tayang Bioskop'), findsOneWidget);

      // Memeriksa rating film muncul
      expect(find.text('9.7'), findsOneWidget);
      expect(find.text('8.1'), findsOneWidget);

      // Menguji tab DRAMA memuat FutureBuilder
      await tester.tap(find.text('DRAMA'));
      await tester.pumpAndSettle();
      expect(find.text('Drama Populer TV'), findsWidgets);

      // Menguji tab FILM memuat FutureBuilder
      await tester.tap(find.text('FILM'));
      await tester.pumpAndSettle();
      expect(find.text('Film Bioskop Populer'), findsWidgets);

      // Menguji tab ANIMASI memuat FutureBuilder & sub-filter
      await tester.tap(find.text('ANIMASI'));
      await tester.pumpAndSettle();
      expect(find.text('Anime Populer'), findsWidgets);
      expect(find.text('Film Animasi Bioskop'), findsWidgets);
      expect(find.text('Semua'), findsWidgets);
      expect(find.text('Anime (Jepang)'), findsWidgets);
      expect(find.text('Kartun Barat'), findsWidgets);
      expect(find.text('Donghua (China)'), findsWidgets);

      // Menguji memilih sub-filter Kartun Barat
      await tester.tap(find.text('Kartun Barat'));
      await tester.pumpAndSettle();
      expect(find.text('Serial Kartun Barat'), findsWidgets);
      expect(find.text('Film Animasi Barat'), findsWidgets);
    });


    test('getDiscoverMovies dan getDiscoverTvShows menambahkan parameter with_genres jika genreId diberikan', () async {
      String? requestedMovieUrl;
      String? requestedTvUrl;

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/discover/movie')) {
          requestedMovieUrl = request.url.toString();
          return http.Response(
            json.encode({'page': 1, 'results': []}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (request.url.path.contains('/discover/tv')) {
          requestedTvUrl = request.url.toString();
          return http.Response(
            json.encode({'page': 1, 'results': []}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient);

      // Panggil dengan genreId = 28 (Aksi)
      await apiService.getDiscoverMovies(28);
      expect(requestedMovieUrl, contains('with_genres=28'));
      expect(requestedMovieUrl, contains('with_original_language=ko'));

      await apiService.getDiscoverTvShows(10749);
      expect(requestedTvUrl, contains('with_genres=10749'));
      expect(requestedTvUrl, contains('with_original_language=ko'));
    });

    test('getMediaByGenre memanggil /discover/movie dengan parameter with_genres', () async {
      String? requestedUrl;
      final mockClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        final mockResults = {
          'page': 1,
          'results': [
            {
              'id': 801,
              'title': 'Crime Film 1',
              'poster_path': '/crime1.jpg',
              'release_date': '2023-05-10',
              'vote_average': 8.1,
            },
          ],
        };
        return http.Response(
          json.encode(mockResults),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final results = await apiService.getMediaByGenre(80);

      expect(requestedUrl, contains('/discover/movie'));
      expect(requestedUrl, contains('with_genres=80'));
      expect(results.length, 1);
      expect(results[0].title, 'Crime Film 1');
      expect(results[0].date, '2023-05-10');
    });

    testWidgets('ExploreTab: Tombol genre di layar utama dihapus, digantikan ikon filter Icons.tune di AppBar yang memunculkan Bottom Sheet Pilih Genre dengan Wrap', (tester) async {
      final mockClient = MockClient((request) async {
        final mockResults = {
          'page': 1,
          'results': [
            {
              'id': 991,
              'title': 'Sample Media',
              'poster_path': '/sample.jpg',
              'release_date': '2024-01-01',
              'vote_average': 7.5,
            },
          ],
        };
        return http.Response(
          json.encode(mockResults),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final mockApiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: ExploreTab(apiService: mockApiService),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Memeriksa ikon pencarian & filter tune di AppBar, serta notifikasi tidak ada
      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsNothing);

      // Memastikan urutan posisi ikon: Icons.search di sebelah kiri Icons.tune
      final searchX = tester.getTopLeft(find.byIcon(Icons.search)).dx;
      final tuneX = tester.getTopLeft(find.byIcon(Icons.tune)).dx;
      expect(searchX < tuneX, isTrue);

      // 2. Memastikan deretan tombol genre TIDAK ADA di layar utama
      expect(find.text('Pilih Genre'), findsNothing);
      expect(find.text('Aksi'), findsNothing);
      expect(find.text('Horor'), findsNothing);

      // 3. Tekan ikon Icons.tune untuk memunculkan Bottom Sheet
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      // 4. Memverifikasi modal bottom sheet muncul dengan judul 'Pilih Genre' dan Wrap
      expect(find.text('Pilih Genre'), findsOneWidget);
      expect(find.byType(Wrap), findsOneWidget);
      expect(find.text('Semua Genre'), findsOneWidget);
      expect(find.text('Aksi'), findsOneWidget);
      expect(find.text('Komedi'), findsOneWidget);
      expect(find.text('Horor'), findsOneWidget);
      expect(find.text('Romantis'), findsOneWidget);
      expect(find.text('Crime'), findsOneWidget);

      // 5. Pilih genre 'Aksi' dari modal bottom sheet
      await tester.tap(find.text('Aksi'));
      await tester.pumpAndSettle();

      // 6. Memastikan modal bottom sheet otomatis tertutup
      expect(find.text('Pilih Genre'), findsNothing);
    });

    testWidgets('ExploreTab: Sub-filter horizontal negara pada tab FILM, DRAMA, dan ANIMASI berfungsi dinamis', (tester) async {
      final mockClient = MockClient((request) async {
        final mockResults = {
          'page': 1,
          'results': [
            {
              'id': 111,
              'title': 'Responsive Movie',
              'poster_path': '/sample.jpg',
              'release_date': '2024-01-01',
              'vote_average': 8.0,
            },
          ],
        };
        return http.Response(
          json.encode(mockResults),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final mockApiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: ExploreTab(apiService: mockApiService),
        ),
      );
      await tester.pumpAndSettle();

      // Cek Tab DRAMA: Opsi 'Semua', 'Korea (Drakor)', 'Jepang (Dorama)', 'Barat', 'China/Thai'
      await tester.tap(find.text('DRAMA'));
      await tester.pumpAndSettle();
      expect(find.text('Korea (Drakor)'), findsOneWidget);
      expect(find.text('Jepang (Dorama)'), findsOneWidget);
      expect(find.text('Barat'), findsOneWidget);
      expect(find.text('China/Thai'), findsOneWidget);

      // Cek Tab FILM: Opsi 'Semua', 'Indonesia', 'Barat', 'Korea', 'Jepang'
      await tester.tap(find.text('FILM'));
      await tester.pumpAndSettle();
      expect(find.text('Indonesia'), findsOneWidget);
      expect(find.text('Barat'), findsOneWidget);
      expect(find.text('Korea'), findsOneWidget);
      expect(find.text('Jepang'), findsOneWidget);

      // Cek Tab ANIMASI: Opsi 'Semua', 'Anime (Jepang)', 'Kartun Barat', 'Donghua (China)'
      await tester.tap(find.text('ANIMASI'));
      await tester.pumpAndSettle();
      expect(find.text('Anime (Jepang)'), findsOneWidget);
      expect(find.text('Kartun Barat'), findsOneWidget);
      expect(find.text('Donghua (China)'), findsOneWidget);
    });

    test('getAnimationTvShows dan getAnimationMovies memanggil /discover dengan with_genres=16 dan filter bahasa opsional', () async {
      final List<String> requestedUrls = [];

      final mockClient = MockClient((request) async {
        requestedUrls.add(request.url.toString());
        return http.Response(
          json.encode({'page': 1, 'results': []}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);

      // Default: tanpa originalLanguage
      await apiService.getAnimationTvShows();
      await apiService.getAnimationMovies();

      expect(requestedUrls[0], contains('/discover/tv'));
      expect(requestedUrls[0], contains('with_genres=16'));
      expect(requestedUrls[0].contains('with_original_language'), isFalse);

      expect(requestedUrls[1], contains('/discover/movie'));
      expect(requestedUrls[1], contains('with_genres=16'));
      expect(requestedUrls[1].contains('with_original_language'), isFalse);

      // Dengan filter: ja, en, zh
      await apiService.getAnimationTvShows(originalLanguage: 'ja');
      expect(requestedUrls[2], contains('with_original_language=ja'));

      await apiService.getAnimationMovies(originalLanguage: 'en');
      expect(requestedUrls[3], contains('with_original_language=en'));

      await apiService.getAnimationTvShows(originalLanguage: 'zh');
      expect(requestedUrls[4], contains('with_original_language=zh'));
    });
  });
}



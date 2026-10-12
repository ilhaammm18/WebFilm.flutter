import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/models/actor.dart';
import 'package:tugas_pbp/screens/detail_page.dart';
import 'package:tugas_pbp/screens/actor_detail_page.dart';
import 'package:tugas_pbp/screens/search_page.dart';
import 'package:tugas_pbp/screens/watchlist_tab.dart';
import 'package:tugas_pbp/screens/explore_tab.dart';
import 'package:tugas_pbp/data/shared_data.dart';
import 'package:tugas_pbp/services/api_service.dart';

void main() {
  setUp(() {
    SharedData.dramaListNotifier.value = [];
  });

  group('Hero Widget Animation Standardization Tests', () {
    testWidgets('DetailPage: Hero tag menggunakan heroTag eksplisit atau poster_{id}', (tester) async {
      final Drama sample = Drama(
        id: 777,
        title: 'Hero Test Drama',
        koreanTitle: '히어로',
        genre: 'Drama',
        rating: 9.0,
        episodes: 16,
        watchedEpisodes: 5,
        status: 'Sedang Menonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2025',
        image: 'https://image.tmdb.org/t/p/w500/sample.jpg',
        rank: '#1',
        popularity: '#1',
        watchers: '50K',
        synopsis: 'Sinopsis uji coba Hero.',
        aired: '2025',
        duration: '60m',
        contentRating: '15+',
        genresList: ['Drama'],
        tagsList: ['Test'],
      );

      // 1. Kasus tanpa heroTag eksplisit -> default: 'poster_777'
      await tester.pumpWidget(MaterialApp(
        home: DetailPage(drama: sample),
      ));
      await tester.pump();

      final defaultHeroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'poster_777',
      );
      expect(defaultHeroFinder, findsOneWidget);

      // 2. Kasus dengan heroTag eksplisit -> 'explore_trending_777'
      await tester.pumpWidget(MaterialApp(
        home: DetailPage(drama: sample, heroTag: 'explore_trending_777'),
      ));
      await tester.pump();

      final customHeroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'explore_trending_777',
      );
      expect(customHeroFinder, findsOneWidget);
    });

    testWidgets('WatchlistTab: Hero tag poster terstandarisasi sebagai poster_{id}', (tester) async {
      final Drama watchlistDrama = Drama(
        id: 555,
        title: 'Watchlist Hero Drama',
        koreanTitle: '워치리스트',
        genre: 'Drama Korea',
        rating: 8.8,
        episodes: 16,
        watchedEpisodes: 8,
        status: 'Sedang Menonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2025',
        image: 'https://image.tmdb.org/t/p/w500/watchlist.jpg',
        rank: '#2',
        popularity: '#2',
        watchers: '30K',
        synopsis: 'Sinopsis watchlist',
        aired: '2025',
        duration: '60m',
        contentRating: '15+',
        genresList: ['Drama'],
        tagsList: ['Watchlist'],
      );

      SharedData.dramaListNotifier.value = [watchlistDrama];

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: WatchlistTab()),
      ));
      await tester.pumpAndSettle();

      final watchlistHero = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'poster_555',
      );
      expect(watchlistHero, findsOneWidget);
    });

    testWidgets('SearchPage: Hero tag poster terstandarisasi pada ListView hasil pencarian', (tester) async {
      final Drama searchDrama = Drama(
        id: 999,
        title: 'Search Hero Drama',
        koreanTitle: '검색',
        genre: 'Film Korea',
        rating: 8.0,
        episodes: 1,
        watchedEpisodes: 0,
        status: 'Belum Ditonton',
        priority: 'Sedang',
        startDate: '',
        endDate: '',
        date: '2025',
        image: 'https://image.tmdb.org/t/p/w500/search.jpg',
        rank: '#5',
        popularity: '#5',
        watchers: '10K',
        synopsis: 'Sinopsis pencarian',
        aired: '2025',
        duration: '120m',
        contentRating: '13+',
        genresList: ['Film'],
        tagsList: ['Search'],
      );

      SharedData.dramaListNotifier.value = [searchDrama];

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SearchPage()),
      ));
      await tester.pumpAndSettle();

      final searchHero = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'poster_999',
      );
      expect(searchHero, findsOneWidget);
    });

    testWidgets('ExploreTab: Hero tag poster unik dengan format explore_{section}_{id}', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/trending/all/day')) {
          return http.Response(
            json.encode({
              'page': 1,
              'results': [
                {
                  'id': 101,
                  'title': 'Trending Hero Movie',
                  'poster_path': '/hero101.jpg',
                  'vote_average': 8.5,
                  'original_language': 'ko',
                  'media_type': 'movie',
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

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ExploreTab(apiService: mockApiService)),
      ));
      await tester.pumpAndSettle();

      final exploreHero = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'explore_trending_hari_ini_101',
      );
      expect(exploreHero, findsOneWidget);
    });

    testWidgets('DetailPage: posterUrl dari konstruktor dirender instan di dalam Hero', (tester) async {
      final Drama sample = Drama(
        id: 888,
        title: 'Instant Poster Drama',
        koreanTitle: '인스턴트',
        genre: 'Action',
        rating: 9.5,
        episodes: 1,
        watchedEpisodes: 0,
        status: 'Belum Ditonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2025',
        image: 'https://image.tmdb.org/t/p/w500/old.jpg',
        rank: '#1',
        popularity: '#1',
        watchers: '10K',
        synopsis: 'Sinopsis instant poster',
        aired: '2025',
        duration: '120m',
        contentRating: '13+',
        genresList: ['Action'],
        tagsList: ['Test'],
      );

      const instantUrl = 'https://image.tmdb.org/t/p/w500/instant.jpg';

      await tester.pumpWidget(MaterialApp(
        home: DetailPage(
          drama: sample,
          heroTag: 'explore_trending_888',
          posterUrl: instantUrl,
        ),
      ));
      await tester.pump();

      // Memastikan Hero ditemukan dengan tag dan Image.network menggunakan instantUrl
      final heroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'explore_trending_888',
      );
      expect(heroFinder, findsOneWidget);

      final imageFinder = find.byWidgetPredicate(
        (widget) => widget is Image && (widget.image as NetworkImage).url == instantUrl,
      );
      expect(imageFinder, findsOneWidget);
    });

    testWidgets('ActorDetailPage: heroTag dan imageUrl dari konstruktor dirender instan di bagian atas', (tester) async {
      final Actor actor = Actor(
        id: 321,
        name: 'Gong Yoo',
        profilePath: '/old_actor.jpg',
      );

      const instantActorUrl = 'https://image.tmdb.org/t/p/w500/instant_actor.jpg';

      await tester.pumpWidget(MaterialApp(
        home: ActorDetailPage(
          actor,
          heroTag: 'actor_321',
          imageUrl: instantActorUrl,
        ),
      ));
      await tester.pump();

      // Memastikan Hero aktor ditemukan dengan tag dan CircleAvatar menggunakan instantActorUrl
      final actorHeroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'actor_321',
      );
      expect(actorHeroFinder, findsOneWidget);

      final circleAvatarFinder = find.byWidgetPredicate(
        (widget) =>
            widget is CircleAvatar &&
            widget.backgroundImage != null &&
            (widget.backgroundImage as NetworkImage).url == instantActorUrl,
      );
      expect(circleAvatarFinder, findsOneWidget);
    });
  });
}


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tugas_pbp/data/shared_data.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/screens/movie_detail_page.dart';
import 'package:tugas_pbp/services/api_service.dart';

void main() {
  setUp(() {
    SharedData.dramaListNotifier.value = [];
  });

  group('MovieDetailPage Re-fetch & Synopsis Fallback Tests', () {
    testWidgets('Re-fetch memanggil getMovieDetails dan menampilkan overview lengkap bukan nama peran', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/credits')) {
          return http.Response('{"cast": []}', 200, headers: {'content-type': 'application/json; charset=utf-8'});
        }
        if (request.url.path.contains('/movie/777') || request.url.path.contains('/tv/777')) {
          return http.Response(
            json.encode({
              'id': 777,
              'title': 'The Sound of Magic',
              'overview': 'Seorang pesulap misterius tinggal di sebuah taman hiburan terbengkalai.',
              'vote_average': 8.1,
              'release_date': '2022-05-06',
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final mockApiService = ApiService(client: mockClient);

      // Data parsial yang dibawa dari filmografi aktor dengan nama peran di synopsis
      final dramaFromActorCredits = Drama(
        id: 777,
        title: 'The Sound of Magic',
        koreanTitle: '안나라수마나라',
        genre: 'Drama',
        rating: 8.1,
        episodes: 6,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Sedang',
        startDate: '',
        endDate: '',
        date: '2022',
        image: '',
        rank: '#1',
        popularity: '90',
        watchers: '500',
        synopsis: 'Berperan sebagai Lee Eul.', // Teks peran parsial
        aired: '2022',
        duration: '60 menit',
        contentRating: '13+',
        genresList: ['Drama'],
        tagsList: ['TMDB'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailPage(
            drama: dramaFromActorCredits,
            apiService: mockApiService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan 'Sinopsis' ada di layar
      expect(find.text('Sinopsis'), findsOneWidget);

      // Memastikan teks overview hasil fetch API ditampilkan
      expect(
        find.text('Seorang pesulap misterius tinggal di sebuah taman hiburan terbengkalai.'),
        findsOneWidget,
      );

      // Memastikan teks peran 'Berperan sebagai Lee Eul.' TIDAK ditampilkan di sinopsis
      expect(find.text('Berperan sebagai Lee Eul.'), findsNothing);
    });

    testWidgets('Tampilan sinopsis menampilkan fallback movie.overview ?? "Sinopsis belum tersedia."', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/movie/888')) {
          return http.Response(
            json.encode({
              'id': 888,
              'title': 'Film Tanpa Sinopsis',
              'overview': '', // Sinopsis kosong dari API
              'vote_average': 6.5,
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('{"cast": []}', 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });

      final mockApiService = ApiService(client: mockClient);

      final emptyOverviewDrama = Drama(
        id: 888,
        title: 'Film Tanpa Sinopsis',
        koreanTitle: '',
        genre: 'Film',
        rating: 6.5,
        episodes: 1,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Sedang',
        startDate: '',
        endDate: '',
        date: '2026',
        image: '',
        rank: '#1',
        popularity: '20',
        watchers: '100',
        synopsis: '',
        aired: '2026',
        duration: '90 menit',
        contentRating: '13+',
        genresList: ['Film'],
        tagsList: ['TMDB'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailPage(
            drama: emptyOverviewDrama,
            apiService: mockApiService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan fallback 'Sinopsis belum tersedia.' muncul
      expect(find.text('Sinopsis'), findsOneWidget);
      expect(find.text('Sinopsis belum tersedia.'), findsOneWidget);
    });
  });
}

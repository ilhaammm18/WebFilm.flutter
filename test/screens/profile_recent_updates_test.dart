import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:tugas_pbp/data/shared_data.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/screens/profile_tab.dart';
import 'package:tugas_pbp/services/api_service.dart';

void main() {
  setUp(() {
    SharedData.dramaListNotifier.value = [];
    ProfileTab.clearCaches();
  });

  group('ProfileTab Pembaruan Terakhir UI Tests', () {
    testWidgets(
        'Card tayangan mengambil poster dan nama genre asli dari TMDB berdasarkan tmdb_id',
        (tester) async {
      // Mock Client untuk TMDB API
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/movie/550')) {
          return http.Response(
            json.encode({
              'id': 550,
              'title': 'Fight Club',
              'poster_path': '/fightclub.jpg',
              'genres': [
                {'id': 28, 'name': 'Action'},
                {'id': 18, 'name': 'Drama'},
              ],
              'media_type': 'movie',
              'vote_average': 8.4,
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(json.encode({'id': 0}), 404);
      });

      final mockApiService = ApiService(client: mockClient);

      // Drama dari Supabase (image kosong, genre 'General', tmdb_id = 550)
      final dramaFromSupabase = Drama.fromSupabase({
        'tmdb_id': 550,
        'judul_film': 'Fight Club',
        'status': 'Sedang Menonton',
      });

      SharedData.dramaListNotifier.value = [dramaFromSupabase];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileTab(apiService: mockApiService),
          ),
        ),
      );

      // Tunggu hingga Future.wait background fetch TMDB selesai
      await tester.pumpAndSettle();

      // 1. Teks judul harus muncul
      expect(find.text('Fight Club'), findsOneWidget);

      // 2. Teks 'General' TIDAK boleh muncul lagi
      expect(find.text('General'), findsNothing);

      // 3. Nama genre asli dari TMDB ('Action') harus muncul menggantikan 'General'
      expect(find.text('Action'), findsOneWidget);

      // 4. Poster harus dirender menggunakan Image.network dengan URL dari TMDB
      final imageFinder = find.byWidgetPredicate((widget) {
        if (widget is Image && widget.image is NetworkImage) {
          final netImage = widget.image as NetworkImage;
          return netImage.url == 'https://image.tmdb.org/t/p/w500/fightclub.jpg';
        }
        return false;
      });
      expect(imageFinder, findsOneWidget);
    });

    testWidgets(
        'Jika genre TMDB kosong, card menampilkan tipe tayangan (Serial TV) menggantikan General',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/tv/770')) {
          return http.Response(
            json.encode({
              'id': 770,
              'name': 'Mystery Drama Series',
              'poster_path': '/mystery.jpg',
              'genres': [],
              'media_type': 'tv',
              'number_of_episodes': 12,
              'vote_average': 8.6,
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(json.encode({'id': 0}), 404);
      });

      final mockApiService = ApiService(client: mockClient);

      final dramaTv = Drama.fromSupabase({
        'tmdb_id': 770,
        'judul_film': 'Mystery Drama Series',
        'status': 'Sedang Menonton',
      });

      SharedData.dramaListNotifier.value = [dramaTv];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileTab(apiService: mockApiService),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mystery Drama Series'), findsOneWidget);
      expect(find.text('General'), findsNothing);
      expect(find.text('Serial TV'), findsOneWidget);

      final imageFinder = find.byWidgetPredicate((widget) {
        if (widget is Image && widget.image is NetworkImage) {
          final netImage = widget.image as NetworkImage;
          return netImage.url == 'https://image.tmdb.org/t/p/w500/mystery.jpg';
        }
        return false;
      });
      expect(imageFinder, findsOneWidget);
    });
  });
}

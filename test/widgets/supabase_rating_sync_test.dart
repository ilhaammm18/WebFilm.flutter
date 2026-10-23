import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tugas_pbp/data/shared_data.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/screens/watchlist_tab.dart';
import 'package:tugas_pbp/widgets/edit_drama_modal.dart';

Drama _createTestDrama({
  int id = 101,
  required String title,
  double rating = 8.5,
  double? userRating,
  String status = 'Sedang Menonton',
  int episodes = 16,
  int watchedEpisodes = 4,
}) {
  return Drama(
    id: id,
    title: title,
    koreanTitle: title,
    mediaType: 'tv',
    genre: 'Drama Korea',
    rating: rating,
    userRating: userRating,
    myRating: userRating,
    episodes: episodes,
    watchedEpisodes: watchedEpisodes,
    status: status,
    priority: 'Sedang',
    startDate: '',
    endDate: '',
    date: '2024',
    image: 'https://example.com/poster.jpg',
    rank: '#1',
    popularity: '100',
    watchers: '10K',
    synopsis: '',
    aired: '',
    duration: '60 menit',
    contentRating: '13+',
    genresList: const ['Drama Korea'],
    tagsList: const [],
  );
}

void main() {
  setUp(() {
    SharedData.dramaListNotifier.value = [];
  });

  group('Supabase Rating Sync & Fallback 0.0 Tests', () {
    test('Drama.fromSupabase memetakan kolom rating dan memberikan fallback 0.0 jika null', () {
      final mapWithRating = {
        'id': 1,
        'tmdb_id': 101,
        'judul_film': 'Drama With Rating',
        'status': 'Sedang Menonton',
        'rating': 7.5,
      };

      final dramaWithRating = Drama.fromSupabase(mapWithRating);
      expect(dramaWithRating.userRating, 7.5);
      expect(dramaWithRating.myRating, 7.5);
      expect(dramaWithRating.rating, 7.5);

      final mapWithNullRating = {
        'id': 2,
        'tmdb_id': 102,
        'judul_film': 'Drama Without Rating',
        'status': 'Rencana Ditonton',
        'rating': null,
      };

      final dramaWithNullRating = Drama.fromSupabase(mapWithNullRating);
      expect(dramaWithNullRating.userRating, 0.0);
      expect(dramaWithNullRating.myRating, 0.0);
      expect(dramaWithNullRating.rating, 0.0);
    });

    testWidgets('Header Modal Edit menampilkan rating Supabase (fallback 0.0), bukan vote_average TMDB', (tester) async {
      // Drama dari TMDB dengan vote_average 8.5 dan userRating null
      final tmdbDrama = _createTestDrama(
        title: 'TMDB Global Show',
        rating: 8.5,
        userRating: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditDramaModal(
              drama: tmdbDrama,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header modal harus menampilkan '0.0', BUKAN '8.5'
      expect(find.textContaining('0.0'), findsWidgets);
      expect(find.textContaining('8.5'), findsNothing);
    });

    testWidgets('Header Modal Edit menampilkan userRating jika sudah ada di database', (tester) async {
      final savedDrama = _createTestDrama(
        title: 'Saved Show',
        rating: 8.5,
        userRating: 7.2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditDramaModal(
              drama: savedDrama,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header modal harus menampilkan '7.2', BUKAN '8.5'
      expect(find.textContaining('7.2'), findsWidgets);
      expect(find.textContaining('8.5'), findsNothing);
    });

    testWidgets('UI Card Daftar Saya menampilkan rating Supabase (fallback 0.0), bukan vote_average TMDB', (tester) async {
      final dramaWithoutUserRating = _createTestDrama(
        id: 201,
        title: 'Show Tanpa Rating Pribadi',
        rating: 8.9, // vote_average TMDB
        userRating: null, // belum dinilai / null di Supabase
        status: 'Sedang Menonton',
      );

      final dramaWithUserRating = _createTestDrama(
        id: 202,
        title: 'Show Dengan Rating Pribadi',
        rating: 8.9,
        userRating: 9.4,
        status: 'Sedang Menonton',
      );

      SharedData.dramaListNotifier.value = [
        dramaWithoutUserRating,
        dramaWithUserRating,
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: WatchlistTab(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Item tanpa rating pribadi menampilkan '0.0', BUKAN global 8.9
      expect(find.text('0.0'), findsOneWidget);
      expect(find.text('8.9'), findsNothing);

      // Item dengan rating pribadi menampilkan '9.4'
      expect(find.text('9.4'), findsOneWidget);
    });

    testWidgets('Payload Supabase memuat tepat 5 key: user_id, judul_film, status, tmdb_id, dan rating', (tester) async {
      final testDrama = _createTestDrama(
        id: 505,
        title: 'Payload 5 Keys Movie',
        status: 'Sedang Menonton',
        rating: 8.5,
        userRating: 0.0,
      );

      final List<Map<String, dynamic>> capturedPayloads = [];

      final mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/auth/v1/token')) {
          return http.Response(
            jsonEncode({
              'access_token': 'test_token',
              'token_type': 'bearer',
              'expires_in': 3600,
              'refresh_token': 'test_refresh',
              'user': {
                'id': 'test_user_payload_id',
                'aud': 'authenticated',
                'email': 'user@example.com',
                'created_at': DateTime.now().toIso8601String(),
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }

        if (request.url.path.contains('/rest/v1/watchlists')) {
          if (request.body.isNotEmpty) {
            final decoded = jsonDecode(request.body);
            if (decoded is Map<String, dynamic>) {
              capturedPayloads.add(decoded);
            } else if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
              capturedPayloads.add(Map<String, dynamic>.from(decoded.first as Map));
            }
          }

          return http.Response(
            '{}',
            201,
            headers: {
              'content-type': 'application/json',
              'preference-applied': 'return=minimal',
            },
            request: request,
          );
        }

        return http.Response('{}', 200,
            headers: {'content-type': 'application/json'},
            request: request);
      });

      final mockSupabase = SupabaseClient(
        'https://example.supabase.co',
        'fake_anon_key',
        httpClient: mockHttpClient,
        authOptions: const AuthClientOptions(
          autoRefreshToken: false,
          authFlowType: AuthFlowType.implicit,
        ),
      );

      await mockSupabase.auth.signInWithPassword(
        email: 'user@example.com',
        password: 'password',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditDramaModal(
              drama: testDrama,
              supabaseClient: mockSupabase,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cari slider dan ubah nilainya ke posisi tertentu
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);
      await tester.tap(slider);
      await tester.pumpAndSettle();

      // Tekan tombol simpan perubahan
      final simpanButton = find.text('Simpan Perubahan');
      expect(simpanButton, findsOneWidget);
      await tester.tap(simpanButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(capturedPayloads.isNotEmpty, isTrue);
      final payload = capturedPayloads.first;

      // Verifikasi: Payload memiliki tepat 5 key
      expect(payload.length, 5);
      expect(payload.containsKey('user_id'), isTrue);
      expect(payload.containsKey('judul_film'), isTrue);
      expect(payload.containsKey('status'), isTrue);
      expect(payload.containsKey('tmdb_id'), isTrue);
      expect(payload.containsKey('rating'), isTrue);

      // Verifikasi: Key yang tidak diinginkan tidak ada
      expect(payload.containsKey('episodes'), isFalse);
      expect(payload.containsKey('date_completed'), isFalse);
      expect(payload.containsKey('drama_id'), isFalse);

      // Verifikasi: Tipe rating adalah double/num
      expect(payload['rating'], isA<num>());
      expect(payload['user_id'], 'test_user_payload_id');
      expect(payload['judul_film'], 'Payload 5 Keys Movie');
      expect(payload['tmdb_id'], 505);

      mockSupabase.dispose();
    });
  });
}

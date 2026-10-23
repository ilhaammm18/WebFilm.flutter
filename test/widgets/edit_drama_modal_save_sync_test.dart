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

Drama _createDrama({
  int id = 0,
  required String title,
  String mediaType = 'tv',
  String genre = 'Drama',
  double rating = 8.0,
  int episodes = 16,
  int watchedEpisodes = 0,
  String status = 'Belum Ditonton',
}) {
  return Drama(
    id: id,
    title: title,
    koreanTitle: title,
    mediaType: mediaType,
    genre: genre,
    rating: rating,
    episodes: episodes,
    watchedEpisodes: watchedEpisodes,
    status: status,
    priority: 'Sedang',
    startDate: '',
    endDate: '',
    date: '2024',
    image: '',
    rank: '#1',
    popularity: '100',
    watchers: '10K',
    synopsis: '',
    aired: '',
    duration: '60 menit',
    contentRating: '13+',
    genresList: const ['Drama'],
    tagsList: const [],
  );
}

void main() {
  setUp(() {
    SharedData.dramaListNotifier.value = [];
  });

  group('EditDramaModal - Sembunyikan Episode 0/0 (UI Requirement)', () {
    testWidgets(
        'Jika episodes bernilai 0 (discover/trending), sembunyikan ikon list dan teks 0/0',
        (tester) async {
      final dramaWithoutEpisodes = _createDrama(
        id: 101,
        title: 'Trending Show',
        mediaType: 'tv',
        episodes: 0,
        watchedEpisodes: 0,
        status: 'Belum Ditonton',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditDramaModal(drama: dramaWithoutEpisodes),
          ),
        ),
      );
      await tester.pump();

      // Memastikan judul tampil
      expect(find.text('Trending Show'), findsOneWidget);
      // Memastikan ikon list_alt dan teks 0/0 TIDAK tampil di UI
      expect(find.byIcon(Icons.list_alt), findsNothing);
      expect(find.text('0/0'), findsNothing);
      expect(find.text('Episode'), findsNothing);
    });

    testWidgets(
        'Jika mediaType adalah movie / Film, sembunyikan ikon list dan teks 0/0',
        (tester) async {
      final movieDrama = _createDrama(
        id: 102,
        title: 'Parasite Movie',
        mediaType: 'movie',
        genre: 'Film Korea',
        episodes: 1,
        watchedEpisodes: 0,
        status: 'Belum Ditonton',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditDramaModal(drama: movieDrama),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Parasite Movie'), findsOneWidget);
      expect(find.byIcon(Icons.list_alt), findsNothing);
      expect(find.text('0/1'), findsNothing);
      expect(find.text('Episode'), findsNothing);
    });

    testWidgets(
        'Jika serial TV dengan episode valid (> 0), tampilkan ikon list dan teks episode',
        (tester) async {
      final tvDrama = _createDrama(
        id: 103,
        title: 'Crash Landing',
        mediaType: 'tv',
        genre: 'Drama Korea',
        episodes: 16,
        watchedEpisodes: 4,
        status: 'Sedang Menonton',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditDramaModal(
              drama: tvDrama,
              initialStatus: 'Sedang Menonton',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Crash Landing'), findsOneWidget);
      // Ikon list dan teks 4/16 harus muncul
      expect(find.byIcon(Icons.list_alt), findsOneWidget);
      expect(find.text('4/16'), findsWidgets);
      expect(find.text('Episode'), findsOneWidget);
    });
  });

  group('EditDramaModal - Error Handling & Rollback Database Supabase', () {
    testWidgets(
        'Jika insert ke Supabase gagal: rollback status, jangan ubah ke pena, tampilkan SnackBar merah',
        (tester) async {
      final testDrama = _createDrama(
        id: 555,
        title: 'Test Failed Insert Drama',
        mediaType: 'tv',
        episodes: 10,
        watchedEpisodes: 0,
        status: 'Belum Ditonton',
      );

      final mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/auth/v1/token')) {
          return http.Response(
            jsonEncode({
              'access_token': 'fake_token',
              'token_type': 'bearer',
              'expires_in': 3600,
              'refresh_token': 'fake_refresh',
              'user': {
                'id': 'test_user_id_123',
                'aud': 'authenticated',
                'email': 'test@example.com',
                'created_at': DateTime.now().toIso8601String(),
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        if (request.url.path.contains('/rest/v1/watchlists')) {
          return http.Response(
            jsonEncode({'message': 'Simulated DB constraint error'}),
            500,
            headers: {'content-type': 'application/json'},
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
        email: 'test@example.com',
        password: 'password',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditDramaModal(
              drama: testDrama,
              initialStatus: 'Belum Ditonton',
              supabaseClient: mockSupabase,
            ),
          ),
        ),
      );
      await tester.pump();

      // Pilih status 'Rencana Ditonton'
      await tester.tap(find.text('Belum Ditonton'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rencana Ditonton').last);
      await tester.pumpAndSettle();

      // Tekan tombol Simpan Perubahan / Tambah ke Daftar
      await tester.tap(find.text('Tambah ke Daftar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi: Objek drama status tetap 'Belum Ditonton' (di-rollback)
      expect(testDrama.status, 'Belum Ditonton');
      // Verifikasi: savedMovieIds tidak memuat id 555 (tetap '+')
      expect(SharedData.savedMovieIds.contains(555), isFalse);
      // Verifikasi: SnackBar peringatan muncul
      expect(find.textContaining('Gagal menyimpan ke database'), findsOneWidget);

      mockSupabase.dispose();
    });

    testWidgets(
        'Jika insert ke Supabase sukses: state lokal terupdate dan masuk ke savedMovieIds',
        (tester) async {
      final testDrama = _createDrama(
        id: 777,
        title: 'Test Success Insert Drama',
        mediaType: 'tv',
        episodes: 12,
        watchedEpisodes: 0,
        status: 'Belum Ditonton',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditDramaModal(
              drama: testDrama,
              initialStatus: 'Belum Ditonton',
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Belum Ditonton'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rencana Ditonton').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tambah ke Daftar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(testDrama.status, 'Rencana Ditonton');
      expect(SharedData.savedMovieIds.contains(777), isTrue);
      expect(find.textContaining('berhasil ditambahkan ke daftar'), findsOneWidget);
    });

    test('Drama.toSupabaseJson menghasilkan payload dengan tmdb_id dan judul_film', () {
      final drama = _createDrama(id: 888, title: 'Test TMDB ID');
      final json = drama.toSupabaseJson(userId: 'user_xyz');
      expect(json['tmdb_id'], 888);
      expect(json['judul_film'], 'Test TMDB ID');
      expect(json.containsKey('drama_id'), isFalse);
      expect(json.containsKey('korean_title'), isFalse);
      expect(json['user_id'], 'user_xyz');
    });

    testWidgets(
        'Supabase insert mengirimkan tmdb_id tanpa drama_id/korean_title dan menangani PGRST204 secara resilient',
        (tester) async {
      final testDrama = _createDrama(
        id: 999,
        title: 'Resilient Upsert Drama',
        mediaType: 'movie',
        episodes: 0,
        watchedEpisodes: 0,
        status: 'Belum Ditonton',
      );

      final List<Map<String, dynamic>> interceptedPayloads = [];
      int mutationCount = 0;

      final mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/auth/v1/token')) {
          return http.Response(
            jsonEncode({
              'access_token': 'fake_token',
              'token_type': 'bearer',
              'expires_in': 3600,
              'refresh_token': 'fake_refresh',
              'user': {
                'id': 'test_user_id_resilient',
                'aud': 'authenticated',
                'email': 'test@example.com',
                'created_at': DateTime.now().toIso8601String(),
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }

        if (request.url.path.contains('/rest/v1/watchlists')) {
          if (request.method == 'GET') {
            return http.Response('[]', 200,
                headers: {'content-type': 'application/json'},
                request: request);
          }

          mutationCount++;
          if (request.body.isNotEmpty) {
            final body = jsonDecode(request.body);
            if (body is Map<String, dynamic>) {
              interceptedPayloads.add(body);
            } else if (body is List && body.isNotEmpty && body.first is Map) {
              interceptedPayloads.add(Map<String, dynamic>.from(body.first as Map));
            }
          }

          // Pada panggilan mutasi pertama, simulasikan error kolom hilang (PGRST204)
          if (mutationCount == 1) {
            return http.Response(
              jsonEncode({
                'code': 'PGRST204',
                'message': "Could not find the 'non_existent_col' column of 'watchlists' in the schema cache",
                'details': '',
                'hint': null,
              }),
              400,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }

          // Panggilan mutasi kedua sukses setelah retry
          return http.Response(
            '',
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
        email: 'test@example.com',
        password: 'password',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditDramaModal(
              drama: testDrama,
              initialStatus: 'Belum Ditonton',
              supabaseClient: mockSupabase,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Belum Ditonton'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rencana Ditonton').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tambah ke Daftar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi: Panggilan pertama memuat tmdb_id dan TIDAK memuat drama_id
      expect(interceptedPayloads.isNotEmpty, isTrue);
      expect(interceptedPayloads.first['tmdb_id'], 999);
      expect(interceptedPayloads.first.containsKey('drama_id'), isFalse);

      // Verifikasi: Retry berhasil setelah PGRST204 dan status sukses
      expect(testDrama.status, 'Rencana Ditonton');
      expect(SharedData.savedMovieIds.contains(999), isTrue);

      mockSupabase.dispose();
    });
  });

  group('WatchlistTab - Fetch Database Kolom tmdb_id & Re-render', () {
    testWidgets('WatchlistTab memetakan baris dengan tmdb_id dan merender UI',
        (tester) async {
      final mockData = [
        {
          'id': 1,
          'tmdb_id': 999,
          'title': 'Watchlist Item 999',
          'genre': 'Action',
          'media_type': 'tv',
          'rating': 9.2,
          'episodes': 16,
          'watched_episodes': 8,
          'status': 'Sedang Menonton',
        }
      ];

      final mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/rest/v1/watchlists')) {
          return http.Response(
            jsonEncode(mockData),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('[]', 200,
            headers: {'content-type': 'application/json'});
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

      await tester.pumpWidget(
        MaterialApp(
          home: WatchlistTab(supabaseClient: mockSupabase),
        ),
      );
      await tester.pump();

      // Isi dramaListNotifier dengan hasil map Supabase yang memiliki tmdb_id
      SharedData.dramaListNotifier.value = [
        Drama.fromSupabase(mockData.first),
      ];
      await tester.pump();

      expect(find.text('Watchlist Item 999'), findsOneWidget);
      expect(SharedData.savedMovieIds.contains(999), isTrue);

      mockSupabase.dispose();
    });
  });
}


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tugas_pbp/data/shared_data.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/screens/watchlist_tab.dart';
import 'package:tugas_pbp/services/api_service.dart';
import 'package:tugas_pbp/widgets/edit_drama_modal.dart';

void main() {
  setUp(() {
    SharedData.dramaListNotifier.value = [];
  });

  group('WatchlistTab & EditDramaModal 3 Bugfixes Verification', () {
    testWidgets('Bug 1 (Status): Memilih "Sedang Menonton" benar-benar tersimpan sebagai "Sedang Menonton" ke Supabase dan state', (tester) async {
      final testDrama = Drama(
        id: 12345,
        title: 'Crash Course in Romance',
        koreanTitle: '일타 스캔들',
        mediaType: 'tv',
        genre: 'Drama Korea',
        rating: 8.2,
        episodes: 16,
        watchedEpisodes: 0,
        status: 'Belum Ditonton',
        priority: 'Sedang',
        startDate: '',
        endDate: '',
        date: '2023',
        image: '',
        rank: '#1',
        popularity: '100',
        watchers: '10K',
        synopsis: '',
        aired: '2023',
        duration: '70 menit',
        contentRating: '15+',
        genresList: const ['Drama'],
        tagsList: const [],
      );

      final List<Map<String, dynamic>> interceptedPayloads = [];

      final mockHttp = MockClient((request) async {
        final path = request.url.path;
        final method = request.method;

        if (path.contains('/auth/v1/token')) {
          return http.Response(
            jsonEncode({
              'access_token': 'fake_access_token',
              'token_type': 'bearer',
              'expires_in': 3600,
              'refresh_token': 'fake_refresh_token',
              'user': {
                'id': 'user_status_test',
                'aud': 'authenticated',
                'role': 'authenticated',
                'email': 'status_test@example.com',
                'created_at': DateTime.now().toIso8601String(),
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }

        if (path.contains('/rest/v1/watchlists')) {
          if (method == 'GET') {
            return http.Response('[]', 200,
                headers: {'content-type': 'application/json'},
                request: request);
          }
          if (method == 'POST') {
            if (request.body.isNotEmpty) {
              final body = jsonDecode(request.body);
              if (body is Map<String, dynamic>) {
                interceptedPayloads.add(body);
              } else if (body is List && body.isNotEmpty && body.first is Map) {
                interceptedPayloads.add(Map<String, dynamic>.from(body.first as Map));
              }
            }
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
        }

        return http.Response('{}', 200,
            headers: {'content-type': 'application/json'},
            request: request);
      });

      final mockSupabase = SupabaseClient(
        'https://fake.supabase.co',
        'fake_anon_key',
        httpClient: mockHttp,
        authOptions: const AuthClientOptions(
          autoRefreshToken: false,
          authFlowType: AuthFlowType.implicit,
        ),
      );

      await mockSupabase.auth.signInWithPassword(
        email: 'status_test@example.com',
        password: 'password123',
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
      await tester.pumpAndSettle();

      // Pilih status 'Sedang Menonton'
      await tester.tap(find.text('Belum Ditonton'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sedang Menonton').last);
      await tester.pumpAndSettle();

      // Tekan tombol Simpan Perubahan / Tambah ke Daftar
      await tester.tap(find.text('Tambah ke Daftar'));
      await tester.pumpAndSettle();

      // Verifikasi status pada objek drama tidak berubah ke 'Rencana Ditonton'
      expect(testDrama.status, 'Sedang Menonton');

      // Verifikasi payload yang dikirim ke Supabase benar-benar berisi 'status': 'Sedang Menonton'
      expect(interceptedPayloads.isNotEmpty, isTrue);
      expect(interceptedPayloads.last['status'], 'Sedang Menonton');
      expect(interceptedPayloads.last['tmdb_id'], 12345);

      mockSupabase.dispose();
    });

    testWidgets('Bug 2 (Poster): WatchlistTab mem-fetch poster dari TMDB API berdasarkan tmdb_id jika image kosong', (tester) async {
      // Drama dari Supabase dengan image kosong
      final dramaFromSupabase = Drama(
        id: 77777,
        title: 'Squid Game',
        koreanTitle: '오징어 게임',
        mediaType: 'tv',
        genre: 'Drama Korea',
        rating: 8.5,
        episodes: 9,
        watchedEpisodes: 3,
        status: 'Sedang Menonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2021',
        image: '', // Kosong dari Supabase
        rank: '#1',
        popularity: '200',
        watchers: '50K',
        synopsis: 'Survival game.',
        aired: '2021',
        duration: '60 menit',
        contentRating: '18+',
        genresList: const ['Action'],
        tagsList: const [],
      );

      SharedData.dramaListNotifier.value = [dramaFromSupabase];

      // Mock TMDB Client yang mengembalikan poster_path
      final mockTmdbClient = MockClient((request) async {
        if (request.url.path.contains('/tv/77777') || request.url.path.contains('/movie/77777')) {
          return http.Response(
            jsonEncode({
              'id': 77777,
              'name': 'Squid Game',
              'poster_path': '/squidgame_poster.jpg',
              'vote_average': 8.5,
              'number_of_episodes': 9,
              'original_language': 'ko',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      });

      final customApiService = ApiService(client: mockTmdbClient);

      await tester.pumpWidget(
        MaterialApp(
          home: WatchlistTab(apiService: customApiService),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi poster berhasil di-fetch dan drama.image terisi
      expect(dramaFromSupabase.image, contains('/squidgame_poster.jpg'));

      // Verifikasi Image.network merender URL poster TMDB tersebut
      final imageFinder = find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is NetworkImage && (widget.image as NetworkImage).url.contains('/squidgame_poster.jpg'),
      );
      expect(imageFinder, findsOneWidget);
    });

    testWidgets('Bug 3 (Keterangan Episode): Desain card di Daftar Saya menampilkan informasi total episode untuk Serial TV / Drama', (tester) async {
      final tvDrama = Drama(
        id: 88888,
        title: 'The Glory',
        koreanTitle: '더 글로리',
        mediaType: 'tv',
        genre: 'Drama Korea',
        rating: 8.9,
        episodes: 16,
        watchedEpisodes: 4,
        status: 'Sedang Menonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2022',
        image: 'https://example.com/theglory.jpg',
        rank: '#2',
        popularity: '150',
        watchers: '30K',
        synopsis: 'Pembalasan dendam.',
        aired: '2022',
        duration: '50 menit',
        contentRating: '18+',
        genresList: const ['Drama'],
        tagsList: const [],
      );

      final movieItem = Drama(
        id: 99999,
        title: 'Parasite Movie',
        koreanTitle: '기생충',
        mediaType: 'movie',
        genre: 'Film Korea',
        rating: 9.1,
        episodes: 1,
        watchedEpisodes: 0,
        status: 'Sedang Menonton',
        priority: 'Sedang',
        startDate: '',
        endDate: '',
        date: '2019',
        image: 'https://example.com/parasite.jpg',
        rank: '#1',
        popularity: '200',
        watchers: '80K',
        synopsis: 'Kisah keluarga Kim.',
        aired: '2019',
        duration: '132 menit',
        contentRating: '18+',
        genresList: const ['Film'],
        tagsList: const [],
      );

      SharedData.dramaListNotifier.value = [tvDrama, movieItem];

      await tester.pumpWidget(
        const MaterialApp(
          home: WatchlistTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Tab 'SEDANG MENONTON'
      // Untuk TV Drama (The Glory): harus menampilkan total episode '16' dan progress 'Progres: 4/16'
      expect(find.text('16'), findsOneWidget);
      expect(find.text('Progres: 4/16'), findsOneWidget);

      // Untuk Film (Parasite): tidak boleh menampilkan teks episode '1' atau 'Eps' pada header rating
      expect(find.text('Progres: 0/1'), findsNothing);
    });
  });
}

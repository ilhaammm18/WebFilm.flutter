import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_pbp/data/shared_data.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/screens/watchlist_tab.dart';
import 'package:tugas_pbp/services/api_service.dart';
import 'package:tugas_pbp/widgets/edit_drama_modal.dart';

class MockApiService extends ApiService {
  final Map<int, Drama> mockDetails;
  MockApiService({required this.mockDetails});

  @override
  Future<Drama> getMovieDetails(int movieId, {String? mediaType}) async {
    if (mockDetails.containsKey(movieId)) {
      return mockDetails[movieId]!;
    }
    throw Exception('Not found');
  }
}

Drama _createTestDrama({
  int id = 101,
  required String title,
  String genre = 'General',
  String mediaType = 'movie',
  double rating = 8.5,
  double? userRating = 0.0,
  int episodes = 1,
  int watchedEpisodes = 0,
  String status = 'Sedang Menonton',
}) {
  return Drama(
    id: id,
    title: title,
    koreanTitle: title,
    mediaType: mediaType,
    genre: genre,
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
    duration: '120 menit',
    contentRating: '13+',
    genresList: const ['Film'],
    tagsList: const [],
  );
}

void main() {
  setUp(() {
    SharedData.dramaListNotifier.value = [];
  });

  group('EditDramaModal Subtitle General Replacement Tests', () {
    testWidgets('Ganti teks General di modal edit dengan tipe tayangan Film jika mediaType adalah movie', (tester) async {
      final movieDrama = _createTestDrama(
        id: 301,
        title: 'Parasite',
        genre: 'General', // Data dari Supabase awalnya General
        mediaType: 'movie',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditDramaModal(
              drama: movieDrama,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan teks 'General' TIDAK muncul
      expect(find.text('General'), findsNothing);
      // Memastikan teks tipe tayangan 'Film' muncul di bawah judul
      expect(find.text('Film'), findsOneWidget);
    });

    testWidgets('Fetch tipe tayangan Film dari TMDB API menggunakan tmdb_id saat modal dibuka', (tester) async {
      // Drama dari Supabase awalnya genre 'General' dan mediaType default 'tv'
      final unEnrichedMovie = Drama.fromSupabase({
        'id': 1,
        'tmdb_id': 550,
        'judul_film': 'Fight Club',
        'status': 'Sedang Menonton',
        'rating': 0.0,
      });

      expect(unEnrichedMovie.genre, 'General');

      final mockApi = MockApiService(
        mockDetails: {
          550: Drama(
            id: 550,
            title: 'Fight Club',
            koreanTitle: 'Fight Club',
            genre: 'Drama',
            mediaType: 'movie',
            rating: 8.4,
            episodes: 1,
            watchedEpisodes: 0,
            status: 'Sedang Menonton',
            priority: 'Sedang',
            startDate: '',
            endDate: '',
            date: '1999',
            image: 'https://example.com/fight_club.jpg',
            rank: '#1',
            popularity: '100',
            watchers: '10K',
            synopsis: '',
            aired: '',
            duration: '139 menit',
            contentRating: '18+',
            genresList: const ['Drama'],
            tagsList: const [],
          ),
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditDramaModal(
              drama: unEnrichedMovie,
              apiService: mockApi,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi: Teks 'General' sudah digantikan dengan tipe tayangan 'Film'
      expect(find.text('General'), findsNothing);
      expect(find.text('Film'), findsOneWidget);
    });

    testWidgets('Tipe tayangan Serial TV ditampilkan untuk drama serial bergenre General', (tester) async {
      final tvDrama = _createTestDrama(
        id: 302,
        title: 'Stranger Things',
        genre: 'General',
        mediaType: 'tv',
        episodes: 25,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditDramaModal(
              drama: tvDrama,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('General'), findsNothing);
      expect(find.text('Serial TV'), findsOneWidget);
    });

    testWidgets('Card Daftar Saya dan Modal Edit konsisten menampilkan tipe tayangan yang sama (Film)', (tester) async {
      final movieItem = _createTestDrama(
        id: 777,
        title: 'Interstellar',
        genre: 'General',
        mediaType: 'movie',
      );

      SharedData.dramaListNotifier.value = [movieItem];

      await tester.pumpWidget(
        const MaterialApp(
          home: WatchlistTab(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verifikasi: Di Card Daftar Saya sudah menampilkan teks 'Film'
      expect(find.text('Film'), findsOneWidget);
      expect(find.text('General'), findsNothing);

      // Buka modal edit melalui tombol pensil di card
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verifikasi: Di header Modal Edit juga menampilkan 'Film', bukan 'General'
      expect(find.byType(EditDramaModal), findsOneWidget);
      expect(find.text('General'), findsNothing);
      // 'Film' ditemukan di card dan di header modal
      expect(find.text('Film'), findsWidgets);
    });
  });
}

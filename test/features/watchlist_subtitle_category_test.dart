import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/screens/watchlist_tab.dart';
import 'package:tugas_pbp/utils/helpers.dart';
import 'package:tugas_pbp/data/shared_data.dart';

void main() {
  group('Logika Helper Kategori & Subtitle Card Watchlist Tests', () {
    test('getDynamicLabel dan getCustomCategory mengembalikan kategori yang tepat sesuai bahasa & tipe', () {
      // 1. original_language 'ko' dan tipe 'tv' -> 'Drama Korea'
      final kdrama = Drama(
        title: 'Crash Landing on You',
        koreanTitle: '사랑의 불시착',
        genre: 'Romance',
        mediaType: 'tv',
        originalLanguage: 'ko',
        rating: 9.0,
        episodes: 16,
        watchedEpisodes: 4,
        status: 'Sedang Menonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2019',
        image: '',
        rank: '#1',
        popularity: '100',
        watchers: '10K',
        synopsis: 'Romance.',
        aired: '2019',
        duration: '70 menit',
        contentRating: '15+',
        genresList: ['Romance'],
        tagsList: [],
      );
      expect(getDynamicLabel(drama: kdrama), equals('Drama Korea'));
      expect(getCustomCategory(drama: kdrama), equals('Drama Korea'));

      // 2. original_language 'ko' dan tipe 'movie' -> 'Film Korea'
      final kmovie = Drama(
        title: 'Parasite',
        koreanTitle: '기생충',
        genre: 'Thriller',
        mediaType: 'movie',
        originalLanguage: 'ko',
        rating: 9.5,
        episodes: 1,
        watchedEpisodes: 1,
        status: 'Selesai',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2019',
        image: '',
        rank: '#1',
        popularity: '200',
        watchers: '50K',
        synopsis: 'Thriller.',
        aired: '2019',
        duration: '132 menit',
        contentRating: '18+',
        genresList: ['Thriller'],
        tagsList: [],
      );
      expect(getDynamicLabel(drama: kmovie), equals('Film Korea'));
      expect(getCustomCategory(drama: kmovie), equals('Film Korea'));

      // 3. original_language 'en' dan tipe 'tv' -> 'Drama Barat'
      final wdrama = Drama(
        title: 'Breaking Bad',
        koreanTitle: '',
        genre: 'Crime',
        mediaType: 'tv',
        originalLanguage: 'en',
        rating: 9.5,
        episodes: 62,
        watchedEpisodes: 10,
        status: 'Sedang Menonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2008',
        image: '',
        rank: '#1',
        popularity: '300',
        watchers: '100K',
        synopsis: 'Chemistry teacher.',
        aired: '2008',
        duration: '45 menit',
        contentRating: '18+',
        genresList: ['Crime'],
        tagsList: [],
      );
      expect(getDynamicLabel(drama: wdrama), equals('Drama Barat'));
      expect(getCustomCategory(drama: wdrama), equals('Drama Barat'));

      // 4. original_language 'en' dan tipe 'movie' -> 'Film Barat'
      final wmovie = Drama(
        title: 'Inception',
        koreanTitle: '',
        genre: 'Sci-Fi',
        mediaType: 'movie',
        originalLanguage: 'en',
        rating: 9.2,
        episodes: 1,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Sedang',
        startDate: '',
        endDate: '',
        date: '2010',
        image: '',
        rank: '#2',
        popularity: '250',
        watchers: '80K',
        synopsis: 'Dream within a dream.',
        aired: '2010',
        duration: '148 menit',
        contentRating: '13+',
        genresList: ['Sci-Fi'],
        tagsList: [],
      );
      expect(getDynamicLabel(drama: wmovie), equals('Film Barat'));
      expect(getCustomCategory(drama: wmovie), equals('Film Barat'));
    });

    testWidgets('Subtitle pada card WatchlistTab menampilkan kategori kustom bukan format hardcoded genre/tahun', (tester) async {
      final kdrama = Drama(
        title: 'My Mister',
        koreanTitle: '나의 아저씨',
        genre: 'Drama',
        mediaType: 'tv',
        originalLanguage: 'ko',
        rating: 9.1,
        episodes: 16,
        watchedEpisodes: 5,
        status: 'Sedang Menonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2018',
        image: '',
        rank: '#1',
        popularity: '100',
        watchers: '10K',
        synopsis: '',
        aired: '2018',
        duration: '75 menit',
        contentRating: '15+',
        genresList: ['Drama'],
        tagsList: [],
      );

      final wdrama = Drama(
        title: 'Stranger Things',
        koreanTitle: '',
        genre: 'Sci-Fi',
        mediaType: 'tv',
        originalLanguage: 'en',
        rating: 8.7,
        episodes: 34,
        watchedEpisodes: 10,
        status: 'Sedang Menonton',
        priority: 'Sedang',
        startDate: '',
        endDate: '',
        date: '2016',
        image: '',
        rank: '#2',
        popularity: '200',
        watchers: '50K',
        synopsis: '',
        aired: '2016',
        duration: '50 menit',
        contentRating: '15+',
        genresList: ['Sci-Fi'],
        tagsList: [],
      );

      SharedData.dramaListNotifier.value = [kdrama, wdrama];

      await tester.pumpWidget(
        const MaterialApp(
          home: WatchlistTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan kedua judul tampil
      expect(find.text('My Mister'), findsOneWidget);
      expect(find.text('Stranger Things'), findsOneWidget);

      // Memastikan subtitle card adalah kategori kustom
      expect(find.text('Drama Korea'), findsOneWidget);
      expect(find.text('Drama Barat'), findsOneWidget);

      // Memastikan format lama hardcoded • 2025 tidak tampil
      expect(find.textContaining('• 2025'), findsNothing);
    });

    test('Drama toSupabaseJson dan fromSupabase menyertakan original_language dan media_type', () {
      final original = Drama(
        title: 'Squid Game',
        koreanTitle: '오징어 게임',
        genre: 'Thriller',
        mediaType: 'tv',
        originalLanguage: 'ko',
        rating: 8.5,
        episodes: 9,
        watchedEpisodes: 9,
        status: 'Selesai',
        priority: 'Tinggi',
        startDate: '2021-09-17',
        endDate: '2021-09-20',
        date: '2021',
        image: 'https://example.com/squid.jpg',
        rank: '#1',
        popularity: '500',
        watchers: '100K',
        synopsis: 'Survival game.',
        aired: '2021',
        duration: '55 menit',
        contentRating: '18+',
        genresList: ['Thriller'],
        tagsList: [],
      );

      final json = original.toSupabaseJson(userId: 'test-user-uuid');
      expect(json['user_id'], equals('test-user-uuid'));
      expect(json['media_type'], equals('tv'));
      expect(json['original_language'], equals('ko'));

      final restored = Drama.fromSupabase(json);
      expect(restored.mediaType, equals('tv'));
      expect(restored.originalLanguage, equals('ko'));
      expect(getDynamicLabel(drama: restored), equals('Drama Korea'));
    });
  });
}

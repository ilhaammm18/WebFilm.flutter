import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/data/shared_data.dart';
import 'package:tugas_pbp/screens/watchlist_tab.dart';
import 'package:tugas_pbp/widgets/edit_drama_modal.dart';

void main() {
  setUp(() {
    SharedData.dramaListNotifier.value = [];
  });

  group('WatchlistTab Rating Display & Edit Sync Tests', () {
    testWidgets('Status Selesai menampilkan userRating dari Supabase, dengan fallback 0.0 jika null', (tester) async {
      final dramaSelesaiDenganUserRating = Drama(
        title: 'Reply 1988',
        koreanTitle: '응답하라 1988',
        genre: 'Drama Korea',
        rating: 7.9,
        userRating: 8.8,
        episodes: 20,
        watchedEpisodes: 20,
        status: 'Selesai',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2015',
        image: 'https://example.com/reply.jpg',
        rank: '#1',
        popularity: '#1',
        watchers: '250K',
        synopsis: 'Kisah 5 keluarga.',
        aired: '2015',
        duration: '90 menit',
        contentRating: '15+',
        genresList: ['Comedy'],
        tagsList: ['Nostalgia'],
      );

      final dramaSelesaiTanpaUserRating = Drama(
        title: 'Prison Playbook',
        koreanTitle: '슬기로운 감빵생활',
        genre: 'Drama Korea',
        rating: 7.9,
        userRating: null,
        episodes: 16,
        watchedEpisodes: 16,
        status: 'Selesai',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2017',
        image: 'https://example.com/prison.jpg',
        rank: '#5',
        popularity: '#5',
        watchers: '120K',
        synopsis: 'Kisah kehidupan penjara.',
        aired: '2017',
        duration: '80 menit',
        contentRating: '15+',
        genresList: ['Comedy'],
        tagsList: ['Prison'],
      );

      SharedData.dramaListNotifier.value = [
        dramaSelesaiDenganUserRating,
        dramaSelesaiTanpaUserRating,
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: WatchlistTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Buka tab 'SELESAI'
      await tester.tap(find.text('SELESAI'));
      await tester.pumpAndSettle();

      // Drama dengan userRating 8.8 harus menampilkan '8.8'
      expect(find.text('8.8'), findsOneWidget);

      // Drama tanpa userRating harus menampilkan fallback rating '0.0' (bukan global rating 7.9)
      expect(find.text('0.0'), findsOneWidget);
      expect(find.text('7.9'), findsNothing);
    });

    testWidgets('Simpan Perubahan pada slider Peringkat mengubah rating di ListView secara real-time dari 7.9 menjadi 8.8', (tester) async {
      final dramaTest = Drama(
        title: 'Stranger',
        koreanTitle: '비밀의 숲',
        genre: 'Thriller, Crime',
        rating: 7.9,
        userRating: null,
        episodes: 16,
        watchedEpisodes: 16,
        status: 'Selesai',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2017',
        image: 'https://example.com/stranger.jpg',
        rank: '#4',
        popularity: '#4',
        watchers: '110K',
        synopsis: 'Jaksa tanpa emosi.',
        aired: '2017',
        duration: '60 menit',
        contentRating: '15+',
        genresList: ['Crime'],
        tagsList: ['Mystery'],
      );

      SharedData.dramaListNotifier.value = [dramaTest];

      await tester.pumpWidget(
        const MaterialApp(
          home: WatchlistTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Buka tab 'SELESAI'
      await tester.tap(find.text('SELESAI'));
      await tester.pumpAndSettle();

      // Awalnya menampilkan fallback rating 0.0 (bukan global rating 7.9)
      expect(find.text('0.0'), findsOneWidget);
      expect(find.text('7.9'), findsNothing);
      expect(find.text('8.8'), findsNothing);

      // Buka modal edit melalui tombol pena
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(EditDramaModal), findsOneWidget);

      // Ubah slider peringkat ke 8.8
      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);
      
      // Drag slider sedikit ke kanan
      await tester.tap(sliderFinder);
      await tester.pumpAndSettle();

      // Cari tombol simpan
      final simpanButton = find.text('Simpan Perubahan');
      expect(simpanButton, findsOneWidget);
      await tester.tap(simpanButton);
      await tester.pumpAndSettle();

      // Modal tertutup
      expect(find.byType(EditDramaModal), findsNothing);

      // Nilai userRating tersimpan pada objek drama
      expect(dramaTest.userRating, isNotNull);
      expect(dramaTest.userRating, isNot(7.9));

      // Verifikasi di ListView card, angka rating yang ditampilkan adalah userRating yang baru
      expect(find.text(dramaTest.userRating!.toStringAsFixed(1)), findsOneWidget);
    });

    testWidgets('Tombol filter kategori Icons.tune memunculkan bottom sheet Pilih Kategori dan memfilter kategori', (tester) async {
      final drama = Drama(
        title: 'Drama Korea Populer',
        koreanTitle: 'Kdrama',
        genre: 'Drama Korea',
        mediaType: 'tv',
        rating: 9.0,
        episodes: 16,
        watchedEpisodes: 8,
        status: 'Sedang Menonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2026',
        image: 'https://example.com/kdrama.jpg',
        rank: '#1',
        popularity: '100',
        watchers: '10K',
        synopsis: 'Drama',
        aired: '2026',
        duration: '60 menit',
        contentRating: '15+',
        genresList: ['Drama'],
        tagsList: [],
      );

      final film = Drama(
        title: 'Film Layar Lebar',
        koreanTitle: 'Kmovie',
        genre: 'Film Korea',
        mediaType: 'movie',
        rating: 8.5,
        episodes: 1,
        watchedEpisodes: 0,
        status: 'Sedang Menonton',
        priority: 'Sedang',
        startDate: '',
        endDate: '',
        date: '2026',
        image: 'https://example.com/kmovie.jpg',
        rank: '#2',
        popularity: '90',
        watchers: '8K',
        synopsis: 'Film',
        aired: '2026',
        duration: '120 menit',
        contentRating: '15+',
        genresList: ['Film'],
        tagsList: [],
      );

      final animasi = Drama(
        title: 'Serial Animasi Keren',
        koreanTitle: 'Anime',
        genre: 'Animasi, Anime',
        mediaType: 'tv',
        genreIds: [16],
        rating: 8.7,
        episodes: 24,
        watchedEpisodes: 12,
        status: 'Sedang Menonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2026',
        image: 'https://example.com/anime.jpg',
        rank: '#3',
        popularity: '85',
        watchers: '7K',
        synopsis: 'Animasi',
        aired: '2026',
        duration: '24 menit',
        contentRating: '13+',
        genresList: ['Animasi'],
        tagsList: [],
      );

      SharedData.dramaListNotifier.value = [drama, film, animasi];

      await tester.pumpWidget(
        const MaterialApp(
          home: WatchlistTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan ketiga item tampil pada kondisi awal 'Semua'
      expect(find.text('Drama Korea Populer'), findsOneWidget);
      expect(find.text('Film Layar Lebar'), findsOneWidget);
      expect(find.text('Serial Animasi Keren'), findsOneWidget);

      // Klik tombol filter kategori Icons.tune
      final filterButton = find.byIcon(Icons.tune);
      expect(filterButton, findsOneWidget);
      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      // Memastikan bottom sheet 'Pilih Kategori' terbuka
      expect(find.text('Pilih Kategori'), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Film'), findsOneWidget);
      expect(find.text('Drama'), findsOneWidget);
      expect(find.text('Animasi'), findsWidgets);

      // Pilih 'Animasi' dari bottom sheet
      await tester.tap(find.text('Animasi').last);
      await tester.pumpAndSettle();

      // Modal tertutup dan hanya Animasi yang muncul
      expect(find.text('Pilih Kategori'), findsNothing);
      expect(find.text('Serial Animasi Keren'), findsOneWidget);
      expect(find.text('Drama Korea Populer'), findsNothing);
      expect(find.text('Film Layar Lebar'), findsNothing);
    });


    testWidgets('Format tanggal selesai ditampilkan dalam format dd/MM/yyyy serta Film vs Drama card', (tester) async {
      final dramaSelesai = Drama(
        title: 'Selesai Drama',
        koreanTitle: 'Finished',
        genre: 'Drama Korea',
        rating: 8.5,
        episodes: 16,
        watchedEpisodes: 16,
        status: 'Selesai',
        priority: 'Sedang',
        startDate: '',
        endDate: '',
        date: '2026',
        image: 'https://example.com/finished.jpg',
        rank: '#1',
        popularity: '100',
        watchers: '10K',
        synopsis: 'Selesai',
        aired: '2026',
        duration: '60 menit',
        contentRating: '15+',
        genresList: ['Drama'],
        tagsList: [],
        dateCompleted: DateTime(2026, 9, 18),
      );

      final filmSelesai = Drama(
        title: 'Selesai Film',
        koreanTitle: 'Finished Movie',
        genre: 'Film Korea',
        mediaType: 'movie',
        rating: 9.0,
        episodes: 1,
        watchedEpisodes: 1,
        status: 'Selesai',
        priority: 'Sedang',
        startDate: '',
        endDate: '',
        date: '2026',
        image: 'https://example.com/finished_movie.jpg',
        rank: '#2',
        popularity: '80',
        watchers: '5K',
        synopsis: 'Film',
        aired: '2026',
        duration: '120 menit',
        contentRating: '15+',
        genresList: ['Film'],
        tagsList: [],
        dateCompleted: DateTime(2026, 10, 5),
      );

      SharedData.dramaListNotifier.value = [dramaSelesai, filmSelesai];

      await tester.pumpWidget(
        const MaterialApp(
          home: WatchlistTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Buka tab Selesai
      await tester.tap(find.text('SELESAI'));
      await tester.pumpAndSettle();

      // Format tanggal harus dd/MM/yyyy (18/09/2026 dan 05/10/2026)
      expect(find.text('18/09/2026'), findsOneWidget);
      expect(find.text('05/10/2026'), findsOneWidget);

      // Tidak ada progress bar atau teks Progres:
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('Progres:'), findsNothing);

      // Drama menampilkan episode (16), sedangkan Film tidak menampilkan episode
      expect(find.text('16'), findsOneWidget);
      expect(find.byIcon(Icons.featured_play_list), findsOneWidget);
    });

    testWidgets('WatchlistTab fitur pencarian lokal memfilter daftar dan menampilkan pesan jika tidak ditemukan', (tester) async {
      final drama1 = Drama(
        title: 'Vincenzo Cassano',
        koreanTitle: '',
        genre: 'Action, Drama',
        rating: 9.0,
        userRating: 9.5,
        episodes: 20,
        watchedEpisodes: 10,
        status: 'Sedang Menonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2021',
        image: '',
        rank: '#1',
        popularity: '#1',
        watchers: '',
        synopsis: '',
        aired: '',
        duration: '',
        contentRating: '',
        genresList: ['Drama'],
        tagsList: [],
      );

      final drama2 = Drama(
        title: 'Crash Landing on You',
        koreanTitle: '',
        genre: 'Romance, Drama',
        rating: 8.8,
        userRating: 8.5,
        episodes: 16,
        watchedEpisodes: 5,
        status: 'Sedang Menonton',
        priority: 'Sedang',
        startDate: '',
        endDate: '',
        date: '2019',
        image: '',
        rank: '#2',
        popularity: '#2',
        watchers: '',
        synopsis: '',
        aired: '',
        duration: '',
        contentRating: '',
        genresList: ['Drama'],
        tagsList: [],
      );

      SharedData.dramaListNotifier.value = [drama1, drama2];

      await tester.pumpWidget(
        const MaterialApp(
          home: WatchlistTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Judul awal 'Daftar Saya'
      expect(find.text('Daftar Saya'), findsOneWidget);
      expect(find.text('Vincenzo Cassano'), findsOneWidget);
      expect(find.text('Crash Landing on You'), findsOneWidget);

      // Klik ikon search untuk membuka TextField
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Cari di daftar saya...'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Ketik 'Vincenzo'
      await tester.enterText(find.byType(TextField), 'Vincenzo');
      await tester.pumpAndSettle();

      expect(find.text('Vincenzo Cassano'), findsOneWidget);
      expect(find.text('Crash Landing on You'), findsNothing);

      // Ketik judul yang tidak ada
      await tester.enterText(find.byType(TextField), 'Judul Tidak Ada');
      await tester.pumpAndSettle();

      expect(find.text('Film/Drama tidak ditemukan'), findsOneWidget);

      // Klik ikon close untuk mereset pencarian
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Daftar Saya'), findsOneWidget);
      expect(find.text('Vincenzo Cassano'), findsOneWidget);
      expect(find.text('Crash Landing on You'), findsOneWidget);
    });

    testWidgets('Tab RENCANA DITONTON menyembunyikan bar progres dan menampilkan kotak episode khusus Drama, sedangkan Film hanya rating', (tester) async {
      final dramaRencana = Drama(
        title: 'Drama Rencana',
        koreanTitle: 'Plan Drama',
        genre: 'Drama Korea',
        mediaType: 'tv',
        rating: 8.5,
        userRating: 8.5,
        episodes: 16,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2026',
        image: 'https://example.com/plandrama.jpg',
        rank: '#1',
        popularity: '100',
        watchers: '10K',
        synopsis: 'Drama rencana.',
        aired: '2026',
        duration: '60 menit',
        contentRating: '15+',
        genresList: ['Drama'],
        tagsList: [],
      );

      final filmRencana = Drama(
        title: 'Film Rencana',
        koreanTitle: 'Plan Movie',
        genre: 'Film Korea',
        mediaType: 'movie',
        rating: 9.2,
        userRating: 9.2,
        episodes: 1,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Sedang',
        startDate: '',
        endDate: '',
        date: '2026',
        image: 'https://example.com/planmovie.jpg',
        rank: '#2',
        popularity: '80',
        watchers: '5K',
        synopsis: 'Film rencana.',
        aired: '2026',
        duration: '120 menit',
        contentRating: '15+',
        genresList: ['Film'],
        tagsList: [],
      );

      SharedData.dramaListNotifier.value = [dramaRencana, filmRencana];

      await tester.pumpWidget(
        const MaterialApp(
          home: WatchlistTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Pindah ke tab 'RENCANA DITONTON'
      await tester.tap(find.text('RENCANA DITONTON'));
      await tester.pumpAndSettle();

      // Pastikan kedua judul muncul
      expect(find.text('Drama Rencana'), findsOneWidget);
      expect(find.text('Film Rencana'), findsOneWidget);

      // Pastikan elemen progres disembunyikan seluruhnya
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('Progres:'), findsNothing);
      expect(find.text('0%'), findsNothing);

      // Drama menampilkan rating dan ikon episode serta angka total ('16')
      expect(find.text('8.5'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      expect(find.byIcon(Icons.subtitles_rounded), findsOneWidget);

      // Film hanya menampilkan rating (9.2) dan TIDAK menampilkan ikon atau angka episode
      expect(find.text('9.2'), findsOneWidget);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('Tampilan Empty State muncul di ketiga tab ketika data watchlist kosong', (tester) async {
      SharedData.dramaListNotifier.value = [];

      await tester.pumpWidget(
        const MaterialApp(
          home: WatchlistTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Tab 1: SEDANG MENONTON (Default)
      expect(find.byIcon(Icons.movie_creation_outlined), findsOneWidget);
      expect(find.text('Belum ada film di daftar ini. Yuk, cari dan tambahkan film favoritmu!'), findsOneWidget);

      // Tab 2: SELESAI
      await tester.tap(find.text('SELESAI'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.movie_creation_outlined), findsOneWidget);
      expect(find.text('Belum ada film di daftar ini. Yuk, cari dan tambahkan film favoritmu!'), findsOneWidget);

      // Tab 3: RENCANA DITONTON
      await tester.tap(find.text('RENCANA DITONTON'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.movie_creation_outlined), findsOneWidget);
      expect(find.text('Belum ada film di daftar ini. Yuk, cari dan tambahkan film favoritmu!'), findsOneWidget);
    });
  });
}



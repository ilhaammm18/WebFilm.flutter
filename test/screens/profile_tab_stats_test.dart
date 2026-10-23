import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/data/shared_data.dart';
import 'package:tugas_pbp/screens/profile_tab.dart';

void main() {
  setUp(() {
    SharedData.dramaListNotifier.value = [];
  });

  testWidgets('Judul Tentang Saya tidak memuat (About Me)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileTab(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tentang Saya'), findsOneWidget);
    expect(find.text('Tentang Saya (About Me)'), findsNothing);
  });

  testWidgets('Akun baru tanpa tontonan menampilkan semua statistik bernilai 0', (tester) async {
    SharedData.dramaListNotifier.value = [];

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileTab(),
      ),
    );
    await tester.pumpAndSettle();

    // 4 kartu waktu tonton berdurasi 0h 0m
    expect(find.text('0h 0m'), findsNWidgets(4));

    // Teks bawah tiap kartu
    expect(find.text('0 episode, 0 drama'), findsOneWidget);
    expect(find.text('0 film'), findsOneWidget);
    expect(find.text('0 episode, 0 animasi'), findsOneWidget);
    expect(find.text('0 tontonan'), findsOneWidget);
  });

  testWidgets('Item dengan status Rencana Ditonton diabaikan dalam perhitungan', (tester) async {
    SharedData.dramaListNotifier.value = [
      Drama(
        title: 'Film Rencana',
        koreanTitle: '영화 계획',
        genre: 'Action Film',
        mediaType: 'movie',
        rating: 8.0,
        episodes: 1,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Sedang',
        startDate: '',
        endDate: '',
        date: '2023',
        image: 'https://example.com/movie.jpg',
        rank: '#1',
        popularity: '100',
        watchers: '10K',
        synopsis: 'Sinopsis',
        aired: '2023',
        duration: '120 menit',
        contentRating: '13+',
        genresList: ['Action'],
        tagsList: [],
        runtime: 120,
      ),
      Drama(
        title: 'Drama Rencana',
        koreanTitle: '드라마 계획',
        genre: 'Romance',
        mediaType: 'tv',
        rating: 8.0,
        episodes: 16,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Sedang',
        startDate: '',
        endDate: '',
        date: '2023',
        image: 'https://example.com/drama.jpg',
        rank: '#2',
        popularity: '100',
        watchers: '10K',
        synopsis: 'Sinopsis',
        aired: '2023',
        duration: '60 menit',
        contentRating: '13+',
        genresList: ['Romance'],
        tagsList: [],
        runtime: 60,
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileTab(),
      ),
    );
    await tester.pumpAndSettle();

    // Semua tetap bernilai 0
    expect(find.text('0h 0m'), findsNWidgets(4));
    expect(find.text('0 episode, 0 drama'), findsOneWidget);
    expect(find.text('0 film'), findsOneWidget);
    expect(find.text('0 episode, 0 animasi'), findsOneWidget);
    expect(find.text('0 tontonan'), findsOneWidget);
  });

  testWidgets('Perhitungan konkret real-time dari data Watchlist Supabase', (tester) async {
    SharedData.dramaListNotifier.value = [
      // 1. Film Selesai dengan runtime 130 menit (2h 10m)
      Drama(
        title: 'Parasite',
        koreanTitle: '기생충',
        genre: 'Drama Film',
        mediaType: 'movie',
        rating: 9.0,
        episodes: 1,
        watchedEpisodes: 1,
        status: 'Selesai',
        priority: 'Tinggi',
        startDate: '2023-01-01',
        endDate: '2023-01-01',
        date: '2019',
        image: 'https://example.com/parasite.jpg',
        rank: '#1',
        popularity: '999',
        watchers: '500K',
        synopsis: 'Parasite story',
        aired: '2019',
        duration: '130 menit',
        contentRating: '18+',
        genresList: ['Drama', 'Thriller'],
        tagsList: [],
        runtime: 130,
      ),
      // 2. Drama Sedang Menonton: 8 episode ditonton, runtime kosong -> fallback 50m per ep = 400m (6h 40m)
      Drama(
        title: 'Vincenzo',
        koreanTitle: '빈센조',
        genre: 'Crime Drama',
        mediaType: 'tv',
        rating: 8.8,
        episodes: 20,
        watchedEpisodes: 8,
        status: 'Sedang Menonton',
        priority: 'Tinggi',
        startDate: '2023-02-01',
        endDate: '',
        date: '2021',
        image: 'https://example.com/vincenzo.jpg',
        rank: '#2',
        popularity: '800',
        watchers: '300K',
        synopsis: 'Consigliere story',
        aired: '2021',
        duration: '',
        contentRating: '15+',
        genresList: ['Crime', 'Drama'],
        tagsList: [],
        runtime: null,
      ),
      // 3. Animasi (genre 16): 10 episode ditonton, runtime kosong -> fallback 24m per ep = 240m (4h 0m)
      Drama(
        title: 'Demon Slayer',
        koreanTitle: '귀멸의 칼날',
        genre: 'Animasi',
        mediaType: 'tv',
        rating: 9.2,
        episodes: 26,
        watchedEpisodes: 10,
        status: 'Sedang Menonton',
        priority: 'Tinggi',
        startDate: '2023-03-01',
        endDate: '',
        date: '2019',
        image: 'https://example.com/demonslayer.jpg',
        rank: '#3',
        popularity: '1200',
        watchers: '700K',
        synopsis: 'Tanjiro story',
        aired: '2019',
        duration: '',
        contentRating: '15+',
        genresList: ['Animasi', 'Action'],
        tagsList: [],
        genreIds: [16, 28],
        runtime: null,
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileTab(),
      ),
    );
    await tester.pumpAndSettle();

    // Cek FILM: 130 menit -> 2h 10m, '1 film'
    expect(find.text('2h 10m'), findsOneWidget);
    expect(find.text('1 film'), findsOneWidget);

    // Cek DRAMA: 8 episode * 50 menit = 400 menit -> 6h 40m, '8 episode, 1 drama'
    expect(find.text('6h 40m'), findsOneWidget);
    expect(find.text('8 episode, 1 drama'), findsOneWidget);

    // Cek ANIMASI: 10 episode * 24 menit = 240 menit -> 4h 0m, '10 episode, 1 animasi'
    expect(find.text('4h 0m'), findsOneWidget);
    expect(find.text('10 episode, 1 animasi'), findsOneWidget);

    // Cek TOTAL KESELURUHAN:
    // Total menit = 130 + 400 + 240 = 770 menit -> 12h 50m
    // Total tontonan = 1 + 1 + 1 = 3 tontonan
    expect(find.text('12h 50m'), findsOneWidget);
    expect(find.text('3 tontonan'), findsOneWidget);
  });

  testWidgets('Format tampilan waktu 24 jam atau lebih menggunakan format Xd Yh Zm', (tester) async {
    // 30 episode drama * 50m = 1500m -> 1d 1h 0m
    SharedData.dramaListNotifier.value = [
      Drama(
        title: 'Long Drama',
        koreanTitle: '긴 드라마',
        genre: 'Historical',
        mediaType: 'tv',
        rating: 8.5,
        episodes: 50,
        watchedEpisodes: 30,
        status: 'Sedang Menonton',
        priority: 'Sedang',
        startDate: '',
        endDate: '',
        date: '2020',
        image: 'https://example.com/long.jpg',
        rank: '#1',
        popularity: '100',
        watchers: '10K',
        synopsis: 'Long story',
        aired: '2020',
        duration: '50 menit',
        contentRating: '13+',
        genresList: ['Historical'],
        tagsList: [],
        runtime: 50,
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileTab(),
      ),
    );
    await tester.pumpAndSettle();

    // 1500 menit = 25 jam = 1 hari 1 jam 0 menit -> 1d 1h 0m
    // Muncul di kartu DRAMA dan TOTAL KESELURUHAN (2 widgets)
    expect(find.text('1d 1h 0m'), findsNWidgets(2));
    expect(find.text('30 episode, 1 drama'), findsOneWidget);
    expect(find.text('1 tontonan'), findsOneWidget);
  });
}

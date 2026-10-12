import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/data/shared_data.dart';
import 'package:tugas_pbp/screens/profile_tab.dart';
import 'package:tugas_pbp/services/api_service.dart';

void main() {
  setUp(() {
    SharedData.dramaListNotifier.value = [];
  });

  testWidgets('ProfileTab rating badge logika kondisional status Selesai vs bukan Selesai', (tester) async {
    final dramaSelesai = Drama(
      title: 'Drama Selesai',
      koreanTitle: '완료 드라마',
      genre: 'Romance',
      rating: 8.5,
      userRating: 9.2,
      episodes: 16,
      watchedEpisodes: 16,
      status: 'Selesai',
      priority: 'Tinggi',
      startDate: '',
      endDate: '',
      date: '2023',
      image: 'https://example.com/poster1.jpg',
      rank: '#1',
      popularity: '#1',
      watchers: '100K',
      synopsis: 'Sinopsis 1',
      aired: '2023',
      duration: '60 menit',
      contentRating: '15+',
      genresList: ['Romance'],
      tagsList: ['Love'],
    );

    final dramaSedangNonton = Drama(
      title: 'Drama Sedang Nonton',
      koreanTitle: '시청 중 드라마',
      genre: 'Action',
      rating: 9.0,
      userRating: 8.0,
      episodes: 16,
      watchedEpisodes: 8,
      status: 'Sedang Menonton',
      priority: 'Sedang',
      startDate: '',
      endDate: '',
      date: '2023',
      image: 'https://example.com/poster2.jpg',
      rank: '#2',
      popularity: '#2',
      watchers: '50K',
      synopsis: 'Sinopsis 2',
      aired: '2023',
      duration: '60 menit',
      contentRating: '15+',
      genresList: ['Action'],
      tagsList: ['Fight'],
    );

    SharedData.dramaListNotifier.value = [
      dramaSelesai,
      dramaSedangNonton,
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileTab(),
      ),
    );
    await tester.pumpAndSettle();

    // Untuk drama dengan status 'Selesai', rating yang ditampilkan adalah userRating (9.2)
    expect(find.text('9.2'), findsOneWidget);

    // Untuk drama dengan status 'Sedang Menonton' (bukan 'Selesai'), rating dipaksa tampil '0.0'
    expect(find.text('0.0'), findsOneWidget);
  });

  testWidgets('ProfileTab menampilkan susunan 2x2 statistik waktu tonton: DRAMA, FILM, ANIMASI, TOTAL KESELURUHAN', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileTab(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DRAMA'), findsOneWidget);
    expect(find.text('FILM'), findsOneWidget);
    expect(find.text('ANIMASI'), findsOneWidget);
    expect(find.text('TOTAL KESELURUHAN'), findsOneWidget);

    expect(find.text('2d 4h 30m'), findsOneWidget);
    expect(find.text('10d 13h 25m'), findsOneWidget);
    expect(find.text('45 episode, 3 animasi'), findsOneWidget);
    expect(find.text('234 tontonan'), findsOneWidget);
  });


  test('SharedData.syncWithTmdb memetakan hasil TMDB ke dalam Watchlist dan Profil dengan poster konkret', () async {
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('/movie/popular')) {
        return http.Response(
          json.encode({
            'page': 1,
            'results': [
              {
                'id': 101,
                'title': 'Real TMDB Movie 1',
                'poster_path': '/real_movie1.jpg',
                'vote_average': 8.8,
              },
              {
                'id': 102,
                'title': 'Real TMDB Movie 2',
                'poster_path': '/real_movie2.jpg',
                'vote_average': 7.6,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      if (request.url.path.contains('/tv/popular')) {
        return http.Response(
          json.encode({
            'page': 1,
            'results': [
              {
                'id': 201,
                'name': 'Real TMDB Drama 1',
                'poster_path': '/real_drama1.jpg',
                'vote_average': 9.1,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response('Not Found', 404);
    });

    final apiService = ApiService(client: mockClient);
    await SharedData.syncWithTmdb(apiService: apiService);

    final list = SharedData.dramaListNotifier.value;
    expect(list.length, 3);

    final statuses = list.map((d) => d.status).toSet();
    expect(statuses.contains('Sedang Menonton'), true);
    expect(statuses.contains('Selesai'), true);
    expect(statuses.contains('Rencana Ditonton'), true);

    // Semua gambar berasal dari TMDB konkret, bukan picsum
    for (final item in list) {
      expect(item.image.startsWith('https://image.tmdb.org/t/p/w500/'), true);
      expect(item.image.contains('picsum'), false);
    }
  });

  testWidgets('ProfileTab: AppBar bersih tanpa actions, hanya memiliki ikon menu di sebelah kiri', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileTab(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Memeriksa ikon menu hamburger ada di leading AppBar
    expect(find.byIcon(Icons.menu), findsOneWidget);

    // 2. Memastikan actions di AppBar telah dihapus (tidak ada ikon edit, settings, support_agent di layar)
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
    expect(find.byIcon(Icons.support_agent), findsNothing);

    // 3. Memastikan tombol ElevatedButton 'Edit Profil' dan 'Pengaturan' juga TIDAK ADA di body
    expect(find.byType(ElevatedButton), findsNothing);

    // 4. Memverifikasi urutan komponen tetap rapi: Judul Profil, Nama, NIM, Tentang Saya
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Muhammad Nur Ilham'), findsOneWidget);
    expect(find.text('NIM : 25051204433'), findsOneWidget);
    expect(find.text('Tentang Saya (About Me)'), findsOneWidget);
  });
}


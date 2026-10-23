import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/screens/search_page.dart';
import 'package:tugas_pbp/services/api_service.dart';
import 'package:tugas_pbp/data/shared_data.dart';
import 'package:tugas_pbp/screens/detail_page.dart';

void main() {
  setUp(() {
    SharedData.dramaListNotifier.value = [];
  });

  group('SearchPage Relevance, Card UI, and Action Button Tests', () {
    testWidgets('1. Algoritma Pengurutan (Sorting): Exact match "project y" berada di indeks ke-0', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/search/movie')) {
          final mockResults = {
            'page': 1,
            'results': [
              {
                'id': 101,
                'title': 'The Project Yesterday Special',
                'poster_path': '/p1.jpg',
                'release_date': '2024-01-01',
                'vote_average': 9.5,
                'popularity': 100.0,
              },
              {
                'id': 102,
                'title': 'Project Y',
                'poster_path': '/p2.jpg',
                'release_date': '2023-01-01',
                'vote_average': 7.0,
                'popularity': 10.0,
              },
              {
                'id': 103,
                'title': 'Project Yellow Submarine',
                'poster_path': '/p3.jpg',
                'release_date': '2022-01-01',
                'vote_average': 8.8,
                'popularity': 50.0,
              },
            ],
          };
          return http.Response(json.encode(mockResults), 200, headers: {'content-type': 'application/json; charset=utf-8'});
        } else if (request.url.path.contains('/search/tv')) {
          return http.Response(json.encode({'page': 1, 'results': []}), 200, headers: {'content-type': 'application/json; charset=utf-8'});
        }
        return http.Response(json.encode({'page': 1, 'results': []}), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });

      final mockApi = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: SearchPage(apiService: mockApi),
        ),
      );
      await tester.pumpAndSettle();

      // Ketik 'project y'
      await tester.enterText(find.byType(TextField), 'project y');
      await tester.pumpAndSettle();

      // Temukan semua teks judul yang muncul di card
      final titleFinders = find.byWidgetPredicate(
        (w) => w is Text && ['Project Y', 'The Project Yesterday Special', 'Project Yellow Submarine'].contains(w.data),
      );
      expect(titleFinders, findsNWidgets(3));

      // Ambil elemen yang ter-render berdasarkan urutan vertikalnya
      final elements = tester.widgetList<Text>(titleFinders).toList();
      expect(elements[0].data, 'Project Y', reason: 'Exact match "Project Y" harus berada di urutan teratas (indeks 0)');
    });

    testWidgets('2. UI Card Film: Hapus Peringkat & Logika Episode/Durasi Film vs Drama', (tester) async {
      // Siapkan item Film dan item Drama di data lokal
      final movieItem = Drama.fromTmdbJson({
        'id': 201,
        'title': 'Film Layar Lebar',
        'release_date': '2024-05-10',
        'vote_average': 8.5,
        'runtime': 125, // 2j 5m
        'media_type': 'movie',
      });

      final tvItem = Drama.fromTmdbJson({
        'id': 202,
        'name': 'Serial Drama Keren',
        'first_air_date': '2024-06-15',
        'vote_average': 9.0,
        'media_type': 'tv',
      });
      tvItem.episodes = 16;

      SharedData.dramaListNotifier.value = [movieItem, tvItem];

      final mockClient = MockClient((request) async {
        return http.Response(json.encode({'page': 1, 'results': []}), 200);
      });
      final mockApi = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: SearchPage(apiService: mockApi),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Pastikan TIDAK ADA ikon grafik peringkat (Icons.trending_up) atau teks '#1', '#2'
      expect(find.byIcon(Icons.trending_up), findsNothing, reason: 'Ikon grafik peringkat harus dihapus');
      expect(find.text('#1'), findsNothing, reason: 'Teks peringkat #1 harus dihapus');
      expect(find.text('#2'), findsNothing, reason: 'Teks peringkat #2 harus dihapus');

      // 2. Logika Episode:
      // - Untuk Film: ikon list_alt dan teks episode disembunyikan, ditampilkan durasi '2j 5m' dengan ikon access_time
      expect(find.text('2j 5m'), findsOneWidget, reason: 'Film harus menampilkan durasi terformat');
      expect(find.byIcon(Icons.access_time), findsOneWidget, reason: 'Ikon jam durasi muncul untuk Film');

      // - Untuk Drama/TV: ikon list_alt dan angka episode '16' muncul HANYA 1 kali (milik TV series)
      expect(find.byIcon(Icons.list_alt), findsOneWidget, reason: 'Ikon list episode hanya muncul untuk Serial TV/Drama');
      expect(find.text('16'), findsOneWidget, reason: 'Angka episode hanya muncul untuk Drama');
    });

    testWidgets('3. Desain Kotak Tombol Aksi (+ dan Pena/Pensil) dan Logika Perubahan Ikon Dinamis', (tester) async {
      final item = Drama.fromTmdbJson({
        'id': 301,
        'title': 'Sample Title',
        'release_date': '2024-01-01',
        'vote_average': 8.0,
        'media_type': 'movie',
      });

      // Awalnya film BELUM ada di Watchlist
      SharedData.dramaListNotifier.value = [];

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/trending') ||
            request.url.path.contains('/movie/popular')) {
          return http.Response(
            json.encode({
              'page': 1,
              'results': [
                {
                  'id': 301,
                  'title': 'Sample Title',
                  'release_date': '2024-01-01',
                  'vote_average': 8.0,
                  'media_type': 'movie',
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(json.encode({'page': 1, 'results': []}), 200);
      });
      final mockApi = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: SearchPage(apiService: mockApi),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verifikasi ikon awal adalah Icons.add (karena belum ada di Watchlist)
      expect(find.byIcon(Icons.add), findsOneWidget, reason: 'Harus menampilkan ikon tambah saat belum di Watchlist');
      expect(find.byIcon(Icons.edit_outlined), findsNothing, reason: 'Ikon edit tidak boleh muncul jika belum di Watchlist');

      // 2. Verifikasi spesifikasi tombol Container (38x38, borderRadius 10, bukan warna biru)
      final containerFinder = find.ancestor(
        of: find.byIcon(Icons.add),
        matching: find.byType(Container),
      ).first;
      final Container containerWidget = tester.widget<Container>(containerFinder);
      expect(containerWidget.constraints?.maxWidth, 38);
      expect(containerWidget.constraints?.maxHeight, 38);
      final decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(10));
      // Pastikan bukan warna biru
      expect(decoration.color != const Color(0xFF0094FF), isTrue);

      final Icon iconWidget = tester.widget<Icon>(find.byIcon(Icons.add));
      expect(iconWidget.size, 20);
      expect(iconWidget.color != const Color(0xFF0094FF), isTrue);

      // 3. Ketuk ikon Icons.add: Buka EditDramaModal dengan initialStatus 'Belum Ditonton'
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byType(EditDramaModal), findsOneWidget);
      expect(find.text('Belum Ditonton'), findsOneWidget);
      expect(find.text('Episode'), findsNothing);
      expect(find.text('Peringkat'), findsNothing);

      // Tutup modal
      Navigator.pop(tester.element(find.byType(EditDramaModal)));
      await tester.pumpAndSettle();

      // 4. Simulasikan film masuk ke Watchlist user ('Sedang Menonton')
      SharedData.dramaListNotifier.value = [
        item.copyWith(
          status: 'Sedang Menonton',
          watchedEpisodes: 1,
        ),
      ];
      await tester.pumpAndSettle();

      // 5. Ikon berubah secara dinamis menjadi Icons.edit_outlined
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget, reason: 'Ikon harus berubah menjadi edit_outlined saat ada di Watchlist');
      expect(find.byIcon(Icons.add), findsNothing);

      // 6. Ketuk ikon Icons.edit_outlined: Membuka modal dengan data tersimpan
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(EditDramaModal), findsOneWidget);
      expect(find.text('Sedang Menonton'), findsOneWidget);
    });

    testWidgets('4. Sorting Hasil Pencarian: Film dengan judul yang sama, rating tertinggi berada di urutan paling atas', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/search/movie')) {
          final mockResults = {
            'page': 1,
            'results': [
              {
                'id': 501,
                'title': 'Project Y',
                'poster_path': '/low.jpg',
                'release_date': '2020-01-01',
                'vote_average': 6.2,
                'popularity': 80.0,
              },
              {
                'id': 502,
                'title': 'Project Y',
                'poster_path': '/high.jpg',
                'release_date': '2024-01-01',
                'vote_average': 9.1,
                'popularity': 50.0,
              },
            ],
          };
          return http.Response(json.encode(mockResults), 200, headers: {'content-type': 'application/json; charset=utf-8'});
        }
        return http.Response(json.encode({'page': 1, 'results': []}), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });

      final mockApi = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: SearchPage(apiService: mockApi),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Project Y');
      await tester.pumpAndSettle();

      // Temukan kedua widget card yang menampilkan rating
      expect(find.text('9.1'), findsOneWidget);
      expect(find.text('6.2'), findsOneWidget);

      final ratingWidgets = tester.widgetList<Text>(find.byWidgetPredicate(
        (w) => w is Text && (w.data == '9.1' || w.data == '6.2'),
      )).toList();

      // Rating 9.1 harus berada di urutan sebelum 6.2
      expect(ratingWidgets[0].data, '9.1', reason: 'Film dengan rating tertinggi harus berada di atas');
      expect(ratingWidgets[1].data, '6.2');
    });

    testWidgets('5. Dynamic Cast Badge di DetailPage: 3 teratas Peran Utama, urutan ke-4 dst Peran Pendukung', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/credits')) {
          final mockCredits = {
            'id': 99,
            'cast': [
              {'id': 1, 'name': 'Aktor Satu', 'character': 'Karakter 1', 'profile_path': null},
              {'id': 2, 'name': 'Aktor Dua', 'character': 'Karakter 2', 'profile_path': null},
              {'id': 3, 'name': 'Aktor Tiga', 'character': 'Karakter 3', 'profile_path': null},
              {'id': 4, 'name': 'Aktor Empat', 'character': 'Karakter 4', 'profile_path': null},
              {'id': 5, 'name': 'Aktor Lima', 'character': 'Karakter 5', 'profile_path': null},
            ],
            'crew': [],
          };
          return http.Response(json.encode(mockCredits), 200, headers: {'content-type': 'application/json; charset=utf-8'});
        } else if (request.url.path.contains('/movie/99')) {
          final mockDetail = {
            'id': 99,
            'title': 'Test Movie',
            'overview': 'Sinopsis film pengujian.',
            'runtime': 120,
            'release_date': '2024-01-01',
            'vote_average': 8.5,
            'vote_count': 100,
            'popularity': 50.0,
            'genres': [{'id': 28, 'name': 'Action'}],
          };
          return http.Response(json.encode(mockDetail), 200, headers: {'content-type': 'application/json; charset=utf-8'});
        }
        return http.Response(json.encode({'results': {}}), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });

      final mockApi = ApiService(client: mockClient);
      final drama = Drama.fromTmdbJson({
        'id': 99,
        'title': 'Test Movie',
        'media_type': 'movie',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: DetailPage(drama: drama, apiService: mockApi),
        ),
      );
      await tester.pumpAndSettle();

      // Periksa kemunculan 'Peran Utama' (untuk 3 teratas) dan 'Peran Pendukung' (untuk ke-4 dst)
      expect(find.text('Peran Utama'), findsNWidgets(3));
      expect(find.text('Peran Pendukung'), findsWidgets);
    });
  });
}

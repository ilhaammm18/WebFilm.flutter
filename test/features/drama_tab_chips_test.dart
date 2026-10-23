import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tugas_pbp/screens/explore_tab.dart';
import 'package:tugas_pbp/services/api_service.dart';

void main() {
  group('Drama Tab Filter Chip Tests', () {
    testWidgets('Tombol chip Drama memiliki label "Korea" dan "Jepang", serta aksi onTap memicu fetch TMDB dengan bahasa yang benar', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final List<Uri> requestedUris = [];

      final mockClient = MockClient((request) async {
        requestedUris.add(request.url);
        return http.Response(
          json.encode({
            'page': 1,
            'results': [
              {
                'id': 999,
                'name': 'Sample Drama',
                'title': 'Sample Drama',
                'poster_path': '/sample.jpg',
                'vote_average': 8.5,
                'first_air_date': '2025-01-01',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ExploreTab(apiService: apiService)),
        ),
      );
      await tester.pumpAndSettle();

      // Pindah ke tab DRAMA
      await tester.tap(find.text('DRAMA'));
      await tester.pumpAndSettle();

      // Verifikasi teks lama "Korea (Drakor)" dan "Jepang (Dorama)" sudah TIDAK ada
      expect(find.text('Korea (Drakor)'), findsNothing);
      expect(find.text('Jepang (Dorama)'), findsNothing);

      // Verifikasi teks baru "Korea" dan "Jepang" muncul sebagai ChoiceChip
      final koreaChips = find.widgetWithText(ChoiceChip, 'Korea');
      final jepangChips = find.widgetWithText(ChoiceChip, 'Jepang');
      expect(koreaChips, findsWidgets);
      expect(jepangChips, findsWidgets);

      // Tap chip 'Korea' pada tab Drama
      requestedUris.clear();
      await tester.tap(koreaChips.first);
      await tester.pumpAndSettle();

      // Verifikasi TMDB API dipanggil dengan with_original_language=ko
      expect(
        requestedUris.any((uri) =>
            uri.path.contains('/discover/tv') &&
            uri.queryParameters['with_original_language'] == 'ko'),
        isTrue,
      );
      expect(find.text('Drama Korea Populer'), findsWidgets);

      // Tap chip 'Jepang' pada tab Drama
      requestedUris.clear();
      await tester.tap(jepangChips.first);
      await tester.pumpAndSettle();

      // Verifikasi TMDB API dipanggil dengan with_original_language=ja
      expect(
        requestedUris.any((uri) =>
            uri.path.contains('/discover/tv') &&
            uri.queryParameters['with_original_language'] == 'ja'),
        isTrue,
      );
      expect(find.text('Drama Jepang Pilihan'), findsWidgets);
    });
  });
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tugas_pbp/screens/search_page.dart';
import 'package:tugas_pbp/services/api_service.dart';

void main() {
  group('SearchPage Tab AKTOR Color Visibility Tests', () {
    final mockActorResponse = {
      'results': [
        {
          'id': 1,
          'name': 'Song Joong-ki',
          'original_name': '송중기',
          'profile_path': '/song.jpg',
          'popularity': 90.0,
          'known_for_department': 'Acting',
        },
      ],
    };

    testWidgets('Light Mode: Teks nama aktor dan deskripsi adaptif dan kontras',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode(mockActorResponse),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final mockApiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: SearchPage(apiService: mockApiService),
        ),
      );
      await tester.pumpAndSettle();

      // Klik tab AKTOR
      await tester.tap(find.text('AKTOR'));
      await tester.pumpAndSettle();

      // Temukan Text nama aktor
      final actorNameText = tester.widget<Text>(find.text('Song Joong-ki'));
      expect(actorNameText.style?.color, equals(Colors.black87));

      // Temukan Text deskripsi 'Aktor / Pemeran'
      final deptText = tester.widget<Text>(find.text('Aktor / Pemeran'));
      expect(deptText.style?.color, equals(Colors.grey[700]));
    });

    testWidgets('Dark Mode: Teks nama aktor putih dan deskripsi grey[400]',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode(mockActorResponse),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final mockApiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: SearchPage(apiService: mockApiService),
        ),
      );
      await tester.pumpAndSettle();

      // Klik tab AKTOR
      await tester.tap(find.text('AKTOR'));
      await tester.pumpAndSettle();

      // Temukan Text nama aktor
      final actorNameText = tester.widget<Text>(find.text('Song Joong-ki'));
      expect(actorNameText.style?.color, equals(Colors.white));

      // Temukan Text deskripsi 'Aktor / Pemeran'
      final deptText = tester.widget<Text>(find.text('Aktor / Pemeran'));
      expect(deptText.style?.color, equals(Colors.grey[400]));
    });
  });
}

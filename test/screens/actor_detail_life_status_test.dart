import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tugas_pbp/models/actor.dart';
import 'package:tugas_pbp/screens/actor_detail_page.dart';
import 'package:tugas_pbp/services/api_service.dart';

void main() {
  group('Actor Model deathday & TMDB /person/{person_id} JSON Mapping', () {
    test('Actor.fromJson membaca properti birthday dan deathday dari TMDB', () {
      final jsonResponse = {
        'id': 12345,
        'name': 'Lee Sun-kyun',
        'birthday': '1975-03-01',
        'deathday': '2023-12-27',
        'place_of_birth': 'Seoul, South Korea',
        'known_for_department': 'Acting',
        'popularity': 42.0,
      };

      final actor = Actor.fromJson(jsonResponse);
      expect(actor.id, 12345);
      expect(actor.name, 'Lee Sun-kyun');
      expect(actor.birthday, '1975-03-01');
      expect(actor.deathday, '2023-12-27');
      expect(actor.death_day, '2023-12-27');
    });

    test('Actor.fromJson dengan deathday null (masih hidup)', () {
      final jsonResponse = {
        'id': 67890,
        'name': 'Song Joong-ki',
        'birthday': '1985-09-19',
        'deathday': null,
        'place_of_birth': 'Daejeon, South Korea',
        'known_for_department': 'Acting',
      };

      final actor = Actor.fromJson(jsonResponse);
      expect(actor.id, 67890);
      expect(actor.birthday, '1985-09-19');
      expect(actor.deathday, isNull);
      expect(actor.death_day, isNull);
    });
  });

  group('ActorDetailPage Logika Umur dan Status Kehidupan (Living vs Deceased)', () {
    testWidgets('Aktor yang sudah wafat (deathday != null): menampilkan tanggal wafat dan usia hingga wafat dengan teks abu-abu redup', (tester) async {
      final deceasedActor = Actor(
        id: 777,
        name: 'Lee Sun-kyun',
        birthday: '1975-03-01',
        deathday: '2023-12-27',
        placeOfBirth: 'Seoul, South Korea',
      );

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/person/777')) {
          final mockDetail = {
            'id': 777,
            'name': 'Lee Sun-kyun',
            'birthday': '1975-03-01',
            'deathday': '2023-12-27',
            'place_of_birth': 'Seoul, South Korea',
            'known_for_department': 'Acting',
          };
          return http.Response(json.encode(mockDetail), 200, headers: {'content-type': 'application/json; charset=utf-8'});
        } else if (request.url.path.contains('/combined_credits')) {
          return http.Response(json.encode({'cast': []}), 200, headers: {'content-type': 'application/json; charset=utf-8'});
        }
        return http.Response('{}', 200);
      });

      final mockApiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: ActorDetailPage(deceasedActor, apiService: mockApiService),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi teks format: 'Wafat: 27 Des 2023 (Usia 48)'
      final deathTextFinder = find.text('Wafat: 27 Des 2023 (Usia 48)');
      expect(deathTextFinder, findsOneWidget, reason: 'Harus menampilkan tanggal wafat dan usia sampai wafat (48 tahun)');

      // Verifikasi warna teks adalah abu-abu redup (dim gray)
      final Text deathTextWidget = tester.widget<Text>(deathTextFinder);
      expect(deathTextWidget.style?.color, const Color(0xFF9CA3AF));

      // Verifikasi di card Biodata: label 'Wafat' dan nilai '27 Des 2023 (Usia 48)'
      expect(find.text('Wafat'), findsOneWidget);
      expect(find.text('27 Des 2023 (Usia 48)'), findsOneWidget);
    });

    testWidgets('Aktor yang masih hidup (deathday == null): menghitung usia ke tahun sekarang dan menampilkan "Usia: X Tahun"', (tester) async {
      // Hitung ekspektasi usia dinamis berdasarkan tahun berjalan
      final now = DateTime.now();
      int expectedAge = now.year - 1981;
      if (now.month < 4 || (now.month == 4 && now.day < 10)) {
        expectedAge--;
      }

      final livingActor = Actor(
        id: 888,
        name: 'Gong Yoo',
        birthday: '1981-04-10',
        deathday: null,
        placeOfBirth: 'Busan, South Korea',
      );

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/person/888')) {
          final mockDetail = {
            'id': 888,
            'name': 'Gong Yoo',
            'birthday': '1981-04-10',
            'deathday': null,
            'place_of_birth': 'Busan, South Korea',
            'known_for_department': 'Acting',
          };
          return http.Response(json.encode(mockDetail), 200, headers: {'content-type': 'application/json; charset=utf-8'});
        } else if (request.url.path.contains('/combined_credits')) {
          return http.Response(json.encode({'cast': []}), 200, headers: {'content-type': 'application/json; charset=utf-8'});
        }
        return http.Response('{}', 200);
      });

      final mockApiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: ActorDetailPage(livingActor, apiService: mockApiService),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi teks format: 'Usia: {expectedAge} Tahun'
      expect(find.text('Usia: $expectedAge Tahun'), findsOneWidget);

      // Verifikasi di card Biodata: label 'Usia' dan nilai '{expectedAge} Tahun'
      expect(find.text('Usia'), findsOneWidget);
      expect(find.text('$expectedAge Tahun'), findsOneWidget);
    });
  });
}

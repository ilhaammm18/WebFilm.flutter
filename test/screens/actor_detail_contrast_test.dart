import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tugas_pbp/models/actor.dart';
import 'package:tugas_pbp/screens/actor_detail_page.dart';
import 'package:tugas_pbp/services/api_service.dart';

void main() {
  group('ActorDetailPage Contrast & Theme Verification Tests', () {
    const testActor = Actor(
      id: 101,
      name: 'Song Joong-ki',
      koreanName: '송중기',
      birthday: '1985-09-19',
      placeOfBirth: 'Daejeon, South Korea',
      knownForDepartment: 'Acting',
      biography: 'Song Joong-ki adalah seorang aktor populer asal Korea Selatan.',
    );

    ApiService createMockApiService() {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/combined_credits')) {
          final mockCredits = {
            'cast': [
              {
                'id': 501,
                'title': 'Vincenzo',
                'poster_path': '/vincenzo.jpg',
                'release_date': '2021-02-20',
                'character': 'Vincenzo Cassano',
                'vote_average': 8.9,
                'media_type': 'tv',
              },
            ]
          };
          return http.Response(
            json.encode(mockCredits),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path.contains('/person/101')) {
          final mockPerson = {
            'id': 101,
            'name': 'Song Joong-ki',
            'original_name': '송중기',
            'birthday': '1985-09-19',
            'place_of_birth': 'Daejeon, South Korea',
            'known_for_department': 'Acting',
            'biography': 'Song Joong-ki adalah seorang aktor populer asal Korea Selatan.',
          };
          return http.Response(
            json.encode(mockPerson),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('{}', 200);
      });
      return ApiService(client: mockClient);
    }

    testWidgets('Light Mode: Kontras teks, ikon, label biodata, border, dan divider nyaman dibaca', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockApiService = createMockApiService();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: ActorDetailPage(testActor, apiService: mockApiService),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Header Nama Aktor (Colors.black87)
      final nameFinder = find.text('Song Joong-ki').first;
      final Text nameText = tester.widget(nameFinder);
      expect(nameText.style?.color, Colors.black87);

      // 2. Teks Seksi 'Biodata' (Colors.black87)
      final biodataHeaderFinder = find.text('Biodata');
      final Text biodataHeaderText = tester.widget(biodataHeaderFinder);
      expect(biodataHeaderText.style?.color, Colors.black87);

      // 3. Ikon di sebelah kiri Biodata (Colors.blueGrey[700])
      final personIconFinder = find.byIcon(Icons.person_outline);
      expect(personIconFinder, findsOneWidget);
      final Icon personIcon = tester.widget(personIconFinder);
      expect(personIcon.color, Colors.blueGrey[700]);

      // 4. Teks Label Biodata 'Nama Asli' (Colors.grey[800], FontWeight.w500)
      final labelFinder = find.text('Nama Asli');
      expect(labelFinder, findsOneWidget);
      final Text labelText = tester.widget(labelFinder);
      expect(labelText.style?.color, Colors.grey[800]);
      expect(labelText.style?.fontWeight, FontWeight.w500);

      // 5. Teks Isi Data Nilai Biodata (Colors.black87, FontWeight.w600)
      final valueFinder = find.text('Song Joong-ki').last; // Nilai nama asli di sebelah kanan
      final Text valueText = tester.widget(valueFinder);
      expect(valueText.style?.color, Colors.black87);
      expect(valueText.style?.fontWeight, FontWeight.w600);

      // 6. Garis Pemisah Divider (Colors.grey[300])
      final dividerFinder = find.byType(Divider).first;
      final Divider dividerWidget = tester.widget(dividerFinder);
      expect(dividerWidget.color, Colors.grey[300]);

      // 7. Seksi Biografi telah dihapus
      expect(find.text('Biografi'), findsNothing);

      // 8. Seksi Filmografi dan Kartu Film
      expect(find.text('Drama / Filmografi'), findsOneWidget);
      final movieTitleFinder = find.text('Vincenzo');
      expect(movieTitleFinder, findsOneWidget);
      final Text movieTitle = tester.widget(movieTitleFinder);
      expect(movieTitle.style?.color, Colors.black87);

      final movieYearFinder = find.text('2021');
      expect(movieYearFinder, findsOneWidget);
      final Text movieYear = tester.widget(movieYearFinder);
      expect(movieYear.style?.color, Colors.grey[700]);
    });

    testWidgets('Dark Mode: Kontras teks dan ikon di latar belakang gelap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockApiService = createMockApiService();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: ActorDetailPage(testActor, apiService: mockApiService),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Header Nama Aktor (Colors.white)
      final nameFinder = find.text('Song Joong-ki').first;
      final Text nameText = tester.widget(nameFinder);
      expect(nameText.style?.color, Colors.white);

      // 2. Ikon di sebelah kiri Biodata (Colors.white70)
      final personIconFinder = find.byIcon(Icons.person_outline);
      final Icon personIcon = tester.widget(personIconFinder);
      expect(personIcon.color, Colors.white70);

      // 3. Teks Label Biodata 'Nama Asli' (Colors.white70, FontWeight.w500)
      final labelFinder = find.text('Nama Asli');
      final Text labelText = tester.widget(labelFinder);
      expect(labelText.style?.color, Colors.white70);
      expect(labelText.style?.fontWeight, FontWeight.w500);

      // 4. Teks Isi Data Nilai Biodata (Colors.white, FontWeight.w600)
      final valueFinder = find.text('Song Joong-ki').last;
      final Text valueText = tester.widget(valueFinder);
      expect(valueText.style?.color, Colors.white);
      expect(valueText.style?.fontWeight, FontWeight.w600);

      // 5. Garis Pemisah Divider (Colors.white12)
      final dividerFinder = find.byType(Divider).first;
      final Divider dividerWidget = tester.widget(dividerFinder);
      expect(dividerWidget.color, Colors.white12);

      // 6. Seksi Biografi telah dihapus
      expect(find.text('Biografi'), findsNothing);

      // 7. Kartu Filmografi
      final movieTitleFinder = find.text('Vincenzo');
      final Text movieTitle = tester.widget(movieTitleFinder);
      expect(movieTitle.style?.color, Colors.white);

      final movieYearFinder = find.text('2021');
      final Text movieYear = tester.widget(movieYearFinder);
      expect(movieYear.style?.color, Colors.white70);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_pbp/models/actor.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/screens/actor_detail_page.dart';
import 'package:tugas_pbp/screens/movie_detail_page.dart';

void main() {
  final sampleCast = [
    const ActorCredit(
      id: 101,
      title: 'Song Joong-ki',
      profilePath: '/song_joong_ki.jpg',
      releaseDate: '2021',
      character: 'Vincenzo Cassano',
    ),
    const ActorCredit(
      id: 102,
      title: 'Jeon Yeo-been',
      profilePath: '/jeon_yeo_been.jpg',
      releaseDate: '2021',
      character: 'Hong Cha-young',
    ),
    const ActorCredit(
      id: 103,
      title: 'Ok Taec-yeon',
      profilePath: '/ok_taec_yeon.jpg',
      releaseDate: '2021',
      character: 'Jang Jun-woo',
    ),
  ];

  final sampleCrew = [
    const MovieCrewMember(
      id: 201,
      name: 'Kim Hee-won',
      job: 'Sutradara',
      department: 'Directing',
      profilePath: '/kim_hee_won.jpg',
    ),
    const MovieCrewMember(
      id: 202,
      name: 'Park Jae-bum',
      job: 'Penulis Skenario',
      department: 'Writing',
      profilePath: '/park_jae_bum.jpg',
    ),
  ];

  group('FullCreditsPage UI & Layout Tests', () {
    testWidgets('Merender AppBar sederhana dengan tombol back, judul di tengah, dan tanpa TabBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: FullCreditsPage(
            title: 'Semua Pemeran',
            cast: sampleCast,
          ),
        ),
      );

      // Verifikasi judul pada AppBar
      expect(find.text('Semua Pemeran'), findsOneWidget);

      // Verifikasi icon back pada AppBar
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Verifikasi TIDAK ADA TabBar
      expect(find.byType(TabBar), findsNothing);

      // Verifikasi AppBar centerTitle
      final AppBar appBar = tester.widget(find.byType(AppBar));
      expect(appBar.centerTitle, isTrue);
    });

    testWidgets('Merender GridView responsif (3 kolom di mobile width < 600) dengan crossAxisSpacing 4.0, mainAxisSpacing 12.0, childAspectRatio 0.72', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: FullCreditsPage(
            title: 'Semua Pemeran',
            cast: sampleCast,
          ),
        ),
      );

      final gridViewFinder = find.byType(GridView);
      expect(gridViewFinder, findsOneWidget);

      final GridView gridView = tester.widget(gridViewFinder);
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals(3));
      expect(delegate.crossAxisSpacing, equals(4.0));
      expect(delegate.mainAxisSpacing, equals(12.0));
      expect(delegate.childAspectRatio, equals(0.72));
    });

    testWidgets('Merender GridView responsif di layar lebar (laptop/desktop >= 600)', (tester) async {
      tester.view.physicalSize = const Size(960, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: FullCreditsPage(
            title: 'Semua Pemeran',
            cast: sampleCast,
          ),
        ),
      );

      final gridViewFinder = find.byType(GridView);
      final GridView gridView = tester.widget(gridViewFinder);
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals((960 / 120).floor()));
    });

    testWidgets('Setiap item menampilkan CircleAvatar besar (radius: 45), nama putih bold tengah maxLines: 1, peran abu-abu', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: FullCreditsPage(
            title: 'Semua Pemeran',
            cast: sampleCast,
          ),
        ),
      );

      // Verifikasi jumlah CircleAvatar sesuai data cast
      expect(find.byType(CircleAvatar), findsNWidgets(3));

      // Verifikasi ukuran CircleAvatar besar (radius 45)
      final CircleAvatar firstAvatar = tester.widget(find.byType(CircleAvatar).first);
      expect(firstAvatar.radius, equals(45));

      // Verifikasi teks nama asli aktor
      final nameFinder = find.text('Song Joong-ki');
      expect(nameFinder, findsOneWidget);
      final Text nameText = tester.widget(nameFinder);
      expect(nameText.style?.color, equals(Colors.white));
      expect(nameText.style?.fontWeight, equals(FontWeight.bold));
      expect(nameText.textAlign, equals(TextAlign.center));
      expect(nameText.maxLines, equals(1));
      expect(nameText.overflow, equals(TextOverflow.ellipsis));

      // Verifikasi teks peran/karakter
      final roleFinder = find.text('Vincenzo Cassano');
      expect(roleFinder, findsOneWidget);
      final Text roleText = tester.widget(roleFinder);
      expect(roleText.style?.color, equals(const Color(0xFF9CA3AF)));
      expect(roleText.textAlign, equals(TextAlign.center));
      expect(roleText.maxLines, equals(2));
      expect(roleText.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('Menerjemahkan jabatan kru dari bahasa Inggris ke bahasa Indonesia di FullCreditsPage', (tester) async {
      final englishCrew = [
        const MovieCrewMember(
          id: 301,
          name: 'Christopher Nolan',
          job: 'Director',
          department: 'Directing',
        ),
        const MovieCrewMember(
          id: 302,
          name: 'Emma Thomas',
          job: 'Executive Producer',
          department: 'Production',
        ),
        const MovieCrewMember(
          id: 303,
          name: 'Hans Zimmer',
          job: 'Original Music Composer',
          department: 'Sound',
        ),
        const MovieCrewMember(
          id: 304,
          name: 'Hoyte van Hoytema',
          job: 'Director of Photography',
          department: 'Camera',
        ),
        const MovieCrewMember(
          id: 305,
          name: 'Custom Unmapped Role Name',
          job: 'Stunt Coordinator Extraordinary',
          department: 'Crew',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: FullCreditsPage(
            title: 'Semua Tim Kru',
            crew: englishCrew,
          ),
        ),
      );

      expect(find.text('Semua Tim Kru'), findsOneWidget);

      // Terjemahan jabatan umum ke bahasa Indonesia
      expect(find.text('Sutradara'), findsOneWidget);
      expect(find.text('Produser Eksekutif'), findsOneWidget);
      expect(find.text('Komposer'), findsOneWidget);
      expect(find.text('Sinematografer'), findsOneWidget);

      // Jabatan yang tidak ada di dalam kamus tetap menampilkan teks aslinya
      expect(find.text('Stunt Coordinator Extraordinary'), findsOneWidget);
    });

    testWidgets('Menampilkan kru dengan judul "Semua Tim Kru"', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: FullCreditsPage(
            title: 'Semua Tim Kru',
            crew: sampleCrew,
          ),
        ),
      );

      expect(find.text('Semua Tim Kru'), findsOneWidget);
      expect(find.text('Kim Hee-won'), findsOneWidget);
      expect(find.text('Sutradara'), findsOneWidget);
      expect(find.text('Park Jae-bum'), findsOneWidget);
      expect(find.text('Penulis Skenario'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsNWidgets(2));
    });

    testWidgets('Menampilkan pesan kosong jika tidak ada data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FullCreditsPage(
            title: 'Semua Pemeran',
            cast: [],
          ),
        ),
      );

      expect(find.text('Tidak ada data yang tersedia'), findsOneWidget);
    });

    testWidgets('Mengetuk foto profil aktor membuka ActorDetailPage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FullCreditsPage(
            title: 'Semua Pemeran',
            cast: sampleCast,
          ),
        ),
      );

      // Mengetuk foto CircleAvatar aktor membuka ActorDetailPage
      await tester.tap(find.byType(CircleAvatar).first);
      await tester.pumpAndSettle();

      expect(find.byType(ActorDetailPage), findsOneWidget);
    });
  });

  group('MovieDetailPage -> FullCreditsPage Navigation Integration Tests', () {
    testWidgets('Klik "Lihat Semua" di bagian Pemeran mengarahkan ke FullCreditsPage dengan judul "Semua Pemeran"', (tester) async {
      final sampleDrama = Drama(
        id: 888,
        title: 'Vincenzo',
        koreanTitle: '빈센조',
        genre: 'Action, Crime',
        date: '2021',
        rating: 9.0,
        episodes: 20,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        image: '',
        rank: '#1',
        popularity: '99',
        watchers: '1000',
        synopsis: 'Pengacara mafia Italia kembali ke Korea Selatan.',
        aired: '2021',
        duration: '70 menit',
        contentRating: '15+',
        genresList: const ['Action', 'Crime'],
        tagsList: const ['Law', 'Mafia'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailPage(
            drama: sampleDrama,
          ),
        ),
      );
      await tester.pump();

      // Klik 'Lihat Semua' pertama (bagian Pemeran)
      final seeAllButtons = find.text('Lihat Semua');
      expect(seeAllButtons, findsWidgets);

      await tester.ensureVisible(seeAllButtons.first);
      await tester.tap(seeAllButtons.first);
      await tester.pumpAndSettle();

      // Memastikan berada di FullCreditsPage dengan judul 'Semua Pemeran'
      expect(find.byType(FullCreditsPage), findsOneWidget);
      expect(find.text('Semua Pemeran'), findsOneWidget);
      expect(find.byType(TabBar), findsNothing);

      // Tombol back kembali ke MovieDetailPage
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(MovieDetailPage), findsOneWidget);
    });

    testWidgets('Klik "Lihat Semua" di bagian Tim mengarahkan ke FullCreditsPage dengan judul "Semua Tim Kru"', (tester) async {
      final sampleDrama = Drama(
        id: 888,
        title: 'Vincenzo',
        koreanTitle: '빈센조',
        genre: 'Action, Crime',
        date: '2021',
        rating: 9.0,
        episodes: 20,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        image: '',
        rank: '#1',
        popularity: '99',
        watchers: '1000',
        synopsis: 'Pengacara mafia Italia kembali ke Korea Selatan.',
        aired: '2021',
        duration: '70 menit',
        contentRating: '15+',
        genresList: const ['Action', 'Crime'],
        tagsList: const ['Law', 'Mafia'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailPage(
            drama: sampleDrama,
          ),
        ),
      );
      await tester.pump();

      // Klik 'Lihat Semua' kedua (bagian Tim)
      final seeAllButtons = find.text('Lihat Semua');
      expect(seeAllButtons, findsWidgets);

      await tester.ensureVisible(seeAllButtons.last);
      await tester.tap(seeAllButtons.last);
      await tester.pumpAndSettle();

      // Memastikan berada di FullCreditsPage dengan judul 'Semua Tim Kru'
      expect(find.byType(FullCreditsPage), findsOneWidget);
      expect(find.text('Semua Tim Kru'), findsOneWidget);
      expect(find.byType(TabBar), findsNothing);
    });
  });

  group('translateCrewRole & crewJobTranslations Tests', () {
    test('Menerjemahkan jabatan umum TMDB ke bahasa Indonesia', () {
      expect(translateCrewRole('Director'), equals('Sutradara'));
      expect(translateCrewRole('directing'), equals('Sutradara'));
      expect(translateCrewRole('Writer'), equals('Penulis'));
      expect(translateCrewRole('writing'), equals('Penulis'));
      expect(translateCrewRole('Producer'), equals('Produser'));
      expect(translateCrewRole('Executive Producer'), equals('Produser Eksekutif'));
      expect(translateCrewRole('Original Music Composer'), equals('Komposer'));
      expect(translateCrewRole('Editor'), equals('Editor'));
      expect(translateCrewRole('Director of Photography'), equals('Sinematografer'));
    });

    test('Mengembalikan teks aslinya jika tidak ada dalam kamus', () {
      expect(translateCrewRole('Pyrotechnic Expert'), equals('Pyrotechnic Expert'));
      expect(translateCrewRole('Catering Staff'), equals('Catering Staff'));
      expect(translateCrewRole(''), equals(''));
      expect(translateCrewRole(null), equals(''));
    });
  });

  group('FullCreditsPage Theming Responsiveness Tests', () {
    testWidgets('Responsif terhadap Dark Mode dan Light Mode pada AppBar dan GridView items', (tester) async {
      // 1. Pengujian dalam Light Mode
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: const ColorScheme.light(),
          ),
          home: FullCreditsPage(
            title: 'Semua Pemeran',
            cast: sampleCast,
          ),
        ),
      );

      // Verifikasi Scaffold dan AppBar tidak memiliki background hardcoded
      final Scaffold scaffold = tester.widget(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNull);

      final AppBar appBar = tester.widget(find.byType(AppBar));
      expect(appBar.backgroundColor, isNull);

      // Verifikasi judul AppBar dan icon back di Light Mode berwarna gelap
      final Text titleText = tester.widget(find.text('Semua Pemeran'));
      expect(titleText.style?.color, equals(Colors.black87));

      final Icon backIcon = tester.widget(find.byIcon(Icons.arrow_back));
      expect(backIcon.color, equals(Colors.black87));

      // Verifikasi teks nama aktor dan peran di Light Mode
      final Text nameTextLight = tester.widget(find.text('Song Joong-ki'));
      expect(nameTextLight.style?.color, equals(Colors.black87));

      final Text roleTextLight = tester.widget(find.text('Vincenzo Cassano'));
      expect(roleTextLight.style?.color, equals(Colors.grey.shade600));

      // 2. Pengujian dalam Dark Mode
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(),
          ),
          home: FullCreditsPage(
            key: const Key('dark_credits'),
            title: 'Semua Pemeran',
            cast: sampleCast,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi judul AppBar dan icon back di Dark Mode berwarna putih
      final Text titleTextDark = tester.widget(find.text('Semua Pemeran'));
      expect(titleTextDark.style?.color, equals(Colors.white));

      final Icon backIconDark = tester.widget(find.byIcon(Icons.arrow_back));
      expect(backIconDark.color, equals(Colors.white));

      // Verifikasi teks nama aktor dan peran di Dark Mode
      final Text nameTextDark = tester.widget(find.text('Song Joong-ki'));
      expect(nameTextDark.style?.color, equals(Colors.white));

      final Text roleTextDark = tester.widget(find.text('Vincenzo Cassano'));
      expect(roleTextDark.style?.color, equals(const Color(0xFF9CA3AF)));
    });
  });
}

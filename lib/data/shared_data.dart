import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/drama.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'dart:math';

class DramaListNotifier extends ValueNotifier<List<Drama>> {
  DramaListNotifier(super.value);

  @override
  void notifyListeners() {
    super.notifyListeners();
  }
}

class SharedData {
  static final List<String> _realPosters = [
    'https://image.tmdb.org/t/p/w500/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
    'https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
    'https://image.tmdb.org/t/p/w500/74xTEgt7R36Fpooo50r9T25onhq.jpg',
    'https://image.tmdb.org/t/p/w500/vQWk5YBFWF4bZaofAbv0tShwBvQ.jpg',
    'https://image.tmdb.org/t/p/w500/fiVW06jE7z9YnO4trhaMEdclSiC.jpg',
    'https://image.tmdb.org/t/p/w500/iuFNMS8U5cb6xfzi51Dbkovj7vM.jpg',
    'https://image.tmdb.org/t/p/w500/1E5baAaEse26fej7uHcjOgEE2t2.jpg',
    'https://image.tmdb.org/t/p/w500/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg',
    'https://image.tmdb.org/t/p/w500/pFlaoHTZeyNkG83vxsAJiGzfSsa.jpg',
    'https://image.tmdb.org/t/p/w500/r2J02Z2OpNTctetOs2qYygh528v.jpg',
    'https://image.tmdb.org/t/p/w500/kDp1vUBnMpe8ak4rjgl3cLELqjU.jpg',
    'https://image.tmdb.org/t/p/w500/393rwsLqWdgT28gJkU96TqZJpfn.jpg',
    'https://image.tmdb.org/t/p/w500/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg',
    'https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg',
    'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
    'https://image.tmdb.org/t/p/w500/A4j8S6moJS2zNtRR8oWF08gRwL.jpg',
    'https://image.tmdb.org/t/p/w500/9cqNxx0GxF0bflZmeSMuL5tnGzr.jpg',
    'https://image.tmdb.org/t/p/w500/dB6Krk806zeqd005BmDaIaqWR2o.jpg',
    'https://image.tmdb.org/t/p/w500/7WsyChQLEftFiDOVTGkv3hFpyyt.jpg',
    'https://image.tmdb.org/t/p/w500/h8g3pivkM87vB1g5aO2F5bYlF8S.jpg',
  ];

  static final List<String> _filmKorea = [
    "Hijack 1971", "Time to Hunt", "Officer Black Belt", "Forgotten", "Colony", 
    "Escape", "Silenced", "Shark : The Beginning", "Brave Citizen", "Veteran", 
    "The Witch", "Midnight", "Midnight Runners", "Revelations", "Tunnel"
  ];
  
  static final List<String> _dramaKorea = [
    "Island", "Taxi Driver", "The First Responders", "Move To Heaven", "The Glory", 
    "My Name", "Weak Hero", "Kingdom", "Duty after school", "The Guest"
  ];

  static final List<String> _dramaJepang = [
    "Litre of Tears (Ichi Rittoru no Namida)", "Alice in Borderland", "Great Teacher Onizuka (GTO)", 
    "Nodame Cantabile", "Hana Yori Dango", "Tokyo Love Story", "Midnight Diner", 
    "Crow's Zero / Bossko", "Pahlawanku (My Boss My Hero)", "Orange Days"
  ];

  static final List<String> _filmJepang = [
    "Seven Samurai (1954)", "Tokyo Story (1953)", "Rashomon (1950)", "Spirited Away (2001)", 
    "Battle Royale (2000)", "Perfect Blue (1997)", "Nobody Knows (2004)", "Drive My Car (2021)", 
    "Tampopo (1985)", "Shoplifters (2018)"
  ];

  static List<Drama> generateData() {
    List<Drama> generatedList = [];
    Random random = Random(42);
    int posterIndex = 0;

    void addToList(List<String> titles, String genreBase, bool isFilm) {
      for (var title in titles) {
        double rating = 7.5 + (random.nextDouble() * 2.4); 
        int episodes = isFilm ? 1 : 8 + random.nextInt(12); 
        
        List<String> statuses = ['Selesai', 'Sedang Menonton', 'Rencana Ditonton', 'Belum Ditonton', 'Belum Ditonton'];
        String randomStatus = statuses[random.nextInt(statuses.length)];
        
        final String posterUrl = _realPosters[posterIndex % _realPosters.length];
        posterIndex++;

        generatedList.add(Drama(
          mediaType: isFilm ? 'movie' : 'tv',
          title: title,
          koreanTitle: title, 
          genre: genreBase,
          rating: double.parse(rating.toStringAsFixed(1)),
          episodes: episodes,
          watchedEpisodes: randomStatus == 'Selesai' ? episodes : (randomStatus == 'Belum Ditonton' ? 0 : (isFilm ? 0 : random.nextInt(episodes))),
          status: randomStatus,
          myRating: randomStatus == 'Selesai'
              ? double.parse((rating - 0.2).clamp(1.0, 10.0).toStringAsFixed(1))
              : null,
          userRating: randomStatus == 'Selesai'
              ? double.parse((rating - 0.2).clamp(1.0, 10.0).toStringAsFixed(1))
              : null,
          dateCompleted: randomStatus == 'Selesai' ? DateTime(2026, 10, 16) : null,
          priority: 'Sedang',
          startDate: '',
          endDate: '',
          date: '2024',
          image: posterUrl,
          rank: '#${random.nextInt(500) + 1}',
          popularity: '#${random.nextInt(1000) + 1}',
          watchers: '${(10 + random.nextDouble() * 90).toStringAsFixed(1)}K',
          synopsis: 'Ini adalah sinopsis untuk $title. Sebuah kisah menarik yang penuh dengan emosi dan ketegangan.',
          aired: '2020 - 2026',
          duration: isFilm ? '2 jam 10 menit' : '60 menit',
          contentRating: '15+',
          genresList: ['Action', 'Thriller', 'Drama'],
          tagsList: ['Popular', 'Must Watch'],
          genreIds: (title.contains('Spirited Away') || title.contains('Perfect Blue')) ? [16] : <int>[],
        ));
      }
    }

    addToList(_filmKorea, 'Film Korea', true);
    addToList(_dramaKorea, 'Drama Korea', false);
    addToList(_dramaJepang, 'Drama Jepang', false);
    addToList(_filmJepang, 'Film Jepang', true);

    return generatedList;
  }

  static bool isSynced = false;

  /// Mensimulasikan pemetaan data riil dari TMDB API ke dalam status Watchlist:
  /// 'Sedang Menonton', 'Selesai', dan 'Rencana Ditonton'
  static Future<void> syncWithTmdb({ApiService? apiService}) async {
    try {
      final service = apiService ?? ApiService();
      final List<Drama> movies = await service.getMovies();
      final List<Drama> dramas = await service.getDramas();

      final List<Drama> combined = [...dramas, ...movies];
      if (combined.isEmpty) return;

      final List<Drama> simulatedList = [];
      for (int i = 0; i < combined.length; i++) {
        final Drama item = combined[i];
        final int totalEps = item.episodes > 1 ? item.episodes : 16;
        final int mode = i % 3;

        if (mode == 0) {
          // Sedang Menonton (misal telah ditonton setengah jalan)
          final int watched = (totalEps / 2).round().clamp(1, totalEps - 1);
          simulatedList.add(item.copyWith(
            status: 'Sedang Menonton',
            episodes: totalEps,
            watchedEpisodes: watched,
            priority: 'Tinggi',
          ));
        } else if (mode == 1) {
          // Selesai (semua episode telah ditonton dan memiliki penilaian)
          simulatedList.add(item.copyWith(
            status: 'Selesai',
            episodes: totalEps,
            watchedEpisodes: totalEps,
            myRating: item.rating,
            userRating: item.rating,
            priority: 'Sedang',
            dateCompleted: DateTime.now().subtract(Duration(days: i * 2)),
          ));
        } else {
          // Rencana Ditonton
          simulatedList.add(item.copyWith(
            status: 'Rencana Ditonton',
            episodes: totalEps,
            watchedEpisodes: 0,
            priority: 'Sedang',
          ));
        }
      }

      dramaListNotifier.value = simulatedList;
      isSynced = true;
    } catch (_) {
      // Abaikan jika offline, data poster riil fallback tetap berjalan
    }
  }

  static SupabaseClient? _getSupabaseClient([SupabaseClient? client]) {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Mengambil data watchlist pengguna dari Supabase yang difilter ketat berdasarkan user login (user_id).
  /// Memastikan user baru hanya melihat daftar kosong, dan user lama hanya melihat data miliknya sendiri.
  static Future<void> fetchUserWatchlist({SupabaseClient? client, ApiService? apiService}) async {
    final supabase = _getSupabaseClient(client);
    if (supabase == null) return;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      // Jika tidak ada user login, pastikan daftar kosong
      dramaListNotifier.value = [];
      return;
    }

    try {
      final List<dynamic> data = await supabase
          .from('watchlists')
          .select()
          .eq('user_id', userId);

      final List<Drama> list = data
          .map((item) => Drama.fromSupabase(item as Map<String, dynamic>))
          .toList();

      dramaListNotifier.value = List<Drama>.from(list);
      dramaListNotifier.notifyListeners();

      // Lakukan background fetch detail TMDB berdasarkan tmdb_id untuk mengisi poster & episode
      final service = apiService ?? ApiService();
      final itemsToEnrich = list
          .where((d) =>
              d.id > 0 &&
              (d.image.isEmpty ||
                  d.episodes == 0 ||
                  d.genre == 'General' ||
                  d.genre.isEmpty))
          .toList();
      if (itemsToEnrich.isNotEmpty) {
        Future.wait(itemsToEnrich.map((drama) async {
          try {
            final detail = await service.getMovieDetails(
              drama.id,
              mediaType: drama.mediaType.isNotEmpty ? drama.mediaType : null,
            );
            if (detail.image.isNotEmpty) drama.image = detail.image;
            if (detail.backdrop.isNotEmpty && drama.backdrop.isEmpty) {
              drama.backdrop = detail.backdrop;
            }
            if (detail.genre.isNotEmpty && detail.genre != 'General') {
              drama.genre = detail.genre;
            } else if (drama.genre == 'General' || drama.genre.isEmpty) {
              drama.genre = detail.mediaType == 'tv' ? 'Serial TV' : 'Film';
            }
            if (detail.genresList.isNotEmpty) {
              drama.genresList = detail.genresList;
            }
            if (detail.genreIds.isNotEmpty) {
              drama.genreIds = detail.genreIds;
            }
            if (detail.episodes > 0 && drama.episodes == 0) {
              drama.episodes = detail.episodes;
            }
            if (detail.originalLanguage.isNotEmpty && drama.originalLanguage.isEmpty) {
              drama.originalLanguage = detail.originalLanguage;
            }
            if (detail.mediaType.isNotEmpty && (drama.mediaType.isEmpty || drama.mediaType == 'tv')) {
              drama.mediaType = detail.mediaType;
            }
          } catch (_) {}
        })).then((_) {
          dramaListNotifier.value = List<Drama>.from(list);
          dramaListNotifier.notifyListeners();
        });
      }
    } catch (e) {
      debugPrint('Gagal fetch data watchlist dari Supabase: $e');
    }
  }

  /// Mengambil data riwayat pembaruan pengguna dari Supabase (dinonaktifkan / tidak digunakan lagi di web)
  static Future<List<Map<String, dynamic>>> fetchUserRiwayat({SupabaseClient? client}) async {
    // Fitur riwayat pencarian/pembaruan sudah tidak digunakan lagi di aplikasi web ini
    /*
    final supabase = _getSupabaseClient(client);
    if (supabase == null) return [];

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final List<dynamic> data = await supabase
          .from('riwayat')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('Gagal fetch data riwayat dari Supabase: $e');
      return [];
    }
    */
    return [];
  }

  static final DramaListNotifier dramaListNotifier = DramaListNotifier([]);

  /// Mengambil daftar ID numerik film tersimpan (berdasarkan tmdb_id/drama_id) dari Supabase / watchlist aktif
  static List<int> get savedMovieIds => dramaListNotifier.value
      .where((d) =>
          d.status == 'Rencana Ditonton' ||
          d.status == 'Sedang Menonton' ||
          d.status == 'Selesai')
      .map((d) => d.id)
      .where((id) => id > 0)
      .toList();

  /// Memetakan daftar id film tersimpan langsung dari raw response Supabase berdasarkan kolom tmdb_id
  static List<int> mapSavedMovieIdsFromSupabase(List<dynamic> rows) {
    return rows.map((row) {
      if (row is Map) {
        final rawTmdbId = row['tmdb_id'] ?? row['drama_id'] ?? row['id'];
        if (rawTmdbId is num) return rawTmdbId.toInt();
        return int.tryParse(rawTmdbId?.toString() ?? '') ?? 0;
      }
      return 0;
    }).where((id) => id > 0).toList();
  }

  static final User currentUser = User(
    username: 'ilham_dev',
    fullName: 'Muhamad Ilham',
    email: 'ilham@mywatchlist.id',
    avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&auto=format&fit=crop&q=80',
    joinedDate: DateTime(2024, 2, 14),
  );

  static final ValueNotifier<UserProfileData> userProfileNotifier =
      ValueNotifier<UserProfileData>(const UserProfileData());

  /// Sinkronisasi data profil pengguna dari Supabase Auth dan tabel profiles
  static Future<void> fetchUserProfile({SupabaseClient? client}) async {
    final supabase = _getSupabaseClient(client);
    if (supabase == null) return;
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      String name = userProfileNotifier.value.fullName;
      String uname = userProfileNotifier.value.username;
      String bio = userProfileNotifier.value.bio;
      String avatar = userProfileNotifier.value.avatarUrl;

      final meta = user.userMetadata ?? {};
      if (meta['full_name'] != null && (meta['full_name'] as String).trim().isNotEmpty) {
        name = (meta['full_name'] as String).trim();
      }
      if (meta['username'] != null && (meta['username'] as String).trim().isNotEmpty) {
        uname = (meta['username'] as String).trim();
      }
      if (meta['bio'] != null && (meta['bio'] as String).trim().isNotEmpty) {
        bio = (meta['bio'] as String).trim();
      }
      if (meta['avatar_url'] != null && (meta['avatar_url'] as String).trim().isNotEmpty) {
        avatar = (meta['avatar_url'] as String).trim();
      }

      try {
        final profile = await supabase.from('profiles').select().eq('id', user.id).maybeSingle();
        if (profile != null) {
          if (profile['full_name'] != null && (profile['full_name'] as String).trim().isNotEmpty) {
            name = (profile['full_name'] as String).trim();
          }
          if (profile['username'] != null && (profile['username'] as String).trim().isNotEmpty) {
            uname = (profile['username'] as String).trim();
          }
          if (profile['bio'] != null && (profile['bio'] as String).trim().isNotEmpty) {
            bio = (profile['bio'] as String).trim();
          }
          if (profile['avatar_url'] != null && (profile['avatar_url'] as String).trim().isNotEmpty) {
            avatar = (profile['avatar_url'] as String).trim();
          }
        } else {
          // Akun lama belum tercatat di profiles -> sinkronkan otomatis dari userMetadata ke tabel profiles
          try {
            await supabase.from('profiles').upsert({
              'id': user.id,
              'username': uname.toLowerCase(),
              'full_name': name,
              'bio': bio,
              'avatar_url': avatar,
            });
          } catch (_) {}
        }
      } catch (_) {}

      userProfileNotifier.value = UserProfileData(
        fullName: name,
        username: uname,
        bio: bio,
        avatarUrl: avatar,
      );
    } catch (_) {}
  }
}

class UserProfileData {
  final String fullName;
  final String username;
  final String bio;
  final String avatarUrl;

  const UserProfileData({
    this.fullName = 'Muhammad Nur Ilham',
    this.username = '25051204433',
    this.bio =
        'Selamat Datang di MyWatchList! Halo! Saya Muhammad Nur Ilham. Saat ini saya adalah mahasiswa Teknik Informatika Universitas Negeri Surabaya (Unesa) semester 3. Web ini dibuat untuk memenuhi tugas mata kuliah Pemrograman Berbasis Platform (PBP).',
    this.avatarUrl = 'assets/profile.jpg',
  });

  UserProfileData copyWith({
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
  }) {
    return UserProfileData(
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
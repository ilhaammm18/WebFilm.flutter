import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/actor.dart';
import '../models/drama.dart';

const List<String> vipActors = ApiService.vipActors;

class ApiService {
  static const String apiKey = 'f2d1d576c288316fc43ddc223871f357';
  static const String baseUrl = 'https://api.themoviedb.org/3';
  final http.Client _client;

  /// Daftar Nama Aktor Kurasi VIP (Korea & Jepang)
  static const List<String> vipActors = [
    // Korea
    'Ji Chang Wook',
    'Park Shin Hye',
    'Go Youn Jung',
    'Lee Dong Wook',
    'Park Seo Jun',
    'Bae Suzy',
    'Nam Joo Hyuk',
    'Kim So Hyun',
    'Jung So Min',
    'Park Bo Gum',
    'Gong Yoo',
    'Cha Eun Woo',
    'Song Kang',
    'Kim Se Jeong',

    // Jepang
    'Yagira Yuya',
    'Kasamatsu Sho',
    'Yoshioka Riho',
    'Takasugi Mahiro',
    'Yamazaki Kento',
    'Tsuchiya Tao',
    'Murakami Nijiro',
  ];

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Mengambil daftar aktor kurasi VIP (Korea & Jepang)
  /// Menggunakan Future.wait() untuk mencari masing-masing nama secara paralel
  /// pada endpoint /search/person?query={nama}&include_adult=false
  Future<List<Actor>> getCuratedActors({List<String>? actorNames}) async {
    final List<String> names = actorNames ?? vipActors;

    try {
      final List<Future<Actor?>> futures = names.map((name) async {
        try {
          final url = Uri.parse(
            '$baseUrl/search/person?api_key=$apiKey&query=${Uri.encodeComponent(name)}&include_adult=false',
          );
          final response = await _client.get(url);

          if (response.statusCode == 200) {
            final Map<String, dynamic> data =
                json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
            final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

            if (results.isNotEmpty) {
              final Map<String, dynamic> firstResult =
                  results[0] as Map<String, dynamic>;
              return Actor.fromJson(firstResult);
            }
          }
        } catch (_) {
          // Abaikan kegagalan individu agar aktor lain tetap termuat
        }
        return null;
      }).toList();

      final List<Actor?> resolved = await Future.wait(futures);

      // Deduplikasi berdasarkan ID aktor
      final Set<int> seenIds = <int>{};
      final List<Actor> actors = [];

      for (final actor in resolved) {
        if (actor != null) {
          if (actor.id == 0 || seenIds.add(actor.id)) {
            actors.add(actor);
          }
        }
      }

      return actors;
    } catch (e) {
      throw Exception('Terjadi kesalahan saat memuat data aktor kurasi: $e');
    }
  }

  /// Mengambil daftar aktor populer dari TMDB API
  /// Melakukan perulangan HTTP GET page 1 sampai page 5 (~100 aktor),
  /// lalu memfilter aktor non-adult dan hanya menyimpan aktor Asia ('ko' atau 'ja')
  Future<List<Actor>> getPopularActors() async {
    final List<dynamic> allResults = [];

    try {
      // 1. Looping HTTP GET dari page 1 sampai page 5
      for (int page = 1; page <= 5; page++) {
        final url = Uri.parse(
          '$baseUrl/person/popular?api_key=$apiKey&language=en-US&page=$page',
        );

        final response = await _client.get(url);

        if (response.statusCode == 200) {
          final Map<String, dynamic> data =
              json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
          final List<dynamic> results = data['results'] as List<dynamic>? ?? [];
          allResults.addAll(results);
        } else if (page == 1) {
          throw Exception(
            'Gagal mengambil data aktor dari TMDB (Status Code: ${response.statusCode})',
          );
        }
      }

      // 2. SETELAH digabung, lakukan filtering:
      // - Buang aktor konten dewasa (adult content)
      // - Hanya simpan aktor yang original_language pada known_for-nya adalah 'ko' atau 'ja'
      // - Deduplikasi berdasarkan ID aktor
      final Set<int> seenIds = <int>{};
      final List<dynamic> filtered = allResults.where((item) {
        if (item is! Map<String, dynamic>) return false;

        // Membuang aktor dewasa (adult content)
        if (item['adult'] == true) return false;

        final int id = item['id'] as int? ?? 0;
        if (id > 0 && !seenIds.add(id)) {
          return false; // Lewati jika sudah ada (mencegah duplikat antar halaman)
        }

        final knownFor = item['known_for'] as List<dynamic>?;
        if (knownFor != null && knownFor.isNotEmpty) {
          return knownFor.any((work) {
            if (work is Map<String, dynamic>) {
              if (work['adult'] == true) return false;
              final lang = (work['original_language'] as String?)?.toLowerCase();
              return lang == 'ko' || lang == 'ja';
            }
            return false;
          });
        }
        return true; // Fallback jika tidak ada data known_for (seperti pada unit test)
      }).toList();

      return filtered
          .map((item) => Actor.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Terjadi kesalahan saat menghubungi TMDB API: $e');
    }
  }

  /// Mengambil film populer (/movie/popular atau /discover/movie jika ada filter)
  Future<List<Drama>> getMovies({int? genreId, String? originalLanguage}) async {
    if (genreId == null && (originalLanguage == null || originalLanguage.isEmpty)) {
      final url = Uri.parse(
        '$baseUrl/movie/popular?api_key=$apiKey&language=en-US&page=1',
      );

      try {
        final response = await _client.get(url);

        if (response.statusCode == 200) {
          final Map<String, dynamic> data =
              json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
          final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

          return results
              .map((item) =>
                  Drama.fromTmdbJson(item as Map<String, dynamic>, defaultGenre: 'Film'))
              .toList();
        } else {
          throw Exception(
            'Gagal mengambil movies dari TMDB (Status Code: ${response.statusCode})',
          );
        }
      } catch (e) {
        throw Exception('Terjadi kesalahan saat mengambil movies: $e');
      }
    } else {
      final Map<String, String> params = {};
      if (originalLanguage != null && originalLanguage.isNotEmpty) {
        params['with_original_language'] = originalLanguage;
      }
      return _fetchDiscoverMedia(
        endpoint: 'movie',
        params: params,
        defaultGenre: 'Film',
        genreId: genreId,
      );
    }
  }

  /// Mengambil serial drama populer (/tv/popular atau /discover/tv jika ada filter)
  Future<List<Drama>> getDramas({int? genreId, String? originalLanguage}) async {
    if (genreId == null && (originalLanguage == null || originalLanguage.isEmpty)) {
      final url = Uri.parse(
        '$baseUrl/tv/popular?api_key=$apiKey&language=en-US&page=1',
      );

      try {
        final response = await _client.get(url);

        if (response.statusCode == 200) {
          final Map<String, dynamic> data =
              json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
          final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

          return results
              .map((item) =>
                  Drama.fromTmdbJson(item as Map<String, dynamic>, defaultGenre: 'Drama'))
              .toList();
        } else {
          throw Exception(
            'Gagal mengambil drama dari TMDB (Status Code: ${response.statusCode})',
          );
        }
      } catch (e) {
        throw Exception('Terjadi kesalahan saat mengambil drama: $e');
      }
    } else {
      final Map<String, String> params = {};
      if (originalLanguage != null && originalLanguage.isNotEmpty) {
        params['with_original_language'] = originalLanguage;
      }
      return _fetchDiscoverMedia(
        endpoint: 'tv',
        params: params,
        defaultGenre: 'Drama',
        genreId: genreId,
      );
    }
  }

  /// Mengambil serial anime populer (/discover/tv?with_genres=16)
  Future<List<Drama>> getAnimes() async {
    final url = Uri.parse(
      '$baseUrl/discover/tv?api_key=$apiKey&with_genres=16&language=en-US&page=1',
    );

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

        return results
            .map((item) =>
                Drama.fromTmdbJson(item as Map<String, dynamic>, defaultGenre: 'Anime'))
            .toList();
      } else {
        throw Exception(
          'Gagal mengambil anime dari TMDB (Status Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengambil anime: $e');
    }
  }

  /// Mengambil serial drama yang sedang tayang di TV (/tv/on_the_air)
  Future<List<Drama>> getOnTheAirTv({int page = 1}) async {
    final url = Uri.parse(
      '$baseUrl/tv/on_the_air?api_key=$apiKey&language=en-US&page=$page',
    );

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

        return results
            .map((item) => Drama.fromTmdbJson(
                  item as Map<String, dynamic>,
                  defaultGenre: 'Drama',
                  mediaType: 'tv',
                ))
            .toList();
      } else {
        throw Exception(
          'Gagal mengambil drama sedang tayang (Status Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengambil on the air TV: $e');
    }
  }

  /// Mengambil daftar film dan serial yang segera hadir (masa depan)
  /// Menggunakan TMDB /discover/movie & /discover/tv dengan filter primary_release_date.gte & first_air_date.gte
  Future<List<Drama>> getUpcomingMovies({int page = 1}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final movieUrl = Uri.parse(
      '$baseUrl/discover/movie?api_key=$apiKey&language=en-US&primary_release_date.gte=$todayStr&sort_by=popularity.desc&page=$page',
    );
    final tvUrl = Uri.parse(
      '$baseUrl/discover/tv?api_key=$apiKey&language=en-US&first_air_date.gte=$todayStr&sort_by=popularity.desc&page=$page',
    );

    try {
      final responses = await Future.wait([
        _client.get(movieUrl),
        _client.get(tvUrl),
      ]);

      final List<Drama> upcomingList = [];

      // 1. Parse Hasil Film
      if (responses[0].statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(responses[0].bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];
        upcomingList.addAll(results.map((item) => Drama.fromTmdbJson(
              item as Map<String, dynamic>,
              defaultGenre: 'Film',
              mediaType: 'movie',
            )));
      }

      // 2. Parse Hasil TV Show / Drama / Anime
      if (responses[1].statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(responses[1].bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];
        upcomingList.addAll(results.map((item) => Drama.fromTmdbJson(
              item as Map<String, dynamic>,
              defaultGenre: 'Drama',
              mediaType: 'tv',
            )));
      }

      if (responses[0].statusCode != 200 && responses[1].statusCode != 200) {
        throw Exception(
          'Gagal mengambil jadwal segera hadir dari TMDB (Status Code: ${responses[0].statusCode})',
        );
      }

      // Filter Ganda di Dart (Wajib): Hanya tanggal yang belum rilis atau rilis mulai hari ini
      final filtered = upcomingList.where((drama) {
        final rawDate = drama.date.isNotEmpty ? drama.date : drama.aired;
        if (rawDate.trim().isEmpty) return false;
        final releaseDate = DateTime.tryParse(rawDate.trim());
        if (releaseDate == null) return false;
        final releaseDay =
            DateTime(releaseDate.year, releaseDate.month, releaseDate.day);
        return !releaseDay.isBefore(today);
      }).toList();

      // Hapus duplikasi berdasarkan ID
      final Set<int> seenIds = {};
      final uniqueList = filtered.where((d) => seenIds.add(d.id)).toList();

      // Urutkan berdasarkan tanggal rilis terdekat (ascending) lalu rating/popularitas
      uniqueList.sort((a, b) {
        final dateA = DateTime.tryParse(a.date.isNotEmpty ? a.date : a.aired);
        final dateB = DateTime.tryParse(b.date.isNotEmpty ? b.date : b.aired);
        if (dateA != null && dateB != null) {
          final comp = dateA.compareTo(dateB);
          if (comp != 0) return comp;
        }
        return b.rating.compareTo(a.rating);
      });

      return uniqueList;
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengambil upcoming movies: $e');
    }
  }

  /// Mengambil gabungan jadwal sedang tayang (Film /movie/now_playing & Drama /tv/on_the_air)
  /// Memastikan hanya tayangan yang rilis dalam 2 bulan terakhir hingga hari ini
  Future<List<Drama>> getNowAiringSchedule({int page = 1}) async {
    try {
      final List<List<Drama>> results = await Future.wait<List<Drama>>([
        getNowPlayingMovies(page: page).catchError((_) => <Drama>[]),
        getOnTheAirTv(page: page).catchError((_) => <Drama>[]),
      ]);
      final List<Drama> combined = [...results[0], ...results[1]];

      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final twoMonthsAgo = now.subtract(const Duration(days: 60));

      final filtered = combined.where((drama) {
        final rawDate = drama.date.isNotEmpty ? drama.date : drama.aired;
        final releaseDate = DateTime.tryParse(rawDate);
        if (releaseDate == null) return false;
        // Hanya yang rilis dalam 2 bulan terakhir hingga hari ini (isBefore(tomorrow))
        return releaseDate.isBefore(tomorrow) &&
            (releaseDate.isAfter(twoMonthsAgo) || releaseDate.isAtSameMomentAs(twoMonthsAgo));
      }).toList();

      final Set<int> seenIds = {};
      final uniqueList = filtered.where((d) => seenIds.add(d.id)).toList();

      uniqueList.sort((a, b) {
        final dateA = DateTime.tryParse(a.date.isNotEmpty ? a.date : a.aired);
        final dateB = DateTime.tryParse(b.date.isNotEmpty ? b.date : b.aired);
        if (dateA != null && dateB != null) {
          final comp = dateB.compareTo(dateA); // Terbaru di atas
          if (comp != 0) return comp;
        }
        return b.rating.compareTo(a.rating);
      });

      return uniqueList;
    } catch (e) {
      throw Exception('Terjadi kesalahan saat memuat jadwal sedang tayang: $e');
    }
  }


  /// Mengambil daftar film/drama yang dibintangi aktor (/person/{person_id}/combined_credits)
  Future<List<ActorCredit>> getActorCredits(int personId) async {
    final url = Uri.parse(
      '$baseUrl/person/$personId/combined_credits?api_key=$apiKey&language=en-US',
    );

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> cast = data['cast'] as List<dynamic>? ?? [];

        // Urutkan berdasarkan popularitas atau tanggal rilis terbaru
        final List<ActorCredit> credits = cast
            .map((item) => ActorCredit.fromJson(item as Map<String, dynamic>))
            .where((c) => c.title.isNotEmpty)
            .toList();

        credits.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
        return credits;
      } else {
        throw Exception(
          'Gagal mengambil credits aktor dari TMDB (Status Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengambil credits aktor: $e');
    }
  }

  /// Mengambil detail profil lengkap aktor (/person/{person_id})
  Future<Actor> getActorDetail(int personId) async {
    final url = Uri.parse(
      '$baseUrl/person/$personId?api_key=$apiKey&language=en-US',
    );

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return Actor.fromJson(data);
      } else {
        throw Exception(
          'Gagal mengambil detail aktor dari TMDB (Status Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengambil detail aktor: $e');
    }
  }

  /// Mengambil daftar film trending harian dari TMDB API
  Future<List<Drama>> getTrendingMovies() async {
    final url = Uri.parse(
      '$baseUrl/trending/movie/day?api_key=$apiKey',
    );

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

        return results
            .map((item) => Drama.fromTmdbJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Gagal mengambil data trending movies dari TMDB (Status Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengambil trending movies: $e');
    }
  }

  /// Mengambil daftar film yang sedang tayang (now playing) dari TMDB API
  Future<List<Drama>> getNowPlayingMovies({int? page}) async {
    final url = Uri.parse(
      page != null
          ? '$baseUrl/movie/now_playing?api_key=$apiKey&language=en-US&page=$page'
          : '$baseUrl/movie/now_playing?api_key=$apiKey',
    );

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

        return results
            .map((item) => Drama.fromTmdbJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Gagal mengambil data now playing movies dari TMDB (Status Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengambil now playing movies: $e');
    }
  }

  // =========================================================================
  // PERLUASAN TMDB DENGAN FILTER KATEGORI & NEGARA (FOKUS ASIA)
  // =========================================================================

  /// Mengambil data Trending Hari Ini dari TMDB (/trending/all/day), maks 20 item penuh
  Future<List<Drama>> getTrendingAllMix({int limit = 20}) async {
    final url = Uri.parse('$baseUrl/trending/all/day?api_key=$apiKey');

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

        return results
            .where((item) {
              if (item is! Map<String, dynamic>) return false;
              if (item['media_type'] == 'person') return false;
              return true;
            })
            .take(limit)
            .map((item) => Drama.fromTmdbJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Gagal mengambil trending all mix dari TMDB (Status Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengambil trending all mix: $e');
    }
  }

  /// Mengambil data Trending Minggu Ini dari TMDB (/trending/all/week)
  Future<List<Drama>> getTrendingAllWeek({int limit = 20}) async {
    final url = Uri.parse('$baseUrl/trending/all/week?api_key=$apiKey');

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

        return results
            .where((item) {
              if (item is! Map<String, dynamic>) return false;
              if (item['media_type'] == 'person') return false;
              return true;
            })
            .take(limit)
            .map((item) => Drama.fromTmdbJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Gagal mengambil trending all week dari TMDB (Status Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengambil trending all week: $e');
    }
  }

  /// Mengambil daftar film dengan rating tertinggi dari TMDB (/movie/top_rated atau /discover/movie)
  Future<List<Drama>> getTopRatedMovies({
    int? genreId,
    int page = 1,
    int limit = 20,
  }) async {
    final Uri url;
    if (genreId != null) {
      url = Uri.parse(
        '$baseUrl/discover/movie?api_key=$apiKey&language=en-US&sort_by=vote_average.desc&vote_count.gte=200&with_genres=$genreId&page=$page',
      );
    } else {
      url = Uri.parse(
        '$baseUrl/movie/top_rated?api_key=$apiKey&language=en-US&page=$page',
      );
    }

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

        return results
            .take(limit)
            .map((item) => Drama.fromTmdbJson(
                  item as Map<String, dynamic>,
                  defaultGenre: 'Film',
                  mediaType: 'movie',
                ))
            .toList();
      } else {
        throw Exception(
          'Gagal mengambil film top rated dari TMDB (Status Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengambil film top rated: $e');
    }
  }

  /// Mengambil daftar film segera hadir langsung dari TMDB (/discover/movie)
  Future<List<Drama>> getMovieUpcoming({
    int page = 1,
    int limit = 20,
    bool useDiscover = true,
  }) async {
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final Uri url = Uri.parse(
      '$baseUrl/discover/movie?api_key=$apiKey&language=en-US&primary_release_date.gte=$todayStr&sort_by=primary_release_date.asc&page=$page',
    );

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

        // API TMDB mengirimkan daftar utuh yang sudah terfilter dari sananya
        final validItems = results
            .whereType<Map<String, dynamic>>()
            .map((item) => Drama.fromTmdbJson(
                  item,
                  defaultGenre: 'Film',
                  mediaType: 'movie',
                ))
            .take(limit)
            .toList();

        return validItems;
      } else {
        throw Exception(
          'Gagal mengambil movie upcoming dari TMDB (Status Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengambil movie upcoming: $e');
    }
  }

  /// Mengambil film berdasarkan rentang dekade rilis (/discover/movie)
  /// Mendukung parameter string dekade (misal '2020s', '1990s') atau range tanggal eksplisit
  Future<List<Drama>> getMoviesByDecade({
    String? decade,
    String? startDate,
    String? endDate,
    int? year,
    int page = 1,
    int limit = 30,
  }) async {
    if (year != null) {
      return getMoviesByYear(year: year, page: page, limit: limit);
    }
    if (decade != null && RegExp(r'^\d{4}$').hasMatch(decade.trim())) {
      return getMoviesByYear(year: int.parse(decade.trim()), page: page, limit: limit);
    }

    String start = startDate ?? '';
    String end = endDate ?? '';

    if (start.isEmpty || end.isEmpty) {
      if (decade != null) {
        final match = RegExp(r'^(\d{4})s$').firstMatch(decade.trim());
        if (match != null) {
          final startYear = int.parse(match.group(1)!);
          final endYear = startYear + 9;
          start = '$startYear-01-01';
          end = '$endYear-12-31';
        }
      }
      if (start.isEmpty || end.isEmpty) {
        start = '2020-01-01';
        end = '2029-12-31';
      }
    }

    final url = Uri.parse(
      '$baseUrl/discover/movie?api_key=$apiKey&language=en-US&primary_release_date.gte=$start&primary_release_date.lte=$end&sort_by=popularity.desc&page=$page',
    );

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

        return results
            .take(limit)
            .map((item) => Drama.fromTmdbJson(
                  item as Map<String, dynamic>,
                  defaultGenre: 'Film',
                  mediaType: 'movie',
                ))
            .toList();
      } else {
        throw Exception(
          'Gagal mengambil film dekade ($start s/d $end) dari TMDB (Status Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengambil film dekade: $e');
    }
  }

  /// Mengambil film berdasarkan tahun rilis spesifik (/discover/movie?primary_release_year=$year)
  Future<List<Drama>> getMoviesByYear({
    required int year,
    int page = 1,
    int limit = 30,
  }) async {
    final url = Uri.parse(
      '$baseUrl/discover/movie?api_key=$apiKey&language=en-US&primary_release_year=$year&sort_by=popularity.desc&page=$page',
    );

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

        return results
            .take(limit)
            .map((item) => Drama.fromTmdbJson(
                  item as Map<String, dynamic>,
                  defaultGenre: 'Film',
                  mediaType: 'movie',
                ))
            .toList();
      } else {
        throw Exception(
          'Gagal mengambil film untuk tahun $year dari TMDB (Status Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengambil film tahun $year: $e');
    }
  }

  /// Mengambil serial TV berdasarkan tahun tayang perdana spesifik (/discover/tv?first_air_date_year=$year)
  Future<List<Drama>> getTvShowsByYear({
    required int year,
    int page = 1,
    int limit = 30,
  }) async {
    final url = Uri.parse(
      '$baseUrl/discover/tv?api_key=$apiKey&language=en-US&first_air_date_year=$year&sort_by=popularity.desc&page=$page',
    );

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

        return results
            .take(limit)
            .map((item) => Drama.fromTmdbJson(
                  item as Map<String, dynamic>,
                  defaultGenre: 'Drama',
                  mediaType: 'tv',
                ))
            .toList();
      } else {
        throw Exception(
          'Gagal mengambil serial TV untuk tahun $year dari TMDB (Status Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengambil serial TV tahun $year: $e');
    }
  }

  /// Mengambil film berdasarkan parameter genre (/discover/movie?with_genres=$genreId)
  /// Mendukung filter tahun tunggal (primary_release_year) atau rentang dekade/tanggal
  Future<List<Drama>> getMoviesByGenre(
    int genreId, {
    int page = 1,
    int limit = 20,
    int? year,
    String? decade,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{
      'api_key': apiKey,
      'language': 'en-US',
      'with_genres': genreId.toString(),
      'sort_by': 'popularity.desc',
      'page': page.toString(),
    };

    if (year != null) {
      queryParams['primary_release_year'] = year.toString();
    } else if (startDate != null &&
        endDate != null &&
        startDate.isNotEmpty &&
        endDate.isNotEmpty) {
      queryParams['primary_release_date.gte'] = startDate;
      queryParams['primary_release_date.lte'] = endDate;
    } else if (decade != null) {
      final match = RegExp(r'^(\d{4})s$').firstMatch(decade.trim());
      if (match != null) {
        final startYear = int.parse(match.group(1)!);
        final endYear = startYear + 9;
        queryParams['primary_release_date.gte'] = '$startYear-01-01';
        queryParams['primary_release_date.lte'] = '$endYear-12-31';
      }
    }

    final url = Uri.parse('$baseUrl/discover/movie')
        .replace(queryParameters: queryParams);

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

        return results
            .take(limit)
            .map((item) => Drama.fromTmdbJson(
                  item as Map<String, dynamic>,
                  defaultGenre: _getGenreNameForId(genreId),
                  mediaType: 'movie',
                ))
            .toList();
      } else {
        throw Exception(
          'Gagal mengambil film genre $genreId dari TMDB (Status Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengambil film genre $genreId: $e');
    }
  }

  /// Mengambil film Populer di Horor (with_genres=27)
  Future<List<Drama>> getPopularHorrorMovies({
    int page = 1,
    int limit = 20,
    int? year,
    String? decade,
    String? startDate,
    String? endDate,
  }) async {
    return getMoviesByGenre(
      27,
      page: page,
      limit: limit,
      year: year,
      decade: decade,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Mengambil film Populer di Thriller (with_genres=53)
  Future<List<Drama>> getPopularThrillerMovies({
    int page = 1,
    int limit = 20,
    int? year,
    String? decade,
    String? startDate,
    String? endDate,
  }) async {
    return getMoviesByGenre(
      53,
      page: page,
      limit: limit,
      year: year,
      decade: decade,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Mengambil film Sci-Fi & Fantasi (with_genres=878)
  Future<List<Drama>> getPopularSciFiMovies({
    int page = 1,
    int limit = 20,
    int? year,
    String? decade,
    String? startDate,
    String? endDate,
  }) async {
    return getMoviesByGenre(
      878,
      page: page,
      limit: limit,
      year: year,
      decade: decade,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Mengambil film Populer di Aksi (with_genres=28)
  Future<List<Drama>> getPopularActionMovies({
    int page = 1,
    int limit = 20,
    int? year,
    String? decade,
    String? startDate,
    String? endDate,
  }) async {
    return getMoviesByGenre(
      28,
      page: page,
      limit: limit,
      year: year,
      decade: decade,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Mengambil film Populer di Komedi (with_genres=35)
  Future<List<Drama>> getPopularComedyMovies({
    int page = 1,
    int limit = 20,
    int? year,
    String? decade,
    String? startDate,
    String? endDate,
  }) async {
    return getMoviesByGenre(
      35,
      page: page,
      limit: limit,
      year: year,
      decade: decade,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Mengambil film Populer di Romantis (with_genres=10749)
  Future<List<Drama>> getPopularRomanceMovies({
    int page = 1,
    int limit = 20,
    int? year,
    String? decade,
    String? startDate,
    String? endDate,
  }) async {
    return getMoviesByGenre(
      10749,
      page: page,
      limit: limit,
      year: year,
      decade: decade,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Mengambil film Populer di Crime (with_genres=80)
  Future<List<Drama>> getPopularCrimeMovies({
    int page = 1,
    int limit = 20,
    int? year,
    String? decade,
    String? startDate,
    String? endDate,
  }) async {
    return getMoviesByGenre(
      80,
      page: page,
      limit: limit,
      year: year,
      decade: decade,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Mengambil film Populer di Drama (with_genres=18)
  Future<List<Drama>> getPopularDramaMovies({
    int page = 1,
    int limit = 20,
    int? year,
    String? decade,
    String? startDate,
    String? endDate,
  }) async {
    return getMoviesByGenre(
      18,
      page: page,
      limit: limit,
      year: year,
      decade: decade,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Mengambil film Populer di Animasi (with_genres=16)
  Future<List<Drama>> getPopularAnimationMovies({
    int page = 1,
    int limit = 20,
    int? year,
    String? decade,
    String? startDate,
    String? endDate,
  }) async {
    return getMoviesByGenre(
      16,
      page: page,
      limit: limit,
      year: year,
      decade: decade,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Mengambil film Populer di Fantasi (with_genres=14)
  Future<List<Drama>> getPopularFantasyMovies({
    int page = 1,
    int limit = 20,
    int? year,
    String? decade,
    String? startDate,
    String? endDate,
  }) async {
    return getMoviesByGenre(
      14,
      page: page,
      limit: limit,
      year: year,
      decade: decade,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Mengambil film Populer di Misteri (with_genres=9648)
  Future<List<Drama>> getPopularMysteryMovies({
    int page = 1,
    int limit = 20,
    int? year,
    String? decade,
    String? startDate,
    String? endDate,
  }) async {
    return getMoviesByGenre(
      9648,
      page: page,
      limit: limit,
      year: year,
      decade: decade,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Mengambil serial TV berdasarkan parameter genre (/discover/tv?with_genres=$genreId)
  /// Mendukung filter tahun tunggal (first_air_date_year) atau rentang dekade/tanggal
  Future<List<Drama>> getTvShowsByGenre(
    int genreId, {
    int page = 1,
    int limit = 20,
    int? year,
    String? decade,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{
      'api_key': apiKey,
      'language': 'en-US',
      'with_genres': genreId.toString(),
      'sort_by': 'popularity.desc',
      'page': page.toString(),
    };

    if (year != null) {
      queryParams['first_air_date_year'] = year.toString();
    } else if (startDate != null &&
        endDate != null &&
        startDate.isNotEmpty &&
        endDate.isNotEmpty) {
      queryParams['first_air_date.gte'] = startDate;
      queryParams['first_air_date.lte'] = endDate;
    } else if (decade != null) {
      final match = RegExp(r'^(\d{4})s$').firstMatch(decade.trim());
      if (match != null) {
        final startYear = int.parse(match.group(1)!);
        final endYear = startYear + 9;
        queryParams['first_air_date.gte'] = '$startYear-01-01';
        queryParams['first_air_date.lte'] = '$endYear-12-31';
      }
    }

    final url =
        Uri.parse('$baseUrl/discover/tv').replace(queryParameters: queryParams);

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

        return results
            .take(limit)
            .map((item) => Drama.fromTmdbJson(
                  item as Map<String, dynamic>,
                  defaultGenre: _getGenreNameForId(genreId),
                  mediaType: 'tv',
                ))
            .toList();
      } else {
        throw Exception(
          'Gagal mengambil serial TV genre $genreId dari TMDB (Status Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengambil serial TV genre $genreId: $e');
    }
  }

  String _getGenreNameForId(int genreId) {
    switch (genreId) {
      case 27:
        return 'Horor';
      case 53:
        return 'Thriller';
      case 878:
        return 'Sci-Fi';
      case 28:
        return 'Aksi';
      case 35:
        return 'Komedi';
      case 10749:
        return 'Romantis';
      case 80:
        return 'Crime';
      case 18:
        return 'Drama';
      case 16:
        return 'Animasi';
      case 14:
        return 'Fantasi';
      case 9648:
        return 'Misteri';
      default:
        return 'Film';
    }
  }

  /// Mengambil data film/media berdasarkan genre spesifik (/discover/movie?with_genres=$genreId)
  Future<List<Drama>> getMediaByGenre(int genreId, {int limit = 30}) async {
    return _fetchDiscoverMedia(
      endpoint: 'movie',
      params: {
        'with_genres': '$genreId',
        'sort_by': 'popularity.desc',
      },
      defaultGenre: 'Film',
      limit: limit,
      genreId: genreId,
    );
  }

  /// Mengambil discover movies dengan parameter opsional [int? genreId]
  Future<List<Drama>> getDiscoverMovies([int? genreId, int limit = 20]) async {
    final Map<String, String> params = {'with_original_language': 'ko'};
    if (genreId != null) {
      params['with_genres'] = '$genreId';
    }
    return _fetchDiscoverMedia(
      endpoint: 'movie',
      params: params,
      defaultGenre: 'Film Korea',
      limit: limit,
      genreId: genreId,
    );
  }

  /// Mengambil discover tv shows dengan parameter opsional [int? genreId]
  Future<List<Drama>> getDiscoverTvShows([int? genreId, int limit = 20]) async {
    final Map<String, String> params = {'with_original_language': 'ko'};
    if (genreId != null) {
      params['with_genres'] = '$genreId';
    }
    return _fetchDiscoverMedia(
      endpoint: 'tv',
      params: params,
      defaultGenre: 'Drama Korea',
      limit: limit,
      genreId: genreId,
    );
  }

  /// Film Korea: /discover/movie?with_original_language=ko (Maks 20)
  Future<List<Drama>> getKoreanMovies({int? genreId, int limit = 20}) async {
    final Map<String, String> params = {'with_original_language': 'ko'};
    if (genreId != null) {
      params['with_genres'] = '$genreId';
    }
    return _fetchDiscoverMedia(
      endpoint: 'movie',
      params: params,
      defaultGenre: 'Film Korea',
      limit: limit,
      genreId: genreId,
    );
  }

  /// Drama Korea: /discover/tv?with_original_language=ko (Maks 20)
  Future<List<Drama>> getKoreanDramas({int? genreId, int limit = 20}) async {
    final Map<String, String> params = {'with_original_language': 'ko'};
    if (genreId != null) {
      params['with_genres'] = '$genreId';
    }
    return _fetchDiscoverMedia(
      endpoint: 'tv',
      params: params,
      defaultGenre: 'Drama Korea',
      limit: limit,
      genreId: genreId,
    );
  }

  /// Film Jepang: /discover/movie?with_original_language=ja (Maks 20)
  Future<List<Drama>> getJapaneseMovies({int? genreId, int limit = 20}) async {
    return _fetchDiscoverMedia(
      endpoint: 'movie',
      params: {'with_original_language': 'ja'},
      defaultGenre: 'Film Jepang',
      limit: limit,
      genreId: genreId,
    );
  }

  /// Drama Jepang: /discover/tv?with_original_language=ja (Maks 20)
  Future<List<Drama>> getJapaneseDramas({int? genreId, int limit = 20}) async {
    return _fetchDiscoverMedia(
      endpoint: 'tv',
      params: {'with_original_language': 'ja'},
      defaultGenre: 'Drama Jepang',
      limit: limit,
      genreId: genreId,
    );
  }

  /// Film Barat/Global: /discover/movie?with_original_language=en (Maks 20)
  Future<List<Drama>> getWesternMovies({int? genreId, int limit = 20}) async {
    return _fetchDiscoverMedia(
      endpoint: 'movie',
      params: {'with_original_language': 'en'},
      defaultGenre: 'Film Barat',
      limit: limit,
      genreId: genreId,
    );
  }

  /// Drama Barat: /discover/tv?with_original_language=en (Maks 20)
  Future<List<Drama>> getWesternDramas({int? genreId, int limit = 20}) async {
    return _fetchDiscoverMedia(
      endpoint: 'tv',
      params: {'with_original_language': 'en'},
      defaultGenre: 'Drama Barat',
      limit: limit,
      genreId: genreId,
    );
  }

  /// Anime/Drama Jepang: /discover/tv?with_original_language=ja&with_genres=16 (Maks 20)
  Future<List<Drama>> getAnimeList({int? genreId, int limit = 20}) async {
    return _fetchDiscoverMedia(
      endpoint: 'tv',
      params: {'with_original_language': 'ja', 'with_genres': '16'},
      defaultGenre: 'Anime',
      limit: limit,
      genreId: genreId,
    );
  }

  /// Serial TV Animasi Global (/discover/tv?with_genres=16)
  /// Opsional filter bahasa [originalLanguage] dan [genreId]
  Future<List<Drama>> getAnimationTvShows({
    String? originalLanguage,
    int? genreId,
    int limit = 20,
  }) async {
    final Map<String, String> params = {'with_genres': '16'};
    if (originalLanguage != null && originalLanguage.isNotEmpty) {
      params['with_original_language'] = originalLanguage;
    }
    return _fetchDiscoverMedia(
      endpoint: 'tv',
      params: params,
      defaultGenre: 'Anime',
      limit: limit,
      genreId: genreId,
    );
  }

  /// Film Animasi Global (/discover/movie?with_genres=16)
  /// Opsional filter bahasa [originalLanguage] dan [genreId]
  Future<List<Drama>> getAnimationMovies({
    String? originalLanguage,
    int? genreId,
    int limit = 20,
  }) async {
    final Map<String, String> params = {'with_genres': '16'};
    if (originalLanguage != null && originalLanguage.isNotEmpty) {
      params['with_original_language'] = originalLanguage;
    }
    return _fetchDiscoverMedia(
      endpoint: 'movie',
      params: params,
      defaultGenre: 'Film Animasi',
      limit: limit,
      genreId: genreId,
    );
  }

  /// Discover movies dengan filter bahasa dan genre
  Future<List<Drama>> getDiscoverMoviesByLanguage({
    String? originalLanguage,
    int? genreId,
    String? sortBy,
    int limit = 20,
  }) async {
    final Map<String, String> params = {};
    if (originalLanguage != null && originalLanguage.isNotEmpty) {
      params['with_original_language'] = originalLanguage;
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      params['sort_by'] = sortBy;
    }
    return _fetchDiscoverMedia(
      endpoint: 'movie',
      params: params,
      defaultGenre: 'Film',
      limit: limit,
      genreId: genreId,
    );
  }

  /// Discover TV drama dengan filter bahasa dan genre
  Future<List<Drama>> getDiscoverTvByLanguage({
    String? originalLanguage,
    int? genreId,
    String? sortBy,
    int limit = 20,
  }) async {
    final Map<String, String> params = {};
    if (originalLanguage != null && originalLanguage.isNotEmpty) {
      params['with_original_language'] = originalLanguage;
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      params['sort_by'] = sortBy;
    }
    return _fetchDiscoverMedia(
      endpoint: 'tv',
      params: params,
      defaultGenre: 'Drama',
      limit: limit,
      genreId: genreId,
    );
  }

  /// Helper untuk memanggil endpoint /discover/{movie|tv} dengan query parameter spesifik
  Future<List<Drama>> _fetchDiscoverMedia({
    required String endpoint,
    required Map<String, String> params,
    required String defaultGenre,
    int limit = 20,
    int? genreId,
  }) async {
    final queryParams = {
      'api_key': apiKey,
      'language': 'en-US',
      'page': '1',
      ...params,
    };
    if (genreId != null) {
      if (params.containsKey('with_genres') && params['with_genres'] != '$genreId') {
        queryParams['with_genres'] = '${params['with_genres']},$genreId';
      } else {
        queryParams['with_genres'] = '$genreId';
      }
    }
    final uri = Uri.parse('$baseUrl/discover/$endpoint').replace(
      queryParameters: queryParams,
    );

    try {
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

        return results
            .take(limit)
            .map((item) => Drama.fromTmdbJson(item as Map<String, dynamic>,
                defaultGenre: defaultGenre))
            .toList();
      } else {
        throw Exception(
          'Gagal mengambil data discover $endpoint (Status Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat discover $endpoint: $e');
    }
  }

  /// Mengambil daftar pemeran dan tim khusus untuk film/drama (/movie/{id}/credits atau /tv/{id}/credits)
  Future<MovieCreditsResult> getMovieCredits(int id, {String mediaType = 'movie'}) async {
    if (id <= 0) return const MovieCreditsResult();

    final String type = mediaType == 'tv' ? 'tv' : 'movie';
    final url =
        Uri.parse('$baseUrl/$type/$id/credits?api_key=$apiKey&language=en-US');

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> rawCast = data['cast'] as List<dynamic>? ?? [];
        final List<dynamic> rawCrew = data['crew'] as List<dynamic>? ?? [];

        final List<ActorCredit> cast = rawCast
            .take(15)
            .map((item) => ActorCredit.fromCastJson(item as Map<String, dynamic>))
            .where((c) => c.title.isNotEmpty)
            .toList();

        final Set<String> seenCrew = <String>{};
        final List<MovieCrewMember> crew = [];
        for (final item in rawCrew) {
          if (item is Map<String, dynamic>) {
            final member = MovieCrewMember.fromJson(item);
            final key = '${member.name}_${member.job}';
            if (member.name.isNotEmpty && seenCrew.add(key)) {
              crew.add(member);
              if (crew.length >= 15) break;
            }
          }
        }

        return MovieCreditsResult(cast: cast, crew: crew);
      } else {
        return const MovieCreditsResult();
      }
    } catch (_) {
      return const MovieCreditsResult();
    }
  }

  /// Mengambil daftar pemeran khusus untuk film/drama (/movie/{id}/credits atau /tv/{id}/credits)
  Future<List<ActorCredit>> getMediaCredits(int id, {String mediaType = 'tv'}) async {
    final credits = await getMovieCredits(id, mediaType: mediaType);
    return credits.cast;
  }

  /// Mengambil daftar platform tempat menonton untuk film/drama (/movie/{id}/watch/providers)
  /// Khusus untuk region 'ID' (Indonesia)
  Future<List<WatchProvider>> getMovieWatchProviders(int movieId, {String mediaType = 'movie'}) async {
    if (movieId <= 0) return [];

    final String type = mediaType == 'tv' ? 'tv' : 'movie';
    final url = Uri.parse('$baseUrl/$type/$movieId/watch/providers?api_key=$apiKey');

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final Map<String, dynamic> results =
            data['results'] as Map<String, dynamic>? ?? {};
        final Map<String, dynamic>? idRegion =
            results['ID'] as Map<String, dynamic>?;

        if (idRegion == null) return [];

        // Urutan prioritas tipe: jika platform muncul di beberapa kategori,
        // tipe pertama yang ditemukan yang dipakai.
        const List<String> types = ['flatrate', 'free', 'ads', 'rent', 'buy'];
        final Set<int> seenIds = <int>{};
        final List<WatchProvider> providers = [];

        for (final type in types) {
          final List<dynamic> items = idRegion[type] as List<dynamic>? ?? [];
          for (final item in items) {
            if (item is Map<String, dynamic>) {
              final int pId = item['provider_id'] as int? ?? 0;
              if (pId > 0 && seenIds.add(pId)) {
                providers.add(WatchProvider.fromJson(item, type: type));
              }
            }
          }
        }

        return providers;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Mengambil YouTube video key trailer untuk film atau TV/Drama dari TMDB (/movie/{id}/videos atau /tv/{id}/videos)
  Future<String?> getMovieTrailerKey(int id, {String mediaType = 'movie'}) async {
    if (id <= 0) return null;

    final String type = mediaType == 'tv' ? 'tv' : 'movie';

    // 1. Coba panggil dengan parameter language=en-US terlebih dahulu
    try {
      final urlEn = Uri.parse('$baseUrl/$type/$id/videos?api_key=$apiKey&language=en-US');
      final responseEn = await _client.get(urlEn);

      if (responseEn.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(responseEn.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];
        final String? key = _extractYouTubeKey(results);
        if (key != null && key.isNotEmpty) {
          return key;
        }
      }
    } catch (_) {}

    // 2. Jika en-US kosong atau gagal, panggil tanpa filter bahasa (ambil video apa saja yang tersedia)
    try {
      final urlAll = Uri.parse('$baseUrl/$type/$id/videos?api_key=$apiKey');
      final responseAll = await _client.get(urlAll);

      if (responseAll.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(responseAll.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];
        final String? key = _extractYouTubeKey(results);
        if (key != null && key.isNotEmpty) {
          return key;
        }
      }
    } catch (_) {}

    return null;
  }

  /// Mengekstrak video key YouTube: mengutamakan site == 'YouTube' dan type == 'Trailer',
  /// lalu fallback ke 'Teaser', atau video YouTube pertama yang ditemukan.
  String? _extractYouTubeKey(List<dynamic> results) {
    if (results.isEmpty) return null;

    final List<Map<String, dynamic>> youtubeVideos = results
        .whereType<Map<String, dynamic>>()
        .where((v) => (v['site'] as String?)?.toLowerCase() == 'youtube')
        .toList();

    if (youtubeVideos.isEmpty) return null;

    // Prioritas 1: type == 'Trailer'
    for (final v in youtubeVideos) {
      if ((v['type'] as String?)?.toLowerCase() == 'trailer') {
        final key = v['key'] as String?;
        if (key != null && key.trim().isNotEmpty) return key.trim();
      }
    }

    // Prioritas 2: type == 'Teaser'
    for (final v in youtubeVideos) {
      if ((v['type'] as String?)?.toLowerCase() == 'teaser') {
        final key = v['key'] as String?;
        if (key != null && key.trim().isNotEmpty) return key.trim();
      }
    }

    // Prioritas 3: Video YouTube pertama yang ditemukan
    for (final v in youtubeVideos) {
      final key = v['key'] as String?;
      if (key != null && key.trim().isNotEmpty) return key.trim();
    }

    return null;
  }

  /// Mengambil data detail film lengkap (/movie/{movie_id} atau /tv/{movie_id})
  Future<Drama> getMovieDetails(int movieId, {String? mediaType}) async {
    final String type = (mediaType == 'tv') ? 'tv' : 'movie';
    final url = Uri.parse('$baseUrl/$type/$movieId?api_key=$apiKey');

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return Drama.fromTmdbJson(data, mediaType: type);
      } else {
        // Fallback untuk serial TV jika ID merupakan entitas TV di TMDB atau sebaliknya
        final String fallbackType = (type == 'movie') ? 'tv' : 'movie';
        final fallbackUrl = Uri.parse('$baseUrl/$fallbackType/$movieId?api_key=$apiKey');
        final fallbackResponse = await _client.get(fallbackUrl);
        if (fallbackResponse.statusCode == 200) {
          final Map<String, dynamic> fallbackData =
              json.decode(utf8.decode(fallbackResponse.bodyBytes)) as Map<String, dynamic>;
          return Drama.fromTmdbJson(fallbackData, mediaType: fallbackType);
        }
      }
      throw Exception('Gagal mengambil detail film dari TMDB');
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mengambil detail film: $e');
    }
  }

  // =========================================================================
  // PENCARIAN GLOBAL TMDB (TANPA FILTER WILAYAH / BAHASA / GENRE)
  // =========================================================================

  /// Mencari film global (/search/movie)
  /// Parameter yang diizinkan hanya: query, language, page, dan include_adult
  Future<List<Drama>> searchMovies(String query, {int page = 1}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final encodedQuery = Uri.encodeComponent(cleanQuery);
    final url = Uri.parse(
      '$baseUrl/search/movie?api_key=$apiKey&query=$encodedQuery&language=en-US&page=$page&include_adult=false',
    );

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

        return results
            .map((item) => Drama.fromTmdbJson(item as Map<String, dynamic>,
                defaultGenre: 'Film', mediaType: 'movie'))
            .toList();
      } else {
        throw Exception(
          'Gagal mencari film dari TMDB (Status Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mencari film: $e');
    }
  }

  /// Mencari serial TV / drama global (/search/tv)
  /// Parameter yang diizinkan hanya: query, language, page, dan include_adult
  Future<List<Drama>> searchTvShows(String query, {int page = 1}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final encodedQuery = Uri.encodeComponent(cleanQuery);
    final url = Uri.parse(
      '$baseUrl/search/tv?api_key=$apiKey&query=$encodedQuery&language=en-US&page=$page&include_adult=false',
    );

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

        return results
            .map((item) => Drama.fromTmdbJson(item as Map<String, dynamic>,
                defaultGenre: 'Drama', mediaType: 'tv'))
            .toList();
      } else {
        throw Exception(
          'Gagal mencari serial TV dari TMDB (Status Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mencari serial TV: $e');
    }
  }

  /// Mencari aktor / orang global (/search/person)
  /// Parameter yang diizinkan hanya: query, language, page, dan include_adult
  Future<List<Actor>> searchActors(String query, {int page = 1}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final encodedQuery = Uri.encodeComponent(cleanQuery);
    final url = Uri.parse(
      '$baseUrl/search/person?api_key=$apiKey&query=$encodedQuery&language=en-US&page=$page&include_adult=false',
    );

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

        return results
            .where((item) => item is Map<String, dynamic> && item['adult'] != true)
            .map((item) => Actor.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Gagal mencari aktor dari TMDB (Status Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mencari aktor: $e');
    }
  }

  /// Mengambil data papan peringkat / leaderboard dinamis dari TMDB API
  /// Menggunakan /discover/movie dan /discover/tv dengan filter kategori, bahasa, dan genre
  /// Logika Pengurutan:
  /// - Tab 'Rating Tertinggi' (isTopRated: true): sort_by=vote_average.desc,
  ///   vote_count.gte=15 untuk 'Film Indonesia', vote_count.gte=200 untuk kategori lainnya.
  /// - Tab 'Sedang Tren' (isTopRated: false): sort_by=popularity.desc, vote_count.gte=10.
  Future<List<Drama>> getLeaderboardMedia({
    String category = 'Semua',
    String genre = 'Semua Genre',
    bool isTopRated = true,
    int limit = 30,
  }) async {
    final String sortBy = isTopRated ? 'vote_average.desc' : 'popularity.desc';
    final int voteCountGte = isTopRated
        ? (category == 'Film Indonesia' ? 15 : 200)
        : 10;

    final int? movieGenreId = _getMovieGenreId(genre);
    final int? tvGenreId = _getTvGenreId(genre);

    if (category == 'Semua') {
      final results = await Future.wait([
        _fetchDiscoverLeaderboard(
          endpoint: 'movie',
          params: {
            'sort_by': sortBy,
            'vote_count.gte': '$voteCountGte',
          },
          genreId: movieGenreId,
          defaultGenre: 'Film',
          limit: limit,
        ),
        _fetchDiscoverLeaderboard(
          endpoint: 'tv',
          params: {
            'sort_by': sortBy,
            'vote_count.gte': '$voteCountGte',
          },
          genreId: tvGenreId,
          defaultGenre: 'Drama',
          limit: limit,
        ),
      ]);

      final Set<int> seenIds = <int>{};
      final List<Drama> combined = [];

      for (final list in results) {
        for (final item in list) {
          if (item.id == 0 || seenIds.add(item.id)) {
            combined.add(item);
          }
        }
      }

      if (isTopRated) {
        combined.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
      } else {
        combined.sort((a, b) => b.popularity.compareTo(a.popularity));
      }
      return combined.take(limit).toList();
    }

    String endpoint = 'movie';
    String defaultGenre = 'Film';
    final Map<String, String> params = {
      'sort_by': sortBy,
      'vote_count.gte': '$voteCountGte',
    };
    int? genreIdToUse;

    switch (category) {
      case 'Semua Film':
        endpoint = 'movie';
        defaultGenre = 'Film';
        genreIdToUse = movieGenreId;
        break;
      case 'Semua Drama':
        endpoint = 'tv';
        defaultGenre = 'Drama';
        genreIdToUse = tvGenreId;
        break;
      case 'Anime':
        endpoint = 'tv';
        defaultGenre = 'Anime';
        params['with_original_language'] = 'ja';
        params['with_genres'] = '16';
        if (tvGenreId != null && tvGenreId != 16) {
          params['with_genres'] = '16,$tvGenreId';
        }
        break;
      case 'Film Indonesia':
        endpoint = 'movie';
        defaultGenre = 'Film Indonesia';
        params['with_original_language'] = 'id';
        genreIdToUse = movieGenreId;
        break;
      case 'Film Barat':
        endpoint = 'movie';
        defaultGenre = 'Film Barat';
        params['with_original_language'] = 'en';
        genreIdToUse = movieGenreId;
        break;
      case 'Film Korea':
        endpoint = 'movie';
        defaultGenre = 'Film Korea';
        params['with_original_language'] = 'ko';
        genreIdToUse = movieGenreId;
        break;
      case 'Film Jepang':
        endpoint = 'movie';
        defaultGenre = 'Film Jepang';
        params['with_original_language'] = 'ja';
        genreIdToUse = movieGenreId;
        break;
      case 'Drama Korea':
        endpoint = 'tv';
        defaultGenre = 'Drama Korea';
        params['with_original_language'] = 'ko';
        genreIdToUse = tvGenreId;
        break;
      case 'Drama Barat':
        endpoint = 'tv';
        defaultGenre = 'Drama Barat';
        params['with_original_language'] = 'en';
        genreIdToUse = tvGenreId;
        break;
      case 'Drama Jepang':
        endpoint = 'tv';
        defaultGenre = 'Drama Jepang';
        params['with_original_language'] = 'ja';
        genreIdToUse = tvGenreId;
        break;
      default:
        endpoint = 'movie';
        defaultGenre = 'Film';
        genreIdToUse = movieGenreId;
        break;
    }

    return _fetchDiscoverLeaderboard(
      endpoint: endpoint,
      params: params,
      genreId: genreIdToUse,
      defaultGenre: defaultGenre,
      limit: limit,
    );
  }

  int? _getMovieGenreId(String genre) {
    switch (genre) {
      case 'Aksi':
        return 28;
      case 'Drama':
        return 18;
      case 'Komedi':
        return 35;
      case 'Horor':
        return 27;
      case 'Romantis':
        return 10749;
      case 'Thriller/Misteri':
        return 53;
      case 'Fiksi Ilmiah & Fantasi':
        return 878;
      case 'Animasi':
        return 16;
      default:
        return null;
    }
  }

  int? _getTvGenreId(String genre) {
    switch (genre) {
      case 'Aksi':
        return 10759;
      case 'Drama':
        return 18;
      case 'Komedi':
        return 35;
      case 'Horor':
        return 9648;
      case 'Romantis':
        return 10749;
      case 'Thriller/Misteri':
        return 9648;
      case 'Fiksi Ilmiah & Fantasi':
        return 10765;
      case 'Animasi':
        return 16;
      default:
        return null;
    }
  }

  Future<List<Drama>> _fetchDiscoverLeaderboard({
    required String endpoint,
    required Map<String, String> params,
    required String defaultGenre,
    int? genreId,
    int limit = 30,
  }) async {
    final queryParams = {
      'api_key': apiKey,
      'language': 'en-US',
      'page': '1',
      'include_adult': 'false',
      ...params,
    };

    if (genreId != null) {
      if (queryParams.containsKey('with_genres')) {
        queryParams['with_genres'] = '${queryParams['with_genres']},$genreId';
      } else {
        queryParams['with_genres'] = '$genreId';
      }
    }

    final uri = Uri.parse('$baseUrl/discover/$endpoint').replace(
      queryParameters: queryParams,
    );

    try {
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

        return results
            .take(limit)
            .map((item) => Drama.fromTmdbJson(
                  item as Map<String, dynamic>,
                  defaultGenre: defaultGenre,
                  mediaType: endpoint,
                ))
            .toList();
      } else {
        throw Exception(
          'Gagal mengambil discover $endpoint dari TMDB (Status Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat memuat leaderboard: $e');
    }
  }
}

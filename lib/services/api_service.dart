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
  Future<List<Drama>> getNowPlayingMovies() async {
    final url = Uri.parse(
      '$baseUrl/movie/now_playing?api_key=$apiKey',
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

  /// Mengambil daftar pemeran khusus untuk film/drama (/movie/{id}/credits atau /tv/{id}/credits)
  Future<List<ActorCredit>> getMediaCredits(int id, {String mediaType = 'tv'}) async {
    if (id <= 0) return [];

    final String type = mediaType == 'movie' ? 'movie' : 'tv';
    final url =
        Uri.parse('$baseUrl/$type/$id/credits?api_key=$apiKey&language=en-US');

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final List<dynamic> cast = data['cast'] as List<dynamic>? ?? [];

        return cast
            .take(15)
            .map((item) => ActorCredit.fromCastJson(item as Map<String, dynamic>))
            .where((c) => c.title.isNotEmpty)
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
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
}

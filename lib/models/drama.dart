class Drama {
  // ==========================================
  // ATRIBUT / PROPERTI PRIVAT (ENKAPSULASI PBO)
  // ==========================================
  // Seluruh atribut dibungkus secara privat dengan awalan underscore (_)
  // untuk menjamin data integrity dan mencegah manipulasi langsung dari luar kelas.
  int _id;
  String _mediaType;
  String _backdrop;
  String _title;
  String _koreanTitle;
  String _genre;
  double _rating;
  double? _myRating;
  int _episodes;
  int _watchedEpisodes;
  String _status;
  String _priority;
  String _startDate;
  String _endDate;
  String _date;
  String _image;
  String _rank;
  String _popularity;
  String _watchers;
  String _synopsis;
  String _aired;
  String _duration;
  String _contentRating;
  List<String> _genresList;
  List<String> _tagsList;
  DateTime? dateCompleted;
  String _originalLanguage;
  List<int> _genreIds;
  int? _runtime;

  // ==========================================
  // CONSTRUCTOR (BLUEPRINT PEMBANGUN OBJEK)
  // ==========================================
  /// Constructor dengan named parameter dan validasi nilai inisialisasi awal.
  Drama({
    int id = 0,
    String? mediaType,
    String? backdrop,
    required String title,
    required String koreanTitle,
    required String genre,
    required double rating,
    required int episodes,
    required int watchedEpisodes,
    required String status,
    required String priority,
    required String startDate,
    required String endDate,
    required String date,
    required String image,
    required String rank,
    required String popularity,
    required String watchers,
    required String synopsis,
    required String aired,
    required String duration,
    required String contentRating,
    required List<String> genresList,
    required List<String> tagsList,
    double? myRating,
    double? userRating,
    this.dateCompleted,
    String originalLanguage = '',
    List<int>? genreIds,
    int? runtime,
  })  : _id = (id >= 0) ? id : 0,
        // ignore: prefer_initializing_formals
        _runtime = runtime,
        _mediaType = (mediaType != null && mediaType.trim().isNotEmpty)
            ? mediaType.trim()
            : ((genre.toLowerCase().contains('film') || episodes == 1)
                ? 'movie'
                : 'tv'),
        _backdrop = backdrop?.trim() ?? '',
        _title = title.trim().isEmpty ? 'Untitled' : title.trim(),
        _koreanTitle = koreanTitle.trim(),
        _genre = genre.trim().isEmpty ? 'General' : genre.trim(),
        _rating = rating.clamp(0.0, 10.0),
        _myRating = (userRating != null)
            ? userRating.clamp(0.0, 10.0)
            : ((myRating != null) ? myRating.clamp(0.0, 10.0) : null),
        _episodes = episodes < 0 ? 0 : episodes,
        _watchedEpisodes = (watchedEpisodes < 0)
            ? 0
            : (episodes > 0 && watchedEpisodes > episodes
                ? episodes
                : watchedEpisodes),
        _status = status.trim().isEmpty ? 'Rencana Ditonton' : status.trim(),
        _priority = priority.trim().isEmpty ? 'Sedang' : priority.trim(),
        _startDate = startDate.trim(),
        _endDate = endDate.trim(),
        _date = date.trim(),
        _image = image.trim(),
        _rank = rank.trim(),
        _popularity = popularity.trim(),
        _watchers = watchers.trim(),
        _synopsis = synopsis.trim(),
        _aired = aired.trim(),
        _duration = duration.trim(),
        _contentRating = contentRating.trim(),
        _genresList = List<String>.from(genresList),
        _tagsList = List<String>.from(tagsList),
        _originalLanguage = originalLanguage.trim(),
        _genreIds = genreIds != null ? List<int>.from(genreIds) : <int>[];

  // ==========================================
  // GETTER & SETTER (PBO: ENKAPSULASI & VALIDASI)
  // ==========================================

  /// Getter untuk ID TMDB drama/film
  int get id => _id;

  /// Setter untuk ID TMDB
  set id(int value) {
    if (value >= 0) {
      _id = value;
    }
  }

  /// Getter untuk tipe media ('movie' atau 'tv')
  String get mediaType => _mediaType;

  /// Setter untuk tipe media
  set mediaType(String value) {
    if (value.trim().isNotEmpty) {
      _mediaType = value.trim();
    }
  }

  /// Memeriksa apakah media adalah film (movie)
  bool get isMovie => _mediaType == 'movie';

  /// Getter untuk bahasa asli
  String get originalLanguage => _originalLanguage;

  /// Setter untuk bahasa asli
  set originalLanguage(String value) {
    _originalLanguage = value.trim();
  }

  /// Getter untuk daftar ID genre
  List<int> get genreIds => List.unmodifiable(_genreIds);

  /// Setter untuk daftar ID genre
  set genreIds(List<int> value) {
    _genreIds = List<int>.from(value);
  }

  /// Getter untuk URL backdrop
  String get backdrop => _backdrop.isNotEmpty ? _backdrop : _image;

  /// Setter untuk URL backdrop
  set backdrop(String value) {
    _backdrop = value.trim();
  }

  /// Getter untuk judul utama drama
  String get title => _title;

  /// Setter untuk judul utama dengan validasi tidak boleh berupa string kosong
  set title(String value) {
    if (value.trim().isNotEmpty) {
      _title = value.trim();
    }
  }

  /// Getter untuk judul Korea/asli
  String get koreanTitle => _koreanTitle;

  /// Setter untuk judul Korea
  set koreanTitle(String value) {
    _koreanTitle = value.trim();
  }

  /// Getter untuk genre drama
  String get genre => _genre;

  /// Setter untuk genre dengan validasi tidak boleh kosong
  set genre(String value) {
    if (value.trim().isNotEmpty) {
      _genre = value.trim();
    }
  }

  /// Getter untuk skor rating
  double get rating => _rating;

  /// Setter untuk skor rating dengan validasi batas rentang 0.0 sampai 10.0
  set rating(double value) {
    _rating = value.clamp(0.0, 10.0);
  }

  /// Getter alias untuk rating (voteAverage dari TMDB)
  double get voteAverage => _rating;

  /// Getter untuk skor rating penilaian pribadi pengguna
  double? get myRating => _myRating;

  /// Setter untuk skor rating penilaian pribadi pengguna dengan validasi [0.0 - 10.0]
  set myRating(double? value) {
    if (value == null) {
      _myRating = null;
    } else {
      _myRating = value.clamp(0.0, 10.0);
    }
  }

  /// Memeriksa apakah pengguna sudah memberikan penilaian pribadi
  bool get hasUserRating => _myRating != null && _myRating! > 0;

  /// Getter alias untuk penilaian pribadi pengguna (userRating)
  double? get userRating => _myRating;

  /// Setter alias untuk penilaian pribadi pengguna (userRating)
  set userRating(double? value) {
    myRating = value;
  }

  /// Getter untuk jumlah total episode
  int get episodes => _episodes;

  /// Setter untuk jumlah total episode dengan validasi non-negatif
  /// serta sinkronisasi jika watchedEpisodes melebihi total baru
  set episodes(int value) {
    _episodes = value < 0 ? 0 : value;
    if (_episodes > 0 && _watchedEpisodes > _episodes) {
      _watchedEpisodes = _episodes;
    }
  }

  /// Getter untuk jumlah episode yang sudah ditonton
  int get watchedEpisodes => _watchedEpisodes;

  /// Setter untuk watchedEpisodes dengan validasi rentang [0, episodes]
  /// serta sinkronisasi status otomatis:
  /// - if (watchedEpisodes == 0) ➔ Ubah status menjadi 'Rencana Ditonton'.
  /// - if (watchedEpisodes > 0 && watchedEpisodes < episodes) ➔ Ubah status menjadi 'Sedang Menonton'.
  /// - if (watchedEpisodes == episodes) ➔ Ubah status menjadi 'Selesai'.
  set watchedEpisodes(int value) {
    if (value < 0) {
      _watchedEpisodes = 0;
    } else if (_episodes > 0 && value > _episodes) {
      _watchedEpisodes = _episodes;
    } else {
      _watchedEpisodes = value;
    }

    _syncStatusWithEpisodes();
  }

  /// Sinkronisasi status otomatis berdasarkan jumlah episode ditonton
  void _syncStatusWithEpisodes() {
    if (_episodes > 0 && _watchedEpisodes >= _episodes) {
      _status = 'Selesai';
    } else if (_watchedEpisodes > 0) {
      _status = 'Sedang Menonton';
    } else if (_status != 'Sedang Menonton') {
      _status = 'Rencana Ditonton';
    }
  }

  /// Getter untuk status tontonan ('Sedang Menonton', 'Selesai', dll.)
  String get status => _status;

  /// Setter untuk status tontonan dengan validasi tidak boleh kosong
  set status(String value) {
    if (value.trim().isNotEmpty) {
      _status = value.trim();
    }
  }

  /// Getter untuk prioritas tontonan ('Tinggi', 'Sedang', 'Rendah')
  String get priority => _priority;

  /// Setter untuk prioritas tontonan
  set priority(String value) {
    if (value.trim().isNotEmpty) {
      _priority = value.trim();
    }
  }

  /// Getter untuk tanggal mulai menonton
  String get startDate => _startDate;

  /// Setter untuk tanggal mulai menonton
  set startDate(String value) {
    _startDate = value.trim();
  }

  /// Getter untuk tanggal selesai menonton
  String get endDate => _endDate;

  /// Setter untuk tanggal selesai menonton
  set endDate(String value) {
    _endDate = value.trim();
  }

  /// Getter untuk tanggal/tahun rilis
  String get date => _date;

  /// Setter untuk tanggal/tahun rilis
  set date(String value) {
    _date = value.trim();
  }

  /// Getter alias untuk tanggal rilis (releaseDate dari TMDB)
  String get releaseDate => _date;

  /// Getter untuk URL gambar poster
  String get image => _image;

  /// Setter untuk URL gambar poster
  set image(String value) {
    _image = value.trim();
  }

  /// Getter untuk peringkat (#1, #2, dll)
  String get rank => _rank;

  /// Setter untuk peringkat
  set rank(String value) {
    _rank = value.trim();
  }

  /// Getter untuk popularitas (#1, #10, dll)
  String get popularity => _popularity;

  /// Setter untuk popularitas
  set popularity(String value) {
    _popularity = value.trim();
  }

  /// Getter untuk jumlah penonton (watchers)
  String get watchers => _watchers;

  /// Setter untuk jumlah penonton
  set watchers(String value) {
    _watchers = value.trim();
  }

  /// Getter untuk sinopsis cerita
  String get synopsis => _synopsis;

  /// Setter untuk sinopsis cerita
  set synopsis(String value) {
    _synopsis = value.trim();
  }

  /// Getter alias untuk overview / sinopsis film (TMDB API overview)
  String? get overview => _synopsis.trim().isNotEmpty ? _synopsis : null;

  /// Setter untuk overview / sinopsis film
  set overview(String? value) {
    _synopsis = value?.trim() ?? '';
  }

  /// Getter alias untuk deskripsi / overview / sinopsis film
  String? get description => overview;

  /// Setter untuk deskripsi film
  set description(String? value) {
    _synopsis = value?.trim() ?? '';
  }

  /// Getter untuk informasi masa tayang (aired)
  String get aired => _aired;

  /// Setter untuk informasi masa tayang
  set aired(String value) {
    _aired = value.trim();
  }

  /// Getter untuk estimasi durasi per episode/film
  String get duration => _duration;

  /// Setter untuk estimasi durasi
  set duration(String value) {
    _duration = value.trim();
  }

  /// Getter untuk runtime durasi dalam menit
  // ignore: unnecessary_getters_setters
  int? get runtime => _runtime;

  /// Setter untuk runtime durasi dalam menit
  // ignore: unnecessary_getters_setters
  set runtime(int? value) {
    _runtime = value;
  }

  /// Getter alias untuk daftar genre film (TMDB genres)
  List<String> get genres => List.unmodifiable(_genresList);

  /// Getter untuk rating usia konten (15+, 18+, dll)
  String get contentRating => _contentRating;

  /// Setter untuk rating usia konten
  set contentRating(String value) {
    _contentRating = value.trim();
  }

  /// Getter untuk daftar kategori genre
  List<String> get genresList => _genresList;

  /// Setter untuk daftar kategori genre
  set genresList(List<String> value) {
    _genresList = List<String>.from(value);
  }

  /// Getter untuk daftar tags/topik
  List<String> get tagsList => _tagsList;

  /// Setter untuk daftar tags/topik
  set tagsList(List<String> value) {
    _tagsList = List<String>.from(value);
  }

  // ==========================================
  // COMPUTED GETTERS (PROPERTI TERHITUNG PBO)
  // ==========================================

  /// Menghitung persentase tontonan desimal dari 0.0 sampai 1.0 (untuk progress bar)
  double get progressPercentage {
    if (_episodes <= 0) return 0.0;
    return (_watchedEpisodes / _episodes).clamp(0.0, 1.0);
  }

  /// Menghitung persentase tontonan dalam bilangan bulat persen (0 - 100)%
  int get progressPercentInt => (progressPercentage * 100).toInt();

  /// Menghitung sisa episode yang belum ditonton
  int get remainingEpisodes => hitungSisaEpisode();

  /// Memeriksa apakah drama telah selesai ditonton seluruhnya
  bool get isCompleted => _episodes > 0 && _watchedEpisodes >= _episodes;

  /// Memeriksa apakah drama sudah mulai ditonton (minimal 1 episode)
  bool get isStarted => _watchedEpisodes > 0;

  /// Format ringkasan teks progres tontonan (contoh: "12/16 Eps")
  String get progressSummary => '$_watchedEpisodes/$_episodes Eps';

  /// Format teks skor rating dengan presisi 1 angka desimal
  String get formattedRating => _rating.toStringAsFixed(1);

  // ==========================================
  // CUSTOM FUNCTIONS / METHODS (PERILAKU OBJEK PBO)
  // ==========================================

  /// [Method 1] Menghitung persentase penyelesaian tontonan dalam format 0.0 - 100.0%
  double hitungPersentaseSelesai() {
    if (_episodes <= 0) return 0.0;
    return ((_watchedEpisodes / _episodes) * 100.0).clamp(0.0, 100.0);
  }

  /// [Method 2] Menghitung jumlah sisa episode yang belum diselesaikan
  int hitungSisaEpisode() {
    if (_episodes <= 0) return 0;
    final int sisa = _episodes - _watchedEpisodes;
    return sisa < 0 ? 0 : sisa;
  }

  /// [Method 3] Memperbarui progres episode yang ditonton sekaligus menyinkronkan status tontonan
  void updateProgress(int eps) {
    watchedEpisodes = eps; // Memanggil setter agar validasi otomatis bekerja
    if (_episodes > 0 && _watchedEpisodes >= _episodes) {
      _status = 'Selesai';
    } else if (_watchedEpisodes > 0) {
      _status = 'Sedang Menonton';
    } else {
      _status = 'Rencana Ditonton';
    }
  }

  /// [Method 4] Menambahkan progres tontonan sebanyak 1 episode
  void tambahSatuEpisode() {
    if (_episodes == 0 || _watchedEpisodes < _episodes) {
      updateProgress(_watchedEpisodes + 1);
    }
  }

  /// [Method 5] Mengurangi progres tontonan sebanyak 1 episode
  void kurangiSatuEpisode() {
    if (_watchedEpisodes > 0) {
      updateProgress(_watchedEpisodes - 1);
    }
  }

  /// [Method 6] Menandai drama telah selesai ditonton seluruhnya
  void tandaiSelesai() {
    _watchedEpisodes = _episodes;
    _status = 'Selesai';
  }

  /// [Method 7] Mereset progres tontonan kembali ke awal (0 episode)
  void resetProgress() {
    _watchedEpisodes = 0;
    _status = 'Rencana Ditonton';
  }

  /// [Method 8] Method copyWith untuk membuat salinan objek dengan modifikasi atribut terpilih (Prinsip PBO)
  Drama copyWith({
    int? id,
    String? mediaType,
    String? backdrop,
    String? title,
    String? koreanTitle,
    String? genre,
    double? rating,
    int? episodes,
    int? watchedEpisodes,
    String? status,
    String? priority,
    String? startDate,
    String? endDate,
    String? date,
    String? image,
    String? rank,
    String? popularity,
    String? watchers,
    String? synopsis,
    String? aired,
    String? duration,
    String? contentRating,
    List<String>? genresList,
    List<String>? tagsList,
    double? myRating,
    double? userRating,
    DateTime? dateCompleted,
    String? originalLanguage,
    List<int>? genreIds,
    int? runtime,
  }) {
    return Drama(
      id: id ?? _id,
      mediaType: mediaType ?? _mediaType,
      backdrop: backdrop ?? _backdrop,
      title: title ?? _title,
      koreanTitle: koreanTitle ?? _koreanTitle,
      genre: genre ?? _genre,
      rating: rating ?? _rating,
      myRating: userRating ?? myRating ?? _myRating,
      episodes: episodes ?? _episodes,
      watchedEpisodes: watchedEpisodes ?? _watchedEpisodes,
      status: status ?? _status,
      priority: priority ?? _priority,
      startDate: startDate ?? _startDate,
      endDate: endDate ?? _endDate,
      date: date ?? _date,
      image: image ?? _image,
      rank: rank ?? _rank,
      popularity: popularity ?? _popularity,
      watchers: watchers ?? _watchers,
      synopsis: synopsis ?? _synopsis,
      aired: aired ?? _aired,
      duration: duration ?? _duration,
      contentRating: contentRating ?? _contentRating,
      genresList: genresList ?? List<String>.from(_genresList),
      tagsList: tagsList ?? List<String>.from(_tagsList),
      dateCompleted: dateCompleted ?? this.dateCompleted,
      originalLanguage: originalLanguage ?? _originalLanguage,
      genreIds: genreIds ?? List<int>.from(_genreIds),
      runtime: runtime ?? _runtime,
    );
  }

  /// Factory constructor untuk memetakan response JSON Movie/TV dari TMDB API
  factory Drama.fromTmdbJson(Map<String, dynamic> json,
      {String defaultGenre = 'Film', String? mediaType}) {
    final int id = json['id'] as int? ?? 0;
    final String? posterPath = json['poster_path'] as String?;
    final String imageUrl = (posterPath != null && posterPath.isNotEmpty)
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : '';
    final String? backdropPath = json['backdrop_path'] as String?;
    final String backdropUrl = (backdropPath != null && backdropPath.isNotEmpty)
        ? 'https://image.tmdb.org/t/p/w780$backdropPath'
        : imageUrl;
    final double voteAverage =
        (json['vote_average'] as num?)?.toDouble() ?? 0.0;
    final String title =
        json['title'] as String? ?? (json['name'] as String? ?? 'Untitled');
    final String originalTitle = json['original_title'] as String? ??
        (json['original_name'] as String? ?? title);
    final String releaseDate = json['release_date'] as String? ??
        (json['first_air_date'] as String? ?? '');
    final String overview = json['overview'] as String? ?? '';
    final int voteCount = json['vote_count'] as int? ?? 0;
    final double pop = (json['popularity'] as num?)?.toDouble() ?? 0.0;
    final String origLang = json['original_language'] as String? ?? '';
    int? runtime = (json['runtime'] as num?)?.toInt();
    if (runtime == null || runtime <= 0) {
      if (json['episode_run_time'] is List &&
          (json['episode_run_time'] as List).isNotEmpty) {
        runtime = ((json['episode_run_time'] as List).first as num?)?.toInt();
      }
    }
    final List<int> gIds = (json['genre_ids'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        <int>[];

    final List<dynamic>? rawGenres = json['genres'] as List<dynamic>?;
    final List<String> parsedGenres = (rawGenres != null && rawGenres.isNotEmpty)
        ? rawGenres
            .map((g) => (g is Map<String, dynamic> ? (g['name'] as String? ?? '') : ''))
            .where((s) => s.isNotEmpty)
            .toList()
        : (json['genresList'] is List
            ? (json['genresList'] as List).map((e) => e.toString()).toList()
            : [defaultGenre]);

    DateTime? dateCompleted;
    if (json['date_completed'] != null) {
      dateCompleted = DateTime.tryParse(json['date_completed'].toString());
    }

    final String detectedMediaType = mediaType ??
        (json['media_type'] as String? ??
            (json.containsKey('title')
                ? 'movie'
                : (json.containsKey('name')
                    ? 'tv'
                    : (defaultGenre.toLowerCase().contains('film')
                        ? 'movie'
                        : 'tv'))));

    final bool isMovieType = detectedMediaType == 'movie';

    String formattedDuration = '';
    if (runtime != null && runtime > 0) {
      final int h = runtime ~/ 60;
      final int m = runtime % 60;
      if (h > 0 && m > 0) {
        formattedDuration = '${h}j ${m}m';
      } else if (h > 0) {
        formattedDuration = '${h}j';
      } else {
        formattedDuration = '${m}m';
      }
    } else if (json['duration'] != null &&
        json['duration'].toString().trim().isNotEmpty) {
      formattedDuration = json['duration'].toString().trim();
    }

    final int? rawEpisodes = (json['number_of_episodes'] as num?)?.toInt() ??
        (json['episodes'] as num?)?.toInt();
    final int eps = isMovieType ? 1 : (rawEpisodes ?? 0);

    final String dynamicCategory = getCategoryLabel(
      mediaType: detectedMediaType,
      originalLanguage: origLang,
      genreIds: gIds,
    );

    final String initialGenre =
        (parsedGenres.isNotEmpty && parsedGenres.first != 'Film')
            ? parsedGenres.first
            : (defaultGenre != 'Film' ? defaultGenre : dynamicCategory);

    return Drama(
      id: id,
      mediaType: detectedMediaType,
      backdrop: backdropUrl,
      title: title,
      koreanTitle: originalTitle,
      genre: initialGenre,
      rating: double.parse(voteAverage.toStringAsFixed(1)),
      episodes: eps,
      watchedEpisodes: 0,
      status: 'Rencana Ditonton',
      priority: 'Sedang',
      startDate: '',
      endDate: '',
      date: releaseDate,
      image: imageUrl,
      rank: '#1',
      popularity: '${pop.round()}',
      watchers: '$voteCount',
      synopsis: overview,
      aired: releaseDate,
      duration: formattedDuration,
      contentRating: '13+',
      genresList: parsedGenres.isNotEmpty && parsedGenres.first != 'Film'
          ? parsedGenres
          : [dynamicCategory],
      tagsList: ['TMDB'],
      dateCompleted: dateCompleted,
      originalLanguage: origLang,
      genreIds: gIds,
      runtime: runtime,
    );
  }

  /// Logika penentuan label kategori akurat berdasarkan TMDB metadata
  static String getCategoryLabel({
    String? mediaType,
    String? originalLanguage,
    List<int>? genreIds,
    List<String>? genres,
    Drama? drama,
  }) {
    final String type = (mediaType ??
            drama?.mediaType ??
            (drama?.episodes == 1 ? 'movie' : 'tv'))
        .trim()
        .toLowerCase();
    final String lang = (originalLanguage ?? drama?.originalLanguage ?? '')
        .trim()
        .toLowerCase();
    final List<int> gIds = genreIds ?? drama?.genreIds ?? <int>[];

    final bool hasAnim = gIds.contains(16) ||
        (genres?.any((g) =>
                g.toLowerCase().contains('anime') ||
                g.toLowerCase().contains('anim')) ??
            false) ||
        (drama?.genre.toLowerCase().contains('anime') ?? false) ||
        (drama?.genre.toLowerCase().contains('anim') ?? false) ||
        (drama?.genresList.any((g) =>
                g.toLowerCase().contains('anime') ||
                g.toLowerCase().contains('anim')) ??
            false);

    // 1. Jika genre_ids mengandung 16 dan original_language == 'ja' -> Anime
    if (hasAnim &&
        (lang == 'ja' ||
            lang == 'jp' ||
            (drama?.genre.toLowerCase().contains('jepang') ?? false))) {
      return 'Anime';
    }

    // 2. Jika genre_ids mengandung 16 (selain Jepang) -> Animasi
    if (hasAnim) {
      return 'Animasi';
    }

    // 3. Jika media_type == 'tv' (atau serial TV):
    if (type == 'tv') {
      if (lang == 'ko' ||
          lang == 'kr' ||
          (drama?.genre.toLowerCase().contains('korea') ?? false)) {
        return 'Drama Korea';
      } else if (lang == 'zh' ||
          lang == 'cn' ||
          (drama?.genre.toLowerCase().contains('china') ?? false) ||
          (drama?.genre.toLowerCase().contains('mandarin') ?? false)) {
        return 'Drama China';
      } else if (lang == 'ja' ||
          lang == 'jp' ||
          (drama?.genre.toLowerCase().contains('jepang') ?? false)) {
        return 'Drama Jepang';
      } else if (lang == 'en' ||
          lang == 'us' ||
          (drama?.genre.toLowerCase().contains('barat') ?? false) ||
          (drama?.genre.toLowerCase().contains('western') ?? false)) {
        return 'Drama Barat';
      } else {
        return 'Serial TV';
      }
    }

    // 4. Jika media_type == 'movie' (atau film):
    if (lang == 'ko' ||
        lang == 'kr' ||
        (drama?.genre.toLowerCase().contains('korea') ?? false)) {
      return 'Film Korea';
    } else if (lang == 'id' ||
        (drama?.genre.toLowerCase().contains('indonesia') ?? false)) {
      return 'Film Indonesia';
    } else if (lang == 'ja' ||
        lang == 'jp' ||
        (drama?.genre.toLowerCase().contains('jepang') ?? false)) {
      return 'Film Jepang';
    } else if (lang == 'en' ||
        lang == 'us' ||
        (drama?.genre.toLowerCase().contains('barat') ?? false) ||
        (drama?.genre.toLowerCase().contains('western') ?? false)) {
      return 'Film Barat';
    } else {
      return 'Film';
    }
  }

  factory Drama.fromTmdbMovieJson(Map<String, dynamic> json) =>
      Drama.fromTmdbJson(json);

  factory Drama.fromJson(Map<String, dynamic> json) => Drama.fromTmdbJson(json);

  /// Factory constructor untuk memetakan row data dari tabel Supabase ('watchlists')
  factory Drama.fromSupabase(Map<String, dynamic> map) {
    int dramaId = 0;
    final rawId = map['tmdb_id'] ?? map['drama_id'] ?? map['id'];
    if (rawId is num) {
      dramaId = rawId.toInt();
    } else if (rawId != null) {
      dramaId = int.tryParse(rawId.toString()) ?? 0;
    }

    final String title = map['judul_film'] as String? ??
        map['title'] as String? ??
        'Untitled';
    final String koreanTitle = map['korean_title'] as String? ?? title;
    final String genre = map['genre'] as String? ?? 'General';
    final double? rawRating = (map['rating'] as num?)?.toDouble() ??
        (map['user_rating'] as num?)?.toDouble() ??
        (map['my_rating'] as num?)?.toDouble();
    final double userRating = rawRating ?? 0.0;
    final double rating = userRating;
    final int episodes = (map['episodes'] as num?)?.toInt() ?? 0;
    final int watchedEpisodes = (map['watched_episodes'] as num?)?.toInt() ?? 0;
    final String status = map['status'] as String? ?? 'Sedang Menonton';
    final String priority = map['priority'] as String? ?? 'Sedang';
    final String startDate = map['start_date'] as String? ?? '';
    final String endDate = map['end_date'] as String? ?? '';
    final String date = map['date'] as String? ?? '';
    final String image = map['image'] as String? ?? '';
    final String backdrop = map['backdrop'] as String? ?? image;
    final String rank = map['rank'] as String? ?? '#1';
    final String popularity = map['popularity'] as String? ?? '100';
    final String watchers = map['watchers'] as String? ?? '10K';
    final String synopsis = map['synopsis'] as String? ?? '';
    final String aired = map['aired'] as String? ?? '';
    final String duration = map['duration'] as String? ?? '60 menit';
    final String contentRating = map['content_rating'] as String? ?? '13+';
    final String mediaType = map['media_type'] as String? ??
        (genre.toLowerCase().contains('film') || episodes == 1 ? 'movie' : 'tv');
    final String originalLanguage = map['original_language'] as String? ??
        (map['originalLanguage'] as String? ?? '');

    DateTime? dateCompleted;
    if (map['date_completed'] != null) {
      dateCompleted = DateTime.tryParse(map['date_completed'].toString());
    }

    List<String> genresList = [];
    if (map['genres_list'] is List) {
      genresList = (map['genres_list'] as List).map((e) => e.toString()).toList();
    } else {
      genresList = [genre];
    }

    List<String> tagsList = [];
    if (map['tags_list'] is List) {
      tagsList = (map['tags_list'] as List).map((e) => e.toString()).toList();
    } else {
      tagsList = ['Watchlist'];
    }

    final int? runtime = (map['runtime'] as num?)?.toInt();
    List<int> genreIds = [];
    if (map['genre_ids'] is List) {
      genreIds = (map['genre_ids'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }

    return Drama(
      id: dramaId,
      mediaType: mediaType,
      backdrop: backdrop,
      title: title,
      koreanTitle: koreanTitle,
      genre: genre,
      rating: rating,
      userRating: userRating,
      myRating: userRating,
      episodes: episodes,
      watchedEpisodes: watchedEpisodes,
      status: status,
      priority: priority,
      startDate: startDate,
      endDate: endDate,
      date: date,
      image: image,
      rank: rank,
      popularity: popularity,
      watchers: watchers,
      synopsis: synopsis,
      aired: aired,
      duration: duration,
      contentRating: contentRating,
      genresList: genresList,
      tagsList: tagsList,
      dateCompleted: dateCompleted,
      originalLanguage: originalLanguage,
      genreIds: genreIds,
      runtime: runtime,
    );
  }

  /// Mengonversi objek Drama ke Map JSON payload untuk Supabase
  Map<String, dynamic> toSupabaseJson({String? userId}) {
    return {
      if (userId != null && userId.isNotEmpty) 'user_id': userId,
      'tmdb_id': id,
      'judul_film': title,
      'title': title,
      'media_type': mediaType,
      'original_language': originalLanguage,
      'episodes': episodes,
      'status': status,
      'rating': userRating ?? myRating ?? 0.0,
      if (dateCompleted != null)
        'date_completed': dateCompleted!.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Drama(title: $_title, progress: $_watchedEpisodes/$_episodes, status: $_status, rating: $_rating)';
  }
}

typedef Movie = Drama;
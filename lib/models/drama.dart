class Drama {
  // ==========================================
  // ATRIBUT / PROPERTI PRIVAT (ENKAPSULASI PBO)
  // ==========================================
  // Seluruh atribut dibungkus secara privat dengan awalan underscore (_)
  // untuk menjamin data integrity dan mencegah manipulasi langsung dari luar kelas.
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

  // ==========================================
  // CONSTRUCTOR (BLUEPRINT PEMBANGUN OBJEK)
  // ==========================================
  /// Constructor dengan named parameter dan validasi nilai inisialisasi awal.
  Drama({
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
  })  : _title = title.trim().isEmpty ? 'Untitled' : title.trim(),
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
        _tagsList = List<String>.from(tagsList);

  // ==========================================
  // GETTER & SETTER (PBO: ENKAPSULASI & VALIDASI)
  // ==========================================

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
    } else {
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
  }) {
    return Drama(
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
    );
  }

  @override
  String toString() {
    return 'Drama(title: $_title, progress: $_watchedEpisodes/$_episodes, status: $_status, rating: $_rating)';
  }
}
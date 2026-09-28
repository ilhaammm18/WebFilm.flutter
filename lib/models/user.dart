class User {
  // ==========================================
  // ATRIBUT BLUEPRINT OBJEK USER
  // ==========================================
  // Properti privat (Menerapkan Enkapsulasi PBO)
  String _username;
  String _fullName;
  String _email;
  String _avatarUrl;
  final DateTime _joinedDate;
  int _totalDramasCompleted;
  int _totalEpisodesWatched;

  // ==========================================
  // CONSTRUCTOR (Blueprint Pembangun Objek)
  // ==========================================
  User({
    required String username,
    required String fullName,
    required String email,
    String avatarUrl = '',
    DateTime? joinedDate,
    int totalDramasCompleted = 0,
    int totalEpisodesWatched = 0,
  })  : _username = username.trim(),
        _fullName = fullName.trim(),
        _email = email.trim(),
        _avatarUrl = avatarUrl.trim(),
        _joinedDate = joinedDate ?? DateTime.now(),
        _totalDramasCompleted = totalDramasCompleted < 0 ? 0 : totalDramasCompleted,
        _totalEpisodesWatched = totalEpisodesWatched < 0 ? 0 : totalEpisodesWatched;

  // ==========================================
  // GETTER & SETTER (Enkapsulasi & Validasi Data)
  // ==========================================

  /// Getter untuk username
  String get username => _username;

  /// Setter untuk username dengan validasi tidak boleh kosong
  set username(String value) {
    if (value.trim().isNotEmpty) {
      _username = value.trim();
    }
  }

  /// Getter untuk fullName
  String get fullName => _fullName;

  /// Setter untuk fullName dengan validasi
  set fullName(String value) {
    if (value.trim().isNotEmpty) {
      _fullName = value.trim();
    }
  }

  /// Getter untuk email
  String get email => _email;

  /// Setter untuk email dengan validasi format dasar
  set email(String value) {
    if (value.contains('@')) {
      _email = value.trim();
    }
  }

  /// Getter untuk avatarUrl
  String get avatarUrl => _avatarUrl;

  /// Setter untuk avatarUrl
  set avatarUrl(String value) {
    _avatarUrl = value.trim();
  }

  /// Getter untuk joinedDate (Read-only property)
  DateTime get joinedDate => _joinedDate;

  /// Getter untuk total drama yang diselesaikan
  int get totalDramasCompleted => _totalDramasCompleted;

  /// Setter untuk total drama yang diselesaikan dengan validasi non-negatif
  set totalDramasCompleted(int value) {
    _totalDramasCompleted = value < 0 ? 0 : value;
  }

  /// Getter untuk total episode yang ditonton
  int get totalEpisodesWatched => _totalEpisodesWatched;

  /// Setter untuk total episode dengan validasi non-negatif
  set totalEpisodesWatched(int value) {
    _totalEpisodesWatched = value < 0 ? 0 : value;
  }

  // ==========================================
  // COMPUTED GETTERS (Properti Terhitung PBO)
  // ==========================================

  /// Nama tampilan prioritas: jika fullName kosong, tampilkan username
  String get displayName => _fullName.isNotEmpty ? _fullName : _username;

  /// Format tanggal bergabung dd/mm/yyyy
  String get formattedJoinDate =>
      '${_joinedDate.day.toString().padLeft(2, '0')}/${_joinedDate.month.toString().padLeft(2, '0')}/${_joinedDate.year}';

  // ==========================================
  // FUNCTION / METHOD PBO (Behavior / Perilaku Objek)
  // ==========================================

  /// Menambahkan progres tontonan ke profil pengguna
  void recordWatchProgress({int episodes = 1, bool isCompleted = false}) {
    if (episodes > 0) {
      _totalEpisodesWatched += episodes;
    }
    if (isCompleted) {
      _totalDramasCompleted++;
    }
  }

  /// Mereset statistik tontonan pengguna
  void resetStats() {
    _totalDramasCompleted = 0;
    _totalEpisodesWatched = 0;
  }

  /// Menghitung rata-rata episode per drama yang diselesaikan
  double hitungRataRataEpisodePerDrama() {
    if (_totalDramasCompleted <= 0) return 0.0;
    return _totalEpisodesWatched / _totalDramasCompleted;
  }

  /// Memperbarui profil pengguna sekaligus (nama, email, avatar) dengan validasi
  void updateProfile({String? fullName, String? email, String? avatarUrl}) {
    if (fullName != null && fullName.trim().isNotEmpty) {
      this.fullName = fullName;
    }
    if (email != null && email.contains('@')) {
      this.email = email;
    }
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      this.avatarUrl = avatarUrl;
    }
  }

  @override
  String toString() {
    return 'User(username: $_username, email: $_email, completed: $_totalDramasCompleted, watchedEps: $_totalEpisodesWatched)';
  }
}

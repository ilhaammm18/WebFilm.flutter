import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../routes/app_router.dart';
import '../models/drama.dart';
import '../data/shared_data.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';

class UserProfileDetailPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? initialProfile;
  final ApiService? apiService;
  final SupabaseClient? supabaseClient;

  const UserProfileDetailPage({
    super.key,
    required this.userId,
    this.initialProfile,
    this.apiService,
    this.supabaseClient,
  });

  @visibleForTesting
  static void clearCaches() {
    _UserProfileDetailPageState.clearCaches();
  }

  @override
  State<UserProfileDetailPage> createState() => _UserProfileDetailPageState();
}

class _UserProfileDetailPageState extends State<UserProfileDetailPage> {
  late final ApiService _apiService;
  bool _isLoading = true;
  String _fullName = '';
  String _username = '';
  String _bio = '';
  String _avatarUrl = '';

  int _followersCount = 0;
  int _followingCount = 0;
  bool _isFollowing = false;
  bool _isTogglingFollow = false;

  List<Drama> _watchlist = [];
  String _selectedStatusFilter = 'Semua';

  // Statistik Waktu Tonton (Seragam dengan Halaman Profil Utama)
  int _jumlahFilm = 0;
  int _totalFilmMinutes = 0;

  int _jumlahDrama = 0;
  int _totalEpisodeDrama = 0;
  int _totalDramaMinutes = 0;

  int _jumlahAnimasi = 0;
  int _totalEpisodeAnimasi = 0;
  int _totalAnimMinutes = 0;

  // Cache detail TMDB agar pemuatan poster & metadata instan dan hemat request
  static final Map<int, Drama> _tmdbDetailCache = {};
  static final Set<int> _pendingTmdbFetches = {};

  @visibleForTesting
  static void clearCaches() {
    _tmdbDetailCache.clear();
    _pendingTmdbFetches.clear();
  }

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _initInitialData();
    _fetchUserData();
  }

  void _initInitialData() {
    if (widget.initialProfile != null) {
      final p = widget.initialProfile!;
      _fullName = (p['full_name'] ?? p['username'] ?? '').toString();
      _username = (p['username'] ?? '').toString();
      _bio = (p['bio'] ?? '').toString();
      _avatarUrl = SharedData.sanitizeAvatarUrl(
        p['avatar_url'] as String?,
        fallback: '',
      );
    }
  }

  SupabaseClient? get _supabaseClient {
    if (widget.supabaseClient != null) return widget.supabaseClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchUserData() async {
    final client = _supabaseClient;
    if (client == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUserId = client.auth.currentUser?.id;

      // 1. Ambil data profil dari tabel profiles
      try {
        final profile = await client
            .from('profiles')
            .select()
            .eq('id', widget.userId)
            .maybeSingle();

        if (profile != null) {
          _fullName = (profile['full_name'] ?? _fullName).toString();
          _username = (profile['username'] ?? _username).toString();
          _bio = (profile['bio'] ?? _bio).toString();
          final rawAvatar = profile['avatar_url'] as String?;
          if (rawAvatar != null && rawAvatar.trim().isNotEmpty) {
            _avatarUrl = SharedData.sanitizeAvatarUrl(
              rawAvatar,
              fallback: _avatarUrl,
            );
          }
        }
      } catch (_) {}

      // 2. Ambil data Pengikut & Mengikuti
      try {
        final followersRes = await client
            .from('follows')
            .select('follower_id')
            .eq('following_id', widget.userId);
        _followersCount = (followersRes as List).length;

        final followingRes = await client
            .from('follows')
            .select('following_id')
            .eq('follower_id', widget.userId);
        _followingCount = (followingRes as List).length;

        // Cek apakah current user mengikuti user ini
        if (currentUserId != null && currentUserId != widget.userId) {
          final isFollowRes = await client
              .from('follows')
              .select('id')
              .eq('follower_id', currentUserId)
              .eq('following_id', widget.userId)
              .maybeSingle();
          _isFollowing = isFollowRes != null;
        }
      } catch (_) {}

      // 3. Ambil watchlist user target
      try {
        final watchlistRes = await client
            .from('watchlists')
            .select()
            .eq('user_id', widget.userId);

        final items = (watchlistRes as List)
            .map((item) => Drama.fromSupabase(item as Map<String, dynamic>))
            .toList();

        // Pulihkan dari cache lokal atau SharedData jika sudah pernah dimuat
        for (final drama in items) {
          _restoreFromLocalCache(drama);
        }

        _watchlist = items;
        _calculateWatchStatistics(items);

        // Enrich metadata & poster asli dari TMDB API
        _enrichWatchlistWithTmdb(items);
      } catch (_) {}
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _restoreFromLocalCache(Drama drama) {
    if (drama.id <= 0) return;

    // 1. Cek cache TMDB di halaman ini
    final cached = _tmdbDetailCache[drama.id];
    if (cached != null) {
      _applyTmdbDetail(drama, cached);
      return;
    }

    // 2. Cek apakah item dengan ID yang sama sudah ter-enrich di SharedData
    for (final sharedItem in SharedData.dramaListNotifier.value) {
      if (sharedItem.id == drama.id && sharedItem.image.isNotEmpty) {
        _applyTmdbDetail(drama, sharedItem);
        break;
      }
    }
  }

  void _applyTmdbDetail(Drama target, Drama detail) {
    if (detail.image.isNotEmpty) {
      target.image = detail.image;
    }
    if (detail.backdrop.isNotEmpty && target.backdrop.isEmpty) {
      target.backdrop = detail.backdrop;
    }
    if (detail.mediaType.isNotEmpty) {
      target.mediaType = detail.mediaType;
    }
    if (detail.originalLanguage.isNotEmpty && target.originalLanguage.isEmpty) {
      target.originalLanguage = detail.originalLanguage;
    }
    if (detail.genreIds.isNotEmpty && target.genreIds.isEmpty) {
      target.genreIds = detail.genreIds;
    }
    if (detail.genresList.isNotEmpty) {
      target.genresList = detail.genresList;
    }

    // Perbarui genre agar tidak lagi 'General'
    String detectedGenre = detail.genre;
    if (detectedGenre.isEmpty || detectedGenre == 'General') {
      if (detail.genresList.isNotEmpty &&
          detail.genresList.first.isNotEmpty &&
          detail.genresList.first != 'General') {
        detectedGenre = detail.genresList.first;
      } else {
        detectedGenre = getDynamicLabel(drama: detail);
      }
    }
    if (detectedGenre.isNotEmpty && detectedGenre != 'General') {
      target.genre = detectedGenre;
    }

    if (detail.date.isNotEmpty && target.date.isEmpty) {
      target.date = detail.date;
    }
    if (detail.aired.isNotEmpty && target.aired.isEmpty) {
      target.aired = detail.aired;
    }
    if (detail.episodes > 0 && target.episodes == 0) {
      target.episodes = detail.episodes;
    }
    if (detail.runtime != null &&
        detail.runtime! > 0 &&
        (target.runtime == null || target.runtime! <= 0)) {
      target.runtime = detail.runtime;
    }
    if (detail.duration.isNotEmpty &&
        (target.duration.isEmpty || target.duration == '60 menit')) {
      target.duration = detail.duration;
    }
    if (target.rating <= 0 && detail.rating > 0) {
      target.rating = detail.rating;
    }
  }

  Future<void> _enrichWatchlistWithTmdb(List<Drama> list) async {
    final itemsToEnrich = list.where((d) {
      final needsPoster = d.image.isEmpty;
      final needsGenre = d.genre.isEmpty || d.genre == 'General';
      final needsDate = d.date.isEmpty && d.aired.isEmpty;
      final needsEpisodes = !_isMovie(d) && d.episodes == 0;
      return (needsPoster || needsGenre || needsDate || needsEpisodes) &&
          (d.id > 0 ? !_pendingTmdbFetches.contains(d.id) : d.title.isNotEmpty);
    }).toList();

    if (itemsToEnrich.isEmpty) return;

    for (final item in itemsToEnrich) {
      if (item.id > 0) {
        _pendingTmdbFetches.add(item.id);
      }
    }

    bool updated = false;
    await Future.wait(
      itemsToEnrich.map((drama) async {
        try {
          Drama? detail;
          if (drama.id > 0) {
            detail = await _apiService.getMovieDetails(
              drama.id,
              mediaType: drama.mediaType.isNotEmpty ? drama.mediaType : null,
            );
            _tmdbDetailCache[drama.id] = detail;
          } else if (drama.title.isNotEmpty) {
            // Fallback pencarian berdasarkan judul jika tmdb_id tidak tersimpan
            final isTv = drama.mediaType == 'tv' || drama.episodes > 1;
            final results = isTv
                ? await _apiService.searchTvShows(drama.title)
                : await _apiService.searchMovies(drama.title);
            if (results.isNotEmpty) {
              detail = results.first;
              if (detail.id > 0) {
                drama.id = detail.id;
                _tmdbDetailCache[detail.id] = detail;
              }
            }
          }

          if (detail != null) {
            _applyTmdbDetail(drama, detail);
            updated = true;
          }
        } catch (e) {
          debugPrint('Error enrich TMDB user profile drama ${drama.id}: $e');
        } finally {
          if (drama.id > 0) {
            _pendingTmdbFetches.remove(drama.id);
          }
        }
      }),
    );

    if (updated && mounted) {
      _calculateWatchStatistics(_watchlist);
      setState(() {});
    }
  }

  /// Perhitungan statistik waktu tonton yang identik dengan halaman Profil utama (`ProfileTab`)
  void _calculateWatchStatistics(List<Drama> items) {
    int jumlahFilm = 0;
    int totalFilmMinutes = 0;

    int jumlahDrama = 0;
    int totalEpisodeDrama = 0;
    int totalDramaMinutes = 0;

    int jumlahAnimasi = 0;
    int totalEpisodeAnimasi = 0;
    int totalAnimMinutes = 0;

    for (final d in items) {
      // Hanya hitung item yang statusnya sudah ditonton: 'Selesai' atau 'Sedang Menonton'
      final status = d.status.trim();
      if (status != 'Selesai' && status != 'Sedang Menonton') {
        continue;
      }

      if (_isAnimation(d)) {
        // Kartu ANIMASI: status 'Sedang Menonton' atau 'Selesai'
        jumlahAnimasi++;
        int eps = d.watchedEpisodes;
        if (eps == 0 && status == 'Selesai') {
          eps = d.episodes > 0 ? d.episodes : 1;
        }
        if (_isMovie(d) && eps == 0) {
          eps = 1;
        }
        totalEpisodeAnimasi += eps;
        final epDur = _getEpisodeDuration(d, 24);
        totalAnimMinutes += eps * epDur;
      } else if (_isMovie(d)) {
        // Kartu FILM: Item bertipe movie (non-animasi) yang berstatus 'Selesai'
        if (status == 'Selesai') {
          jumlahFilm++;
          final movieDur = _getEpisodeDuration(d, 120);
          totalFilmMinutes += movieDur;
        }
      } else {
        // Kartu DRAMA: Item bertipe tv (non-animasi) yang berstatus 'Sedang Menonton' atau 'Selesai'
        jumlahDrama++;
        int eps = d.watchedEpisodes;
        if (eps == 0 && status == 'Selesai') {
          eps = d.episodes > 0 ? d.episodes : 1;
        }
        totalEpisodeDrama += eps;
        final epDur = _getEpisodeDuration(d, 50);
        totalDramaMinutes += eps * epDur;
      }
    }

    _jumlahFilm = jumlahFilm;
    _totalFilmMinutes = totalFilmMinutes;
    _jumlahDrama = jumlahDrama;
    _totalEpisodeDrama = totalEpisodeDrama;
    _totalDramaMinutes = totalDramaMinutes;
    _jumlahAnimasi = jumlahAnimasi;
    _totalEpisodeAnimasi = totalEpisodeAnimasi;
    _totalAnimMinutes = totalAnimMinutes;
  }

  // Helper identifikasi kategori & durasi tontonan (konsisten dengan ProfileTab)
  bool _isAnimation(Drama d) {
    if (d.genreIds.contains(16)) return true;
    final g = d.genre.toLowerCase();
    if (g.contains('anim') || g.contains('anime')) return true;
    for (final item in d.genresList) {
      final s = item.toLowerCase();
      if (s.contains('anim') || s.contains('anime')) return true;
    }
    for (final item in d.tagsList) {
      final s = item.toLowerCase();
      if (s.contains('anim') || s.contains('anime')) return true;
    }
    return false;
  }

  bool _isMovie(Drama d) {
    if (d.mediaType == 'movie' || d.isMovie) return true;
    final g = d.genre.toLowerCase();
    if (g.contains('film') || g.contains('movie')) return true;
    return d.episodes == 1;
  }

  int _getEpisodeDuration(Drama d, int defaultMinutes) {
    if (d.runtime != null && d.runtime! > 0) {
      return d.runtime!;
    }
    final durStr = d.duration.toLowerCase().trim();
    if (durStr.isNotEmpty) {
      final regexHM = RegExp(r'(\d+)\s*(?:j|h)\s*(?:(\d+)\s*m)?');
      final matchHM = regexHM.firstMatch(durStr);
      if (matchHM != null) {
        final h = int.tryParse(matchHM.group(1) ?? '0') ?? 0;
        final m = int.tryParse(matchHM.group(2) ?? '0') ?? 0;
        final total = h * 60 + m;
        if (total > 0) return total;
      }
      final regexM = RegExp(r'(\d+)\s*(?:menit|m)?');
      final matchM = regexM.firstMatch(durStr);
      if (matchM != null) {
        final val = int.tryParse(matchM.group(1) ?? '');
        if (val != null && val > 0) return val;
      }
    }
    return defaultMinutes;
  }

  String _formatDuration(int totalMinutes) {
    if (totalMinutes <= 0) return '0h 0m';

    final int days = totalMinutes ~/ (60 * 24);
    final int remainingMinutes = totalMinutes % (60 * 24);
    final int hours = remainingMinutes ~/ 60;
    final int mins = remainingMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${mins}m';
    } else {
      return '${hours}h ${mins}m';
    }
  }

  /// Menyusun teks metadata konkret untuk item Daftar Tontonan (tanpa fallback 'General • N/A')
  String _buildItemMetadataText(Drama drama) {
    final String categoryLabel = getDynamicLabel(drama: drama);

    // Cari genre spesifik yang valid (bukan 'General', 'Film', 'Serial TV', atau 'N/A')
    String specificGenre = '';
    final List<String> candidates = [
      drama.genre,
      ...drama.genresList,
    ];
    for (final g in candidates) {
      final clean = g.trim();
      final lower = clean.toLowerCase();
      if (clean.isNotEmpty &&
          lower != 'general' &&
          lower != 'n/a' &&
          lower != 'film' &&
          lower != 'serial tv' &&
          lower != categoryLabel.toLowerCase()) {
        specificGenre = clean;
        break;
      }
    }

    // Ekstrak tahun rilis 4 digit dari date, aired, atau judul
    String releaseYear = '';
    final yearRegex = RegExp(r'\b(19\d{2}|20\d{2})\b');
    final rawDate = drama.date.isNotEmpty ? drama.date : drama.aired;
    final dateMatch = yearRegex.firstMatch(rawDate);
    if (dateMatch != null) {
      releaseYear = dateMatch.group(1) ?? '';
    } else {
      final titleMatch = yearRegex.firstMatch(drama.title);
      if (titleMatch != null) {
        releaseYear = titleMatch.group(1) ?? '';
      }
    }

    final List<String> parts = [];
    if (categoryLabel.isNotEmpty && categoryLabel.toLowerCase() != 'general') {
      parts.add(categoryLabel);
    }
    if (specificGenre.isNotEmpty &&
        !parts.any((p) => p.toLowerCase() == specificGenre.toLowerCase())) {
      // Jika kategori masih umum ('Film' / 'Serial TV'), utamakan genre spesifik atau gabungkan
      if (parts.isEmpty ||
          parts.first == 'Film' ||
          parts.first == 'Serial TV') {
        parts.add(specificGenre);
      } else if (releaseYear.isEmpty) {
        parts.add(specificGenre);
      }
    }
    if (releaseYear.isNotEmpty) {
      parts.add(releaseYear);
    } else if (parts.length == 1) {
      // Informasi konkret pendamping jika tahun rilis belum tersedia
      if (!_isMovie(drama) && drama.episodes > 0) {
        parts.add('${drama.episodes} Episode');
      } else if (_isMovie(drama) &&
          drama.duration.isNotEmpty &&
          drama.duration != '60 menit') {
        parts.add(drama.duration);
      }
    }

    if (parts.isEmpty) {
      return _isMovie(drama) ? 'Film' : 'Serial TV';
    }
    return parts.join(' \u2022 ');
  }

  Future<void> _toggleFollow() async {
    final client = _supabaseClient;
    final currentUserId = client?.auth.currentUser?.id;

    if (client == null || currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu untuk mengikuti teman.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (currentUserId == widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak dapat mengikuti akun Anda sendiri.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isTogglingFollow = true);

    try {
      if (_isFollowing) {
        await client
            .from('follows')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('following_id', widget.userId);

        setState(() {
          _isFollowing = false;
          _followersCount = (_followersCount - 1).clamp(0, 999999);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Berhenti mengikuti @$_username'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        await client.from('follows').insert({
          'follower_id': currentUserId,
          'following_id': widget.userId,
        });

        setState(() {
          _isFollowing = true;
          _followersCount++;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Berhasil mengikuti @$_username!'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui status ikuti: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingFollow = false);
      }
    }
  }

  Widget _buildAvatarWidget(String? url, {double radius = 42}) {
    final sanitizedUrl = SharedData.sanitizeAvatarUrl(url, fallback: '');
    final isNetwork = sanitizedUrl.startsWith('http://') ||
        sanitizedUrl.startsWith('https://');
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: isNetwork
            ? Image.network(
                sanitizedUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF0094FF).withValues(alpha: 0.15),
                  child: Icon(
                    Icons.person,
                    color: const Color(0xFF0094FF),
                    size: radius,
                  ),
                ),
              )
            : Image.asset(
                sanitizedUrl.isNotEmpty ? sanitizedUrl : 'assets/profile.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF0094FF).withValues(alpha: 0.15),
                  child: Icon(
                    Icons.person,
                    color: const Color(0xFF0094FF),
                    size: radius,
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF15171E) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF1F222B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade600;
    final borderColor = isDark ? const Color(0xFF2A2E3D) : Colors.grey.shade200;
    const primaryBlue = Color(0xFF0094FF);

    final currentUserId = _supabaseClient?.auth.currentUser?.id;
    final isOwnProfile = currentUserId == widget.userId;

    final filteredWatchlist = _watchlist.where((d) {
      if (_selectedStatusFilter == 'Semua') return true;
      return d.status.toLowerCase() == _selectedStatusFilter.toLowerCase();
    }).toList();

    final int totalAllMinutes =
        _totalDramaMinutes + _totalFilmMinutes + _totalAnimMinutes;
    final int totalTontonan = _jumlahDrama + _jumlahFilm + _jumlahAnimasi;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          _username.isNotEmpty ? '@$_username' : 'Profil Teman',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: cardBg,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
              onRefresh: _fetchUserData,
              color: primaryBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    // 1. HEADER PROFIL
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0094FF), Color(0xFF00D2FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: _buildAvatarWidget(_avatarUrl, radius: 46),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _fullName.isNotEmpty
                                ? _fullName
                                : 'Pengguna MyWatchList',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${_username.isNotEmpty ? _username : 'user'}',
                            style: const TextStyle(
                              color: primaryBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Tombol Ikuti / Mengikuti (Jika bukan profil sendiri)
                          if (!isOwnProfile)
                            SizedBox(
                              width: 160,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isTogglingFollow ? null : _toggleFollow,
                                icon: _isTogglingFollow
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        _isFollowing
                                            ? Icons.check_rounded
                                            : Icons.person_add_rounded,
                                        size: 16,
                                      ),
                                label: Text(
                                  _isFollowing ? 'Mengikuti' : 'Ikuti',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isFollowing
                                      ? (isDark
                                          ? const Color(0xFF2E3344)
                                          : Colors.grey.shade300)
                                      : primaryBlue,
                                  foregroundColor: _isFollowing
                                      ? (isDark
                                          ? Colors.white70
                                          : Colors.black87)
                                      : Colors.white,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 2. STATISTIK PENGIKUT & MENGIKUTI
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.03,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildFollowStatItem(
                              _followersCount.toString(),
                              'Pengikut',
                              textColor,
                              subTextColor,
                            ),
                          ),
                          Container(
                            height: 28,
                            width: 1,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey.shade300,
                          ),
                          Expanded(
                            child: _buildFollowStatItem(
                              _followingCount.toString(),
                              'Mengikuti',
                              textColor,
                              subTextColor,
                            ),
                          ),
                          Container(
                            height: 28,
                            width: 1,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey.shade300,
                          ),
                          Expanded(
                            child: _buildFollowStatItem(
                              _watchlist.length.toString(),
                              'Tontonan',
                              textColor,
                              subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 3. TENTANG SAYA / BIO
                    if (_bio.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.2 : 0.03,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          primaryBlue.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.info_outline_rounded,
                                      color: primaryBlue,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Tentang Saya',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _bio,
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFC7CBD8)
                                      : const Color(0xFF4A4E5A),
                                  fontSize: 13.5,
                                  height: 1.55,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 4. KARTU STATISTIK WAKTU TONTON (SUSUNAN 2x2 SERAGAM DENGAN PROFIL UTAMA)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // BARIS 1: DRAMA & FILM
                          Row(
                            children: [
                              // KOTAK DRAMA
                              Expanded(
                                child: _buildStatCard(
                                  title: 'DRAMA',
                                  accentColor: isDark
                                      ? const Color(0xFF70B6FF)
                                      : primaryBlue,
                                  icon: Icons.tv_rounded,
                                  durationText:
                                      _formatDuration(_totalDramaMinutes),
                                  subInfo:
                                      '$_totalEpisodeDrama episode, $_jumlahDrama drama',
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  isDark: isDark,
                                  textColor: textColor,
                                  subTextColor: subTextColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // KOTAK FILM
                              Expanded(
                                child: _buildStatCard(
                                  title: 'FILM',
                                  accentColor: isDark
                                      ? const Color(0xFFB57AFF)
                                      : const Color(0xFF7A33E2),
                                  icon: Icons.movie_creation_outlined,
                                  durationText:
                                      _formatDuration(_totalFilmMinutes),
                                  subInfo: '$_jumlahFilm film',
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  isDark: isDark,
                                  textColor: textColor,
                                  subTextColor: subTextColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // BARIS 2: ANIMASI & TOTAL KESELURUHAN
                          Row(
                            children: [
                              // KOTAK ANIMASI
                              Expanded(
                                child: _buildStatCard(
                                  title: 'ANIMASI',
                                  accentColor: isDark
                                      ? const Color(0xFFFF9E58)
                                      : const Color(0xFFE65100),
                                  icon: Icons.animation,
                                  durationText:
                                      _formatDuration(_totalAnimMinutes),
                                  subInfo:
                                      '$_totalEpisodeAnimasi episode, $_jumlahAnimasi animasi',
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  isDark: isDark,
                                  textColor: textColor,
                                  subTextColor: subTextColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // KOTAK TOTAL KESELURUHAN
                              Expanded(
                                child: _buildStatCard(
                                  title: 'TOTAL KESELURUHAN',
                                  accentColor: isDark
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF059669),
                                  icon: Icons.stacked_line_chart,
                                  durationText:
                                      _formatDuration(totalAllMinutes),
                                  subInfo: '$totalTontonan tontonan',
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  isDark: isDark,
                                  textColor: textColor,
                                  subTextColor: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 5. DAFTAR TONTONAN PENGGUNA
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daftar Tontonan (${_watchlist.length})',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filter Status Watchlist
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          'Semua',
                          'Selesai',
                          'Sedang Menonton',
                          'Rencana Ditonton',
                        ].map((status) {
                          final isSelected = _selectedStatusFilter == status;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(status),
                              selected: isSelected,
                              selectedColor: primaryBlue,
                              backgroundColor: cardBg,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : subTextColor,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 12,
                              ),
                              side: BorderSide(
                                color: isSelected ? primaryBlue : borderColor,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _selectedStatusFilter = status;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (filteredWatchlist.isEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.movie_creation_outlined,
                                size: 48,
                                color: subTextColor,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Belum ada tontonan di kategori ini',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pengguna belum menambahkan film ke kategori ini.',
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredWatchlist.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final drama = filteredWatchlist[index];
                          return _buildWatchlistItemCard(
                            context: context,
                            drama: drama,
                            isDark: isDark,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            primaryBlue: primaryBlue,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWatchlistItemCard({
    required BuildContext context,
    required Drama drama,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
    required Color primaryBlue,
  }) {
    final String effectivePoster = drama.image.isNotEmpty
        ? drama.image
        : (_tmdbDetailCache[drama.id]?.image ?? '');
    final String metadataText = _buildItemMetadataText(drama);
    final Color statusColor = _getStatusColor(drama.status);
    final bool isTvSeries = !_isMovie(drama) || drama.episodes > 1;
    final double displayRatingVal =
        (drama.userRating != null && drama.userRating! > 0)
            ? drama.userRating!
            : ((drama.myRating != null && drama.myRating! > 0)
                ? drama.myRating!
                : drama.rating);

    String episodeInfoText = '';
    if (isTvSeries) {
      if (drama.status.toLowerCase() == 'sedang menonton') {
        episodeInfoText = drama.episodes > 0
            ? '${drama.watchedEpisodes}/${drama.episodes} Eps'
            : '${drama.watchedEpisodes} Eps';
      } else if (drama.status.toLowerCase() == 'selesai') {
        final totalEps =
            drama.episodes > 0 ? drama.episodes : drama.watchedEpisodes;
        if (totalEps > 0) {
          episodeInfoText = '$totalEps/$totalEps Eps';
        }
      } else if (drama.episodes > 0) {
        episodeInfoText = '${drama.episodes} Eps';
      }
    }

    Widget posterWidget;
    if (effectivePoster.isNotEmpty) {
      posterWidget = Image.network(
        effectivePoster,
        width: 58,
        height: 84,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 58,
          height: 84,
          color: isDark ? const Color(0xFF282C37) : Colors.grey.shade200,
          child: Icon(
            Icons.movie_creation_outlined,
            color: subTextColor,
            size: 24,
          ),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 58,
            height: 84,
            color: isDark ? const Color(0xFF282C37) : Colors.grey.shade200,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primaryBlue,
                ),
              ),
            ),
          );
        },
      );
    } else if (drama.id > 0 && _pendingTmdbFetches.contains(drama.id)) {
      posterWidget = Container(
        width: 58,
        height: 84,
        color: isDark ? const Color(0xFF282C37) : Colors.grey.shade200,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: primaryBlue,
            ),
          ),
        ),
      );
    } else {
      posterWidget = Container(
        width: 58,
        height: 84,
        color: isDark ? const Color(0xFF282C37) : Colors.grey.shade200,
        child: Icon(
          Icons.movie_creation_outlined,
          color: subTextColor,
          size: 24,
        ),
      );
    }

    return InkWell(
      onTap: () {
        context.push(
          '/movie/${drama.id}',
          extra: {
            'drama': drama,
            'apiService': _apiService,
            'posterUrl': effectivePoster,
          },
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Poster Asli TMDB
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: SizedBox(
                width: 58,
                height: 84,
                child: posterWidget,
              ),
            ),
            const SizedBox(width: 12),

            // Informasi Detail Tontonan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    drama.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metadataText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Badge Status (Sedang Menonton, Selesai, Rencana Ditonton)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          drama.status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Rating Badge
                      if (displayRatingVal > 0 ||
                          drama.status.toLowerCase() == 'selesai')
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFB800),
                              size: 15,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              displayRatingVal.toStringAsFixed(1),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                      // Progres Episode (Untuk Drama / Serial TV / Anime)
                      if (episodeInfoText.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tv_rounded,
                              color: subTextColor,
                              size: 13.5,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              episodeInfoText,
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: subTextColor.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return const Color(0xFF10B981);
      case 'sedang menonton':
        return const Color(0xFF0094FF);
      case 'rencana ditonton':
        return const Color(0xFFFFB800);
      default:
        return Colors.grey;
    }
  }

  Widget _buildFollowStatItem(
    String count,
    String label,
    Color textColor,
    Color subTextColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: subTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Kartu Statistik Waktu Tonton yang seragam 100% dengan halaman Profil utama (`ProfileTab`)
  Widget _buildStatCard({
    required String title,
    required Color accentColor,
    required IconData icon,
    required String durationText,
    required String subInfo,
    required Color cardBg,
    required Color borderColor,
    required bool isDark,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                icon,
                size: 16,
                color: accentColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            durationText,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Waktu Tonton',
            style: TextStyle(
              color: subTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262A37) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              subInfo,
              style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

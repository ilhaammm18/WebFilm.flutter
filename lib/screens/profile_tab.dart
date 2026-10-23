import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../routes/app_router.dart';
import '../widgets/app_drawer.dart';
import '../models/drama.dart';
import '../data/shared_data.dart';
import '../services/api_service.dart';
import 'main_navigation.dart';

class ProfileTab extends StatefulWidget {
  final ApiService? apiService;
  const ProfileTab({super.key, this.apiService});

  @visibleForTesting
  static void clearCaches() {
    _ProfileTabState.clearCaches();
  }

  // Halaman Edit Profil
  static void showEditProfileDialog(BuildContext context) {
    context.push('/settings/edit-profile');
  }

  // Halaman Customer Service
  static void showCustomerServiceModal(BuildContext context) {
    context.push('/customer-service');
  }

  // Halaman Pengaturan
  static void showSettingsModal(BuildContext context) {
    context.push('/settings');
  }

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final ApiService _apiService;
  String _fullName = 'Muhammad Nur Ilham';
  String _username = '25051204433';
  String _bio =
      'Selamat Datang di MyWatchList! Halo! Saya Muhammad Nur Ilham. Saat ini saya adalah mahasiswa Teknik Informatika Universitas Negeri Surabaya (Unesa) semester 3. Web ini dibuat untuk memenuhi tugas mata kuliah Pemrograman Berbasis Platform (PBP).';
  String _avatarUrl = 'assets/profile.jpg';
  int _followersCount = 0;
  int _followingCount = 0;

  static final Map<int, String> _posterCache = {};
  static final Map<int, String> _genreCache = {};
  static final Map<int, int> _episodesCache = {};
  static final Set<int> _pendingTmdbFetches = {};
  static final Set<int> _enrichedIds = {};

  @visibleForTesting
  static void clearCaches() {
    _posterCache.clear();
    _genreCache.clear();
    _episodesCache.clear();
    _pendingTmdbFetches.clear();
    _enrichedIds.clear();
  }

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    SharedData.userProfileNotifier.addListener(_syncUserProfile);
    _syncUserProfile();
    SharedData.dramaListNotifier.addListener(_onDramaListChanged);
    _onDramaListChanged();
    _fetchProfileData();
  }

  @override
  void dispose() {
    SharedData.userProfileNotifier.removeListener(_syncUserProfile);
    SharedData.dramaListNotifier.removeListener(_onDramaListChanged);
    super.dispose();
  }

  void _onDramaListChanged() {
    final list = SharedData.dramaListNotifier.value;
    if (list.isNotEmpty) {
      final needsEnrich = list.any((d) =>
          d.id > 0 &&
          (d.image.isEmpty || d.genre == 'General' || d.genre.isEmpty) &&
          !_pendingTmdbFetches.contains(d.id) &&
          !_enrichedIds.contains(d.id));
      if (needsEnrich) {
        _enrichDramasWithTmdb(list);
      }
    }
  }

  Future<void> _enrichDramasWithTmdb(List<Drama> list) async {
    final itemsToEnrich = list
        .where((d) =>
            d.id > 0 &&
            (d.image.isEmpty || d.genre == 'General' || d.genre.isEmpty) &&
            !_pendingTmdbFetches.contains(d.id) &&
            !_enrichedIds.contains(d.id))
        .toList();

    if (itemsToEnrich.isEmpty) return;

    for (final item in itemsToEnrich) {
      _pendingTmdbFetches.add(item.id);
    }

    bool updated = false;
    await Future.wait(
      itemsToEnrich.map((drama) async {
        try {
          final detail = await _apiService.getMovieDetails(
            drama.id,
            mediaType: drama.mediaType.isNotEmpty ? drama.mediaType : null,
          );

          // 1. Gambar poster dari TMDB
          if (detail.image.isNotEmpty) {
            _posterCache[drama.id] = detail.image;
            drama.image = detail.image;
            updated = true;
          }
          if (detail.backdrop.isNotEmpty && drama.backdrop.isEmpty) {
            drama.backdrop = detail.backdrop;
          }

          // 2. Genre asli atau tipe tayangan (Film/Serial TV) dari TMDB
          String detectedGenre = detail.genre;
          if (detectedGenre.isEmpty || detectedGenre == 'General') {
            if (detail.genresList.isNotEmpty &&
                detail.genresList.first != 'General' &&
                detail.genresList.first.isNotEmpty) {
              detectedGenre = detail.genresList.first;
            } else {
              detectedGenre = detail.mediaType == 'tv' ? 'Serial TV' : 'Film';
            }
          }
          _genreCache[drama.id] = detectedGenre;
          drama.genre = detectedGenre;
          updated = true;

          // 3. Metadata pendukung (media type, episode, genreIds, dsb.)
          if (detail.mediaType.isNotEmpty) {
            drama.mediaType = detail.mediaType;
          }
          if (detail.episodes > 0 && drama.episodes == 0) {
            _episodesCache[drama.id] = detail.episodes;
            drama.episodes = detail.episodes;
            updated = true;
          }
          if (detail.originalLanguage.isNotEmpty && drama.originalLanguage.isEmpty) {
            drama.originalLanguage = detail.originalLanguage;
          }
          if (detail.genresList.isNotEmpty) {
            drama.genresList = detail.genresList;
          }
          if (detail.genreIds.isNotEmpty && drama.genreIds.isEmpty) {
            drama.genreIds = detail.genreIds;
          }

          _enrichedIds.add(drama.id);
        } catch (e) {
          debugPrint('Error enrich TMDB drama ${drama.id}: $e');
        } finally {
          _pendingTmdbFetches.remove(drama.id);
        }
      }),
    );

    if (updated && mounted) {
      SharedData.dramaListNotifier.value = List<Drama>.from(list);
      SharedData.dramaListNotifier.notifyListeners();
      setState(() {});
    }
  }

  void _syncUserProfile() {
    final p = SharedData.userProfileNotifier.value;
    if (mounted) {
      setState(() {
        _fullName = p.fullName;
        _username = p.username;
        _bio = p.bio;
        _avatarUrl = p.avatarUrl;
      });
    }
  }

  SupabaseClient? get _supabaseClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchProfileData() async {
    final client = _supabaseClient;
    if (client == null) return;
    try {
      final user = client.auth.currentUser;
      final userId = user?.id;

      // 1. Baca metadata profil pengguna dari Supabase Auth
      if (user != null) {
        final metadata = user.userMetadata ?? {};
        if (metadata['full_name'] != null &&
            (metadata['full_name'] as String).trim().isNotEmpty) {
          _fullName = (metadata['full_name'] as String).trim();
        }
        if (metadata['username'] != null &&
            (metadata['username'] as String).trim().isNotEmpty) {
          _username = (metadata['username'] as String).trim();
        }
        if (metadata['bio'] != null &&
            (metadata['bio'] as String).trim().isNotEmpty) {
          _bio = (metadata['bio'] as String).trim();
        }
        if (metadata['avatar_url'] != null &&
            (metadata['avatar_url'] as String).trim().isNotEmpty) {
          _avatarUrl = (metadata['avatar_url'] as String).trim();
        }
      }

      // 2. Baca dari tabel profiles jika tersedia di database Supabase
      if (userId != null) {
        try {
          final profileData = await client
              .from('profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();
          if (profileData != null) {
            if (profileData['full_name'] != null &&
                (profileData['full_name'] as String).trim().isNotEmpty) {
              _fullName = (profileData['full_name'] as String).trim();
            }
            if (profileData['username'] != null &&
                (profileData['username'] as String).trim().isNotEmpty) {
              _username = (profileData['username'] as String).trim();
            }
            if (profileData['bio'] != null &&
                (profileData['bio'] as String).trim().isNotEmpty) {
              _bio = (profileData['bio'] as String).trim();
            }
            if (profileData['avatar_url'] != null &&
                (profileData['avatar_url'] as String).trim().isNotEmpty) {
              _avatarUrl = (profileData['avatar_url'] as String).trim();
            }
          } else {
            // Auto sinkronkan akun lama ke tabel profiles
            try {
              await client.from('profiles').upsert({
                'id': userId,
                'username': _username.toLowerCase(),
                'full_name': _fullName,
                'bio': _bio,
                'avatar_url': _avatarUrl,
              });
            } catch (_) {}
          }
        } catch (_) {}

        // 3. Fetch Real Pengikut & Mengikuti dari tabel public.follows
        try {
          final followersRes = await client
              .from('follows')
              .select('follower_id')
              .eq('following_id', userId);
          _followersCount = (followersRes as List).length;

          final followingRes = await client
              .from('follows')
              .select('following_id')
              .eq('follower_id', userId);
          _followingCount = (followingRes as List).length;
        } catch (_) {}
      }

      SharedData.userProfileNotifier.value = UserProfileData(
        fullName: _fullName,
        username: _username,
        bio: _bio,
        avatarUrl: _avatarUrl,
      );

      if (mounted) {
        setState(() {});
      }

      // 4. Filter Data Berdasarkan User Login (Watchlist)
      if (userId != null) {
        final List<dynamic> data = await client
            .from('watchlists')
            .select()
            .eq('user_id', userId);

        final List<Drama> list = data
            .map((item) => Drama.fromSupabase(item as Map<String, dynamic>))
            .toList();

        // Pulihkan dari cache lokal jika sudah pernah di-fetch sebelumnya
        for (final drama in list) {
          if (drama.id > 0) {
            if (drama.image.isEmpty && _posterCache.containsKey(drama.id)) {
              drama.image = _posterCache[drama.id]!;
            }
            if ((drama.genre == 'General' || drama.genre.isEmpty) &&
                _genreCache.containsKey(drama.id)) {
              drama.genre = _genreCache[drama.id]!;
            }
            if (drama.episodes == 0 && _episodesCache.containsKey(drama.id)) {
              drama.episodes = _episodesCache[drama.id]!;
            }
          }
        }

        SharedData.dramaListNotifier.value = list;

        // Background fetch TMDB berdasarkan tmdb_id
        _enrichDramasWithTmdb(list);

        // 5. Fetch Riwayat Pembaruan filter by user_id (dinonaktifkan / tidak digunakan lagi di web)
        /*
        await client
            .from('riwayat')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        */
      } else {
        SharedData.dramaListNotifier.value = [];
      }
    } catch (e) {
      debugPrint('Error fetching profile data: $e');
    }
  }

  Widget _buildProfileAvatar() {
    ImageProvider imageProvider;
    if (_avatarUrl.startsWith('http')) {
      imageProvider = NetworkImage(_avatarUrl);
    } else {
      imageProvider = AssetImage(
        _avatarUrl.isNotEmpty ? _avatarUrl : 'assets/profile.jpg',
      );
    }

    return CircleAvatar(
      radius: 48,
      backgroundColor: const Color(0xFF262A36),
      backgroundImage: imageProvider,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor = isDark ? const Color(0xFF15171E) : const Color(0xFFF8F9FA);
    Color cardBg = isDark ? const Color(0xFF1F222B) : Colors.white;
    Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    Color subTextColor = isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade600;
    Color borderColor = isDark ? const Color(0xFF2A2E3D) : Colors.grey.shade200;
    Color primaryBlue = const Color(0xFF0094FF);

    return Scaffold(
      backgroundColor: bgColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textColor),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            color: textColor,
            tooltip: 'Menu Navigasi',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'Profil',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProfileData,
        color: primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // ==========================================
              // 1. HEADER PROFIL
              // ==========================================
            // Foto Profil Melingkar
            _buildProfileAvatar(),
            const SizedBox(height: 14),

            // Nama Lengkap
            Text(
              _fullName,
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            // Username / NIM
            Text(
              _username.startsWith('@')
                  ? _username
                  : (_username.contains(RegExp(r'^[0-9]+$'))
                      ? 'NIM : $_username'
                      : '@$_username'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================
            // 2. STATISTIK PENGIKUT (ROW)
            // ==========================================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        context.push('/friends').then((_) => _fetchProfileData());
                      },
                      child: _buildFollowStatItem(
                        _followersCount.toString(),
                        'Pengikut',
                        textColor,
                        subTextColor,
                      ),
                    ),
                  ),
                  Container(
                    height: 28,
                    width: 1,
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        context.push('/friends').then((_) => _fetchProfileData());
                      },
                      child: _buildFollowStatItem(
                        _followingCount.toString(),
                        'Mengikuti',
                        textColor,
                        subTextColor,
                      ),
                    ),
                  ),
                  Container(
                    height: 28,
                    width: 1,
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                  ),
                  Expanded(
                    child: _buildFollowStatItem('0', 'Suka', textColor, subTextColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==========================================
            // 3. CARD TENTANG SAYA (ABOUT ME)
            // ==========================================
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
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
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
                        color: isDark ? const Color(0xFFC7CBD8) : const Color(0xFF4A4E5A),
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

            // ==========================================
            // 5. CARD STATISTIK WAKTU TONTON (SUSUNAN 2x2)
            // ==========================================
            ValueListenableBuilder<List<Drama>>(
              valueListenable: SharedData.dramaListNotifier,
              builder: (context, dramaList, _) {
                int jumlahFilm = 0;
                int totalFilmMinutes = 0;

                int jumlahDrama = 0;
                int totalEpisodeDrama = 0;
                int totalDramaMinutes = 0;

                int jumlahAnimasi = 0;
                int totalEpisodeAnimasi = 0;
                int totalAnimMinutes = 0;

                for (final d in dramaList) {
                  // Hanya hitung item yang statusnya sudah ditonton: 'Selesai' atau 'Sedang Menonton'
                  // (Abaikan 'Rencana Ditonton' atau 'Belum Ditonton')
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

                // TOTAL KESELURUHAN: Jumlahkan seluruh menit dan total judul
                final int totalAllMinutes =
                    totalDramaMinutes + totalFilmMinutes + totalAnimMinutes;
                final int totalTontonan =
                    jumlahDrama + jumlahFilm + jumlahAnimasi;

                return Padding(
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
                              durationText: _formatDuration(totalDramaMinutes),
                              subInfo:
                                  '$totalEpisodeDrama episode, $jumlahDrama drama',
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
                              durationText: _formatDuration(totalFilmMinutes),
                              subInfo: '$jumlahFilm film',
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
                              durationText: _formatDuration(totalAnimMinutes),
                              subInfo:
                                  '$totalEpisodeAnimasi episode, $jumlahAnimasi animasi',
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
                              durationText: _formatDuration(totalAllMinutes),
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
                );
              },
            ),


            // ==========================================
            // 6. BAGIAN PEMBARUAN TERAKHIR
            // ==========================================
            ValueListenableBuilder<List<Drama>>(
              valueListenable: SharedData.dramaListNotifier,
              builder: (context, dramaList, _) {
                // List drama yang baru ditonton atau sedang aktif
                List<Drama> recentDramas = dramaList.where((d) => 
                  d.status == 'Sedang Menonton' || d.status == 'Selesai' || d.watchedEpisodes > 0
                ).toList();
                if (recentDramas.isEmpty) {
                  recentDramas = dramaList.take(8).toList();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pembaruan Terakhir',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.1,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              globalNavIndex.value = 1; // Pindah ke tab Watchlist
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Lihat Daftar',
                                    style: TextStyle(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 11,
                                    color: primaryBlue,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Horizontal List Card Drama atau Empty State Riwayat
                    if (recentDramas.isEmpty)
                      Container(
                        height: 130,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 36,
                                color: subTextColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Belum ada riwayat pembaruan',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Aktivitas tontonan film atau dramamu akan muncul di sini',
                                textAlign: TextAlign.center,
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
                      SizedBox(
                        height: 220,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: recentDramas.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final drama = recentDramas[index];
                            return _buildRecentDramaCard(
                              context,
                              drama,
                              isDark,
                              cardBg,
                              textColor,
                              subTextColor,
                              primaryBlue,
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  );
}

  // ==========================================
  // HELPER WIDGETS & METHODS
  // ==========================================

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

  Widget _buildRecentDramaCard(
    BuildContext context,
    Drama drama,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subTextColor,
    Color primaryBlue,
  ) {
    bool isCompleted = drama.status == 'Selesai';
    Color statusColor = isCompleted ? const Color(0xFF10B981) : primaryBlue;

    final String posterUrl = drama.image.isNotEmpty
        ? drama.image
        : (_posterCache[drama.id] ?? '');

    String displayGenre = drama.genre;
    if (displayGenre.isEmpty || displayGenre == 'General') {
      if (_genreCache.containsKey(drama.id) &&
          _genreCache[drama.id] != 'General') {
        displayGenre = _genreCache[drama.id]!;
      } else {
        displayGenre = (drama.mediaType == 'tv' || drama.episodes > 1)
            ? 'Serial TV'
            : 'Film';
      }
    }

    Widget posterWidget;
    if (posterUrl.isNotEmpty) {
      posterWidget = Image.network(
        posterUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: isDark ? const Color(0xFF282C37) : Colors.grey.shade300,
          child: Icon(Icons.movie, color: subTextColor, size: 30),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
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
    } else {
      posterWidget = Container(
        color: isDark ? const Color(0xFF282C37) : Colors.grey.shade300,
        child: Icon(Icons.movie, color: subTextColor, size: 30),
      );
    }

    return GestureDetector(
      onTap: () {
        context.push(
          '/movie/${drama.id}',
          extra: {
            'drama': drama,
            'apiService': _apiService,
            'posterUrl': posterUrl,
          },
        );
      },
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2E3D) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                  child: SizedBox(
                    height: 140,
                    width: 120,
                    child: posterWidget,
                  ),
                ),

                // Rating Badge di pojok kanan atas
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 12),
                        const SizedBox(width: 2),
                        Text(
                          drama.status == 'Selesai'
                              ? (drama.userRating ?? drama.myRating ?? 0.0).toStringAsFixed(1)
                              : '0.0',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Status Badge di pojok kiri bawah foto
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isCompleted ? 'Selesai' : 'Nonton',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Detail teks di bawah poster
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drama.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayGenre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper identifikasi kategori & durasi tontonan dari TMDB / Supabase
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

  // Fungsi pembantu untuk mengubah total menit menjadi format "3d 2h 0m" atau "8h 40m"
  String _formatDuration(int totalMinutes) {
    if (totalMinutes <= 0) return '0h 0m';

    int days = totalMinutes ~/ (60 * 24);
    int remainingMinutes = totalMinutes % (60 * 24);
    int hours = remainingMinutes ~/ 60;
    int mins = remainingMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${mins}m';
    } else {
      return '${hours}h ${mins}m';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../routes/app_router.dart';
import '../data/shared_data.dart';
import '../models/drama.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import 'movie_detail_page.dart';

/// Alias penamaan LeaderboardPage yang merujuk pada RankingTab
typedef LeaderboardPage = RankingTab;

class RankingTab extends StatefulWidget {
  final ApiService? apiService;

  const RankingTab({super.key, this.apiService});

  @override
  State<RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends State<RankingTab> {
  late final ApiService _apiService;

  // Filter 1: Kategori & Negara
  static const List<String> _categoryOptions = [
    'Semua',
    'Semua Film',
    'Semua Drama',
    'Anime',
    'Film Indonesia',
    'Film Barat',
    'Film Korea',
    'Film Jepang',
    'Drama Korea',
    'Drama Barat',
    'Drama Jepang',
  ];

  // Filter 2: Genre
  static const List<String> _genreOptions = [
    'Semua Genre',
    'Aksi',
    'Drama',
    'Komedi',
    'Horor',
    'Romantis',
    'Thriller/Misteri',
    'Fiksi Ilmiah & Fantasi',
    'Animasi',
  ];

  String _selectedCategory = 'Semua';
  String _selectedGenre = 'Semua Genre';

  List<Drama> _topRatedDramas = [];
  List<Drama> _trendingDramas = [];
  bool _isLoadingTopRated = true;
  bool _isLoadingTrending = true;
  int _fetchToken = 0;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _refreshWatchlistData();
    SharedData.dramaListNotifier.addListener(_onWatchlistChanged);
    _fetchLeaderboardData();
  }

  @override
  void dispose() {
    SharedData.dramaListNotifier.removeListener(_onWatchlistChanged);
    super.dispose();
  }

  void _onWatchlistChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshWatchlistData() async {
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser != null) {
        await SharedData.fetchUserWatchlist(client: client);
      }
    } catch (_) {}
  }

  Future<void> _fetchLeaderboardData() async {
    final currentToken = ++_fetchToken;
    setState(() {
      _isLoadingTopRated = true;
      _isLoadingTrending = true;
    });

    try {
      final topRatedFuture = _apiService.getLeaderboardMedia(
        category: _selectedCategory,
        genre: _selectedGenre,
        isTopRated: true,
        limit: 30,
      );

      final trendingFuture = _apiService.getLeaderboardMedia(
        category: _selectedCategory,
        genre: _selectedGenre,
        isTopRated: false,
        limit: 30,
      );

      final results = await Future.wait([topRatedFuture, trendingFuture]);

      if (currentToken == _fetchToken && mounted) {
        setState(() {
          _topRatedDramas = results[0];
          _trendingDramas = results[1];
          _isLoadingTopRated = false;
          _isLoadingTrending = false;
        });
      }
    } catch (_) {
      if (currentToken == _fetchToken && mounted) {
        // Fallback untuk offline / mock test jika list kosong
        final fallback = SharedData.dramaListNotifier.value;
        setState(() {
          _topRatedDramas = List<Drama>.from(fallback);
          _trendingDramas = List<Drama>.from(fallback);
          _isLoadingTopRated = false;
          _isLoadingTrending = false;
        });
      }
    }
  }

  String _formatSubtitle(Drama drama) {
    // 1. Ekstrak Tahun Rilis
    String year = '';
    if (drama.releaseDate.isNotEmpty) {
      year = drama.releaseDate.split('-')[0].trim();
    } else if (drama.date.isNotEmpty) {
      year = drama.date.split('-')[0].trim();
    }
    if (year.isEmpty) year = '2024';

    // 2. Tentukan Label Kategori / Negara
    final bool isFilm = drama.mediaType == 'movie' ||
        drama.isMovie ||
        drama.genre.toLowerCase().contains('film');
    final String lang = drama.originalLanguage.toLowerCase();
    final bool isAnime = (drama.genreIds.contains(16) ||
            drama.genresList.any((g) => g.toLowerCase().contains('anim'))) &&
        (lang == 'ja' || lang.isEmpty);

    String categoryText;
    if (_selectedCategory == 'Anime' || isAnime) {
      categoryText = 'Anime';
    } else if (lang == 'id') {
      categoryText = isFilm ? 'Film Indonesia' : 'Drama Indonesia';
    } else if (lang == 'ko') {
      categoryText = isFilm ? 'Film Korea' : 'Drama Korea';
    } else if (lang == 'ja') {
      categoryText = isFilm ? 'Film Jepang' : 'Drama Jepang';
    } else if (lang == 'en') {
      categoryText = isFilm ? 'Film Barat' : 'Drama Barat';
    } else if (_selectedCategory != 'Semua' &&
        _selectedCategory != 'Semua Film' &&
        _selectedCategory != 'Semua Drama') {
      categoryText = _selectedCategory;
    } else {
      categoryText = isFilm ? 'Film' : 'Drama';
    }

    return '$year \u2022 $categoryText';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor =
        isDark ? const Color(0xFF15171E) : const Color(0xFFF8F9FA);
    final Color cardBg = isDark ? const Color(0xFF1F222B) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final Color subTextColor =
        isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade600;
    final Color borderColor =
        isDark ? const Color(0xFF2A2E3D) : Colors.grey.shade200;
    const Color primaryBlue = Color(0xFF0094FF);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            'Papan Peringkat',
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          bottom: TabBar(
            indicatorColor: primaryBlue,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: primaryBlue,
            unselectedLabelColor: subTextColor,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: const [
              Tab(
                icon: Icon(Icons.star_rounded, size: 20),
                text: 'Rating Tertinggi',
              ),
              Tab(
                icon: Icon(Icons.local_fire_department_rounded, size: 20),
                text: 'Sedang Tren',
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),

            // Baris Filter 1: Kategori & Negara (Horizontal Scroll Chips)
            _buildFilterChipsRow(
              options: _categoryOptions,
              selectedOption: _selectedCategory,
              onSelected: (val) {
                setState(() {
                  _selectedCategory = val;
                });
                _fetchLeaderboardData();
              },
              isDark: isDark,
              primaryBlue: primaryBlue,
              subTextColor: subTextColor,
            ),

            const SizedBox(height: 8),

            // Baris Filter 2: Genre (Horizontal Scroll Chips)
            _buildFilterChipsRow(
              options: _genreOptions,
              selectedOption: _selectedGenre,
              onSelected: (val) {
                setState(() {
                  _selectedGenre = val;
                });
                _fetchLeaderboardData();
              },
              isDark: isDark,
              primaryBlue: primaryBlue,
              subTextColor: subTextColor,
            ),

            const SizedBox(height: 6),

            // Konten Tab Baris Peringkat
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Rating Tertinggi
                  _buildRankingView(
                    dramas: _topRatedDramas,
                    isLoading: _isLoadingTopRated,
                    isDark: isDark,
                    cardBg: cardBg,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    primaryBlue: primaryBlue,
                    borderColor: borderColor,
                  ),
                  // Tab 2: Sedang Tren
                  _buildRankingView(
                    dramas: _trendingDramas,
                    isLoading: _isLoadingTrending,
                    isDark: isDark,
                    cardBg: cardBg,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    primaryBlue: primaryBlue,
                    borderColor: borderColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET BUILDER: HORIZONTAL FILTER CHIPS ROW
  // ==========================================
  Widget _buildFilterChipsRow({
    required List<String> options,
    required String selectedOption,
    required ValueChanged<String> onSelected,
    required bool isDark,
    required Color primaryBlue,
    required Color subTextColor,
  }) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final bool isSelected = option == selectedOption;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (option != selectedOption) {
                  onSelected(option);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryBlue
                      : (isDark
                          ? const Color(0xFF1F222B)
                          : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? primaryBlue
                        : (isDark
                            ? const Color(0xFF2E3342)
                            : Colors.grey.shade300),
                    width: 1,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? Colors.grey.shade300
                            : const Color(0xFF2C3E50)),
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // WIDGET BUILDER: LISTVIEW & STATUS VIEW
  // ==========================================
  Widget _buildRankingView({
    required List<Drama> dramas,
    required bool isLoading,
    required bool isDark,
    required Color cardBg,
    required Color textColor,
    required Color subTextColor,
    required Color primaryBlue,
    required Color borderColor,
  }) {
    if (isLoading && dramas.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: primaryBlue),
      );
    }

    if (dramas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_filter_rounded,
              size: 54,
              color: subTextColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada film/drama untuk filter ini',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'Semua';
                  _selectedGenre = 'Semua Genre';
                });
                _fetchLeaderboardData();
              },
              child: Text(
                'Reset Filter ke Semua',
                style: TextStyle(color: primaryBlue),
              ),
            ),
          ],
        ),
      );
    }

    return ValueListenableBuilder<List<Drama>>(
      valueListenable: SharedData.dramaListNotifier,
      builder: (context, userWatchlist, _) {
        final Color actionBtnBg = isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.06);
        final Color actionIconColor =
            isDark ? Colors.white70 : Colors.black87;

        return RefreshIndicator(
          color: primaryBlue,
          backgroundColor: cardBg,
          onRefresh: _fetchLeaderboardData,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: dramas.length,
            itemBuilder: (context, index) {
              final drama = dramas[index];
              final rank = index + 1;
              return _buildRankingCard(
                context: context,
                drama: drama,
                rank: rank,
                userWatchlist: userWatchlist,
                isDark: isDark,
                cardBg: cardBg,
                textColor: textColor,
                subTextColor: subTextColor,
                borderColor: borderColor,
                actionBtnBg: actionBtnBg,
                actionIconColor: actionIconColor,
              );
            },
          ),
        );
      },
    );
  }

  // ==========================================
  // WIDGET BUILDER: CARD BARIS PER FILM
  // ==========================================
  Widget _buildRankingCard({
    required BuildContext context,
    required Drama drama,
    required int rank,
    required List<Drama> userWatchlist,
    required bool isDark,
    required Color cardBg,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
    required Color actionBtnBg,
    required Color actionIconColor,
  }) {
    final int effId = drama.id;

    final List<int> savedMovieIds = userWatchlist
        .where((d) =>
            d.status == 'Rencana Ditonton' ||
            d.status == 'Sedang Menonton' ||
            d.status == 'Selesai')
        .map((d) => d.id)
        .where((id) => id > 0)
        .toList();

    final bool isSavedInWatchlist = effId > 0 && savedMovieIds.contains(effId);

    Drama? matchedWatchlist;
    if (isSavedInWatchlist) {
      for (final d in userWatchlist) {
        final bool hasValidStatus = d.status == 'Rencana Ditonton' ||
            d.status == 'Sedang Menonton' ||
            d.status == 'Selesai';
        if (!hasValidStatus) continue;

        if (effId > 0 && d.id == effId) {
          matchedWatchlist = d;
          break;
        }
      }
    }
    final bool isFilm = drama.mediaType == 'movie' ||
        drama.isMovie ||
        drama.genre.toLowerCase().contains('film');

    final String ratingDisplay = drama.voteAverage > 0
        ? drama.voteAverage.toStringAsFixed(1)
        : (drama.rating > 0 ? drama.rating.toStringAsFixed(1) : '8.0');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank <= 3
              ? _getRankColor(rank, isDark).withValues(alpha: 0.45)
              : borderColor,
          width: rank <= 3 ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push(
              '/movie/${drama.id}',
              extra: drama,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // ------------------------------------
                // KIRI: ANGKA PERINGKAT TEBAL & BESAR
                // ------------------------------------
                _buildRankNumber(rank, isDark),

                const SizedBox(width: 12),

                // ------------------------------------
                // TENGAH: POSTER TMDB, JUDUL, TAHUN & KATEGORI
                // ------------------------------------
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 62,
                    height: 88,
                    child: drama.image.isNotEmpty
                        ? Image.network(
                            drama.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: isDark
                                  ? const Color(0xFF282C37)
                                  : Colors.grey.shade300,
                              child: Icon(
                                Icons.movie,
                                color: subTextColor,
                                size: 28,
                              ),
                            ),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: isDark
                                    ? const Color(0xFF282C37)
                                    : Colors.grey.shade200,
                                child: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0094FF),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: isDark
                                ? const Color(0xFF282C37)
                                : Colors.grey.shade300,
                            child: Icon(
                              Icons.movie,
                              color: subTextColor,
                              size: 28,
                            ),
                          ),
                  ),
                ),

                const SizedBox(width: 14),

                // Judul, Subtitle (Tahun • Kategori), dan Skor Rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Judul Utama Film / Drama
                      Text(
                        drama.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Format Subtitle Spesifik: Tahun • Kategori
                      Text(
                        _formatSubtitle(drama),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Skor Rating dengan Bintang Kuning & Badge Film/Eps
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB800),
                            size: 17,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ratingDisplay,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF282C38)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isFilm
                                  ? 'Film'
                                  : (drama.episodes > 1
                                      ? '${drama.episodes} Eps'
                                      : 'Serial'),
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ------------------------------------
                // KANAN: KOTAK TOMBOL AKSI (+ dan Pensil/Edit)
                // ------------------------------------
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      if (matchedWatchlist != null) {
                        final savedItem = matchedWatchlist;
                        final dramaToEdit = drama.copyWith(
                          status: savedItem.status,
                          watchedEpisodes: savedItem.watchedEpisodes,
                          episodes: savedItem.episodes > 0
                              ? savedItem.episodes
                              : drama.episodes,
                          myRating: savedItem.userRating ?? savedItem.myRating,
                          userRating:
                              savedItem.userRating ?? savedItem.myRating,
                          priority: savedItem.priority,
                          startDate: savedItem.startDate,
                          endDate: savedItem.endDate,
                          dateCompleted: savedItem.dateCompleted,
                        );

                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => EditDramaModal(
                            drama: dramaToEdit,
                            initialStatus: savedItem.status,
                          ),
                        );
                      } else {
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => EditDramaModal(
                            drama: drama,
                            initialStatus: 'Belum Ditonton',
                          ),
                        );
                      }

                      await _refreshWatchlistData();
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: actionBtnBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        savedMovieIds.contains(drama.id)
                            ? Icons.edit_outlined
                            : Icons.add,
                        color: actionIconColor,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HELPER LOGIKA WARNA & FORMAT ANGKA PERINGKAT
  // ==========================================
  Color _getRankColor(int rank, bool isDark) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Emas
      case 2:
        return const Color(0xFFC0C0C0); // Perak
      case 3:
        return const Color(0xFFCD7F32); // Perunggu
      default:
        return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    }
  }

  Widget _buildRankNumber(int rank, bool isDark) {
    final Color color = _getRankColor(rank, isDark);

    return SizedBox(
      width: 38,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ikon piala / medali khusus untuk 3 besar
          if (rank == 1)
            const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFFD700),
              size: 16,
            )
          else if (rank == 2)
            const Icon(
              Icons.military_tech_rounded,
              color: Color(0xFFC0C0C0),
              size: 16,
            )
          else if (rank == 3)
            const Icon(
              Icons.military_tech_rounded,
              color: Color(0xFFCD7F32),
              size: 16,
            ),

          Text(
            '$rank',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: rank <= 3 ? 24 : 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

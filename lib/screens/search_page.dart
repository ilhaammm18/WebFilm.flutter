import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../routes/app_router.dart';
import '../models/drama.dart';
import '../models/actor.dart';
import '../services/api_service.dart';
import '../data/shared_data.dart';
import '../widgets/edit_drama_modal.dart';

class SearchPage extends StatefulWidget {
  final ApiService? apiService;
  final SupabaseClient? supabaseClient;
  const SearchPage({super.key, this.apiService, this.supabaseClient});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  String _selectedSort = 'Paling Populer';
  late final ApiService _apiService;
  late Future<List<Actor>> _actorsFuture;

  List<Drama> _allMedia = [];
  List<Drama> _displayedMedia = [];
  List<int> savedMovieIds = [];
  int _searchToken = 0;
  bool _isLoadingOnline = false;

  void _updateSavedMovieIds() {
    savedMovieIds = SharedData.dramaListNotifier.value
        .where((d) =>
            d.status == 'Rencana Ditonton' ||
            d.status == 'Sedang Menonton' ||
            d.status == 'Selesai')
        .map((d) => d.id)
        .where((id) => id > 0)
        .toList();
  }

  SupabaseClient? get _supabaseClient {
    if (widget.supabaseClient != null) return widget.supabaseClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _apiService = widget.apiService ?? ApiService();
    _actorsFuture = _apiService.getCuratedActors();
    _allMedia = List<Drama>.from(SharedData.dramaListNotifier.value);
    _updateSavedMovieIds();
    _filterAndSortMedia();
    _refreshWatchlistData();
    _loadDefaultTmdbMedia();
    SharedData.dramaListNotifier.addListener(_onDramaListChanged);
  }

  Future<void> _refreshWatchlistData() async {
    try {
      final client = _supabaseClient;
      if (client != null && client.auth.currentUser != null) {
        await SharedData.fetchUserWatchlist(client: client);
        _updateSavedMovieIds();
        if (mounted) {
          setState(() {});
        }
      }
    } catch (_) {}
  }

  /// Memuat daftar film/drama default langsung dari TMDB API saat kolom pencarian kosong
  Future<void> _loadDefaultTmdbMedia() async {
    final token = ++_searchToken;
    setState(() {
      _isLoadingOnline = true;
    });

    try {
      List<Drama> defaultMedia = [];
      if (_selectedCategory == 'Film') {
        defaultMedia = await _apiService.getMovies();
      } else if (_selectedCategory == 'Drama') {
        defaultMedia = await _apiService.getDramas();
      } else if (_selectedCategory == 'Anime') {
        defaultMedia = await _apiService.getAnimes();
      } else {
        // 'Semua': Ambil trending all/day atau gabungan popular movie & tv
        try {
          defaultMedia = await _apiService.getTrendingAllMix(limit: 40);
        } catch (_) {
          defaultMedia = [];
        }
        if (defaultMedia.isEmpty) {
          final results = await Future.wait([
            _apiService.getMovies(),
            _apiService.getDramas(),
          ]);
          defaultMedia = [...results[0], ...results[1]];
        }
      }

      if (token != _searchToken || !mounted) return;

      if (defaultMedia.isNotEmpty) {
        _allMedia = defaultMedia;
      } else {
        // Fallback untuk offline atau unit test jika mock TMDB kosong
        _allMedia = List<Drama>.from(SharedData.dramaListNotifier.value);
      }

      setState(() {
        _isLoadingOnline = false;
        _filterAndSortMedia();
      });
    } catch (_) {
      if (token == _searchToken && mounted) {
        if (_allMedia.isEmpty) {
          _allMedia = List<Drama>.from(SharedData.dramaListNotifier.value);
        }
        setState(() {
          _isLoadingOnline = false;
          _filterAndSortMedia();
        });
      }
    }
  }

  void _onDramaListChanged() {
    _updateSavedMovieIds();
    if (mounted) {
      setState(() {
        if (_allMedia.isEmpty) {
          _allMedia = List<Drama>.from(SharedData.dramaListNotifier.value);
          if (_searchQuery.isEmpty) {
            _filterAndSortMedia();
          }
        }
      });
    }
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    _searchQuery = query;

    if (query.isEmpty) {
      _filterAndSortMedia();
      setState(() {
        _actorsFuture = _apiService.getCuratedActors();
        _isLoadingOnline = false;
      });
      _loadDefaultTmdbMedia();
      return;
    }

    // 1. Filter lokal terlebih dahulu untuk respon instan
    _filterAndSortMedia();

    // 2. Jalankan pencarian online global untuk Aktor
    setState(() {
      _actorsFuture = _apiService.searchActors(query);
      _isLoadingOnline = true;
    });

    // 3. Jalankan pencarian online global untuk Judul (Film / Serial TV)
    final token = ++_searchToken;
    _performOnlineJudulSearch(query, token);
  }

  Future<void> _performOnlineJudulSearch(String query, int token) async {
    try {
      List<Drama> onlineResults = [];

      if (_selectedCategory == 'Film') {
        onlineResults = await _apiService.searchMovies(query);
      } else if (_selectedCategory == 'Drama') {
        onlineResults = await _apiService.searchTvShows(query);
      } else if (_selectedCategory == 'Anime') {
        final tvs = await _apiService.searchTvShows(query);
        onlineResults =
            tvs.where((item) => item.genreIds.contains(16)).toList();
        if (onlineResults.isEmpty) {
          onlineResults = tvs;
        }
      } else {
        // 'Semua' - cari movie dan tv show global sekaligus secara paralel
        final results = await Future.wait([
          _apiService.searchMovies(query),
          _apiService.searchTvShows(query),
        ]);
        onlineResults = [...results[0], ...results[1]];
      }

      if (token != _searchToken || !mounted) return;

      final Set<int> seenIds = <int>{};
      final List<Drama> merged = [];

      // Masukkan hasil online TMDB
      for (final item in onlineResults) {
        if (item.id == 0 || seenIds.add(item.id)) {
          final localMatch = _allMedia.firstWhere(
            (local) => local.id == item.id,
            orElse: () => item,
          );
          merged.add(localMatch);
        }
      }

      // Tambahkan hasil lokal yang cocok jika belum tercakup
      for (final local in _displayedMedia) {
        if (local.id == 0 || seenIds.add(local.id)) {
          merged.add(local);
        }
      }

      setState(() {
        _displayedMedia = merged;
        _isLoadingOnline = false;
        _applySort();
      });
    } catch (_) {
      if (token == _searchToken && mounted) {
        setState(() {
          _isLoadingOnline = false;
        });
      }
    }
  }

  void _filterAndSortMedia() {
    if (_selectedCategory == 'Film') {
      _displayedMedia =
          _allMedia.where((item) => item.mediaType == 'movie').toList();
    } else if (_selectedCategory == 'Drama') {
      _displayedMedia = _allMedia
          .where((item) => item.mediaType == 'tv' && !item.genreIds.contains(16))
          .toList();
    } else if (_selectedCategory == 'Anime') {
      _displayedMedia = _allMedia
          .where((item) => item.mediaType == 'tv' && item.genreIds.contains(16))
          .toList();
    } else {
      _displayedMedia = List<Drama>.from(_allMedia);
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      _displayedMedia = _displayedMedia
          .where((d) =>
              d.title.toLowerCase().contains(q) ||
              d.koreanTitle.toLowerCase().contains(q))
          .toList();
    }

    _applySort();
  }

  String _cleanString(String s) {
    return s
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  int _calculateRelevanceScore(Drama drama, String qClean) {
    if (qClean.isEmpty) return 99;

    final String title = drama.title.trim().toLowerCase();
    final String korean = drama.koreanTitle.trim().toLowerCase();
    final String titleClean = _cleanString(title);
    final String koreanClean = _cleanString(korean);

    // 0. Exact match judul utama
    if (titleClean == qClean || title == qClean) {
      return 0;
    }
    // 1. Exact match judul alternatif / Korea
    if (koreanClean == qClean || korean == qClean) {
      return 1;
    }

    // 2. Judul utama diawali dengan kata kunci persis
    if (titleClean.startsWith(qClean) || title.startsWith(qClean)) {
      return 2;
    }
    // 3. Judul Korea diawali dengan kata kunci persis
    if (koreanClean.startsWith(qClean) || korean.startsWith(qClean)) {
      return 3;
    }

    // 4. Kata kunci cocok sebagai satu kata/frasa utuh di judul
    final wordPattern = RegExp('\\b${RegExp.escape(qClean)}\\b');
    if (wordPattern.hasMatch(titleClean)) {
      return 4;
    }
    if (wordPattern.hasMatch(koreanClean)) {
      return 5;
    }

    // 6. Judul mengandung kata kunci
    if (titleClean.contains(qClean) || title.contains(qClean)) {
      return 6;
    }
    if (koreanClean.contains(qClean) || korean.contains(qClean)) {
      return 7;
    }

    // 8. Seluruh kata dalam kata kunci ada dalam judul
    final tokens = qClean.split(' ').where((t) => t.isNotEmpty).toList();
    if (tokens.isNotEmpty && tokens.every((t) => titleClean.contains(t))) {
      return 8;
    }

    return 99;
  }

  void _applySort() {
    final rawQuery = _searchQuery.trim().toLowerCase();
    final qClean = _cleanString(rawQuery);

    _displayedMedia.sort((a, b) {
      // 1. Prioritaskan relevansi pencarian jika pengguna mengetikkan kata kunci
      if (qClean.isNotEmpty) {
        final scoreA = _calculateRelevanceScore(a, qClean);
        final scoreB = _calculateRelevanceScore(b, qClean);

        // Pertahankan exact match di paling atas (indeks 0) jika ada
        if (scoreA == 0 || scoreB == 0) {
          if (scoreA != scoreB) {
            return scoreA.compareTo(scoreB);
          }
        }

        // Urutkan berdasarkan nilai rating (vote_average) tertinggi di paling atas (descending)
        final ratingCmp = b.voteAverage.compareTo(a.voteAverage);
        if (ratingCmp != 0) return ratingCmp;

        if (scoreA != scoreB) {
          return scoreA.compareTo(scoreB);
        }

        // Jika rating sama persis, utamakan yang selisih panjangnya paling dekat
        final lenDiffA = (_cleanString(a.title).length - qClean.length).abs();
        final lenDiffB = (_cleanString(b.title).length - qClean.length).abs();
        if (lenDiffA != lenDiffB) {
          return lenDiffA.compareTo(lenDiffB);
        }
      }

      // 2. Kriteria sorting sekunder atau saat kata kunci pencarian kosong
      if (_selectedSort == 'Peringkat Teratas' ||
          _selectedSort == 'Rating Tertinggi') {
        return b.voteAverage.compareTo(a.voteAverage);
      } else if (_selectedSort == 'Tahun Rilis') {
        return b.releaseDate.compareTo(a.releaseDate);
      } else if (_selectedSort == 'Paling Populer' ||
          _selectedSort == 'Kepopuleran') {
        return b.popularity.compareTo(a.popularity);
      }

      // Default pengurutan hasil pencarian: rating tertinggi ke terendah (descending)
      return b.voteAverage.compareTo(a.voteAverage);
    });
  }

  @override
  void dispose() {
    SharedData.dramaListNotifier.removeListener(_onDramaListChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = isDark ? const Color(0xFF15171E) : const Color(0xFFF8F9FA);
    Color cardColor = isDark ? const Color(0xFF1F222A) : Colors.white;
    Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    Color subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    Color primaryBlue = const Color(0xFF0094FF);
    Color inputBg = isDark ? const Color(0xFF1F222A) : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: textColor),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade300),
                      ),
                      child: TextField(
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Cari',
                          hintStyle: TextStyle(color: subTextColor, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          suffixIcon: Icon(Icons.search, color: subTextColor, size: 20),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tombol 1: Ikon Sorting (Icons.swap_vert)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C38) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.swap_vert, size: 22),
                      color: textColor,
                      tooltip: 'Urutkan Berdasarkan',
                      onPressed: () => _showSortingBottomSheet(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tombol 2: Ikon Filter (Icons.tune)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C38) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.tune, size: 20),
                      color: textColor,
                      tooltip: 'Pilih Kategori',
                      onPressed: () => _showCategoryFilterBottomSheet(context),
                    ),
                  ),
                ],
              ),
            ),
            
            TabBar(
              controller: _tabController,
              labelColor: primaryBlue,
              unselectedLabelColor: subTextColor,
              indicatorColor: primaryBlue,
              dividerColor: Colors.transparent, 
              tabs: const [
                Tab(text: 'JUDUL'),
                Tab(text: 'AKTOR'),
              ],
            ),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildJudulTab(cardColor, textColor, subTextColor),
                  _buildAktorTab(cardColor, textColor, subTextColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modal Bottom Sheet 'Pilih Kategori'
  void _showCategoryFilterBottomSheet(BuildContext context) {
    String tempCategory = _selectedCategory;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF1E2129) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final Color primaryBlue = const Color(0xFF0094FF);

    final List<String> categories = ['Semua', 'Film', 'Drama', 'Anime'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar kecil
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Judul tebal di bagian atas tengah
                  Text(
                    'Pilih Kategori',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Opsi Kategori: 'Semua', 'Film', 'Drama', 'Anime'
                  ...categories.map((cat) {
                    return _buildSortOption(
                      title: cat,
                      isSelected: tempCategory == cat,
                      textColor: textColor,
                      primaryBlue: primaryBlue,
                      onTap: () {
                        setModalState(() {
                          tempCategory = cat;
                        });
                      },
                    );
                  }),

                  const SizedBox(height: 24),

                  // Tombol 'Terapkan' berwarna biru (width: double.infinity)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedCategory = tempCategory;
                          _filterAndSortMedia();
                          if (_searchQuery.isNotEmpty) {
                            _performOnlineJudulSearch(
                                _searchQuery, ++_searchToken);
                          } else {
                            _loadDefaultTmdbMedia();
                          }
                        });
                        ctx.pop();
                      },
                      child: const Text(
                        'Terapkan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Modal Bottom Sheet 'Urutkan Berdasarkan'
  void _showSortingBottomSheet(BuildContext context) {
    String tempSort = _selectedSort;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF1E2129) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final Color primaryBlue = const Color(0xFF0094FF);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar kecil
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Judul tebal di bagian atas tengah
                  Text(
                    'Urutkan Berdasarkan',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Opsi a. 'Paling Populer'
                  _buildSortOption(
                    title: 'Paling Populer',
                    isSelected: tempSort == 'Paling Populer',
                    textColor: textColor,
                    primaryBlue: primaryBlue,
                    onTap: () {
                      setModalState(() {
                        tempSort = 'Paling Populer';
                      });
                    },
                  ),

                  // Opsi b. 'Peringkat Teratas'
                  _buildSortOption(
                    title: 'Peringkat Teratas',
                    isSelected: tempSort == 'Peringkat Teratas',
                    textColor: textColor,
                    primaryBlue: primaryBlue,
                    onTap: () {
                      setModalState(() {
                        tempSort = 'Peringkat Teratas';
                      });
                    },
                  ),

                  // Opsi c. 'Tahun Rilis'
                  _buildSortOption(
                    title: 'Tahun Rilis',
                    isSelected: tempSort == 'Tahun Rilis',
                    textColor: textColor,
                    primaryBlue: primaryBlue,
                    onTap: () {
                      setModalState(() {
                        tempSort = 'Tahun Rilis';
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Tombol 'Terapkan' berwarna biru (width: double.infinity)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedSort = tempSort;
                          _applySort();
                        });
                        ctx.pop();
                      },
                      child: const Text(
                        'Terapkan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortOption({
    required String title,
    required bool isSelected,
    required Color textColor,
    required Color primaryBlue,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? primaryBlue : textColor,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, color: primaryBlue, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatMovieDuration(Drama drama) {
    if (drama.runtime != null && drama.runtime! > 0) {
      final h = drama.runtime! ~/ 60;
      final m = drama.runtime! % 60;
      if (h > 0 && m > 0) return '${h}j ${m}m';
      if (h > 0) return '${h}j';
      return '${m}m';
    }
    final d = drama.duration.trim();
    if (d.isNotEmpty &&
        d != '-' &&
        d != '0' &&
        !d.toLowerCase().contains('0 menit')) {
      return d;
    }
    return '';
  }

  Widget _buildJudulTab(Color cardColor, Color textColor, Color subTextColor) {
    Color primaryBlue = const Color(0xFF0094FF);

    if (_isLoadingOnline && _displayedMedia.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryBlue),
            const SizedBox(height: 12),
            Text(
              'Mencari judul...',
              style: TextStyle(
                color: subTextColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_displayedMedia.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 54, color: subTextColor.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'Tidak ditemukan judul yang cocok',
              style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ValueListenableBuilder<List<Drama>>(
      valueListenable: SharedData.dramaListNotifier,
      builder: (context, userWatchlist, _) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final Color actionBtnBg = isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.06);
        final Color actionIconColor = isDark ? Colors.white70 : Colors.black87;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          itemCount: _displayedMedia.length,
          itemBuilder: (context, index) {
            final Drama item = _displayedMedia[index];
            final String heroTag = 'poster_${item.id > 0 ? item.id : item.title}';

            final bool isFilm = item.mediaType == 'movie' ||
                (item.mediaType != 'tv' &&
                    (item.isMovie || item.genre.toLowerCase().contains('film')));
            final String movieDuration = isFilm ? _formatMovieDuration(item) : '';
            final String year = item.releaseDate.isNotEmpty
                ? item.releaseDate.split('-')[0]
                : (item.date.isNotEmpty
                    ? item.date.split('-')[0]
                    : (item.aired.isNotEmpty ? item.aired.split('-')[0] : ''));

            final String categoryLabel = Drama.getCategoryLabel(
              mediaType: item.mediaType,
              originalLanguage: item.originalLanguage,
              genreIds: item.genreIds,
              drama: item,
            );
            final String subtitle = year.isNotEmpty
                ? '$categoryLabel \u2022 $year'
                : categoryLabel;

            final int tmdbId = item.id;
            final String tmdbIdStr = tmdbId.toString();

            // Memperbarui dan menggunakan savedMovieIds (berdasarkan tmdb_id numerik)
            savedMovieIds = userWatchlist
                .where((d) =>
                    d.status == 'Rencana Ditonton' ||
                    d.status == 'Sedang Menonton' ||
                    d.status == 'Selesai')
                .map((d) => d.id)
                .where((id) => id > 0)
                .toList();

            // Pengecekan status tersimpan strictly menggunakan ID, BUKAN membandingkan judul film
            final bool isSavedInWatchlist = item.id > 0 && savedMovieIds.contains(item.id);

            Drama? matchedWatchlist;
            if (isSavedInWatchlist) {
              for (final d in userWatchlist) {
                final bool hasValidStatus = d.status == 'Rencana Ditonton' ||
                    d.status == 'Sedang Menonton' ||
                    d.status == 'Selesai';
                if (!hasValidStatus) continue;

                final int wId = d.id;
                final String wIdStr = wId.toString();

                // Cocokkan strictly id item TMDB dengan watchlist dalam tipe int maupun String
                final bool idMatches = (tmdbId > 0 && wId > 0 && tmdbId == wId) ||
                    (tmdbIdStr.isNotEmpty && tmdbIdStr != '0' && tmdbIdStr == wIdStr);

                if (idMatches) {
                  matchedWatchlist = d;
                  break;
                }
              }
            }

            final int displayEpisodes = matchedWatchlist != null && matchedWatchlist.episodes > 0
                ? matchedWatchlist.episodes
                : item.episodes;

            return GestureDetector(
              onTap: () async {
                await context.push(
                  '/movie/${item.id}',
                  extra: {
                    'drama': item,
                    'heroTag': heroTag,
                    'posterUrl': item.image,
                  },
                );
                await _refreshWatchlistData();
                if (mounted) setState(() {});
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Hero(
                      tag: heroTag,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.image, 
                          width: 60, 
                          height: 85, 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(width: 60, height: 85, color: Colors.grey.shade800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Text(subtitle, style: TextStyle(color: subTextColor, fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                item.rating.toStringAsFixed(1), 
                                style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)
                              ),
                              if (!isFilm) ...[
                                if (displayEpisodes > 0) ...[
                                  const SizedBox(width: 12),
                                  Icon(Icons.list_alt, color: subTextColor, size: 14),
                                  const SizedBox(width: 4),
                                  Text('$displayEpisodes', style: TextStyle(color: subTextColor, fontSize: 13)),
                                ],
                              ] else if (movieDuration.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Icon(Icons.access_time, color: subTextColor, size: 14),
                                const SizedBox(width: 4),
                                Text(movieDuration, style: TextStyle(color: subTextColor, fontSize: 13)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // KOTAK TOMBOL AKSI (+ dan Pena/Pensil)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          if (matchedWatchlist != null) {
                            final savedItem = matchedWatchlist;
                            final dramaToEdit = item.copyWith(
                              status: savedItem.status,
                              watchedEpisodes: savedItem.watchedEpisodes,
                              episodes: savedItem.episodes > 0
                                  ? savedItem.episodes
                                  : item.episodes,
                              myRating: savedItem.userRating ??
                                  savedItem.myRating,
                              userRating: savedItem.userRating ??
                                  savedItem.myRating,
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
                                drama: item,
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
                            savedMovieIds.contains(item.id)
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
            );
          },
        );
      },
    );
  }

  String _getDepartmentText(String? dept) {
    if (dept == null || dept.isEmpty || dept == 'Acting') {
      return 'Aktor / Pemeran';
    }
    if (dept == 'Directing') return 'Sutradara';
    if (dept == 'Writing') return 'Penulis';
    if (dept == 'Production') return 'Produser';
    return dept;
  }

  Widget _buildAktorTab(Color cardColor, Color textColor, Color subTextColor) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color primaryBlue = const Color(0xFF0094FF);

    return FutureBuilder<List<Actor>>(
      future: _actorsFuture,
      builder: (context, snapshot) {
        // Saat loading, tampilkan CircularProgressIndicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: primaryBlue),
                const SizedBox(height: 16),
                Text(
                  'Memuat data aktor...',
                  style: TextStyle(color: subTextColor, fontSize: 13),
                ),
              ],
            ),
          );
        }

        // Saat terjadi error dalam koneksi / response
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 52,
                    color: Colors.redAccent.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Gagal Memuat Data Aktor',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: subTextColor, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _actorsFuture = _apiService.getCuratedActors();
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final List<Actor> actors = snapshot.data ?? [];

        // Filter daftar aktor berdasarkan query pencarian jika ada
        List<Actor> filteredActors = actors.where((actor) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return actor.name.toLowerCase().contains(q) ||
              actor.koreanName.toLowerCase().contains(q) ||
              actor.nationality.toLowerCase().contains(q);
        }).toList();

        // Jika filter lokal tidak cocok tapi aktor dari API TMDB ada, tampilkan hasil API
        if (filteredActors.isEmpty && actors.isNotEmpty) {
          filteredActors = actors;
        }

        if (filteredActors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off_rounded,
                  size: 54,
                  color: subTextColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tidak ditemukan aktor yang cocok',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        // Saat data berhasil dimuat, tampilkan ListView.builder berisi Container untuk masing-masing aktor
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          physics: const BouncingScrollPhysics(),
          itemCount: filteredActors.length,
          itemBuilder: (context, index) {
            final Actor actor = filteredActors[index];

            // Sub-info: Data dinamis profesi dari known_for_department
            final String department = _getDepartmentText(actor.knownForDepartment);

            final String actorHeroTag =
                'actor_${actor.id > 0 ? actor.id : actor.name}';

            return GestureDetector(
              onTap: () {
                context.push(
                  '/actor/${actor.id}',
                  extra: {
                    'actor': actor,
                    'apiService': _apiService,
                    'heroTag': actorHeroTag,
                    'imageUrl': actor.imageUrl,
                  },
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C38) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF383848)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    // Bagian Kiri: Foto Profil Aktor (Kotak Vertikal Portrait 65x90)
                    Hero(
                      tag: actorHeroTag,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 65,
                          height: 90,
                          child: (actor.imageUrl.isNotEmpty)
                              ? Image.network(
                                  actor.imageUrl,
                                  width: 65,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          Container(
                                    width: 65,
                                    height: 90,
                                    color: isDark
                                        ? const Color(0xFF363644)
                                        : Colors.grey.shade300,
                                    child: Icon(
                                      Icons.person,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                      size: 34,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 65,
                                  height: 90,
                                  color: isDark
                                      ? const Color(0xFF363644)
                                      : Colors.grey.shade300,
                                  child: Icon(
                                    Icons.person,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                    size: 34,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Bagian Kanan: Informasi Teks (Nama & Sub-info)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            actor.name,
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.black87
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (actor.koreanName.isNotEmpty &&
                              actor.koreanName != actor.name) ...[
                            const SizedBox(height: 3),
                            Text(
                              actor.koreanName,
                              style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? Colors.grey[700]
                                    : Colors.grey[400],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            department,
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.grey[700]
                                  : Colors.grey[400],
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

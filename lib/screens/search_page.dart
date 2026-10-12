import 'package:flutter/material.dart';
import '../models/drama.dart';
import '../models/actor.dart';
import 'actor_detail_page.dart';
import '../services/api_service.dart';
import '../data/shared_data.dart';
import 'detail_page.dart'; 

class SearchPage extends StatefulWidget {
  final ApiService? apiService;
  const SearchPage({super.key, this.apiService});

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
  int _searchToken = 0;
  bool _isLoadingOnline = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _apiService = widget.apiService ?? ApiService();
    _actorsFuture = _apiService.getCuratedActors();
    _allMedia = List<Drama>.from(SharedData.dramaListNotifier.value);
    _filterAndSortMedia();
    SharedData.dramaListNotifier.addListener(_onDramaListChanged);
  }

  void _onDramaListChanged() {
    if (mounted) {
      setState(() {
        _allMedia = List<Drama>.from(SharedData.dramaListNotifier.value);
        if (_searchQuery.isEmpty) {
          _filterAndSortMedia();
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

  void _applySort() {
    if (_selectedSort == 'Peringkat Teratas' ||
        _selectedSort == 'Rating Tertinggi') {
      _displayedMedia.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
    } else if (_selectedSort == 'Tahun Rilis') {
      _displayedMedia.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
    } else if (_selectedSort == 'Paling Populer' ||
        _selectedSort == 'Kepopuleran') {
      _displayedMedia.sort((a, b) => b.popularity.compareTo(a.popularity));
    }
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
                    onPressed: () => Navigator.pop(context),
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
                          }
                        });
                        Navigator.pop(ctx);
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
                        Navigator.pop(ctx);
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

  Widget _buildJudulTab(Color cardColor, Color textColor, Color subTextColor) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: _displayedMedia.length,
      itemBuilder: (context, index) {
        final Drama item = _displayedMedia[index];
        final String heroTag = 'poster_${item.id > 0 ? item.id : item.title}';
        
        // LOGIKA CERDAS: Cek apakah film sudah masuk daftar tonton
        bool isInWatchlist = ['Selesai', 'Sedang Menonton', 'Rencana Ditonton'].contains(item.status);
        
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPage(
                  drama: item,
                  heroTag: heroTag,
                  posterUrl: item.image,
                ),
              ),
            );
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
                      Text('${item.genre.split('•')[0].trim()}  •  2025', style: TextStyle(color: subTextColor, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            item.rating.toStringAsFixed(1), 
                            style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.list_alt, color: subTextColor, size: 14),
                          const SizedBox(width: 4),
                          Text('${item.episodes}', style: TextStyle(color: subTextColor, fontSize: 13)),
                          const SizedBox(width: 12),
                          Icon(Icons.trending_up, color: subTextColor, size: 14),
                          const SizedBox(width: 4),
                          Text('#${index + 1}', style: TextStyle(color: subTextColor, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // TOMBOL DINAMIS: PENA (EDIT) ATAU PLUS (TAMBAH)
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => EditDramaModal(drama: item),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isInWatchlist
                          ? (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100)
                          : primaryBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isInWatchlist ? Icons.edit : Icons.add, 
                      color: isInWatchlist ? subTextColor : primaryBlue, 
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActorDetailPage(
                      actor,
                      apiService: _apiService,
                      heroTag: actorHeroTag,
                      imageUrl: actor.imageUrl,
                    ),
                  ),
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
                            style: const TextStyle(
                              color: Colors.white,
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
                                color: Colors.grey.shade400,
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
                              color: Colors.grey.shade400,
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
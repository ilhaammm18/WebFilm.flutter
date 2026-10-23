import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../routes/app_router.dart';
import '../widgets/app_drawer.dart';
import '../models/drama.dart';
import '../data/shared_data.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';
import '../widgets/edit_drama_modal.dart';

class WatchlistTab extends StatefulWidget {
  final SupabaseClient? supabaseClient;
  final ApiService? apiService;
  const WatchlistTab({super.key, this.supabaseClient, this.apiService});

  @override
  State<WatchlistTab> createState() => _WatchlistTabState();
}

class _WatchlistTabState extends State<WatchlistTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final ApiService _apiService;
  static final Map<int, String> _posterCache = {};
  static final Map<int, int> _episodesCache = {};
  final Set<int> _loadingPosters = {};
  
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua'; 
  final String _selectedSort = 'Baru Ditambahkan';

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _tabController = TabController(length: 3, vsync: this);
    _fetchWatchlist();
  }

  SupabaseClient? get _supabaseClient {
    if (widget.supabaseClient != null) return widget.supabaseClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchWatchlist() async {
    final client = _supabaseClient;
    if (client == null) return;
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        SharedData.dramaListNotifier.value = [];
        SharedData.dramaListNotifier.notifyListeners();
        if (mounted) setState(() {});
        return;
      }
      final List<dynamic> data = await client
          .from('watchlists')
          .select()
          .eq('user_id', userId);

      final List<Drama> list = data
          .map((item) => Drama.fromSupabase(item as Map<String, dynamic>))
          .toList();

      // Pulihkan gambar poster & episode dari cache lokal jika sudah pernah di-fetch
      for (final drama in list) {
        if (drama.id > 0) {
          if (drama.image.isEmpty && _posterCache.containsKey(drama.id)) {
            drama.image = _posterCache[drama.id]!;
          }
          if (drama.episodes == 0 && _episodesCache.containsKey(drama.id)) {
            drama.episodes = _episodesCache[drama.id]!;
          }
        }
      }

      SharedData.dramaListNotifier.value = List<Drama>.from(list);
      SharedData.dramaListNotifier.notifyListeners();
      if (mounted) {
        setState(() {});
      }

      // Lakukan background fetch detail TMDB berdasarkan tmdb_id
      _enrichWatchlistWithTmdb(list);
    } catch (e) {
      debugPrint('Error fetch watchlist: $e');
    }
  }

  Future<void> _enrichWatchlistWithTmdb(List<Drama> list) async {
    final itemsToEnrich = list
        .where((d) => d.id > 0 && (d.image.isEmpty || d.episodes == 0))
        .toList();
    if (itemsToEnrich.isEmpty) return;

    bool updated = false;
    await Future.wait(
      itemsToEnrich.map((drama) async {
        try {
          final detail = await _apiService.getMovieDetails(
            drama.id,
            mediaType: drama.mediaType.isNotEmpty ? drama.mediaType : null,
          );
          if (detail.image.isNotEmpty) {
            _posterCache[drama.id] = detail.image;
            drama.image = detail.image;
            updated = true;
          }
          if (detail.backdrop.isNotEmpty && drama.backdrop.isEmpty) {
            drama.backdrop = detail.backdrop;
          }
          if (detail.episodes > 0 && drama.episodes == 0) {
            _episodesCache[drama.id] = detail.episodes;
            drama.episodes = detail.episodes;
            updated = true;
          }
          if (detail.originalLanguage.isNotEmpty && drama.originalLanguage.isEmpty) {
            drama.originalLanguage = detail.originalLanguage;
          }
          if (detail.genre.isNotEmpty && detail.genre != 'General') {
            drama.genre = detail.genre;
          } else if (drama.genre == 'General' || drama.genre.isEmpty) {
            drama.genre = detail.mediaType == 'tv' ? 'Serial TV' : 'Film';
          }
          if (detail.mediaType.isNotEmpty && (drama.mediaType.isEmpty || drama.mediaType == 'tv')) {
            drama.mediaType = detail.mediaType;
          }
        } catch (e) {
          debugPrint('Error enrich TMDB drama ${drama.id}: $e');
        }
      }),
    );

    if (updated && mounted) {
      SharedData.dramaListNotifier.value = List<Drama>.from(list);
      SharedData.dramaListNotifier.notifyListeners();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = isDark ? const Color(0xFF15171E) : const Color(0xFFF8F9FA);
    Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    Color subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    Color primaryBlue = const Color(0xFF0094FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor), 
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: textColor, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Cari di daftar saya...',
                hintStyle: TextStyle(color: subTextColor),
                border: InputBorder.none,
              ),
              onChanged: (value) => setState(() {
                _searchQuery = value;
              }),
            )
          : Text('Daftar Saya', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: textColor),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                  _isSearching = false;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              _selectedCategory == 'Semua' ? Icons.tune : Icons.filter_alt, 
              color: _selectedCategory == 'Semua' ? textColor : primaryBlue,
            ),
            tooltip: 'Pilih Kategori',
            onPressed: () => _showCategoryFilterBottomSheet(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryBlue,
          dividerColor: Colors.transparent,
          isScrollable: true,
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: 'SEDANG MENONTON'),
            Tab(text: 'SELESAI'),
            Tab(text: 'RENCANA DITONTON'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDaftarTab('Sedang Menonton'),
          _buildDaftarTab('Selesai'),
          _buildDaftarTab('Rencana Ditonton'),
        ],
      ),
    );
  }

  // Modal Bottom Sheet Filter Kategori ('Semua', 'Film', 'Drama', 'Animasi')
  void _showCategoryFilterBottomSheet(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF1E2129) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final Color primaryBlue = const Color(0xFF0094FF);

    final List<String> categories = ['Semua', 'Film', 'Drama', 'Animasi'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Material(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Padding(
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

                // Judul 'Pilih Kategori'
                Text(
                  'Pilih Kategori',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Deretan ListTile sederhana untuk opsi: 'Semua', 'Film', 'Drama', dan 'Animasi'
                ...categories.map((category) {
                  final bool isSelected = _selectedCategory == category;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? primaryBlue : textColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_rounded, color: primaryBlue, size: 20)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                      context.pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDaftarTab(String statusFilter) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = isDark ? const Color(0xFF1F222A) : Colors.white;
    Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    Color subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    Color primaryBlue = const Color(0xFF0094FF);

    return ValueListenableBuilder<List<Drama>>(
      valueListenable: SharedData.dramaListNotifier,
      builder: (context, dramaList, _) {
        
        List<Drama> filteredList = dramaList.where((item) {
          // Filter Status Tab
          if (item.status != statusFilter) return false;

          // Logika Pencarian
          if (_searchQuery.isNotEmpty &&
              !item.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
            return false;
          }

          // Logika Kategori Ketat
          if (_selectedCategory == 'Film' && item.mediaType != 'movie') return false;
          if (_selectedCategory == 'Drama' && item.mediaType != 'tv') return false;
          if (_selectedCategory == 'Animasi' &&
              (item.genreIds.contains(16) == false &&
                  !item.genre.toLowerCase().contains('animasi') &&
                  !item.genre.toLowerCase().contains('anime'))) {
            return false;
          }

          return true;
        }).toList();

        // Sorting lokal watchlist (menggunakan list.sort())
        if (_selectedSort == 'Peringkat Teratas' || _selectedSort == 'Rating Tertinggi') {
          filteredList.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
        } else if (_selectedSort == 'Paling Populer' || _selectedSort == 'Kepopuleran') {
          filteredList.sort((a, b) {
            double popA = double.tryParse(a.popularity.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
            double popB = double.tryParse(b.popularity.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
            if (popA != popB) return popB.compareTo(popA);
            return b.popularity.compareTo(a.popularity);
          });
        } else if (_selectedSort == 'Tahun Rilis') {
          filteredList.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
        } else if (_selectedSort == 'Baru Ditambahkan') {
          filteredList.sort((a, b) {
            if (a.dateCompleted != null && b.dateCompleted != null) {
              return b.dateCompleted!.compareTo(a.dateCompleted!);
            } else if (b.dateCompleted != null) {
              return 1;
            } else if (a.dateCompleted != null) {
              return -1;
            }
            return b.id.compareTo(a.id);
          });
        }

        if (filteredList.isEmpty) {
          if (_searchQuery.trim().isNotEmpty) {
            return RefreshIndicator(
              onRefresh: _fetchWatchlist,
              color: primaryBlue,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Center(
                      child: Text(
                        'Film/Drama tidak ditemukan',
                        style: TextStyle(color: subTextColor, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          if (_selectedCategory != 'Semua') {
            return RefreshIndicator(
              onRefresh: _fetchWatchlist,
              color: primaryBlue,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Center(
                      child: Text(
                        'Tidak ada $_selectedCategory yang cocok',
                        style: TextStyle(color: subTextColor, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _fetchWatchlist,
            color: primaryBlue,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.movie_creation_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada judul di daftar ini',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Belum ada film di daftar ini. Yuk, cari dan tambahkan film favoritmu!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _fetchWatchlist,
          color: primaryBlue,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final Drama item = filteredList[index];
              
              // Tampilkan nilai rating pribadi yang ditarik langsung dari Supabase
              // Fallback: jika nilai rating dari Supabase adalah null, tampilkan 0.0
              final double userRatingVal = item.userRating ?? item.myRating ?? 0.0;
              final String displayRating = userRatingVal.toStringAsFixed(1);

              final String effectivePoster = item.image.isNotEmpty
                  ? item.image
                  : (_posterCache[item.id] ?? '');

              if (effectivePoster.isEmpty && item.id > 0 && !_loadingPosters.contains(item.id)) {
                _loadingPosters.add(item.id);
                _apiService.getMovieDetails(item.id, mediaType: item.mediaType).then((detail) {
                  if (detail.image.isNotEmpty) {
                    _posterCache[item.id] = detail.image;
                    item.image = detail.image;
                  }
                  if (detail.episodes > 0 && item.episodes == 0) {
                    _episodesCache[item.id] = detail.episodes;
                    item.episodes = detail.episodes;
                  }
                  if (mounted) setState(() {});
                }).catchError((_) {}).whenComplete(() {
                  _loadingPosters.remove(item.id);
                });
              }

              final String heroTag = 'poster_${item.id > 0 ? item.id : item.title}';
              final bool isTvSeries = item.mediaType == 'tv' ||
                  (!item.isMovie && item.mediaType != 'movie' && !item.genre.toLowerCase().contains('film'));

              return GestureDetector(
                onTap: () {
                  context.push(
                    '/movie/${item.id}',
                    extra: {
                      'drama': item,
                      'heroTag': heroTag,
                      'posterUrl': effectivePoster.isNotEmpty ? effectivePoster : item.image,
                    },
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  // Tampilan card melayang (elevated) dengan bayangan lembut
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.35)
                            : primaryBlue.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // POSTER DENGAN HERO ANIMATION
                      Hero(
                        tag: heroTag,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: effectivePoster.isNotEmpty
                              ? Image.network(
                                  effectivePoster,
                                  width: 72, 
                                  height: 108, 
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 72, 
                                    height: 108, 
                                    color: isDark ? const Color(0xFF222734) : Colors.grey.shade300,
                                    child: const Icon(Icons.movie_rounded, color: Colors.grey),
                                  ),
                                )
                              : (item.id > 0
                                  ? Container(
                                      width: 72,
                                      height: 108,
                                      color: isDark ? const Color(0xFF222734) : Colors.grey.shade300,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 72, 
                                      height: 108, 
                                      color: isDark ? const Color(0xFF222734) : Colors.grey.shade300,
                                      child: const Icon(Icons.movie_rounded, color: Colors.grey),
                                    )),
                        ),
                      ),
                      const SizedBox(width: 14),
                      
                      // KONTEN KANAN
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                          getDynamicLabel(drama: item),
                                          style: TextStyle(color: subTextColor, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 8),
                                      if (statusFilter == 'Selesai' || item.status == 'Selesai')
                                        // BARIS INFORMASI KHUSUS STATUS SELESAI
                                        Row(
                                          children: [
                                            // Bagian 1: Rating
                                            const Icon(Icons.star, color: Colors.amber, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              displayRating,
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 16),

                                            // Bagian 2: Episode (Kondisional: HANYA JIKA Serial TV / Drama dan episode > 0)
                                            if (isTvSeries && item.episodes > 0) ...[
                                              Icon(Icons.featured_play_list, color: subTextColor, size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${item.episodes}',
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                            ],

                                            // Bagian 3: Tanggal Selesai (Format: dd/MM/yyyy, misal: '16/10/2026')
                                            Icon(Icons.calendar_today, color: subTextColor, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              formatDate(item.dateCompleted ?? DateTime.now()),
                                              style: TextStyle(
                                                color: subTextColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        )
                                      else if (statusFilter == 'Rencana Ditonton' || item.status == 'Rencana Ditonton')
                                        // BARIS INFORMASI KHUSUS STATUS RENCANA DITONTON (Rating + Ikon Abu-abu & Total Episode)
                                        Row(
                                          children: [
                                            // Kiri: Ikon Bintang Emas dan teks Rating
                                            const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              displayRating,
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),

                                            // Kanan (Khusus Drama / Serial): Ikon abu-abu + Angka total episode jika > 0
                                            if (isTvSeries && item.episodes > 0) ...[
                                              const SizedBox(width: 16),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.subtitles_rounded,
                                                    size: 18.0,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${item.episodes}',
                                                    style: TextStyle(
                                                      color: isDark ? Colors.white : textColor,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        )
                                      else
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              displayRating,
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (isTvSeries && item.episodes > 0) ...[
                                              const SizedBox(width: 16),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.featured_play_list,
                                                    size: 16.0,
                                                    color: subTextColor,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${item.episodes}',
                                                    style: TextStyle(
                                                      color: textColor,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                // TOMBOL EDIT (PENA)
                                GestureDetector(
                                  onTap: () async {
                                    await showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => EditDramaModal(
                                        drama: item,
                                        apiService: _apiService,
                                      ),
                                    );
                                    if (mounted) setState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100, 
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Icon(Icons.edit_outlined, color: subTextColor, size: 18),
                                  ),
                                ),
                              ],
                            ),
                            
                            // HANYA UNTUK STATUS 'Sedang Menonton' (Bukan Selesai dan Bukan Rencana Ditonton)
                            if (statusFilter == 'Sedang Menonton' ||
                                (statusFilter != 'Selesai' &&
                                    statusFilter != 'Rencana Ditonton' &&
                                    item.status == 'Sedang Menonton')) ...[
                              if (isTvSeries) ...[
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.episodes > 0
                                          ? 'Progres: ${item.watchedEpisodes}/${item.episodes}'
                                          : 'Progres: ${item.watchedEpisodes} Eps', 
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${item.progressPercentInt}%',
                                      style: TextStyle(
                                        color: statusFilter == 'Sedang Menonton' ? primaryBlue : subTextColor,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),
                                
                                // GARIS PROGRESS BAR
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: item.progressPercentage,
                                    backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      statusFilter == 'Sedang Menonton' ? primaryBlue : Colors.grey.shade600,
                                    ),
                                    minHeight: 3,
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

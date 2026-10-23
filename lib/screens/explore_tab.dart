import 'package:flutter/material.dart';
import '../routes/app_router.dart';
import '../widgets/app_drawer.dart';
import '../models/drama.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';
import 'decade_explore_page.dart';

class ExploreTab extends StatefulWidget {
  final ApiService? apiService;
  const ExploreTab({super.key, this.apiService});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final ApiService _apiService;

  // State Filter Genre (Global di AppBar)
  int? _selectedGenreId;

  // State Sub-Filter Bahasa/Negara per Tab
  String? _selectedDramaLanguage;
  String? _selectedFilmLanguage;
  String? _selectedAnimationLanguage;

  // Futures untuk Tab UNTUK ANDA
  late Future<List<Drama>> _trendingWeekFuture;
  late Future<List<Drama>> _topRatedFuture;
  late Future<List<Drama>> _trendingDayFuture;
  late Future<List<Drama>> _upcomingFuture;
  Future<List<Drama>>? _koreanDramasFuture;
  Future<List<Drama>>? _koreanMoviesFuture;
  Future<List<Drama>>? _westernMoviesFuture;

  // Futures untuk Tab DRAMA
  Future<List<Drama>>? _dramasPopulerFuture;
  Future<List<Drama>>? _japaneseDramasFuture;
  Future<List<Drama>>? _westernDramasFuture;
  Future<List<Drama>>? _dramaFilteredMainFuture;
  Future<List<Drama>>? _dramaFilteredSubFuture;

  // Futures untuk Tab FILM
  Future<List<Drama>>? _moviesPopulerFuture;
  Future<List<Drama>>? _japaneseMoviesFuture;
  Future<List<Drama>>? _filmFilteredMainFuture;
  Future<List<Drama>>? _filmFilteredSubFuture;

  // Futures untuk Tab ANIMASI
  Future<List<Drama>>? _animationTvFuture;
  Future<List<Drama>>? _animationMoviesFuture;

  // Daftar Opsi Genre untuk Bottom Sheet di AppBar
  static const List<Map<String, dynamic>> _genreList = [
    {'name': 'Semua Genre', 'id': null},
    {'name': 'Aksi', 'id': 28},
    {'name': 'Komedi', 'id': 35},
    {'name': 'Horor', 'id': 27},
    {'name': 'Romantis', 'id': 10749},
    {'name': 'Crime', 'id': 80},
    {'name': 'Drama', 'id': 18},
    {'name': 'Animasi', 'id': 16},
    {'name': 'Fantasi', 'id': 14},
    {'name': 'Misteri', 'id': 9648},
    {'name': 'Sci-Fi', 'id': 878},
    {'name': 'Thriller', 'id': 53},
  ];

  // Daftar Opsi Sub-Filter Negara di Tab FILM
  static const List<Map<String, dynamic>> _filmFilters = [
    {'label': 'Semua', 'code': null},
    {'label': 'Indonesia', 'code': 'id'},
    {'label': 'Barat', 'code': 'en'},
    {'label': 'Korea', 'code': 'ko'},
    {'label': 'Jepang', 'code': 'ja'},
  ];

  // Daftar Opsi Sub-Filter Negara di Tab DRAMA
  static const List<Map<String, dynamic>> _dramaFilters = [
    {'label': 'Semua', 'code': null},
    {'label': 'Korea', 'code': 'ko'},
    {'label': 'Jepang', 'code': 'ja'},
    {'label': 'Barat', 'code': 'en'},
    {'label': 'China/Thai', 'code': 'zh|th'},
  ];

  // Daftar Opsi Sub-Filter Kategori di Tab ANIMASI
  static const List<Map<String, dynamic>> _animationFilters = [
    {'label': 'Semua', 'code': null},
    {'label': 'Anime (Jepang)', 'code': 'ja'},
    {'label': 'Kartun Barat', 'code': 'en'},
    {'label': 'Donghua (China)', 'code': 'zh'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _apiService = widget.apiService ?? ApiService();

    _fetchUntukAndaData();
    _fetchDramaData();
    _fetchFilmData();
    _fetchAnimationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchUntukAndaData() {
    _trendingWeekFuture = _apiService.getTrendingAllWeek();
    _topRatedFuture = _apiService.getTopRatedMovies(genreId: _selectedGenreId);
    _trendingDayFuture = _apiService.getTrendingAllMix();
    _upcomingFuture = _apiService.getMovieUpcoming();
  }

  void _fetchDramaData() {
    if (_selectedDramaLanguage == null) {
      _dramasPopulerFuture = _apiService.getDramas(genreId: _selectedGenreId);
      _koreanDramasFuture =
          _apiService.getKoreanDramas(genreId: _selectedGenreId);
      _japaneseDramasFuture =
          _apiService.getJapaneseDramas(genreId: _selectedGenreId);
      _westernDramasFuture =
          _apiService.getWesternDramas(genreId: _selectedGenreId);
    } else {
      _dramaFilteredMainFuture = _apiService.getDramas(
        genreId: _selectedGenreId,
        originalLanguage: _selectedDramaLanguage,
      );
      if (_selectedDramaLanguage == 'ko') {
        _dramaFilteredSubFuture =
            _apiService.getKoreanDramas(genreId: _selectedGenreId);
      } else if (_selectedDramaLanguage == 'ja') {
        _dramaFilteredSubFuture =
            _apiService.getJapaneseDramas(genreId: _selectedGenreId);
      } else if (_selectedDramaLanguage == 'en') {
        _dramaFilteredSubFuture =
            _apiService.getWesternDramas(genreId: _selectedGenreId);
      } else {
        _dramaFilteredSubFuture = _apiService.getDiscoverTvByLanguage(
          originalLanguage: _selectedDramaLanguage,
          genreId: _selectedGenreId,
          sortBy: 'vote_average.desc',
        );
      }
    }
  }

  void _fetchFilmData() {
    if (_selectedFilmLanguage == null) {
      _moviesPopulerFuture = _apiService.getMovies(genreId: _selectedGenreId);
      _koreanMoviesFuture =
          _apiService.getKoreanMovies(genreId: _selectedGenreId);
      _japaneseMoviesFuture =
          _apiService.getJapaneseMovies(genreId: _selectedGenreId);
      _westernMoviesFuture =
          _apiService.getWesternMovies(genreId: _selectedGenreId);
    } else {
      _filmFilteredMainFuture = _apiService.getMovies(
        genreId: _selectedGenreId,
        originalLanguage: _selectedFilmLanguage,
      );
      if (_selectedFilmLanguage == 'id') {
        _filmFilteredSubFuture = _apiService.getDiscoverMoviesByLanguage(
          originalLanguage: 'id',
          genreId: _selectedGenreId,
          sortBy: 'vote_average.desc',
        );
      } else if (_selectedFilmLanguage == 'en') {
        _filmFilteredSubFuture =
            _apiService.getWesternMovies(genreId: _selectedGenreId);
      } else if (_selectedFilmLanguage == 'ko') {
        _filmFilteredSubFuture =
            _apiService.getKoreanMovies(genreId: _selectedGenreId);
      } else if (_selectedFilmLanguage == 'ja') {
        _filmFilteredSubFuture =
            _apiService.getJapaneseMovies(genreId: _selectedGenreId);
      } else {
        _filmFilteredSubFuture = _apiService.getDiscoverMoviesByLanguage(
          originalLanguage: _selectedFilmLanguage,
          genreId: _selectedGenreId,
          sortBy: 'vote_average.desc',
        );
      }
    }
  }

  void _fetchAnimationData() {
    _animationTvFuture = _apiService.getAnimationTvShows(
      originalLanguage: _selectedAnimationLanguage,
      genreId: _selectedGenreId,
    );
    _animationMoviesFuture = _apiService.getAnimationMovies(
      originalLanguage: _selectedAnimationLanguage,
      genreId: _selectedGenreId,
    );
  }

  void _refreshAllTabsData() {
    _fetchUntukAndaData();
    _fetchDramaData();
    _fetchFilmData();
    _fetchAnimationData();
  }

  void _showGenreFilterBottomSheet() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color sheetBg = isDark ? const Color(0xFF1F222A) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final Color primaryBlue = const Color(0xFF0094FF);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pilih Genre',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_selectedGenreId != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedGenreId = null;
                                _refreshAllTabsData();
                              });
                              modalContext.pop();
                            },
                            child: Text(
                              'Reset Filter',
                              style: TextStyle(
                                color: primaryBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: _genreList.map((genre) {
                        final String name = genre['name'] as String;
                        final int? id = genre['id'] as int?;
                        final bool isSelected = _selectedGenreId == id;

                        return ChoiceChip(
                          label: Text(name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (isSelected && id != null) {
                                _selectedGenreId = null;
                              } else {
                                _selectedGenreId = id;
                              }
                              _refreshAllTabsData();
                            });
                            modalContext.pop();
                          },
                          selectedColor: primaryBlue,
                          backgroundColor: isDark
                              ? const Color(0xFF262A34)
                              : Colors.grey.shade100,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : textColor,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? primaryBlue
                                  : (isDark
                                      ? const Color(0xFF353A47)
                                      : Colors.grey.shade300),
                            ),
                          ),
                          showCheckmark: false,
                        );
                      }).toList(),
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

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = isDark ? const Color(0xFF15171E) : const Color(0xFFF8F9FA);
    Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    Color primaryBlue = const Color(0xFF0094FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          'Jelajahi',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          // 1. Ikon Pencarian (pertama / lebih kiri)
          IconButton(
            icon: Icon(Icons.search, color: textColor),
            onPressed: () {
              context.push('/search');
            },
          ),
          // 2. Ikon Filter/Kategori Genre (kedua / paling kanan)
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.tune,
                  color: _selectedGenreId != null ? primaryBlue : textColor,
                ),
                if (_selectedGenreId != null)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Pilih Genre',
            onPressed: _showGenreFilterBottomSheet,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryBlue,
          dividerColor: Colors.transparent,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'UNTUK ANDA'),
            Tab(text: 'DRAMA'),
            Tab(text: 'FILM'),
            Tab(text: 'ANIMASI'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      // 1. Deretan tombol genre horizontal di layar utama telah dihapus
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Tab UNTUK ANDA (Mix TMDB & Rekomendasi)
          _buildUntukAndaTab(textColor, primaryBlue, isDark),

          // 2. Tab DRAMA (Populer, Korea, Jepang, Barat, China/Thai dengan Sub-Filter)
          _buildDramaTab(textColor, primaryBlue, isDark),

          // 3. Tab FILM (Bioskop, Indonesia, Barat, Korea, Jepang dengan Sub-Filter)
          _buildFilmTab(textColor, primaryBlue, isDark),

          // 4. Tab ANIMASI (Anime & Animasi Global dengan Sub-Filter)
          _buildAnimasiTab(textColor, primaryBlue, isDark),
        ],
      ),
    );
  }

  // ===========================================================================
  // WIDGET TAB: UNTUK ANDA
  // ===========================================================================
  Widget _buildUntukAndaTab(Color textColor, Color primaryBlue, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // 1. Baris Kategori: Paling Banyak Ditambahkan Minggu Ini (/trending/all/week)
          _buildHorizontalApiSection(
            title: 'Paling Banyak Ditambahkan Minggu Ini',
            future: _trendingWeekFuture,
            textColor: textColor,
            primaryBlue: primaryBlue,
            hideIfEmpty: true,
          ),

          // 2. Baris Kategori: Rekomendasi Untuk Anda (/movie/top_rated atau /discover/movie)
          _buildHorizontalApiSection(
            title: 'Rekomendasi Untuk Anda',
            future: _topRatedFuture,
            textColor: textColor,
            primaryBlue: primaryBlue,
            hideIfEmpty: true,
          ),

          // 3. Baris Kategori: Trending Hari Ini (/trending/all/day)
          _buildHorizontalApiSection(
            title: 'Trending Hari Ini',
            future: _trendingDayFuture,
            textColor: textColor,
            primaryBlue: primaryBlue,
            hideIfEmpty: true,
          ),

          // 4. Baris Kategori: Segera Hadir (/discover/movie)
          // Khusus kategori ini: tampilkan release_date di bawah judul/poster
          _buildHorizontalApiSection(
            title: 'Segera Hadir',
            future: _upcomingFuture,
            textColor: textColor,
            primaryBlue: primaryBlue,
            hideIfEmpty: true,
            showReleaseDate: true,
          ),

          // Seksi: Jelajahi Berdasarkan Dekade (Browse by Decade) - Paling Bawah
          _buildDecadeSection(textColor, primaryBlue, isDark),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ===========================================================================
  // WIDGET SEKSI: JELAJAHI BERDASARKAN DEKADE (BROWSE BY DECADE)
  // ===========================================================================
  Widget _buildDecadeSection(Color textColor, Color primaryBlue, bool isDark) {
    const List<String> decades = [
      '2020s',
      '2010s',
      '2000s',
      '1990s',
      '1980s',
      '1970s',
      '1960s',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Jelajahi Berdasarkan Dekade',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: decades.map((decade) {
              return Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DecadeExplorePage(
                          decade: decade,
                          apiService: _apiService,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1F222A)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2E3340)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      decade,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }



  // ===========================================================================
  // WIDGET TAB: DRAMA DENGAN SUB-FILTER NEGARA DINAMIS
  // ===========================================================================
  Widget _buildDramaTab(Color textColor, Color primaryBlue, bool isDark) {
    String mainTitle = 'Drama Populer TV';
    String subTitle = 'Rekomendasi Drama Populer';

    if (_selectedDramaLanguage == 'ko') {
      mainTitle = 'Drama Korea Populer';
      subTitle = 'Serial Drakor Pilihan';
    } else if (_selectedDramaLanguage == 'ja') {
      mainTitle = 'Drama Jepang Pilihan';
      subTitle = 'Serial Dorama Populer';
    } else if (_selectedDramaLanguage == 'en') {
      mainTitle = 'Drama Barat Populer';
      subTitle = 'Serial TV Barat Pilihan';
    } else if (_selectedDramaLanguage == 'zh|th') {
      mainTitle = 'Drama China & Thai Populer';
      subTitle = 'Serial Drama Asia Pilihan';
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // 3. Sub-Filter Negara Dinamis per Tab
          _buildFilterChipBar(
            filters: _dramaFilters,
            selectedCode: _selectedDramaLanguage,
            onSelected: (code) {
              setState(() {
                _selectedDramaLanguage = code;
                _fetchDramaData();
              });
            },
            isDark: isDark,
            textColor: textColor,
            primaryBlue: primaryBlue,
          ),
          const SizedBox(height: 8),

          if (_selectedDramaLanguage == null) ...[
            _buildHorizontalApiSection(
              title: 'Drama Populer TV',
              future: _dramasPopulerFuture!,
              textColor: textColor,
              primaryBlue: primaryBlue,
            ),
            _buildHorizontalApiSection(
              title: 'Drama Korea Populer',
              future: _koreanDramasFuture!,
              textColor: textColor,
              primaryBlue: primaryBlue,
              hideIfEmpty: true,
            ),
            _buildHorizontalApiSection(
              title: 'Drama Jepang Pilihan',
              future: _japaneseDramasFuture!,
              textColor: textColor,
              primaryBlue: primaryBlue,
              hideIfEmpty: true,
            ),
            _buildHorizontalApiSection(
              title: 'Drama Barat Populer',
              future: _westernDramasFuture!,
              textColor: textColor,
              primaryBlue: primaryBlue,
              hideIfEmpty: true,
            ),
          ] else ...[
            _buildHorizontalApiSection(
              title: mainTitle,
              future: _dramaFilteredMainFuture!,
              textColor: textColor,
              primaryBlue: primaryBlue,
            ),
            _buildHorizontalApiSection(
              title: subTitle,
              future: _dramaFilteredSubFuture!,
              textColor: textColor,
              primaryBlue: primaryBlue,
              hideIfEmpty: true,
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ===========================================================================
  // WIDGET TAB: FILM DENGAN SUB-FILTER NEGARA DINAMIS
  // ===========================================================================
  Widget _buildFilmTab(Color textColor, Color primaryBlue, bool isDark) {
    String mainMovieTitle = 'Film Bioskop Populer';
    String subMovieTitle = 'Rekomendasi Film Populer';

    if (_selectedFilmLanguage == 'id') {
      mainMovieTitle = 'Film Indonesia Populer';
      subMovieTitle = 'Rekomendasi Film Indonesia';
    } else if (_selectedFilmLanguage == 'en') {
      mainMovieTitle = 'Film Barat Populer';
      subMovieTitle = 'Film Barat Pilihan';
    } else if (_selectedFilmLanguage == 'ko') {
      mainMovieTitle = 'Film Korea Pilihan';
      subMovieTitle = 'Film Korea Populer';
    } else if (_selectedFilmLanguage == 'ja') {
      mainMovieTitle = 'Film Jepang Pilihan';
      subMovieTitle = 'Film Jepang Populer';
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // 3. Sub-Filter Negara Dinamis per Tab
          _buildFilterChipBar(
            filters: _filmFilters,
            selectedCode: _selectedFilmLanguage,
            onSelected: (code) {
              setState(() {
                _selectedFilmLanguage = code;
                _fetchFilmData();
              });
            },
            isDark: isDark,
            textColor: textColor,
            primaryBlue: primaryBlue,
          ),
          const SizedBox(height: 8),

          if (_selectedFilmLanguage == null) ...[
            _buildHorizontalApiSection(
              title: 'Film Bioskop Populer',
              future: _moviesPopulerFuture!,
              textColor: textColor,
              primaryBlue: primaryBlue,
            ),
            _buildHorizontalApiSection(
              title: 'Film Korea Pilihan',
              future: _koreanMoviesFuture!,
              textColor: textColor,
              primaryBlue: primaryBlue,
              hideIfEmpty: true,
            ),
            _buildHorizontalApiSection(
              title: 'Film Jepang Pilihan',
              future: _japaneseMoviesFuture!,
              textColor: textColor,
              primaryBlue: primaryBlue,
              hideIfEmpty: true,
            ),
            _buildHorizontalApiSection(
              title: 'Film Barat Populer',
              future: _westernMoviesFuture!,
              textColor: textColor,
              primaryBlue: primaryBlue,
              hideIfEmpty: true,
            ),
          ] else ...[
            _buildHorizontalApiSection(
              title: mainMovieTitle,
              future: _filmFilteredMainFuture!,
              textColor: textColor,
              primaryBlue: primaryBlue,
            ),
            _buildHorizontalApiSection(
              title: subMovieTitle,
              future: _filmFilteredSubFuture!,
              textColor: textColor,
              primaryBlue: primaryBlue,
              hideIfEmpty: true,
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ===========================================================================
  // WIDGET TAB: ANIMASI (GLOBAL & SUB-FILTER KATEGORI)
  // ===========================================================================
  Widget _buildAnimasiTab(Color textColor, Color primaryBlue, bool isDark) {
    String tvTitle = 'Anime Populer';
    String movieTitle = 'Film Animasi Bioskop';

    if (_selectedAnimationLanguage == 'ja') {
      tvTitle = 'Anime Populer (Jepang)';
      movieTitle = 'Film Anime Jepang';
    } else if (_selectedAnimationLanguage == 'en') {
      tvTitle = 'Serial Kartun Barat';
      movieTitle = 'Film Animasi Barat';
    } else if (_selectedAnimationLanguage == 'zh') {
      tvTitle = 'Serial Donghua (China)';
      movieTitle = 'Film Donghua (China)';
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // 3. Sub-Filter Animasi Dinamis
          _buildFilterChipBar(
            filters: _animationFilters,
            selectedCode: _selectedAnimationLanguage,
            onSelected: (code) {
              setState(() {
                _selectedAnimationLanguage = code;
                _fetchAnimationData();
              });
            },
            isDark: isDark,
            textColor: textColor,
            primaryBlue: primaryBlue,
          ),
          const SizedBox(height: 8),
          _buildHorizontalApiSection(
            title: tvTitle,
            future: _animationTvFuture!,
            textColor: textColor,
            primaryBlue: primaryBlue,
          ),
          _buildHorizontalApiSection(
            title: movieTitle,
            future: _animationMoviesFuture!,
            textColor: textColor,
            primaryBlue: primaryBlue,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ===========================================================================
  // WIDGET SUB-FILTER HORIZONTAL CHOICE CHIP
  // ===========================================================================
  Widget _buildFilterChipBar({
    required List<Map<String, dynamic>> filters,
    required String? selectedCode,
    required ValueChanged<String?> onSelected,
    required bool isDark,
    required Color textColor,
    required Color primaryBlue,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: filters.map((filter) {
          final String label = filter['label'] as String;
          final String? code = filter['code'] as String?;
          final bool isSelected = selectedCode == code;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (bool selected) {
                if (selected && selectedCode != code) {
                  onSelected(code);
                }
              },
              selectedColor: primaryBlue,
              backgroundColor:
                  isDark ? const Color(0xFF1F222A) : Colors.grey.shade200,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? primaryBlue
                      : (isDark
                          ? const Color(0xFF2E3340)
                          : Colors.grey.shade300),
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===========================================================================
  // WIDGET: SEKSI API HORIZONTAL DENGAN FUTUREBUILDER
  // ===========================================================================
  Widget _buildHorizontalApiSection({
    required String title,
    required Future<List<Drama>> future,
    required Color textColor,
    required Color primaryBlue,
    bool hideIfEmpty = false,
    bool showReleaseDate = false,
  }) {
    return FutureBuilder<List<Drama>>(
      future: future,
      builder: (context, snapshot) {
        final List<Drama> items = snapshot.data ?? [];

        if (hideIfEmpty &&
            snapshot.connectionState == ConnectionState.done &&
            items.isEmpty) {
          return const SizedBox.shrink();
        }

        void onSeeAll() {
          if (items.isNotEmpty) {
            context.push(
              '/see-all',
              extra: {
                'title': title,
                'dramaList': items,
              },
            );
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(title, textColor, primaryBlue, onSeeAll),
            if (snapshot.connectionState == ConnectionState.waiting)
              SizedBox(
                height: MediaQuery.of(context).size.width > 800 ? 280.0 : 220.0,
                child: Center(
                  child: CircularProgressIndicator(color: primaryBlue),
                ),
              )
            else if (snapshot.hasError)
              SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    'Gagal memuat $title',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else if (items.isEmpty)
              SizedBox(
                height: 80,
                child: Center(
                  child: Text(
                    'Tidak ada data untuk $title',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else
              _buildHorizontalList(
                items,
                textColor,
                section: title,
                onSeeAll: onSeeAll,
                showReleaseDate: showReleaseDate,
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // WIDGET PEMBANTU (HEADER & HORIZONTAL LIST)
  // ===========================================================================
  Widget _buildSectionHeader(
      String title, Color textColor, Color primaryBlue, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: onSeeAll,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalList(
    List<Drama> list,
    Color textColor, {
    String section = 'explore',
    VoidCallback? onSeeAll,
    bool showReleaseDate = false,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = screenWidth > 800 ? 160.0 : 120.0;
    final double listHeight = screenWidth > 800 ? 280.0 : 220.0;
    final double imageHeight = screenWidth > 800 ? 220.0 : 170.0;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final String cleanSection = section
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    final VoidCallback effectiveOnSeeAll = onSeeAll ??
        () {
          if (list.isNotEmpty) {
            context.push(
              '/see-all',
              extra: {
                'title': section,
                'dramaList': list,
              },
            );
          }
        };

    return SizedBox(
      height: listHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: list.isEmpty ? 0 : list.length + 1,
        itemBuilder: (context, index) {
          // Tombol 'Lihat Semua' di ujung kanan daftar (akhir scroll)
          if (index == list.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 4, right: 8),
                child: InkWell(
                  onTap: effectiveOnSeeAll,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF262A37)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: isDark
                            ? Colors.white12
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      'Lihat Semua',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          final Drama item = list[index];
          final String heroTag =
              'explore_${cleanSection}_${item.id > 0 ? item.id : item.title}';

          return GestureDetector(
            onTap: () {
              context.push(
                '/movie/${item.id}',
                extra: {
                  'drama': item,
                  'apiService': _apiService,
                  'heroTag': heroTag,
                  'posterUrl': item.image,
                },
              );
            },
            child: Container(
              width: cardWidth,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Hero(
                        tag: heroTag,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: (item.image.isNotEmpty)
                              ? Image.network(
                                  item.image,
                                  height: imageHeight,
                                  width: cardWidth,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    height: imageHeight,
                                    width: cardWidth,
                                    color: Colors.grey.shade800,
                                    child: const Icon(Icons.movie,
                                        color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  height: imageHeight,
                                  width: cardWidth,
                                  color: Colors.grey.shade800,
                                  child: const Icon(Icons.movie,
                                      color: Colors.grey),
                                ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 12),
                              const SizedBox(width: 4),
                              Text(item.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(item.title,
                      style: TextStyle(
                          color: textColor,
                          fontSize: screenWidth > 800 ? 14 : 13,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                      showReleaseDate
                          ? (item.releaseDate.isNotEmpty
                              ? item.releaseDate
                              : getDynamicLabel(drama: item))
                          : getDynamicLabel(drama: item),
                      style: TextStyle(
                        color: showReleaseDate
                            ? const Color(0xFF0094FF)
                            : Colors.grey,
                        fontSize: 11,
                        fontWeight: showReleaseDate
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

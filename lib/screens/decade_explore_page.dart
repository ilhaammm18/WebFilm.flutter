import 'package:flutter/material.dart';
import '../routes/app_router.dart';
import '../models/drama.dart';
import '../services/api_service.dart';

class _GenreConfig {
  final String title;
  final int id;
  const _GenreConfig({required this.title, required this.id});
}

class DecadeExplorePage extends StatefulWidget {
  final String decade;
  final String? startDate;
  final String? endDate;
  final int? year;
  final ApiService? apiService;

  const DecadeExplorePage({
    super.key,
    required this.decade,
    this.startDate,
    this.endDate,
    this.year,
    this.apiService,
  });

  @override
  State<DecadeExplorePage> createState() => _DecadeExplorePageState();
}

class _DecadeExplorePageState extends State<DecadeExplorePage> {
  late final ApiService _apiService;
  late Future<List<Drama>> _popularMoviesFuture;
  late Map<int, Future<List<Drama>>> _genreFutures;

  late final String _startDate;
  late final String _endDate;
  late List<int> _availableYears;
  int? _selectedYear;

  static const List<_GenreConfig> _genreCategories = [
    _GenreConfig(title: 'Populer di Aksi', id: 28),
    _GenreConfig(title: 'Populer di Komedi', id: 35),
    _GenreConfig(title: 'Populer di Romantis', id: 10749),
    _GenreConfig(title: 'Populer di Horor', id: 27),
    _GenreConfig(title: 'Populer di Thriller', id: 53),
    _GenreConfig(title: 'Populer di Crime', id: 80),
    _GenreConfig(title: 'Populer di Drama', id: 18),
    _GenreConfig(title: 'Populer di Animasi', id: 16),
    _GenreConfig(title: 'Sci-Fi & Fantasi', id: 878),
    _GenreConfig(title: 'Populer di Fantasi', id: 14),
    _GenreConfig(title: 'Populer di Misteri', id: 9648),
  ];

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();

    final range = _resolveDateRange(widget.decade, widget.startDate, widget.endDate);
    _startDate = range.startDate;
    _endDate = range.endDate;

    _availableYears = _calculateYearsForDecade(widget.decade);
    if (widget.year != null && _availableYears.contains(widget.year)) {
      _selectedYear = widget.year;
    } else if (int.tryParse(widget.decade.trim()) != null &&
        _availableYears.contains(int.parse(widget.decade.trim()))) {
      _selectedYear = int.parse(widget.decade.trim());
    }

    _loadData();
  }

  List<int> _calculateYearsForDecade(String decadeStr) {
    final match = RegExp(r'^(\d{4})').firstMatch(decadeStr.trim());
    final int startDecade = match != null ? int.parse(match.group(1)!) : 2020;
    final int currentYear = DateTime.now().year;

    final int startYear = (startDecade ~/ 10) * 10;
    int endYear = startYear + 9;
    if (endYear > currentYear) {
      endYear = currentYear;
    }

    final List<int> years = [];
    for (int y = endYear; y >= startYear; y--) {
      years.add(y);
    }
    return years;
  }

  ({String startDate, String endDate}) _resolveDateRange(
    String decade,
    String? start,
    String? end,
  ) {
    if (start != null && end != null && start.isNotEmpty && end.isNotEmpty) {
      return (startDate: start, endDate: end);
    }

    final match = RegExp(r'^(\d{4})s$').firstMatch(decade.trim());
    if (match != null) {
      final startYear = int.parse(match.group(1)!);
      final endYear = startYear + 9;
      return (startDate: '$startYear-01-01', endDate: '$endYear-12-31');
    }

    final singleYearMatch = RegExp(r'^(\d{4})$').firstMatch(decade.trim());
    if (singleYearMatch != null) {
      final y = int.parse(singleYearMatch.group(1)!);
      return (startDate: '$y-01-01', endDate: '$y-12-31');
    }

    return (startDate: '2020-01-01', endDate: '2029-12-31');
  }

  void _loadData() {
    if (_selectedYear != null) {
      _popularMoviesFuture = _apiService.getMoviesByYear(year: _selectedYear!);
      _genreFutures = {
        for (final g in _genreCategories)
          g.id: _apiService.getMoviesByGenre(g.id, year: _selectedYear!),
      };
    } else {
      _popularMoviesFuture = _apiService.getMoviesByDecade(
        startDate: _startDate,
        endDate: _endDate,
        decade: widget.decade,
      );
      _genreFutures = {
        for (final g in _genreCategories)
          g.id: _apiService.getMoviesByGenre(
            g.id,
            decade: widget.decade,
            startDate: _startDate,
            endDate: _endDate,
          ),
      };
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
    await Future.wait([
      _popularMoviesFuture,
      ..._genreFutures.values,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF15171E) : const Color(0xFFF8F9FA);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final Color subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final Color primaryBlue = const Color(0xFF0094FF);

    final String activePeriodLabel = _selectedYear != null
        ? 'Rilis Tahun $_selectedYear'
        : '$_startDate s/d $_endDate';

    final String popularTitle = _selectedYear != null
        ? 'Populer di $_selectedYear'
        : 'Populer di ${widget.decade}';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Film Dekade ${widget.decade}',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              activePeriodLabel,
              style: TextStyle(
                color: subTextColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Horizontal List Tahun Spesifik (Gaya Plex)
          _buildYearSelector(textColor, primaryBlue, isDark),

          // Scrollable Area (Murni Hanya Deretan Carousel Horizontal Saja)
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: primaryBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // 1. Baris 'Populer di [Tahun]' di posisi paling atas
                    _buildHorizontalApiSection(
                      title: popularTitle,
                      future: _popularMoviesFuture,
                      textColor: textColor,
                      primaryBlue: primaryBlue,
                      hideIfEmpty: false,
                    ),

                    // 2. Baris-baris Carousel Genre Horizontal yang Diperluas
                    for (final g in _genreCategories)
                      _buildHorizontalApiSection(
                        title: g.title,
                        future: _genreFutures[g.id]!,
                        textColor: textColor,
                        primaryBlue: primaryBlue,
                        hideIfEmpty: true,
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalApiSection({
    required String title,
    required Future<List<Drama>> future,
    required Color textColor,
    required Color primaryBlue,
    bool hideIfEmpty = false,
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
                'title': _selectedYear != null
                    ? '$title ($_selectedYear)'
                    : '$title (${widget.decade})',
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
                height: 100,
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
                height: 60,
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
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(
      String title, Color textColor, Color primaryBlue, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
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
    String section = 'genre',
    VoidCallback? onSeeAll,
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
          final String releaseYear = item.releaseDate.length >= 4
              ? item.releaseDate.substring(0, 4)
              : (item.date.isNotEmpty ? item.date : '-');
          final String heroTag =
              'decade_${cleanSection}_${item.id > 0 ? item.id : item.title}';

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
                  Text(
                    item.title,
                    style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        releaseYear,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'â€¢ ${item.genre.isNotEmpty ? item.genre : 'Film'}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildYearSelector(Color textColor, Color primaryBlue, bool isDark) {
    if (_availableYears.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF15171E) : const Color(0xFFF8F9FA),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded, size: 14, color: primaryBlue),
                const SizedBox(width: 6),
                Text(
                  'Tahun Rilis di Dekade ${widget.decade}',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    key: const ValueKey('decade_year_all'),
                    onTap: () {
                      if (_selectedYear != null) {
                        setState(() {
                          _selectedYear = null;
                          _loadData();
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedYear == null
                            ? primaryBlue
                            : (isDark ? const Color(0xFF1F222A) : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedYear == null
                              ? primaryBlue
                              : (isDark ? const Color(0xFF2E3340) : Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        'Semua',
                        style: TextStyle(
                          color: _selectedYear == null ? Colors.white : textColor,
                          fontWeight: _selectedYear == null ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                ..._availableYears.map((year) {
                  final bool isSelected = _selectedYear == year;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      key: ValueKey('year_chip_$year'),
                      onTap: () {
                        setState(() {
                          _selectedYear = year;
                          _loadData();
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryBlue
                              : (isDark ? const Color(0xFF1F222A) : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? primaryBlue
                                : (isDark ? const Color(0xFF2E3340) : Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          '$year',
                          style: TextStyle(
                            color: isSelected ? Colors.white : textColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

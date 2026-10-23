import 'package:flutter/material.dart';
import '../routes/app_router.dart';
import '../models/drama.dart';
import '../services/api_service.dart';

class ReleaseSchedulePage extends StatefulWidget {
  final ApiService? apiService;

  const ReleaseSchedulePage({super.key, this.apiService});

  @override
  State<ReleaseSchedulePage> createState() => _ReleaseSchedulePageState();
}

class _ReleaseSchedulePageState extends State<ReleaseSchedulePage> {
  late final ApiService _apiService;

  late Future<List<Drama>> _nowAiringFuture;
  late Future<List<Drama>> _upcomingFuture;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _loadData();
  }

  void _loadData() {
    _nowAiringFuture = _fetchNowAiring().catchError((e) {
      debugPrint('Error loading now airing schedule: $e');
      return <Drama>[];
    });
    _upcomingFuture = _fetchUpcoming().catchError((e) {
      debugPrint('Error loading upcoming movies: $e');
      return <Drama>[];
    });
  }

  Future<void> _refreshNowAiring() async {
    setState(() {
      _nowAiringFuture = _fetchNowAiring().catchError((e) {
        debugPrint('Error loading now airing schedule: $e');
        return <Drama>[];
      });
    });
    await _nowAiringFuture;
  }

  Future<void> _refreshUpcoming() async {
    setState(() {
      _upcomingFuture = _fetchUpcoming().catchError((e) {
        debugPrint('Error loading upcoming movies: $e');
        return <Drama>[];
      });
    });
    await _upcomingFuture;
  }

  Future<List<Drama>> _fetchNowAiring() async {
    final list = await _apiService.getNowAiringSchedule();
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final twoMonthsAgo = now.subtract(const Duration(days: 60));

    // Pastikan tayangan rilis dalam 2 bulan terakhir hingga hari ini (isBefore(tomorrow))
    final filtered = list.where((drama) {
      final rawDate = drama.date.isNotEmpty ? drama.date : drama.aired;
      final releaseDate = DateTime.tryParse(rawDate);
      if (releaseDate == null) return false;
      return releaseDate.isBefore(tomorrow) &&
          (releaseDate.isAfter(twoMonthsAgo) || releaseDate.isAtSameMomentAs(twoMonthsAgo));
    }).toList();

    filtered.sort((a, b) {
      final dateA = DateTime.tryParse(a.date.isNotEmpty ? a.date : a.aired);
      final dateB = DateTime.tryParse(b.date.isNotEmpty ? b.date : b.aired);
      if (dateA != null && dateB != null) {
        final comp = dateB.compareTo(dateA);
        if (comp != 0) return comp;
      }
      return b.rating.compareTo(a.rating);
    });

    return filtered;
  }

  Future<List<Drama>> _fetchUpcoming() async {
    final list = await _apiService.getUpcomingMovies();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter Ganda di Dart (Wajib): Hanya tanggal yang belum rilis atau rilis mulai hari ini
    final filtered = list.where((drama) {
      final rawDate = drama.date.isNotEmpty ? drama.date : drama.aired;
      if (rawDate.trim().isEmpty) return false;
      final releaseDate = DateTime.tryParse(rawDate.trim());
      if (releaseDate == null) return false;
      final releaseDay =
          DateTime(releaseDate.year, releaseDate.month, releaseDate.day);
      return !releaseDay.isBefore(today);
    }).toList();

    // Urutkan berdasarkan tanggal rilis terdekat (ascending) lalu rating
    filtered.sort((a, b) {
      final dateA = DateTime.tryParse(a.date.isNotEmpty ? a.date : a.aired);
      final dateB = DateTime.tryParse(b.date.isNotEmpty ? b.date : b.aired);
      if (dateA != null && dateB != null) {
        final comp = dateA.compareTo(dateB);
        if (comp != 0) return comp;
      }
      return b.rating.compareTo(a.rating);
    });

    return filtered;
  }

  String _formatReleaseDate(String rawDate) {
    if (rawDate.trim().isEmpty) return 'Segera Diumumkan';
    try {
      final parts = rawDate.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final monthNum = int.tryParse(parts[1]) ?? 1;
        final day = int.tryParse(parts[2]) ?? 1;
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
          'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
        ];
        final monthStr = (monthNum >= 1 && monthNum <= 12) ? months[monthNum - 1] : parts[1];
        return '$day $monthStr $year';
      }
    } catch (_) {}
    return rawDate;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF16181F) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E212B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade600;
    const primaryBlue = Color(0xFF0094FF);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text(
            'Jadwal Tayang',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: cardColor,
          foregroundColor: textColor,
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: primaryBlue,
            indicatorWeight: 3,
            labelColor: primaryBlue,
            unselectedLabelColor: subTextColor,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: const [
              Tab(
                icon: Icon(Icons.play_circle_outline, size: 20),
                text: 'Sedang Tayang',
              ),
              Tab(
                icon: Icon(Icons.calendar_month_outlined, size: 20),
                text: 'Segera Hadir',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Sedang Tayang (/tv/on_the_air & /movie/now_playing)
            _buildScheduleList(
              future: _nowAiringFuture,
              onRefresh: _refreshNowAiring,
              isUpcoming: false,
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),

            // Tab 2: Segera Hadir (/movie/upcoming)
            _buildScheduleList(
              future: _upcomingFuture,
              onRefresh: _refreshUpcoming,
              isUpcoming: true,
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList({
    required Future<List<Drama>> future,
    required Future<void> Function() onRefresh,
    required bool isUpcoming,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    const primaryBlue = Color(0xFF0094FF);

    return FutureBuilder<List<Drama>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryBlue),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 56, color: subTextColor),
                  const SizedBox(height: 12),
                  Text(
                    'Gagal memuat jadwal tayang',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Periksa koneksi internet Anda dan coba lagi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subTextColor, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        if (isUpcoming) {
                          _upcomingFuture = _fetchUpcoming().catchError((e) {
                            debugPrint('Error loading upcoming movies: $e');
                            return <Drama>[];
                          });
                        } else {
                          _nowAiringFuture = _fetchNowAiring().catchError((e) {
                            debugPrint('Error loading now airing schedule: $e');
                            return <Drama>[];
                          });
                        }
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

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.movie_filter_outlined, size: 64, color: subTextColor),
                const SizedBox(height: 12),
                Text(
                  isUpcoming
                      ? 'Belum ada jadwal film segera hadir.'
                      : 'Belum ada tayangan saat ini.',
                  style: TextStyle(color: subTextColor, fontSize: 15),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          color: primaryBlue,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final drama = items[index];
              final formattedDate = _formatReleaseDate(drama.date.isNotEmpty ? drama.date : drama.aired);

              return InkWell(
                onTap: () {
                  context.push(
                    '/movie/${drama.id}',
                    extra: drama,
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2E3344) : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster thumbnail
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                        child: SizedBox(
                          width: 100,
                          height: 145,
                          child: drama.image.isNotEmpty
                              ? Image.network(
                                  drama.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: isDark ? const Color(0xFF282C37) : Colors.grey.shade300,
                                    child: Icon(Icons.movie, color: subTextColor, size: 36),
                                  ),
                                )
                              : Container(
                                  color: isDark ? const Color(0xFF282C37) : Colors.grey.shade300,
                                  child: Icon(Icons.movie, color: subTextColor, size: 36),
                                ),
                        ),
                      ),

                      // Konten Informasi Film
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Kategori & Rating
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      drama.genre,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primaryBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (drama.rating > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14),
                                          const SizedBox(width: 2),
                                          Text(
                                            drama.rating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              color: Color(0xFFFFB800),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (isUpcoming)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFFFF6B00).withValues(alpha: 0.35),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            color: Color(0xFFFF6B00),
                                            size: 11,
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            'Segera',
                                            style: TextStyle(
                                              color: Color(0xFFFF6B00),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Judul Film / Drama
                              Text(
                                drama.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // TANGGAL RILIS SECARA MENONJOL
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isUpcoming
                                      ? const Color(0xFFFF6B00).withValues(alpha: 0.15)
                                      : primaryBlue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isUpcoming
                                        ? const Color(0xFFFF6B00).withValues(alpha: 0.4)
                                        : primaryBlue.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isUpcoming ? Icons.calendar_month : Icons.live_tv_rounded,
                                      size: 14,
                                      color: isUpcoming ? const Color(0xFFFF6B00) : primaryBlue,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isUpcoming ? 'Rilis: $formattedDate' : 'Tayang: $formattedDate',
                                      style: TextStyle(
                                        color: isUpcoming ? const Color(0xFFFF6B00) : primaryBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),
                              // Sinopsis singkat
                              if (drama.synopsis.isNotEmpty)
                                Text(
                                  drama.synopsis,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                            ],
                          ),
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

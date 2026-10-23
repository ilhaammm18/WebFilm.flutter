import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../routes/app_router.dart';
import '../models/drama.dart';
import '../models/actor.dart';
import '../services/api_service.dart';
import '../widgets/edit_drama_modal.dart';
import '../data/shared_data.dart';
import '../utils/helpers.dart';
export '../widgets/edit_drama_modal.dart';
export '../utils/helpers.dart';
export 'full_credits_page.dart';

/// Alias penamaan MovieDetailPage yang merujuk pada DetailPage
typedef MovieDetailPage = DetailPage;

class DetailPage extends StatefulWidget {
  final Drama? drama;
  final Drama? movie;
  final int? movieId;
  final ApiService? apiService;
  final String? heroTag;
  final String? posterUrl;

  const DetailPage({
    super.key,
    this.drama,
    this.movie,
    this.movieId,
    this.apiService,
    this.heroTag,
    this.posterUrl,
  }) : assert(drama != null || movie != null || movieId != null,
            'Either drama, movie or movieId must be provided');

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late final ApiService _apiService;
  Drama? _fetchedMovie;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  List<ActorCredit> _castList = [];
  List<MovieCrewMember> _crewList = [];
  List<WatchProvider> _providersList = [];
  String? _trailerKey;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    final Drama? initialMovie = widget.movie ?? widget.drama;
    final int movieId = widget.movieId ?? initialMovie?.id ?? 0;
    if (movieId > 0) {
      fetchMovieDetails(movieId, initialMovie?.mediaType);
    }
  }

  void fetchMovieDetails(int movieId, [String? mediaType]) async {
    final Drama? initialMovie = widget.movie ?? widget.drama;
    final bool needsFullLoading = _fetchedMovie == null && initialMovie == null;

    if (mounted) {
      setState(() {
        if (needsFullLoading) {
          _isLoading = true;
        }
        _hasError = false;
        _errorMessage = '';
      });
    }

    try {
      final results = await Future.wait([
        _apiService.getMovieDetails(movieId, mediaType: mediaType),
        _apiService.getMovieCredits(movieId, mediaType: mediaType ?? 'movie'),
        _apiService.getMovieWatchProviders(movieId, mediaType: mediaType ?? 'movie'),
        _apiService.getMovieTrailerKey(movieId, mediaType: mediaType ?? 'movie'),
      ]);

      if (mounted) {
        setState(() {
          _fetchedMovie = results[0] as Drama;
          final credits = results[1] as MovieCreditsResult;
          _castList = credits.cast;
          _crewList = credits.crew;
          _providersList = results[2] as List<WatchProvider>;
          _trailerKey = results[3] as String?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_fetchedMovie == null && initialMovie == null) {
            _hasError = true;
            _errorMessage = e.toString();
          }
        });
      }
    }
  }

  /// Memutar trailer video YouTube dari TMDB
  Future<void> _playTrailer(BuildContext context, Drama currentDrama) async {
    final int movieId = currentDrama.id > 0
        ? currentDrama.id
        : (widget.movieId ?? widget.movie?.id ?? widget.drama?.id ?? 0);

    String? key = _trailerKey;

    if (key == null || key.isEmpty) {
      if (movieId > 0) {
        try {
          key = await _apiService.getMovieTrailerKey(
            movieId,
            mediaType: currentDrama.mediaType.isNotEmpty
                ? currentDrama.mediaType
                : (currentDrama.isMovie ? 'movie' : 'tv'),
          );
          _trailerKey = key;
        } catch (_) {}
      }
    }

    if (!context.mounted) return;

    if (key != null && key.isNotEmpty) {
      final Uri youtubeUri = Uri.parse('https://www.youtube.com/watch?v=$key');
      try {
        final bool launched = await launchUrl(
          youtubeUri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          await launchUrl(youtubeUri);
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maaf, trailer belum tersedia untuk tayangan ini.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maaf, trailer belum tersedia untuk tayangan ini.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Fungsi untuk membuka EditDramaModal (Bottom Sheet Edit Tontonan)
  void _openEditModal(BuildContext context, Drama currentDrama) async {
    final int effId = currentDrama.id > 0
        ? currentDrama.id
        : (widget.movieId ?? widget.movie?.id ?? widget.drama?.id ?? 0);

    final String effTitle = currentDrama.title;

    Drama? matchedInWatchlist;
    try {
      matchedInWatchlist = SharedData.dramaListNotifier.value.firstWhere(
        (d) => effId > 0
            ? d.id == effId
            : (effTitle.isNotEmpty &&
                d.title.trim().toLowerCase() == effTitle.trim().toLowerCase()),
      );
    } catch (_) {
      matchedInWatchlist = null;
    }

    final bool isSaved = matchedInWatchlist != null &&
        matchedInWatchlist.status != 'Belum Ditonton' &&
        (matchedInWatchlist.status == 'Rencana Ditonton' ||
            matchedInWatchlist.status == 'Sedang Menonton' ||
            matchedInWatchlist.status == 'Selesai');

    final Drama dramaToEdit = isSaved
        ? currentDrama.copyWith(
            status: matchedInWatchlist.status,
            watchedEpisodes: matchedInWatchlist.watchedEpisodes,
            episodes: matchedInWatchlist.episodes > 0
                ? matchedInWatchlist.episodes
                : currentDrama.episodes,
            myRating:
                matchedInWatchlist.userRating ?? matchedInWatchlist.myRating,
            userRating:
                matchedInWatchlist.userRating ?? matchedInWatchlist.myRating,
            priority: matchedInWatchlist.priority,
            startDate: matchedInWatchlist.startDate,
            endDate: matchedInWatchlist.endDate,
            dateCompleted: matchedInWatchlist.dateCompleted,
          )
        : currentDrama;

    final String initialStatus = isSaved
        ? matchedInWatchlist.status
        : (currentDrama.status.isNotEmpty ? currentDrama.status : 'Belum Ditonton');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditDramaModal(
        drama: dramaToEdit,
        initialStatus: initialStatus,
      ),
    );

    // Refresh data / sinkronisasi ulang dan perbarui tampilan halaman
    await _refreshWatchlistData();
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

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor = isDark ? const Color(0xFF15171E) : const Color(0xFFF8F9FA);
    Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    Color subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    Color primaryBlue = const Color(0xFF0094FF);

    final Drama? initialMovie = widget.movie ?? widget.drama;
    final int effectiveId = widget.movieId ?? initialMovie?.id ?? 0;
    final String fallbackTitle = initialMovie?.title ?? '';

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: CircularProgressIndicator(color: primaryBlue),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 54, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  'Gagal memuat detail film',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage.isNotEmpty
                      ? _errorMessage
                      : 'Silakan periksa koneksi internet Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: subTextColor, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    final int effId = widget.movieId ?? initialMovie?.id ?? 0;
                    if (effId > 0) {
                      fetchMovieDetails(effId);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ValueListenableBuilder<List<Drama>>(
      valueListenable: SharedData.dramaListNotifier,
      builder: (context, dramaList, _) {
        // Sinkronisasi data real-time dari SharedData.dramaListNotifier berdasarkan ID
        Drama? matchedDrama;
        try {
          matchedDrama = dramaList.firstWhere(
            (d) => effectiveId > 0
                ? d.id == effectiveId
                : (fallbackTitle.isNotEmpty &&
                    d.title.trim().toLowerCase() == fallbackTitle.trim().toLowerCase()),
          );
        } catch (_) {
          matchedDrama = null;
        }

        // Prioritaskan data detail terbaru hasil fetch dari API TMDB
        final Drama baseDrama = _fetchedMovie != null
            ? ((_fetchedMovie!.title == 'Untitled' || _fetchedMovie!.title.isEmpty) &&
                    (initialMovie != null &&
                        initialMovie.title.isNotEmpty &&
                        initialMovie.title != 'Untitled'))
                ? _fetchedMovie!.copyWith(title: initialMovie.title)
                : _fetchedMovie!
            : (initialMovie != null
                ? (initialMovie.synopsis.startsWith('Berperan sebagai') ||
                        initialMovie.synopsis.startsWith('Informasi filmografi')
                    ? initialMovie.copyWith(synopsis: '')
                    : initialMovie)
                : (matchedDrama ??
                    Drama(
                      id: effectiveId,
                      title: fallbackTitle.isNotEmpty ? fallbackTitle : 'Memuat...',
                      koreanTitle: '',
                      genre: 'Film',
                      rating: 0.0,
                      episodes: 1,
                      watchedEpisodes: 0,
                      status: 'Rencana Ditonton',
                      priority: 'Sedang',
                      startDate: '',
                      endDate: '',
                      date: '',
                      image: widget.posterUrl ?? '',
                      rank: '#1',
                      popularity: '0',
                      watchers: '0',
                      synopsis: '',
                      aired: '',
                      duration: '',
                      contentRating: '13+',
                      genresList: ['Film'],
                      tagsList: ['TMDB'],
                    )));

        // Pertahankan status watchlist personal milik pengguna jika ada di list tontonan
        final Drama currentDrama = matchedDrama != null
            ? baseDrama.copyWith(
                status: matchedDrama.status,
                watchedEpisodes: matchedDrama.watchedEpisodes,
                episodes: matchedDrama.episodes > 0
                    ? matchedDrama.episodes
                    : baseDrama.episodes,
                myRating: matchedDrama.userRating ?? matchedDrama.myRating,
                userRating: matchedDrama.userRating ?? matchedDrama.myRating,
                priority: matchedDrama.priority,
                startDate: matchedDrama.startDate,
                endDate: matchedDrama.endDate,
                dateCompleted: matchedDrama.dateCompleted,
              )
            : baseDrama;

        final movie = currentDrama;

        // Cek status penyimpanan film di database Supabase (Daftar Saya milik user)
        final bool isSavedInWatchlist = matchedDrama != null &&
            matchedDrama.status != 'Belum Ditonton' &&
            (matchedDrama.status == 'Rencana Ditonton' ||
                matchedDrama.status == 'Sedang Menonton' ||
                matchedDrama.status == 'Selesai');

        bool isSelesai = currentDrama.status == 'Selesai';
        bool hasRated = currentDrama.hasUserRating;

        final String headerImage = currentDrama.backdrop.isNotEmpty
            ? currentDrama.backdrop
            : currentDrama.image;

        return Scaffold(
          backgroundColor: bgColor,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =============================================================
                // ATAS: HEADER BACKDROP + OVERLAPPING POSTER + TOMBOL TRAILER
                // =============================================================
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Backdrop Header Image
                    SizedBox(
                      height: 230,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            headerImage,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: isDark
                                  ? const Color(0xFF1E2129)
                                  : Colors.grey.shade300,
                              child: const Icon(Icons.movie,
                                  size: 60, color: Colors.grey),
                            ),
                          ),
                          // Gradient overlay gelap agar tulisan dan batas terlihat elegan
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.6),
                                  Colors.black.withValues(alpha: 0.1),
                                  bgColor.withValues(alpha: 0.95),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tombol Kembali (Back)
                    Positioned(
                      top: 40,
                      left: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),

                    // Kurva transisi ke bawah
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                      ),
                    ),

                    // Poster Kecil yang Menumpuk (Overlap) di sebelah kiri bawah
                    Positioned(
                      bottom: -35,
                      left: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Hero(
                          tag: widget.heroTag ??
                              (currentDrama.id > 0
                                  ? 'poster_${currentDrama.id}'
                                  : 'poster_${currentDrama.title}'),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              (widget.posterUrl != null &&
                                      widget.posterUrl!.isNotEmpty)
                                  ? widget.posterUrl!
                                  : currentDrama.image,
                              width: 100,
                              height: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 100,
                                height: 140,
                                color: isDark
                                    ? const Color(0xFF1E2129)
                                    : Colors.grey.shade300,
                                child: const Icon(Icons.movie,
                                    color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Detail Judul, Kategori, dan Tombol Trailer Biru di sebelah kanan poster
                Padding(
                  padding: const EdgeInsets.only(left: 130, right: 16, top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentDrama.title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (() {
                          final List<String> gList = movie.genres.isNotEmpty
                              ? movie.genres
                              : (movie.genresList.isNotEmpty
                                  ? movie.genresList
                                  : [movie.genre]);
                          final nonGeneral = gList
                              .where((g) => g.isNotEmpty && g != 'Film' && g != 'Drama')
                              .toList();
                          if (nonGeneral.isNotEmpty) {
                            return nonGeneral.join(', ');
                          }
                          return gList.where((g) => g.isNotEmpty).join(', ');
                        })(),
                        style: TextStyle(color: subTextColor, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // Tombol Trailer Warna Biru
                      ElevatedButton.icon(
                        onPressed: () => _playTrailer(context, currentDrama),
                        icon: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 18),
                        label: const Text(
                          'Trailer',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          minimumSize: const Size(90, 34),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // =============================================================
                // TENGAH: KOTAK STATISTIK (3 KOLOM)
                // =============================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1B2335)
                          : const Color(0xFFE8EEF8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _buildStatItem(
                          Icons.calendar_today,
                          primaryBlue,
                          currentDrama.date.isNotEmpty ? currentDrama.date : '-',
                          'Tanggal Rilis',
                          subTextColor,
                          textColor,
                        ),
                        _buildDivider(subTextColor),
                        _buildStatItem(
                          Icons.access_time,
                          primaryBlue,
                          _formatDuration(
                              currentDrama.runtime, currentDrama.duration),
                          'Durasi',
                          subTextColor,
                          textColor,
                        ),
                        _buildDivider(subTextColor),
                        _buildStatItem(
                          Icons.trending_up,
                          primaryBlue,
                          (() {
                            final popNum =
                                double.tryParse(currentDrama.popularity);
                            if (popNum != null) {
                              return popNum.round().toString();
                            }
                            return currentDrama.popularity.isNotEmpty
                                ? currentDrama.popularity
                                : '0';
                          })(),
                          'Kepopuleran',
                          subTextColor,
                          textColor,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // =============================================================
                // 2 KOTAK RATING (TMDB & USER) DENGAN WARNA DINAMIS
                // =============================================================
                if (isSelesai && hasRated)
                  _buildRatingKondisiA(
                    context,
                    currentDrama,
                    isDark,
                    textColor,
                    subTextColor,
                  )
                else
                  _buildRatingKondisiB(
                    context,
                    currentDrama,
                    isDark,
                    textColor,
                    subTextColor,
                    primaryBlue,
                  ),

                const SizedBox(height: 24),

                // =============================================================
                // BAWAH: DESKRIPSI / SINOPSIS
                // =============================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sinopsis',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        movie.overview ?? movie.description ?? 'Sinopsis belum tersedia.',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // =============================================================
                // BAGIAN: TEMPAT MENONTON (WATCH PROVIDERS TMDB)
                // =============================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Tempat Menonton',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildWatchProvidersSection(
                    isDark, textColor, subTextColor, primaryBlue),

                const SizedBox(height: 24),

                // =============================================================
                // BAGIAN: PEMERAN (CAST TMDB)
                // =============================================================
                _buildSectionHeader(
                  'Pemeran',
                  textColor,
                  primaryBlue,
                  () => _showAllCast(context, isDark, textColor, primaryBlue),
                ),
                const SizedBox(height: 12),
                _buildCastSection(
                    isDark, textColor, subTextColor, primaryBlue),

                const SizedBox(height: 24),

                // =============================================================
                // BAGIAN: TIM (CREW TMDB)
                // =============================================================
                _buildSectionHeader(
                  'Tim',
                  textColor,
                  primaryBlue,
                  () => _showAllCrew(context, isDark, textColor, primaryBlue),
                ),
                const SizedBox(height: 12),
                _buildCrewSection(
                    isDark, textColor, subTextColor, primaryBlue),

                const SizedBox(height: 120),
              ],
            ),
          ),

          floatingActionButton: FloatingActionButton(
            key: const Key('movie_detail_fab'),
            onPressed: () => _openEditModal(context, currentDrama),
            backgroundColor: primaryBlue,
            shape: const CircleBorder(),
            tooltip: isSavedInWatchlist
                ? 'Ubah Status Tontonan'
                : 'Tambah ke Daftar Tontonan',
            child: Icon(
              isSavedInWatchlist ? Icons.edit : Icons.add,
              color: Colors.white,
              size: 26,
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // HELPER FORMAT DURASI (JAM & MENIT)
  // ===========================================================================
  String _formatDuration(int? runtime, [String fallback = '']) {
    if (runtime != null && runtime > 0) {
      final hours = runtime ~/ 60;
      final minutes = runtime % 60;
      if (hours > 0 && minutes > 0) {
        return '${hours}j ${minutes}m';
      } else if (hours > 0) {
        return '${hours}j';
      } else {
        return '${minutes}m';
      }
    }
    if (fallback.isNotEmpty) {
      return fallback;
    }
    return '-';
  }

  // ===========================================================================
  // HEADER SECTION: JUDUL DI KIRI + 'LIHAT SEMUA' DI KANAN
  // ===========================================================================
  Widget _buildSectionHeader(
    String title,
    Color textColor,
    Color primaryBlue,
    VoidCallback onSeeAll,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Lihat Semua',
              style: TextStyle(
                color: primaryBlue,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showAllCast(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color primaryBlue,
  ) {
    final List<ActorCredit> castData = _castList.isNotEmpty
        ? _castList
        : dummyActors
            .map((a) => ActorCredit(
                  id: a.id,
                  title: a.name,
                  profilePath: a.profilePath,
                  releaseDate: '',
                  character: 'Pemeran',
                ))
            .toList();

    context.push(
      '/credits',
      extra: {
        'title': 'Semua Pemeran',
        'cast': castData,
        'apiService': _apiService,
      },
    );
  }

  void _showAllCrew(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color primaryBlue,
  ) {
    final List<MovieCrewMember> crewData =
        _crewList.isNotEmpty ? _crewList : dummyCrew;

    context.push(
      '/credits',
      extra: {
        'title': 'Semua Tim Kru',
        'crew': crewData,
        'apiService': _apiService,
      },
    );
  }

  // ===========================================================================
  // WIDGET PEMBANTU: SECTION TEMPAT MENONTON (WATCH PROVIDERS)
  // ===========================================================================
  Widget _buildWatchProvidersSection(
    bool isDark,
    Color textColor,
    Color subTextColor,
    Color primaryBlue,
  ) {
    final List<WatchProvider> providers = _providersList.isNotEmpty
        ? _providersList
        : dummyProviders;

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: providers.length,
        itemBuilder: (context, index) {
          final provider = providers[index];
          final Color cardBg = Theme.of(context).cardColor;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Membuka platform ${provider.name}...'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: provider.logoUrl.isNotEmpty
                            ? Image.network(
                                provider.logoUrl,
                                width: 34,
                                height: 34,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 34,
                                  height: 34,
                                  color: isDark ? Colors.white12 : Colors.black12,
                                  child: Icon(
                                    Icons.play_circle_fill,
                                    color: primaryBlue,
                                    size: 20,
                                  ),
                                ),
                              )
                            : Container(
                                width: 34,
                                height: 34,
                                color: isDark ? Colors.white12 : Colors.black12,
                                child: Icon(
                                  Icons.play_circle_fill,
                                  color: primaryBlue,
                                  size: 20,
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.name,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color ?? textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            provider.typeLabel,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color ?? subTextColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // WIDGET PEMBANTU: SECTION PEMERAN (CAST TMDB)
  // ===========================================================================
  Widget _buildCastSection(
    bool isDark,
    Color textColor,
    Color subTextColor,
    Color primaryBlue,
  ) {
    final List<ActorCredit> castMembers = _castList.isNotEmpty
        ? _castList.take(15).toList()
        : dummyActors
            .take(10)
            .map((a) => ActorCredit(
                  id: a.id,
                  title: a.name,
                  profilePath: a.profilePath,
                  releaseDate: '',
                  character: 'Pemeran',
                ))
            .toList();

    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: castMembers.length,
        itemBuilder: (context, index) {
          final cast = castMembers[index];
          final String photoUrl = cast.profileUrl;
          final String castHeroTag = 'cast_${cast.id}_$index';

          return Container(
            width: 110,
            margin: const EdgeInsets.only(right: 12),
            child: Material(
              color: isDark ? const Color(0xFF1B2335) : const Color(0xFFF1F4F9),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  if (cast.id > 0) {
                    context.push(
                      '/actor/${cast.id}',
                      extra: {
                        'actor': Actor(
                          id: cast.id,
                          name: cast.title,
                          profilePath: cast.profilePath,
                        ),
                        'apiService': _apiService,
                        'heroTag': castHeroTag,
                        'imageUrl': photoUrl,
                      },
                    );
                  }
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Hero(
                        tag: castHeroTag,
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: isDark
                              ? const Color(0xFF2C3240)
                              : Colors.grey.shade300,
                          backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl.isEmpty
                              ? const Icon(Icons.person,
                                  color: Colors.grey, size: 28)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cast.title,
                        textAlign: TextAlign.center,
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
                        cast.character.isNotEmpty
                            ? cast.character
                            : 'Pemeran',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: primaryBlue.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          index < 3 ? 'Peran Utama' : 'Peran Pendukung',
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // WIDGET PEMBANTU: SECTION TIM / CREW
  // ===========================================================================
  Widget _buildCrewSection(
    bool isDark,
    Color textColor,
    Color subTextColor,
    Color primaryBlue,
  ) {
    final List<MovieCrewMember> crewMembers = _crewList.isNotEmpty
        ? _crewList.take(15).toList()
        : dummyCrew.take(10).toList();

    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: crewMembers.length,
        itemBuilder: (context, index) {
          final crew = crewMembers[index];
          final String photoUrl = crew.profileUrl;

          return Container(
            width: 110,
            margin: const EdgeInsets.only(right: 12),
            child: Material(
              color: isDark ? const Color(0xFF1B2335) : const Color(0xFFF1F4F9),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${crew.name} (${translateCrewRole(crew.job.isNotEmpty ? crew.job : crew.department)})'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: isDark
                            ? const Color(0xFF2C3240)
                            : Colors.grey.shade300,
                        backgroundImage: photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl.isEmpty
                            ? const Icon(Icons.person,
                                color: Colors.grey, size: 28)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        crew.name,
                        textAlign: TextAlign.center,
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
                        translateCrewRole(crew.department.isNotEmpty
                            ? crew.department
                            : (crew.job.isNotEmpty ? crew.job : 'Tim Produksi')),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF6366F1).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFF6366F1)
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          translateCrewRole(crew.job.isNotEmpty ? crew.job : 'Kru'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF818CF8),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // WIDGET PEMBANTU: STAT ITEM (3 KOLOM STATISTIK)
  // ===========================================================================
  Widget _buildStatItem(
    IconData icon,
    Color iconColor,
    String value,
    String label,
    Color subTextColor,
    Color textColor,
  ) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: subTextColor, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Container(height: 30, width: 1, color: color.withValues(alpha: 0.2));
  }

  // ===========================================================================
  // HELPER KOTAK ANGKA RATING (DENGAN WARNA DINAMIS BERDASARKAN SKOR)
  // ===========================================================================
  Widget _buildRatingBadge(String value, Color bgColor) {
    return Container(
      width: 48,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ===========================================================================
  // KONDISI A: DUA KOTAK RATING BERSEBELAHAN (GLOBAL & PENILAIAN SAYA)
  // ===========================================================================
  Widget _buildRatingKondisiA(
    BuildContext context,
    Drama currentDrama,
    bool isDark,
    Color textColor,
    Color subTextColor,
  ) {
    final double globalScore = currentDrama.rating;
    final double userScore =
        currentDrama.myRating ?? currentDrama.userRating ?? 0.0;

    final Color globalBadgeColor = getRatingColor(globalScore);
    final Color userBadgeColor = getRatingColor(userScore);

    final Color cardBackground =
        isDark ? const Color(0xFF2A2D3A) : Colors.white;
    final Color borderColor =
        isDark ? const Color(0xFF2A2E3D) : Colors.grey.shade200;

    final cardDecoration = BoxDecoration(
      color: cardBackground,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // -------------------------------------------------------------------
          // KOTAK KIRI (RATING GLOBAL / TMDB) DENGAN WARNA DINAMIS
          // -------------------------------------------------------------------
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rating Global',
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(Icons.public, color: globalBadgeColor, size: 14),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildRatingBadge(
                        globalScore.toStringAsFixed(1),
                        globalBadgeColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Color(0xFFFFB800), size: 16),
                                const SizedBox(width: 2),
                                Text(
                                  'Skor',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'dari ${currentDrama.watchers.isNotEmpty && currentDrama.watchers != '0' ? currentDrama.watchers : '0'} pengguna',
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
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // -------------------------------------------------------------------
          // KOTAK KANAN (PENILAIAN SAYA / USER) DENGAN WARNA DINAMIS
          // -------------------------------------------------------------------
          Expanded(
            child: Container(
              decoration: cardDecoration,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openEditModal(context, currentDrama),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Penilaian Saya',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Icon(
                              Icons.edit,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              size: 14,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildRatingBadge(
                              userScore.toStringAsFixed(1),
                              userBadgeColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildStarRatingRow(userScore),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Ketuk utk ubah',
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // KONDISI B: CARD RATING TUNGGAL MEMANJANG (DENGAN WARNA DINAMIS)
  // ===========================================================================
  Widget _buildRatingKondisiB(
    BuildContext context,
    Drama currentDrama,
    bool isDark,
    Color textColor,
    Color subTextColor,
    Color primaryBlue,
  ) {
    final double globalScore = currentDrama.rating;
    final Color globalBadgeColor = getRatingColor(globalScore);

    final Color cardBackground =
        isDark ? const Color(0xFF2A2D3A) : Colors.white;
    final Color borderColor =
        isDark ? const Color(0xFF2A2E3D) : Colors.grey.shade200;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(14),
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
            _buildRatingBadge(
              globalScore.toStringAsFixed(1),
              globalBadgeColor,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    5,
                    (index) => const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 16),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'dari ${currentDrama.watchers.isNotEmpty && currentDrama.watchers != '0' ? currentDrama.watchers : '0'} pengguna',
                  style: TextStyle(color: subTextColor, fontSize: 11),
                ),
              ],
            ),
            const Spacer(),
            InkWell(
              onTap: () => _openEditModal(context, currentDrama),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryBlue.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Berikan Penilaian\nSekarang',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // HELPER BINTANG RATING KUNING
  // ===========================================================================
  Widget _buildStarRatingRow(double score) {
    double starRating = (score / 2.0).clamp(0.0, 5.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (starRating >= index + 1) {
          return const Icon(Icons.star_rounded,
              color: Color(0xFFFFB800), size: 14);
        } else if (starRating >= index + 0.5) {
          return const Icon(Icons.star_half_rounded,
              color: Color(0xFFFFB800), size: 14);
        } else {
          return const Icon(Icons.star_outline_rounded,
              color: Color(0xFFFFB800), size: 14);
        }
      }),
    );
  }
}

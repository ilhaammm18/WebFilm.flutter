import 'package:flutter/material.dart';
import '../models/drama.dart';
import '../models/actor.dart';
import 'actor_detail_page.dart';
import '../services/api_service.dart';
import '../widgets/edit_drama_modal.dart';
import '../data/shared_data.dart';
import '../utils/helpers.dart';
export '../widgets/edit_drama_modal.dart';
export '../utils/helpers.dart';

class DetailPage extends StatefulWidget {
  final Drama drama;
  final ApiService? apiService;
  final String? heroTag;
  final String? posterUrl;

  const DetailPage({
    super.key,
    required this.drama,
    this.apiService,
    this.heroTag,
    this.posterUrl,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late final ApiService _apiService;
  Future<List<ActorCredit>>? _creditsFuture;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    if (widget.drama.id > 0) {
      _creditsFuture = _apiService.getMediaCredits(
        widget.drama.id,
        mediaType: widget.drama.mediaType,
      );
    }
  }

  // Fungsi untuk membuka EditDramaModal (Bottom Sheet Edit Tontonan)
  void _openEditModal(BuildContext context, Drama currentDrama) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditDramaModal(drama: currentDrama),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor = isDark ? const Color(0xFF15171E) : const Color(0xFFF8F9FA);
    Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    Color subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    Color primaryBlue = const Color(0xFF0094FF);

    return ValueListenableBuilder<List<Drama>>(
      valueListenable: SharedData.dramaListNotifier,
      builder: (context, dramaList, _) {
        // Sinkronisasi data real-time dari SharedData.dramaListNotifier
        final currentDrama = dramaList.firstWhere(
          (d) =>
              d.title.trim().toLowerCase() ==
              widget.drama.title.trim().toLowerCase(),
          orElse: () => widget.drama,
        );

        bool isSelesai = currentDrama.status == 'Selesai';
        bool hasRated = currentDrama.hasUserRating;
        bool isInWatchlist = [
          'Sedang Menonton',
          'Selesai',
          'Rencana Ditonton'
        ].contains(currentDrama.status);

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
                          onPressed: () => Navigator.pop(context),
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
                      if (currentDrama.koreanTitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          currentDrama.koreanTitle,
                          style: TextStyle(color: subTextColor, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${currentDrama.mediaType == 'movie' ? 'Film' : 'Drama'} • ${currentDrama.date.isNotEmpty ? currentDrama.date : '2023'} • ${currentDrama.genre.split('•')[0].trim()}',
                        style: TextStyle(color: subTextColor, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // Tombol Trailer Warna Biru
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Trailer sedang dipersiapkan...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
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
                // TENGAH: KOTAK STATISTIK (BIRU TUA/GELAP) + KOTAK RATING DINAMIS
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
                          Icons.trending_up,
                          primaryBlue,
                          currentDrama.rank,
                          'Peringkat',
                          subTextColor,
                        ),
                        _buildDivider(subTextColor),
                        _buildStatItem(
                          Icons.local_fire_department,
                          primaryBlue,
                          currentDrama.popularity,
                          'Popularitas',
                          subTextColor,
                        ),
                        _buildDivider(subTextColor),
                        _buildStatItem(
                          Icons.remove_red_eye,
                          primaryBlue,
                          currentDrama.watchers,
                          'Penonton',
                          subTextColor,
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
                        currentDrama.synopsis.isNotEmpty
                            ? currentDrama.synopsis
                            : 'Tidak ada sinopsis yang tersedia untuk judul ini.',
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
                // AKTOR: DAFTAR AKTOR PEMERAN (ENDPOINT CREDITS TMDB)
                // =============================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Pemeran',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _buildCastSection(isDark, textColor, subTextColor, primaryBlue),

                const SizedBox(height: 100),
              ],
            ),
          ),

          floatingActionButton: FloatingActionButton(
            onPressed: () => _openEditModal(context, currentDrama),
            backgroundColor: primaryBlue,
            shape: const CircleBorder(),
            tooltip: isInWatchlist ? 'Edit Tontonan' : 'Tambah ke Tontonan',
            child: Icon(
              isInWatchlist ? Icons.edit : Icons.add,
              color: Colors.white,
              size: 26,
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // WIDGET PEMBANTU: SECTION CREDITS / AKTOR PEMERAN
  // ===========================================================================
  Widget _buildCastSection(
    bool isDark,
    Color textColor,
    Color subTextColor,
    Color primaryBlue,
  ) {
    if (_creditsFuture == null) {
      return _buildActorsList(
        dummyActors
            .take(6)
            .map((a) => ActorCredit(
                  id: a.id,
                  title: a.name,
                  profilePath: a.profilePath,
                  releaseDate: '',
                  character: 'Pemeran',
                ))
            .toList(),
        isDark,
        textColor,
        subTextColor,
      );
    }

    return FutureBuilder<List<ActorCredit>>(
      future: _creditsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 120,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: primaryBlue,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        final List<ActorCredit> credits = snapshot.data ?? [];
        if (credits.isEmpty) {
          return _buildActorsList(
            dummyActors
                .take(6)
                .map((a) => ActorCredit(
                      id: a.id,
                      title: a.name,
                      profilePath: a.profilePath,
                      releaseDate: '',
                      character: 'Pemeran',
                    ))
                .toList(),
            isDark,
            textColor,
            subTextColor,
          );
        }

        return _buildActorsList(credits, isDark, textColor, subTextColor);
      },
    );
  }

  Widget _buildActorsList(
    List<ActorCredit> credits,
    bool isDark,
    Color textColor,
    Color subTextColor,
  ) {
    return SizedBox(
      height: 125,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: credits.length,
        itemBuilder: (context, index) {
          final cast = credits[index];
          final String photoUrl = cast.profileUrl;
          final String castHeroTag = 'cast_${cast.id}';

          return GestureDetector(
            onTap: () {
              if (cast.id > 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActorDetailPage(
                      Actor(
                        id: cast.id,
                        name: cast.title,
                        profilePath: cast.profilePath,
                      ),
                      apiService: _apiService,
                      heroTag: castHeroTag,
                      imageUrl: photoUrl,
                    ),
                  ),
                );
              }
            },
            child: Container(
              width: 84,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: [
                  Hero(
                    tag: castHeroTag,
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: isDark
                          ? const Color(0xFF2C2C34)
                          : Colors.grey.shade300,
                      backgroundImage:
                          photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl.isEmpty
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cast.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cast.character,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    Color iconColor,
    String value,
    String label,
    Color subTextColor,
  ) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: subTextColor, fontSize: 11)),
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
                              'dari ${currentDrama.watchers.isNotEmpty ? currentDrama.watchers : '10.3K'} pengguna',
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
                  'dari ${currentDrama.watchers.isNotEmpty ? currentDrama.watchers : '10.3K'} pengguna',
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
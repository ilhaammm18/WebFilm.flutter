import 'package:flutter/material.dart';
import 'models/drama.dart';
import 'edit_drama_modal.dart';
import 'data/shared_data.dart';
export 'edit_drama_modal.dart';

class DetailPage extends StatefulWidget {
  final Drama drama;

  const DetailPage({super.key, required this.drama});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
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
    
    Color bgColor = isDark ? const Color(0xFF222228) : const Color(0xFFF8F9FA);
    Color cardBg = isDark ? const Color(0xFF2C2C34) : Colors.white;
    Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    Color subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    Color primaryBlue = const Color(0xFF0094FF); 

    return ValueListenableBuilder<List<Drama>>(
      valueListenable: SharedData.dramaListNotifier,
      builder: (context, dramaList, _) {
        // Sinkronisasi data real-time dari SharedData.dramaListNotifier
        final currentDrama = dramaList.firstWhere(
          (d) => d.title.trim().toLowerCase() == widget.drama.title.trim().toLowerCase(),
          orElse: () => widget.drama,
        );

        bool isSelesai = currentDrama.status == 'Selesai';
        bool hasRated = currentDrama.hasUserRating;
        bool isInWatchlist = ['Sedang Menonton', 'Selesai', 'Rencana Ditonton'].contains(currentDrama.status);

        return Scaffold(
          backgroundColor: bgColor,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 220,
                      width: double.infinity,
                      color: Colors.amber, 
                      child: Image.network(
                        currentDrama.image, 
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        color: Colors.black.withValues(alpha: 0.3),
                        colorBlendMode: BlendMode.darken,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: isDark ? const Color(0xFF1E2129) : Colors.grey.shade300,
                          child: const Icon(Icons.movie, size: 60, color: Colors.grey),
                        ),
                      ),
                    ),
                    
                    Positioned(
                      top: 40,
                      left: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: -40,
                      left: 20,
                      child: Hero(
                        tag: 'drama-poster-${currentDrama.title}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            currentDrama.image,
                            width: 100,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 100,
                              height: 140,
                              color: isDark ? const Color(0xFF1E2129) : Colors.grey.shade300,
                              child: const Icon(Icons.movie, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 140, right: 16, top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentDrama.title,
                        style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentDrama.koreanTitle,
                        style: TextStyle(color: subTextColor, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currentDrama.genre.split('•')[0].trim()}  •  2023',
                        style: TextStyle(color: subTextColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        _buildStatItem(Icons.trending_up, primaryBlue, currentDrama.rank, 'Peringkat', subTextColor),
                        _buildDivider(subTextColor),
                        _buildStatItem(Icons.local_fire_department, primaryBlue, currentDrama.popularity, 'Popularitas', subTextColor),
                        _buildDivider(subTextColor),
                        _buildStatItem(Icons.remove_red_eye, primaryBlue, currentDrama.watchers, 'Penonton', subTextColor),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ==========================================
                // CONDITIONAL RENDERING KARTU RATING
                // ==========================================
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

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    currentDrama.synopsis,
                    style: TextStyle(color: textColor.withValues(alpha: 0.9), fontSize: 14, height: 1.6),
                  ),
                ),
                
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

  Widget _buildStatItem(IconData icon, Color iconColor, String value, String label, Color subTextColor) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
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

  // ==========================================
  // HELPER KOTAK HIJAU ANGKA RATING (UKURAN PRESISI IDENTIK)
  // ==========================================
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

  // ==========================================
  // KONDISI A: DUA KOTAK RATING BERSEBELAHAN
  // ==========================================
  Widget _buildRatingKondisiA(
    BuildContext context,
    Drama currentDrama,
    bool isDark,
    Color textColor,
    Color subTextColor,
  ) {
    const Color greenRating = Color(0xFF10B981);
    final Color cardBackground = isDark ? const Color(0xFF2A2D3A) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF2A2E3D) : Colors.grey.shade200;

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
          // ------------------------------------------
          // KOTAK KIRI (RATING GLOBAL)
          // ------------------------------------------
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
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Icon(Icons.public, color: greenRating, size: 14),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Kotak hijau menampilkan nilai rating asli drama
                      _buildRatingBadge(
                        currentDrama.rating.toStringAsFixed(1),
                        greenRating,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
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

          // ------------------------------------------
          // KOTAK KANAN (PENILAIAN SAYA)
          // ------------------------------------------
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
                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Icon(
                              Icons.edit,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              size: 14,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // Kotak hijau menampilkan nilai penilaian pengguna (presisi ukuran sama persis)
                            _buildRatingBadge(
                              (currentDrama.myRating ?? currentDrama.userRating ?? 0.0).toStringAsFixed(1),
                              greenRating,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Deretan ikon bintang kuning
                                  _buildStarRatingRow(
                                    currentDrama.myRating ?? currentDrama.userRating ?? 0.0,
                                  ),
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

  // ==========================================
  // KONDISI B: CARD RATING TUNGGAL MEMANJANG
  // ==========================================
  Widget _buildRatingKondisiB(
    BuildContext context,
    Drama currentDrama,
    bool isDark,
    Color textColor,
    Color subTextColor,
    Color primaryBlue,
  ) {
    const Color greenRating = Color(0xFF10B981);
    final Color cardBackground = isDark ? const Color(0xFF2A2D3A) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF2A2E3D) : Colors.grey.shade200;

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
            // Kotak rating hijau asli drama
            _buildRatingBadge(
              currentDrama.rating.toStringAsFixed(1),
              greenRating,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    5,
                    (index) => const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
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
            // Teks 'Berikan Penilaian Sekarang' berwarna biru (bisa diklik)
            InkWell(
              onTap: () => _openEditModal(context, currentDrama),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

  // ==========================================
  // HELPER BINTANG RATING KUNING
  // ==========================================
  Widget _buildStarRatingRow(double score) {
    double starRating = (score / 2.0).clamp(0.0, 5.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (starRating >= index + 1) {
          return const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14);
        } else if (starRating >= index + 0.5) {
          return const Icon(Icons.star_half_rounded, color: Color(0xFFFFB800), size: 14);
        } else {
          return const Icon(Icons.star_outline_rounded, color: Color(0xFFFFB800), size: 14);
        }
      }),
    );
  }
}
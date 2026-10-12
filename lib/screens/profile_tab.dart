import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'customer_service_page.dart';
import 'edit_profile_page.dart';
import '../models/drama.dart';
import '../data/shared_data.dart';
import 'detail_page.dart';
import 'main_navigation.dart';
import 'settings_page.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor = isDark ? const Color(0xFF15171E) : const Color(0xFFF8F9FA);
    Color cardBg = isDark ? const Color(0xFF1F222B) : Colors.white;
    Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    Color subTextColor = isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade600;
    Color borderColor = isDark ? const Color(0xFF2A2E3D) : Colors.grey.shade200;
    Color primaryBlue = const Color(0xFF0094FF);

    return Scaffold(
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
          'Profil',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ==========================================
            // 1. HEADER PROFIL
            // ==========================================
            // Foto Profil Melingkar
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryBlue.withValues(alpha: 0.5),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.2),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 48,
                backgroundColor: Color(0xFF262A36),
                backgroundImage: AssetImage('assets/profile.jpg'),
              ),
            ),
            const SizedBox(height: 14),

            // Nama Lengkap
            Text(
              'Muhammad Nur Ilham',
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            // Username / Badge NIM (Pill Badge Melengkung Elegan)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B2335) : const Color(0xFFE8F1FC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: primaryBlue.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.badge_outlined,
                    size: 14,
                    color: isDark ? const Color(0xFF70B6FF) : primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'NIM : 25051204433',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF70B6FF) : primaryBlue,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================
            // 2. STATISTIK PENGIKUT (ROW)
            // ==========================================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
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
                  Expanded(
                    child: _buildFollowStatItem('0', 'Pengikut', textColor, subTextColor),
                  ),
                  Container(
                    height: 28,
                    width: 1,
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                  ),
                  Expanded(
                    child: _buildFollowStatItem('0', 'Mengikuti', textColor, subTextColor),
                  ),
                  Container(
                    height: 28,
                    width: 1,
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                  ),
                  Expanded(
                    child: _buildFollowStatItem('0', 'Suka', textColor, subTextColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==========================================
            // 3. CARD TENTANG SAYA (ABOUT ME)
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: primaryBlue,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Tentang Saya (About Me)',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Selamat Datang di MyWatchList! Halo! Saya Muhammad Nur Ilham. Saat ini saya adalah mahasiswa Teknik Informatika Universitas Negeri Surabaya (Unesa) semester 3. Web ini dibuat untuk memenuhi tugas mata kuliah Pemrograman Berbasis Platform (PBP).',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFC7CBD8) : const Color(0xFF4A4E5A),
                        fontSize: 13.5,
                        height: 1.55,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==========================================
            // 5. CARD STATISTIK WAKTU TONTON (SUSUNAN 2x2)
            // ==========================================
            ValueListenableBuilder<List<Drama>>(
              valueListenable: SharedData.dramaListNotifier,
              builder: (context, dramaList, _) {
                // DRAMA stats
                List<Drama> dramasOnly = dramaList
                    .where((d) =>
                        !d.genre.contains('Film') &&
                        !d.genre.contains('Animasi') &&
                        !d.genre.contains('Anime') &&
                        d.episodes > 1)
                    .toList();
                int watchedDramaEpisodes =
                    dramasOnly.fold(0, (sum, d) => sum + d.watchedEpisodes);
                int watchedDramaCount = dramasOnly
                    .where((d) => d.watchedEpisodes > 0 || d.status == 'Selesai')
                    .length;

                // Hitung total dengan fallback angka default yang realistis sesuai permintaan
                int displayDramaEps =
                    watchedDramaEpisodes > 0 ? watchedDramaEpisodes : 74;
                int displayDramaCount =
                    watchedDramaCount > 0 ? watchedDramaCount : 20;
                int totalDramaMinutes = displayDramaEps * 60; // 74 * 60 = 4440m -> 3d 2h 0m

                // FILM stats
                List<Drama> filmsOnly = dramaList
                    .where((d) =>
                        (d.genre.contains('Film') || d.episodes == 1) &&
                        !d.genre.contains('Animasi') &&
                        !d.genre.contains('Anime'))
                    .toList();
                int watchedFilmCount = filmsOnly
                    .where((d) => d.status == 'Selesai' || d.watchedEpisodes > 0)
                    .length;
                int displayFilmCount =
                    watchedFilmCount > 0 ? watchedFilmCount : 25;
                // 520m -> 8h 40m
                int totalFilmMinutes =
                    watchedFilmCount > 0 ? (watchedFilmCount * 115) : 520;

                // ANIMASI stats
                List<Drama> animOnly = dramaList
                    .where((d) =>
                        d.genre.contains('Animasi') ||
                        d.genre.contains('Anime'))
                    .toList();
                int watchedAnimEpisodes =
                    animOnly.fold(0, (sum, d) => sum + d.watchedEpisodes);
                int watchedAnimCount = animOnly
                    .where((d) => d.watchedEpisodes > 0 || d.status == 'Selesai')
                    .length;
                int displayAnimEps =
                    watchedAnimEpisodes > 0 ? watchedAnimEpisodes : 45;
                int displayAnimCount =
                    watchedAnimCount > 0 ? watchedAnimCount : 3;
                // 3150m -> 2d 4h 30m
                int totalAnimMinutes =
                    watchedAnimEpisodes > 0 ? (watchedAnimEpisodes * 70) : 3150;

                // TOTAL KESELURUHAN stats
                int totalAllMinutes;
                String displayTotalCount;
                if (watchedDramaEpisodes > 0 ||
                    watchedFilmCount > 0 ||
                    watchedAnimEpisodes > 0) {
                  totalAllMinutes =
                      totalDramaMinutes + totalFilmMinutes + totalAnimMinutes;
                  int totalWatchCount =
                      displayDramaCount + displayFilmCount + displayAnimCount;
                  displayTotalCount = '$totalWatchCount tontonan';
                } else {
                  // Fallback dummy realistis: '10d 13h 25m', '234 tontonan'
                  totalAllMinutes = 15205; // 10d 13h 25m
                  displayTotalCount = '234 tontonan';
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // BARIS 1: DRAMA & FILM
                      Row(
                        children: [
                          // KOTAK DRAMA
                          Expanded(
                            child: _buildStatCard(
                              title: 'DRAMA',
                              accentColor: isDark
                                  ? const Color(0xFF70B6FF)
                                  : primaryBlue,
                              icon: Icons.tv_rounded,
                              durationText: _formatDuration(totalDramaMinutes),
                              subInfo:
                                  '$displayDramaEps episode, $displayDramaCount drama',
                              cardBg: cardBg,
                              borderColor: borderColor,
                              isDark: isDark,
                              textColor: textColor,
                              subTextColor: subTextColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // KOTAK FILM
                          Expanded(
                            child: _buildStatCard(
                              title: 'FILM',
                              accentColor: isDark
                                  ? const Color(0xFFB57AFF)
                                  : const Color(0xFF7A33E2),
                              icon: Icons.movie_creation_outlined,
                              durationText: _formatDuration(totalFilmMinutes),
                              subInfo: '$displayFilmCount film',
                              cardBg: cardBg,
                              borderColor: borderColor,
                              isDark: isDark,
                              textColor: textColor,
                              subTextColor: subTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // BARIS 2: ANIMASI & TOTAL KESELURUHAN
                      Row(
                        children: [
                          // KOTAK ANIMASI
                          Expanded(
                            child: _buildStatCard(
                              title: 'ANIMASI',
                              accentColor: isDark
                                  ? const Color(0xFFFF9E58)
                                  : const Color(0xFFE65100),
                              icon: Icons.animation,
                              durationText: _formatDuration(totalAnimMinutes),
                              subInfo:
                                  '$displayAnimEps episode, $displayAnimCount animasi',
                              cardBg: cardBg,
                              borderColor: borderColor,
                              isDark: isDark,
                              textColor: textColor,
                              subTextColor: subTextColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // KOTAK TOTAL KESELURUHAN
                          Expanded(
                            child: _buildStatCard(
                              title: 'TOTAL KESELURUHAN',
                              accentColor: isDark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF059669),
                              icon: Icons.stacked_line_chart,
                              durationText: _formatDuration(totalAllMinutes),
                              subInfo: displayTotalCount,
                              cardBg: cardBg,
                              borderColor: borderColor,
                              isDark: isDark,
                              textColor: textColor,
                              subTextColor: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),


            // ==========================================
            // 6. BAGIAN PEMBARUAN TERAKHIR
            // ==========================================
            ValueListenableBuilder<List<Drama>>(
              valueListenable: SharedData.dramaListNotifier,
              builder: (context, dramaList, _) {
                // List drama yang baru ditonton atau sedang aktif
                List<Drama> recentDramas = dramaList.where((d) => 
                  d.status == 'Sedang Menonton' || d.status == 'Selesai' || d.watchedEpisodes > 0
                ).toList();
                if (recentDramas.isEmpty) {
                  recentDramas = dramaList.take(8).toList();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pembaruan Terakhir',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.1,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              globalNavIndex.value = 1; // Pindah ke tab Watchlist
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Lihat Daftar',
                                    style: TextStyle(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 11,
                                    color: primaryBlue,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Horizontal List Card Drama
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: recentDramas.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final drama = recentDramas[index];
                          return _buildRecentDramaCard(
                            context,
                            drama,
                            isDark,
                            cardBg,
                            textColor,
                            subTextColor,
                            primaryBlue,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS & METHODS
  // ==========================================

  Widget _buildStatCard({
    required String title,
    required Color accentColor,
    required IconData icon,
    required String durationText,
    required String subInfo,
    required Color cardBg,
    required Color borderColor,
    required bool isDark,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                icon,
                size: 16,
                color: accentColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            durationText,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Waktu Tonton',
            style: TextStyle(
              color: subTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262A37) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              subInfo,
              style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowStatItem(
    String count,
    String label,
    Color textColor,
    Color subTextColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: subTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentDramaCard(
    BuildContext context,
    Drama drama,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subTextColor,
    Color primaryBlue,
  ) {
    bool isCompleted = drama.status == 'Selesai';
    Color statusColor = isCompleted ? const Color(0xFF10B981) : primaryBlue;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(drama: drama),
          ),
        );
      },
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2E3D) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                  child: SizedBox(
                    height: 140,
                    width: 120,
                    child: Image.network(
                      drama.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: isDark ? const Color(0xFF282C37) : Colors.grey.shade300,
                        child: Icon(Icons.movie, color: subTextColor, size: 30),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: isDark ? const Color(0xFF282C37) : Colors.grey.shade200,
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryBlue,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Rating Badge di pojok kanan atas
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 12),
                        const SizedBox(width: 2),
                        Text(
                          drama.status == 'Selesai'
                              ? (drama.userRating ?? drama.myRating ?? 0.0).toStringAsFixed(1)
                              : '0.0',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Status Badge di pojok kiri bawah foto
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isCompleted ? 'Selesai' : 'Nonton',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Detail teks di bawah poster
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drama.title,
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
                    (drama.mediaType == 'movie' ||
                            drama.isMovie ||
                            drama.genre.toLowerCase().contains('film'))
                        ? drama.genre
                        : (drama.episodes > 1
                            ? '${drama.watchedEpisodes}/${drama.episodes} Eps'
                            : drama.genre),
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
      ),
    );
  }

  // Fungsi pembantu untuk mengubah total menit menjadi format "3d 2h 0m" atau "8h 40m"
  String _formatDuration(int totalMinutes) {
    if (totalMinutes <= 0) return '0h 0m';

    int days = totalMinutes ~/ (60 * 24);
    int remainingMinutes = totalMinutes % (60 * 24);
    int hours = remainingMinutes ~/ 60;
    int mins = remainingMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${mins}m';
    } else {
      return '${hours}h ${mins}m';
    }
  }

  // Halaman Edit Profil
  static void showEditProfileDialog(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const EditProfilePage()),
    );
  }

  // Halaman Customer Service
  static void showCustomerServiceModal(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const CustomerServicePage()),
    );
  }

  // Halaman Pengaturan
  static void showSettingsModal(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const SettingsPage()),
    );
  }
}
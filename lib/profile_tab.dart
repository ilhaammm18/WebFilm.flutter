import 'package:flutter/material.dart';
import 'app_drawer.dart';
import 'models/drama.dart';
import 'data/shared_data.dart';
import 'detail_page.dart';
import 'main_navigation.dart';
import 'main.dart';

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
        actions: [
          IconButton(
            icon: Icon(Icons.support_agent, color: textColor),
            onPressed: () => _showCustomerServiceModal(context),
            tooltip: 'Customer Service',
          ),
        ],
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
            // 3. TOMBOL AKSI (ROW)
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Tombol Edit Profil (dengan ikon pena)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showEditProfileDialog(context),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text(
                        'Edit Profil',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF232734) : Colors.grey.shade200,
                        foregroundColor: textColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF33384A) : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tombol Pengaturan (dengan ikon roda gigi)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showSettingsModal(context),
                      icon: const Icon(Icons.settings_outlined, size: 18),
                      label: const Text(
                        'Pengaturan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF232734) : Colors.grey.shade200,
                        foregroundColor: textColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF33384A) : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==========================================
            // 4. CARD TENTANG SAYA (ABOUT ME)
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
                      'Selamat Datang di MyDramaList! Halo! Saya Muhammad Nur Ilham. Saat ini saya adalah mahasiswa Teknik Informatika Universitas Negeri Surabaya (Unesa) semester 3. Web ini dibuat untuk memenuhi tugas mata kuliah Pemrograman Berbasis Platform (PBP).',
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
            // 5. CARD STATISTIK WAKTU TONTON (GRID 2 KOLOM)
            // ==========================================
            ValueListenableBuilder<List<Drama>>(
              valueListenable: SharedData.dramaListNotifier,
              builder: (context, dramaList, _) {
                // DRAMA stats
                List<Drama> dramasOnly = dramaList
                    .where((d) => !d.genre.contains('Film') && d.episodes > 1)
                    .toList();
                int watchedDramaEpisodes = dramasOnly.fold(0, (sum, d) => sum + d.watchedEpisodes);
                int watchedDramaCount = dramasOnly
                    .where((d) => d.watchedEpisodes > 0 || d.status == 'Selesai')
                    .length;

                // Hitung total dengan fallback angka default yang realistis sesuai permintaan
                int displayDramaEps = watchedDramaEpisodes > 0 ? watchedDramaEpisodes : 74;
                int displayDramaCount = watchedDramaCount > 0 ? watchedDramaCount : 20;
                int totalDramaMinutes = displayDramaEps * 60; // 74 * 60 = 4440m -> 3d 2h 0m

                // FILM stats
                List<Drama> filmsOnly = dramaList
                    .where((d) => d.genre.contains('Film') || d.episodes == 1)
                    .toList();
                int watchedFilmCount = filmsOnly
                    .where((d) => d.status == 'Selesai' || d.watchedEpisodes > 0)
                    .length;
                int displayFilmCount = watchedFilmCount > 0 ? watchedFilmCount : 25;
                // 520m -> 8h 40m
                int totalFilmMinutes = watchedFilmCount > 0 ? (watchedFilmCount * 115) : 520;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // KOTAK DRAMA
                      Expanded(
                        child: Container(
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
                                  Text(
                                    'DRAMA',
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF70B6FF) : primaryBlue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Icon(
                                    Icons.tv_rounded,
                                    size: 16,
                                    color: isDark ? const Color(0xFF70B6FF) : primaryBlue,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _formatDuration(totalDramaMinutes),
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
                                  '$displayDramaEps episode, $displayDramaCount drama',
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
                        ),
                      ),

                      const SizedBox(width: 12),

                      // KOTAK FILM
                      Expanded(
                        child: Container(
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
                                  Text(
                                    'FILM',
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFFB57AFF) : const Color(0xFF7A33E2),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Icon(
                                    Icons.movie_creation_outlined,
                                    size: 16,
                                    color: isDark ? const Color(0xFFB57AFF) : const Color(0xFF7A33E2),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _formatDuration(totalFilmMinutes),
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
                                  '$displayFilmCount film',
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
                        ),
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
                          drama.formattedRating,
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
                    drama.episodes > 1
                        ? '${drama.watchedEpisodes}/${drama.episodes} Eps'
                        : drama.genre,
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

  // Modal Dialog Edit Profil
  void _showEditProfileDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: 'Muhammad Nur Ilham');
    final nimController = TextEditingController(text: '25051204433');
    final bioController = TextEditingController(
      text:
          'Selamat Datang di MyDramaList! Halo! Saya Muhammad Nur Ilham. Saat ini saya adalah mahasiswa Teknik Informatika Universitas Negeri Surabaya (Unesa) semester 3. Aplikasi ini dibuat untuk memenuhi tugas mata kuliah Pemrograman Berbasis Platform (PBP).',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E212B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Profil',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(modalContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF262A37) : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nimController,
                  decoration: InputDecoration(
                    labelText: 'NIM',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF262A37) : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Bio / Tentang Saya',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF262A37) : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profil berhasil disimpan!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0094FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Simpan Perubahan',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  // Modal Bottom Sheet Customer Service
  void _showCustomerServiceModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF0094FF);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade600;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E212B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.support_agent,
                        color: primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Service',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Pusat Bantuan & Layanan Pengguna',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF262A37) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF33384A) : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.chat_bubble_outline, color: primaryBlue),
                        title: const Text(
                          'Bot WhatsApp',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          '+62 812-3456-7890 (Respon Cepat)',
                          style: TextStyle(color: subTextColor, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          Navigator.pop(modalContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Menghubungkan ke Customer Service WhatsApp...'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      Divider(color: isDark ? Colors.white10 : Colors.grey.shade300),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.mail_outline_rounded, color: primaryBlue),
                        title: const Text(
                          'Email Dukungan',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          'support@mydramalist.id',
                          style: TextStyle(color: subTextColor, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          Navigator.pop(modalContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Membuka aplikasi email...'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: subTextColor),
                    const SizedBox(width: 6),
                    Text(
                      'Jam Layanan: Setiap Hari (08.00 - 22.00 WIB)',
                      style: TextStyle(color: subTextColor, fontSize: 11.5),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // Modal Dialog Pengaturan
  void _showSettingsModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E212B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pengaturan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Mode Gelap'),
                  trailing: Switch(
                    value: isDark,
                    activeThumbColor: const Color(0xFF0094FF),
                    onChanged: (val) {
                      MyApp.themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                      Navigator.pop(modalContext);
                    },
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_none_outlined),
                  title: const Text('Notifikasi Pembaruan'),
                  trailing: Switch(
                    value: true,
                    activeThumbColor: const Color(0xFF0094FF),
                    onChanged: (_) {},
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Versi Web'),
                  trailing: const Text('1.0.0+1', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF16181F) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E212B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade600;
    const primaryBlue = Color(0xFF0094FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Tentang Aplikasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Aplikasi & Nama
              Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo-animasi-blue.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Image.asset(
                            'assets/logo-animasi-blue.jpg',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'MyWatchList',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryBlue.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Versi 1.0.0',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Aplikasi Pelacak Film & Serial TV Terintegrasi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Penjelasan Singkat Fitur
              Text(
                'Fitur Utama',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF33384A) : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    _buildFeatureItem(
                      icon: Icons.explore_outlined,
                      title: 'Eksplorasi Katalog Komprehensif',
                      desc: 'Jelajahi ribuan film bioskop, K-Drama, J-Drama, dan anime dengan rating terpercaya.',
                      textColor: textColor,
                      subTextColor: subTextColor,
                      primaryBlue: primaryBlue,
                    ),
                    Divider(color: isDark ? Colors.white10 : Colors.grey.shade200, height: 1),
                    _buildFeatureItem(
                      icon: Icons.timelapse_rounded,
                      title: 'Lacak Progres & Waktu Tonton',
                      desc: 'Hitung total hari, jam, dan menit tontonan Anda secara otomatis dan terperinci.',
                      textColor: textColor,
                      subTextColor: subTextColor,
                      primaryBlue: primaryBlue,
                    ),
                    Divider(color: isDark ? Colors.white10 : Colors.grey.shade200, height: 1),
                    _buildFeatureItem(
                      icon: Icons.play_circle_outline_rounded,
                      title: 'Trailer Resmi YouTube',
                      desc: 'Saksikan cuplikan dan trailer resmi berkualitas tinggi langsung dari TMDB API.',
                      textColor: textColor,
                      subTextColor: subTextColor,
                      primaryBlue: primaryBlue,
                    ),
                    Divider(color: isDark ? Colors.white10 : Colors.grey.shade200, height: 1),
                    _buildFeatureItem(
                      icon: Icons.cloud_sync_outlined,
                      title: 'Sinkronisasi Cloud Real-time',
                      desc: 'Daftar tontonan tersimpan aman dan terhubung otomatis dengan akun Supabase Anda.',
                      textColor: textColor,
                      subTextColor: subTextColor,
                      primaryBlue: primaryBlue,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Kartu Informasi Developer
              Text(
                'Informasi Pengembang (Developer)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1F2430), const Color(0xFF1A1D27)]
                        : [Colors.white, const Color(0xFFF1F5F9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF33384A) : Colors.grey.shade300,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryBlue, width: 2.5),
                      ),
                      child: const CircleAvatar(
                        radius: 36,
                        backgroundImage: AssetImage('assets/profile.jpg'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Muhammad Nur Ilham',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'NIM : 25051204433',
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'S1 Teknik Informatika\nUniversitas Negeri Surabaya (Unesa)',
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mata Kuliah: Pemrograman Berbasis Platform (PBP)',
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String desc,
    required Color textColor,
    required Color subTextColor,
    required Color primaryBlue,
  }) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryBlue, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

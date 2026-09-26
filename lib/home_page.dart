import 'package:flutter/material.dart';
import 'app_drawer.dart';
import 'main.dart';
import 'detail_page.dart';
import 'main_navigation.dart'; 
import 'models/drama.dart'; 
import 'data/shared_data.dart'; 

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // 1. FUNGSI CERDAS: Membaca teks durasi (Misal: "1 jam 15 menit" -> 75 menit)
  int _parseDuration(String durationStr) {
    int minutes = 0;
    String d = durationStr.toLowerCase();
    
    RegExp hourExp = RegExp(r'(\d+)\s*jam');
    var hourMatch = hourExp.firstMatch(d);
    if (hourMatch != null) {
      minutes += int.parse(hourMatch.group(1)!) * 60;
    }
    
    RegExp minExp = RegExp(r'(\d+)\s*menit');
    var minMatch = minExp.firstMatch(d);
    if (minMatch != null) {
      minutes += int.parse(minMatch.group(1)!);
    }
    return minutes;
  }

  // 2. FUNGSI CERDAS: Mengubah total menit jadi format hari, jam, menit (d, h, m)
  String _formatTime(int totalMinutes) {
    if (totalMinutes <= 0) return '0d 0h 0m';
    int d = totalMinutes ~/ (24 * 60);
    int h = (totalMinutes % (24 * 60)) ~/ 60;
    int m = totalMinutes % 60;
    
    String result = '';
    if (d > 0) result += '${d}d ';
    if (h > 0 || d > 0) result += '${h}h ';
    result += '${m}m';
    
    return result.trim();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color cardColor = isDark ? const Color(0xFF222630) : Colors.white;
    Color borderColor = Theme.of(context).dividerColor;
    Color textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
    Color badgeBg = isDark ? const Color(0xFF2E3340) : const Color(0xFFF0F2F5);
    Color primaryBlue = const Color(0xFF0094FF);
    Color editBtnBg = isDark ? const Color(0xFF222630) : const Color(0xFFF0F8FF);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Profil Saya',
          style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.wb_sunny : Icons.nightlight_round,
              color: isDark ? Colors.white70 : const Color(0xFF4A5568),
            ),
            onPressed: () {
              MyApp.themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      
      // KITA BUNGKUS SELURUH BODY DENGAN PENYADAP DATA (ValueListenableBuilder)
      body: ValueListenableBuilder<List<Drama>>(
        valueListenable: SharedData.dramaListNotifier,
        builder: (context, List<Drama> dramaList, _) {
          
          // --- LOGIKA PERHITUNGAN DINAMIS ---
          int dramaCount = 0;
          int dramaEpsWatched = 0;
          int dramaMinutes = 0;
          
          int filmCount = 0;
          int filmMinutes = 0;
          
          for (var item in dramaList) {
            int duration = _parseDuration(item.duration);
            
            // Jika lebih dari 1 episode, dihitung sebagai DRAMA
            if (item.episodes > 1) {
              dramaCount++;
              dramaEpsWatched += item.watchedEpisodes;
              dramaMinutes += item.watchedEpisodes * duration;
            } 
            // Jika 1 episode (atau kurang), dihitung sebagai FILM
            else {
              filmCount++;
              if (item.watchedEpisodes > 0) {
                 filmMinutes += duration;
              }
            }
          }

          String dramaTimeStr = _formatTime(dramaMinutes);
          String filmTimeStr = _formatTime(filmMinutes);
          // ---------------------------------

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: const CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.transparent,
                            backgroundImage: AssetImage('assets/profile.jpg'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Muhammad Nur Ilham',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            'NIM : 25051204433',
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statItem(number: '0', label: 'Pengikut', textColor: textColor),
                      Container(height: 24, width: 1, color: borderColor),
                      _statItem(number: '0', label: 'Mengikuti', textColor: textColor),
                      Container(height: 24, width: 1, color: borderColor),
                      _statItem(number: '0', label: 'Suka', textColor: textColor),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: editBtnBg,
                            side: BorderSide(color: isDark ? borderColor : Colors.transparent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {},
                          icon: Icon(Icons.edit, color: primaryBlue, size: 18),
                          label: Text('Edit Profil', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: editBtnBg,
                            side: BorderSide(color: isDark ? borderColor : Colors.transparent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {},
                          icon: Icon(Icons.settings, color: primaryBlue, size: 18),
                          label: Text('Pengaturan', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tentang Saya (About Me)',
                          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Selamat Datang di MyDramaList!\nHalo! Saya Muhammad Nur Ilham. Saat ini saya adalah mahasiswa Teknik Informatika Universitas Negeri Surabaya (Unesa) semester 3. Aplikasi ini dibuat untuk memenuhi tugas mata kuliah Pemrograman Berbasis Platform (PBP).',
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // MENAMPILKAN HASIL PERHITUNGAN DINAMIS
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard('DRAMA', dramaTimeStr, '$dramaEpsWatched episode, $dramaCount drama', cardColor, borderColor, textColor)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoCard('FILM', filmTimeStr, '$filmCount film', cardColor, borderColor, textColor)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pembaruan Terakhir', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () {
                          globalNavIndex.value = 1; // Pindah ke tab daftar
                        },
                        child: Text('Lihat Daftar', style: TextStyle(color: primaryBlue, fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // LIST PEMBARUAN TERAKHIR
                  SizedBox(
                    height: 240, 
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal, 
                      physics: const BouncingScrollPhysics(),
                      itemCount: dramaList.length,
                      itemBuilder: (context, index) {
                        final Drama item = dramaList[index]; 
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => DetailPage(drama: item)),
                            );
                          },
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 14),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      child: Image.network(item.image, height: 160, width: double.infinity, fit: BoxFit.cover),
                                    ),
                                    Positioned(
                                      top: 8, right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(6)),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 12),
                                            const SizedBox(width: 4),
                                            Text(item.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.title, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text(item.genre.split('•')[0].trim(), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  _buildMenuRow('Feed', '0', cardColor, borderColor, textColor),
                  _buildMenuRow('Komentar', '0', cardColor, borderColor, textColor),
                  _buildMenuRow('Ulasan', '0', cardColor, borderColor, textColor),
                  _buildMenuRow('Ulasan Episode', '0', cardColor, borderColor, textColor),
                  _buildMenuRow('Rekomendasi', '0', cardColor, borderColor, textColor),
                  _buildMenuRow('Daftar Kustom', '0', cardColor, borderColor, textColor),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statItem({required String number, required String label, required Color textColor}) {
    return Column(
      children: [
        Text(number, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildInfoCard(String title, String time, String desc, Color cardColor, Color borderColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(time, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Waktu Tonton', style: TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 12),
          Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildMenuRow(String title, String count, Color cardColor, Color borderColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
          Text(count, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
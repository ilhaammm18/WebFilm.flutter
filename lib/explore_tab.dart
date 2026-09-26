import 'package:flutter/material.dart';
import 'app_drawer.dart';
import 'detail_page.dart';
import 'models/drama.dart';
import 'data/shared_data.dart';
import 'main_navigation.dart';
import 'search_page.dart';
import 'see_all_page.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: Text('Jelajahi', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: textColor),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchPage()));
            }
          ),
          IconButton(icon: Icon(Icons.notifications_none, color: textColor), onPressed: () {}),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryBlue,
          dividerColor: Colors.transparent, // Menghilangkan garis
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'UNTUK ANDA'),
            Tab(text: 'DRAMA'),
            Tab(text: 'FILM'),
            Tab(text: 'ANIME'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Tab UNTUK ANDA (Personal)
          _buildUntukAndaTab(textColor, primaryBlue),
          
          // 2. Tab DRAMA
          _buildCategoryTab('Drama', textColor, primaryBlue),
          
          // 3. Tab FILM
          _buildCategoryTab('Film', textColor, primaryBlue),
          
          // 4. Tab ANIME
          _buildCategoryTab('Anime', textColor, primaryBlue),
        ],
      ),
    );
  }

  // ===========================================================================
  // WIDGET BARU: PEMBUAT TAB KATEGORI (DRAMA / FILM / ANIME)
  // ===========================================================================
  Widget _buildCategoryTab(String category, Color textColor, Color primaryBlue) {
    return ValueListenableBuilder<List<Drama>>(
      valueListenable: SharedData.dramaListNotifier,
      builder: (context, dramaList, _) {
        
        // 1. Filter Data Utama Berdasarkan Kategori
        List<Drama> categoryData = dramaList.where((d) {
          if (category == 'Drama') return d.genre.contains('Drama') || d.episodes > 1;
          if (category == 'Film') return d.genre.contains('Film') || d.episodes == 1;
          if (category == 'Anime') return d.genre.contains('Anime');
          return false;
        }).toList();

        // Tampilan khusus jika data kosong (khususnya untuk Anime)
        if (categoryData.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.movie_creation_outlined, size: 64, color: Colors.grey.shade600),
                const SizedBox(height: 16),
                Text('Belum ada data $category', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              ],
            ),
          );
        }

        // 2. Siapkan logika penyaringan data untuk setiap seksi
        // Trending: Diurutkan berdasarkan rating terbaik
        List<Drama> trending = List.from(categoryData)..sort((a, b) => b.rating.compareTo(a.rating));
        trending = trending.take(10).toList();

        // Segera Datang: Diacak (simulasi film/drama yang akan datang)
        List<Drama> comingSoon = List.from(categoryData)..shuffle();
        comingSoon = comingSoon.take(10).toList();

        // Rekomendasi/Teratas: Rating di atas 8.0 lalu diacak
        List<Drama> recommended = List.from(categoryData)..sort((a, b) => b.rating.compareTo(a.rating));
        recommended = recommended.where((d) => d.rating >= 8.0).toList();
        recommended.shuffle();
        recommended = recommended.take(10).toList();

        // 3. Atur Judul Seksi sesuai permintaanmu
        String section1Title = category == 'Film' ? 'Film Teratas' : 'Trending Minggu Ini';
        List<Drama> section1Data = category == 'Film' ? recommended : trending;

        String section2Title = 'Segera Datang';
        List<Drama> section2Data = comingSoon;

        String section3Title = category == 'Film' ? 'Trending Minggu Ini' : 'Rekomendasi';
        List<Drama> section3Data = category == 'Film' ? trending : recommended;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // SEKSI 1
              _buildSectionHeader(section1Title, textColor, primaryBlue, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SeeAllPage(title: section1Title, dramaList: section1Data)));
              }),
              _buildHorizontalList(section1Data, textColor),

              const SizedBox(height: 24),
              
              // SEKSI 2
              _buildSectionHeader(section2Title, textColor, primaryBlue, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SeeAllPage(title: section2Title, dramaList: section2Data)));
              }),
              _buildHorizontalList(section2Data, textColor),

              const SizedBox(height: 24),
              
              // SEKSI 3
              _buildSectionHeader(section3Title, textColor, primaryBlue, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SeeAllPage(title: section3Title, dramaList: section3Data)));
              }),
              _buildHorizontalList(section3Data, textColor),
              
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // WIDGET TAB: UNTUK ANDA
  // ===========================================================================
  Widget _buildUntukAndaTab(Color textColor, Color primaryBlue) {
    return ValueListenableBuilder<List<Drama>>(
      valueListenable: SharedData.dramaListNotifier,
      builder: (context, dramaList, _) {
        
        List<Drama> recommended = dramaList.where((d) => d.rating >= 8.5).toList();
        recommended.shuffle(); 

        List<Drama> watching = dramaList.where((d) => d.status == 'Sedang Menonton' || d.watchedEpisodes > 0).toList();
        List<Drama> myWatchlist = dramaList.take(8).toList();

        List<Drama> trending = List.from(dramaList);
        trending.sort((a, b) => b.rating.compareTo(a.rating));
        trending = trending.take(10).toList();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildSectionHeader('Direkomendasikan Untuk Anda', textColor, primaryBlue, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SeeAllPage(title: 'Direkomendasikan Untuk Anda', dramaList: recommended)));
              }),
              _buildHorizontalList(recommended, textColor),

              if (watching.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSectionHeader('Sedang Ditonton Sekarang', textColor, primaryBlue, () {
                  globalNavIndex.value = 1; 
                }),
                _buildHorizontalList(watching, textColor),
              ],

              const SizedBox(height: 24),
              _buildSectionHeader('Daftar Tonton Saya', textColor, primaryBlue, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SeeAllPage(title: 'Daftar Tonton Saya', dramaList: myWatchlist)));
              }),
              _buildHorizontalList(myWatchlist, textColor),

              const SizedBox(height: 32),
              _buildSectionHeader('Sedang Tren', textColor, primaryBlue, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SeeAllPage(title: 'Sedang Tren', dramaList: trending)));
              }),
              _buildHorizontalList(trending, textColor),
              
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // WIDGET PEMBANTU (HEADER & LIST)
  // ===========================================================================
  Widget _buildSectionHeader(String title, Color textColor, Color primaryBlue, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold))),
          GestureDetector(
            onTap: onSeeAll,
            child: Text('Lihat Semua', style: TextStyle(color: primaryBlue, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalList(List<Drama> list, Color textColor) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final Drama item = list[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(drama: item)));
            },
            child: Container(
              width: 120,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item.image, 
                          height: 170, 
                          width: 120, 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(height: 170, width: 120, color: Colors.grey.shade800, child: const Icon(Icons.movie, color: Colors.grey)),
                        ),
                      ),
                      Positioned(
                        top: 6, right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(6)),
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
                  const SizedBox(height: 8),
                  Text(item.title, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(item.genre, style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
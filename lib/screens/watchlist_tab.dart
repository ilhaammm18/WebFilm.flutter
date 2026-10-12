import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../models/drama.dart';
import '../data/shared_data.dart';
import 'detail_page.dart';
import '../utils/helpers.dart';

class WatchlistTab extends StatefulWidget {
  const WatchlistTab({super.key});

  @override
  State<WatchlistTab> createState() => _WatchlistTabState();
}

class _WatchlistTabState extends State<WatchlistTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua'; 
  final String _selectedSort = 'Baru Ditambahkan';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = isDark ? const Color(0xFF15171E) : const Color(0xFFF8F9FA);
    Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    Color subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    Color primaryBlue = const Color(0xFF0094FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor), 
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: textColor, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Cari di daftar saya...',
                hintStyle: TextStyle(color: subTextColor),
                border: InputBorder.none,
              ),
              onChanged: (value) => setState(() {
                _searchQuery = value;
              }),
            )
          : Text('Daftar Saya', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: textColor),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                  _isSearching = false;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              _selectedCategory == 'Semua' ? Icons.tune : Icons.filter_alt, 
              color: _selectedCategory == 'Semua' ? textColor : primaryBlue,
            ),
            tooltip: 'Pilih Kategori',
            onPressed: () => _showCategoryFilterBottomSheet(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryBlue,
          dividerColor: Colors.transparent,
          isScrollable: true,
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: 'SEDANG MENONTON'),
            Tab(text: 'SELESAI'),
            Tab(text: 'RENCANA DITONTON'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDaftarTab('Sedang Menonton'),
          _buildDaftarTab('Selesai'),
          _buildDaftarTab('Rencana Ditonton'),
        ],
      ),
    );
  }

  // Modal Bottom Sheet Filter Kategori ('Semua', 'Film', 'Drama', 'Animasi')
  void _showCategoryFilterBottomSheet(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF1E2129) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final Color primaryBlue = const Color(0xFF0094FF);

    final List<String> categories = ['Semua', 'Film', 'Drama', 'Animasi'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Material(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar kecil
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Judul 'Pilih Kategori'
                Text(
                  'Pilih Kategori',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Deretan ListTile sederhana untuk opsi: 'Semua', 'Film', 'Drama', dan 'Animasi'
                ...categories.map((category) {
                  final bool isSelected = _selectedCategory == category;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? primaryBlue : textColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_rounded, color: primaryBlue, size: 20)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDaftarTab(String statusFilter) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = isDark ? const Color(0xFF1F222A) : Colors.white;
    Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    Color subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    Color primaryBlue = const Color(0xFF0094FF);

    return ValueListenableBuilder<List<Drama>>(
      valueListenable: SharedData.dramaListNotifier,
      builder: (context, dramaList, _) {
        
        List<Drama> filteredList = dramaList.where((item) {
          // Filter Status Tab
          if (item.status != statusFilter) return false;

          // Logika Pencarian
          if (_searchQuery.isNotEmpty &&
              !item.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
            return false;
          }

          // Logika Kategori Ketat
          if (_selectedCategory == 'Film' && item.mediaType != 'movie') return false;
          if (_selectedCategory == 'Drama' && item.mediaType != 'tv') return false;
          if (_selectedCategory == 'Animasi' &&
              (item.genreIds.contains(16) == false &&
                  !item.genre.toLowerCase().contains('animasi') &&
                  !item.genre.toLowerCase().contains('anime'))) {
            return false;
          }

          return true;
        }).toList();

        // Sorting lokal watchlist (menggunakan list.sort())
        if (_selectedSort == 'Peringkat Teratas' || _selectedSort == 'Rating Tertinggi') {
          filteredList.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
        } else if (_selectedSort == 'Paling Populer' || _selectedSort == 'Kepopuleran') {
          filteredList.sort((a, b) {
            double popA = double.tryParse(a.popularity.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
            double popB = double.tryParse(b.popularity.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
            if (popA != popB) return popB.compareTo(popA);
            return b.popularity.compareTo(a.popularity);
          });
        } else if (_selectedSort == 'Tahun Rilis') {
          filteredList.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
        } else if (_selectedSort == 'Baru Ditambahkan') {
          filteredList.sort((a, b) {
            if (a.dateCompleted != null && b.dateCompleted != null) {
              return b.dateCompleted!.compareTo(a.dateCompleted!);
            } else if (b.dateCompleted != null) {
              return 1;
            } else if (a.dateCompleted != null) {
              return -1;
            }
            return b.id.compareTo(a.id);
          });
        }

        if (filteredList.isEmpty) {
          final String emptyMessage = _searchQuery.trim().isNotEmpty
              ? 'Film/Drama tidak ditemukan'
              : (_selectedCategory != 'Semua'
                  ? 'Tidak ada $_selectedCategory yang cocok'
                  : 'Belum ada data untuk $statusFilter');
          return Center(
            child: Text(
              emptyMessage, 
              style: TextStyle(color: subTextColor, fontSize: 15),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final Drama item = filteredList[index];
            
            // Logika conditional penilaian:
            // Jika statusnya 'Selesai' dan userRating > 0, maka tampilkan nilai userRating.
            // Jika belum selesai atau belum dinilai, barulah tampilkan rating global.
            String displayRating;
            if (item.status == 'Selesai' && item.userRating != null && item.userRating! > 0) {
              displayRating = item.userRating!.toStringAsFixed(1);
            } else {
              displayRating = item.rating.toStringAsFixed(1);
            }

            final String heroTag = 'poster_${item.id > 0 ? item.id : item.title}';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailPage(
                      drama: item,
                      heroTag: heroTag,
                      posterUrl: item.image,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                // Tampilan card melayang (elevated) dengan bayangan lembut
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.35)
                          : primaryBlue.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // POSTER DENGAN HERO ANIMATION
                    Hero(
                      tag: heroTag,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          item.image, 
                          width: 72, 
                          height: 108, 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 72, 
                            height: 108, 
                            color: isDark ? const Color(0xFF222734) : Colors.grey.shade300,
                            child: const Icon(Icons.movie_rounded, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    
                    // KONTEN KANAN
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '${item.genre.split('•')[0].trim()} • 2025',
                                      style: TextStyle(color: subTextColor, fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    if (statusFilter == 'Selesai' || item.status == 'Selesai')
                                      // BARIS INFORMASI KHUSUS STATUS SELESAI
                                      Row(
                                        children: [
                                          // Bagian 1: Rating
                                          const Icon(Icons.star, color: Colors.amber, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            displayRating,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 16),

                                          // Bagian 2: Episode (Kondisional: HANYA JIKA mediaType == 'tv')
                                          if (item.mediaType == 'tv') ...[
                                            Icon(Icons.featured_play_list, color: subTextColor, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${item.episodes}',
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                          ],

                                          // Bagian 3: Tanggal Selesai (Format: dd/MM/yyyy, misal: '16/10/2026')
                                          Icon(Icons.calendar_today, color: subTextColor, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            formatDate(item.dateCompleted ?? DateTime.now()),
                                            style: TextStyle(
                                              color: subTextColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      )
                                    else if (statusFilter == 'Rencana Ditonton' || item.status == 'Rencana Ditonton')
                                      // BARIS INFORMASI KHUSUS STATUS RENCANA DITONTON (Rating + Ikon Abu-abu & Total Episode)
                                      Row(
                                        children: [
                                          // Kiri: Ikon Bintang Emas dan teks Rating
                                          const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            displayRating,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          // Kanan (Khusus Drama / Serial): Ikon abu-abu + Angka total episode
                                          if (item.mediaType != 'movie' && !item.isMovie && !item.genre.toLowerCase().contains('film')) ...[
                                            const SizedBox(width: 16),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.subtitles_rounded,
                                                  size: 18.0,
                                                  color: Colors.grey.shade400,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '${item.episodes}',
                                                  style: TextStyle(
                                                    color: isDark ? Colors.white : textColor,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      )
                                    else
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            displayRating,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              // TOMBOL EDIT (PENA)
                              GestureDetector(
                                onTap: () async {
                                  await showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => EditDramaModal(drama: item),
                                  );
                                  if (mounted) setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100, 
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Icon(Icons.edit_outlined, color: subTextColor, size: 18),
                                ),
                              ),
                            ],
                          ),
                          
                          // HANYA UNTUK STATUS 'Sedang Menonton' (Bukan Selesai dan Bukan Rencana Ditonton)
                          if (statusFilter == 'Sedang Menonton' ||
                              (statusFilter != 'Selesai' &&
                                  statusFilter != 'Rencana Ditonton' &&
                                  item.status == 'Sedang Menonton')) ...[
                            if (item.mediaType != 'movie' && !item.isMovie && !item.genre.toLowerCase().contains('film')) ...[
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progres: ${item.watchedEpisodes}/${item.episodes}', 
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${item.progressPercentInt}%',
                                    style: TextStyle(
                                      color: statusFilter == 'Sedang Menonton' ? primaryBlue : subTextColor,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),
                              
                              // GARIS PROGRESS BAR
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: item.progressPercentage,
                                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    statusFilter == 'Sedang Menonton' ? primaryBlue : Colors.grey.shade600,
                                  ),
                                  minHeight: 3,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'app_drawer.dart';
import 'models/drama.dart';
import 'data/shared_data.dart';
import 'detail_page.dart';

class WatchlistTab extends StatefulWidget {
  const WatchlistTab({super.key});

  @override
  State<WatchlistTab> createState() => _WatchlistTabState();
}

class _WatchlistTabState extends State<WatchlistTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  String _searchQuery = '';
  String _selectedCategory = 'Semua'; 
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
              autofocus: true,
              style: TextStyle(color: textColor, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Cari judul...',
                hintStyle: TextStyle(color: subTextColor),
                border: InputBorder.none,
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            )
          : Text('Daftar Saya', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search_outlined, color: textColor),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = '';
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedCategory = value),
            color: isDark ? const Color(0xFF2C2C34) : Colors.white,
            icon: Icon(
              _selectedCategory == 'Semua' ? Icons.tune : Icons.filter_alt, 
              color: _selectedCategory == 'Semua' ? textColor : primaryBlue,
            ),
            itemBuilder: (context) => [
              _buildPopupItem('Semua', isDark, primaryBlue),
              _buildPopupItem('Drama', isDark, primaryBlue),
              _buildPopupItem('Film', isDark, primaryBlue),
              _buildPopupItem('Anime', isDark, primaryBlue),
            ],
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

  PopupMenuItem<String> _buildPopupItem(String title, bool isDark, Color primaryBlue) {
    bool isSelected = _selectedCategory == title;
    return PopupMenuItem<String>(
      value: title,
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? primaryBlue : (isDark ? Colors.white : Colors.black),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
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
        
        List<Drama> filteredList = dramaList.where((d) {
          bool matchStatus = d.status == statusFilter;
          bool matchSearch = d.title.toLowerCase().contains(_searchQuery);
          bool matchCategory = true;
          
          if (_selectedCategory == 'Drama') {
            matchCategory = d.genre.contains('Drama') || d.episodes > 1;
          } else if (_selectedCategory == 'Film') {
            matchCategory = d.genre.contains('Film') || d.episodes == 1;
          } else if (_selectedCategory == 'Anime') {
            matchCategory = d.genre.contains('Anime');
          }

          return matchStatus && matchSearch && matchCategory;
        }).toList();

        if (filteredList.isEmpty) {
          return Center(
            child: Text(
              _searchQuery.isNotEmpty || _selectedCategory != 'Semua'
                  ? 'Tidak ada $_selectedCategory yang cocok'
                  : 'Belum ada data untuk $statusFilter', 
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

            return GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(drama: item)));
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
                      tag: 'drama-poster-${item.title}',
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
                          
                          const SizedBox(height: 10),
                          
                          // INFORMASI PROGRES
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
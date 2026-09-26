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
              style: TextStyle(color: subTextColor, fontSize: 15)
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final Drama item = filteredList[index];
            
            String displayRating;
            if (item.status == 'Sedang Menonton') {
              displayRating = '0.0';
            } else {
              displayRating = item.rating.toStringAsFixed(1);
            }

            return GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(drama: item)));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // POSTER
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.image, 
                        width: 70, 
                        height: 105, 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(width: 70, height: 105, color: Colors.grey.shade800),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
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
                                    Text(item.title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 6),
                                    Text('${item.genre.split('•')[0].trim()} • 2025', style: TextStyle(color: subTextColor, fontSize: 12)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 14),
                                        const SizedBox(width: 4),
                                        Text(displayRating, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // TOMBOL EDIT (PENA)
                              GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => EditDramaModal(drama: item),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200, 
                                    borderRadius: BorderRadius.circular(8)
                                  ),
                                  child: Icon(Icons.edit_outlined, color: subTextColor, size: 18),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // ===================================================
                          // FITUR TAMBAH EPISODE KHUSUS TAB "SEDANG MENONTON"
                          // ===================================================
                          if (statusFilter == 'Sedang Menonton') ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Progres: ${item.watchedEpisodes}/${item.episodes}', 
                                  style: TextStyle(color: subTextColor, fontSize: 11)
                                ),
                                // Tombol Cepat Tambah Episode (+1)
                                GestureDetector(
                                  onTap: () {
                                    // Logika menambah 1 episode
                                    if (item.watchedEpisodes < item.episodes) {
                                      setState(() {
                                        item.watchedEpisodes++;
                                        // Jika sudah mencapai total episode, otomatis ubah status jadi Selesai!
                                        if (item.watchedEpisodes >= item.episodes) {
                                          item.status = 'Selesai';
                                        }
                                      });
                                      SharedData.dramaListNotifier.notifyListeners();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryBlue.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.add, color: primaryBlue, size: 14),
                                        const SizedBox(width: 2),
                                        Text('Episode', style: TextStyle(color: primaryBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Teks Progres Biasa untuk Tab Lainnya
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${item.watchedEpisodes}/${item.episodes}', 
                                style: TextStyle(color: subTextColor, fontSize: 11)
                              ),
                            ),
                          ],

                          const SizedBox(height: 4),
                          
                          // GARIS PROGRESS BAR TIPIS
                          LinearProgressIndicator(
                            value: item.episodes > 0 ? item.watchedEpisodes / item.episodes : 0,
                            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(statusFilter == 'Sedang Menonton' ? primaryBlue : Colors.grey.shade700),
                            minHeight: 2,
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
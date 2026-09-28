import 'package:flutter/material.dart';
import 'models/drama.dart';
import 'data/shared_data.dart';
import 'detail_page.dart'; 

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    Color cardColor = isDark ? const Color(0xFF1F222A) : Colors.white;
    Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    Color subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    Color primaryBlue = const Color(0xFF0094FF);
    Color inputBg = isDark ? const Color(0xFF1F222A) : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade300),
                      ),
                      child: TextField(
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Cari',
                          hintStyle: TextStyle(color: subTextColor, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          suffixIcon: Icon(Icons.search, color: subTextColor, size: 20),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Menu PopupMenuButton untuk filter kategori ('Semua', 'Drama', 'Film', 'Anime')
                  PopupMenuButton<String>(
                    initialValue: _selectedCategory,
                    tooltip: 'Filter Kategori',
                    color: isDark ? const Color(0xFF1F222A) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    itemBuilder: (context) => [
                      _buildCategoryPopupItem('Semua', isDark, primaryBlue),
                      _buildCategoryPopupItem('Drama', isDark, primaryBlue),
                      _buildCategoryPopupItem('Film', isDark, primaryBlue),
                      _buildCategoryPopupItem('Anime', isDark, primaryBlue),
                    ],
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedCategory == 'Semua' ? inputBg : primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedCategory == 'Semua'
                              ? (isDark ? Colors.transparent : Colors.grey.shade300)
                              : primaryBlue.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(
                        Icons.tune,
                        color: _selectedCategory == 'Semua' ? subTextColor : primaryBlue,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            TabBar(
              controller: _tabController,
              labelColor: primaryBlue,
              unselectedLabelColor: subTextColor,
              indicatorColor: primaryBlue,
              dividerColor: Colors.transparent, 
              tabs: const [
                Tab(text: 'JUDUL'),
                Tab(text: 'AKTOR'),
              ],
            ),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildJudulTab(cardColor, textColor, subTextColor),
                  const Center(child: Text('Data Aktor Belum Tersedia', style: TextStyle(color: Colors.grey))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildCategoryPopupItem(String title, bool isDark, Color primaryBlue) {
    bool isSelected = _selectedCategory == title;
    return PopupMenuItem<String>(
      value: title,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: isSelected ? primaryBlue : Colors.grey,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? primaryBlue : (isDark ? Colors.white : Colors.black87),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJudulTab(Color cardColor, Color textColor, Color subTextColor) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color primaryBlue = const Color(0xFF0094FF);

    return ValueListenableBuilder<List<Drama>>(
      valueListenable: SharedData.dramaListNotifier,
      builder: (context, dramaList, _) {
        
        // Filter berdasarkan query teks DAN kategori yang dipilih
        List<Drama> searchResults = dramaList.where((d) {
          bool matchesQuery = d.title.toLowerCase().contains(_searchQuery) ||
              d.koreanTitle.toLowerCase().contains(_searchQuery);
          if (!matchesQuery) return false;

          if (_selectedCategory == 'Semua') return true;
          if (_selectedCategory == 'Drama') {
            return d.genre.toLowerCase().contains('drama') || d.episodes > 1;
          }
          if (_selectedCategory == 'Film') {
            return d.genre.toLowerCase().contains('film') || d.episodes == 1;
          }
          if (_selectedCategory == 'Anime') {
            return d.genre.toLowerCase().contains('anime') ||
                d.genresList.any((g) => g.toLowerCase().contains('anime')) ||
                d.tagsList.any((t) => t.toLowerCase().contains('anime'));
          }
          return true;
        }).toList();

        searchResults.sort((a, b) => b.rating.compareTo(a.rating));

        if (searchResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 54, color: subTextColor.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  'Tidak ditemukan judul yang cocok',
                  style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                if (_selectedCategory != 'Semua') ...[
                  const SizedBox(height: 6),
                  Text(
                    'Kategori: $_selectedCategory',
                    style: TextStyle(color: subTextColor, fontSize: 13),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          itemCount: searchResults.length,
          itemBuilder: (context, index) {
            final Drama item = searchResults[index];
            
            // LOGIKA CERDAS: Cek apakah film sudah masuk daftar tonton
            bool isInWatchlist = ['Selesai', 'Sedang Menonton', 'Rencana Ditonton'].contains(item.status);
            
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
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.image, 
                        width: 60, 
                        height: 85, 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(width: 60, height: 85, color: Colors.grey.shade800),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Text('${item.genre.split('•')[0].trim()}  •  2025', style: TextStyle(color: subTextColor, fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                item.rating.toStringAsFixed(1), 
                                style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.list_alt, color: subTextColor, size: 14),
                              const SizedBox(width: 4),
                              Text('${item.episodes}', style: TextStyle(color: subTextColor, fontSize: 13)),
                              const SizedBox(width: 12),
                              Icon(Icons.trending_up, color: subTextColor, size: 14),
                              const SizedBox(width: 4),
                              Text('#${index + 1}', style: TextStyle(color: subTextColor, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // TOMBOL DINAMIS: PENA (EDIT) ATAU PLUS (TAMBAH)
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isInWatchlist
                              ? (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100)
                              : primaryBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // JIKA ADA DI DAFTAR TAMPILKAN PENA (Icons.edit), JIKA BELUM TAMPILKAN PLUS (Icons.add)
                        child: Icon(
                          isInWatchlist ? Icons.edit : Icons.add, 
                          color: isInWatchlist ? subTextColor : primaryBlue, 
                          size: 20,
                        ),
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
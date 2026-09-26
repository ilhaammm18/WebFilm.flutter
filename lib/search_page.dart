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
                          hintStyle: TextStyle(color: subTextColor, fontSize: 14),
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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.swap_vert, color: subTextColor, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.tune, color: subTextColor, size: 20),
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
                Tab(text: 'ORANG'),
              ],
            ),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildJudulTab(cardColor, textColor, subTextColor),
                  const Center(child: Text('Data Orang Belum Tersedia', style: TextStyle(color: Colors.grey))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJudulTab(Color cardColor, Color textColor, Color subTextColor) {
    return ValueListenableBuilder<List<Drama>>(
      valueListenable: SharedData.dramaListNotifier,
      builder: (context, dramaList, _) {
        
        List<Drama> searchResults = dramaList.where((d) => d.title.toLowerCase().contains(_searchQuery)).toList();
        searchResults.sort((a, b) => b.rating.compareTo(a.rating));

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
                    
                    // TOMBOL DINAMIS: PENA ATAU PLUS
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
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white.withValues(alpha: 0.05) 
                              : Colors.grey.shade200, 
                          borderRadius: BorderRadius.circular(8)
                        ),
                        // JIKA ADA DI DAFTAR TAMPILKAN PENA, JIKA BELUM TAMPILKAN PLUS
                        child: Icon(
                          isInWatchlist ? Icons.edit_outlined : Icons.add, 
                          color: subTextColor, 
                          size: 20
                        ),
                      ),
                    )
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
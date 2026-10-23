import 'package:flutter/material.dart';
import '../routes/app_router.dart';
import '../data/shared_data.dart';
import '../models/drama.dart';
import '../widgets/edit_drama_modal.dart';
import 'detail_page.dart';

class SeeAllPage extends StatelessWidget {
  final String title;
  final List<Drama> dramaList;

  const SeeAllPage({
    super.key, 
    required this.title, 
    required this.dramaList
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Warna diatur persis seperti referensi screenshot-mu
    Color bgColor = isDark ? const Color(0xFF15171E) : const Color(0xFFF8F9FA);
    Color cardColor = isDark ? const Color(0xFF1F222A) : Colors.white;
    Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    Color subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    Color borderColor = isDark ? Colors.transparent : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title, 
          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)
        ),
      ),
      body: ValueListenableBuilder<List<Drama>>(
        valueListenable: SharedData.dramaListNotifier,
        builder: (context, userWatchlist, _) {
          final List<int> savedMovieIds = userWatchlist
              .where((d) =>
                  d.status == 'Rencana Ditonton' ||
                  d.status == 'Sedang Menonton' ||
                  d.status == 'Selesai')
              .map((d) => d.id)
              .where((id) => id > 0)
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: dramaList.length,
            itemBuilder: (context, index) {
              final Drama item = dramaList[index];
              final String heroTag = 'see_all_${item.id > 0 ? item.id : item.title}';
              
              Drama? matchedWatchlist;
              if (item.id > 0 && savedMovieIds.contains(item.id)) {
                try {
                  matchedWatchlist = userWatchlist.firstWhere(
                    (d) => d.id == item.id,
                  );
                } catch (_) {
                  matchedWatchlist = null;
                }
              }

              final bool isSaved = item.id > 0 && savedMovieIds.contains(item.id);

              return GestureDetector(
                onTap: () {
                  context.push(
                    '/movie/${item.id}',
                    extra: {
                      'drama': item,
                      'heroTag': heroTag,
                      'posterUrl': item.image,
                    },
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: isDark ? [] : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      // POSTER
                      Hero(
                        tag: heroTag,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.image, 
                            width: 60, 
                            height: 85, 
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60, height: 85,
                                color: Colors.grey.shade800,
                                child: const Icon(Icons.movie, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // INFORMASI JUDUL & TAHUN
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${item.genre.split('â€¢')[0].trim()}  â€¢  2023',
                              style: TextStyle(color: subTextColor, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      
                      // TOMBOL AKSI (+ / EDIT) DI KANAN strictly berdasarkan ID
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          if (matchedWatchlist != null) {
                            final savedItem = matchedWatchlist;
                            final dramaToEdit = item.copyWith(
                              status: savedItem.status,
                              watchedEpisodes: savedItem.watchedEpisodes,
                              episodes: savedItem.episodes > 0 ? savedItem.episodes : item.episodes,
                              myRating: savedItem.userRating ?? savedItem.myRating,
                              userRating: savedItem.userRating ?? savedItem.myRating,
                              priority: savedItem.priority,
                              startDate: savedItem.startDate,
                              endDate: savedItem.endDate,
                              dateCompleted: savedItem.dateCompleted,
                            );

                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => EditDramaModal(
                                drama: dramaToEdit,
                                initialStatus: savedItem.status,
                              ),
                            );
                          } else {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => EditDramaModal(
                                drama: item,
                                initialStatus: 'Belum Ditonton',
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isSaved
                                ? Icons.edit_outlined
                                : Icons.add,
                            color: subTextColor,
                            size: 20,
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
      ),
    );
  }
}

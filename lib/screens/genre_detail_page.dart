import 'package:flutter/material.dart';
import '../models/drama.dart';
import '../services/api_service.dart';
import 'detail_page.dart';

class GenreDetailPage extends StatefulWidget {
  final String genreName;
  final int genreId;
  final ApiService? apiService;

  const GenreDetailPage({
    super.key,
    required this.genreName,
    required this.genreId,
    this.apiService,
  });

  @override
  State<GenreDetailPage> createState() => _GenreDetailPageState();
}

class _GenreDetailPageState extends State<GenreDetailPage> {
  late final ApiService _apiService;
  late Future<List<Drama>> _mediaFuture;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _mediaFuture = _apiService.getMediaByGenre(widget.genreId);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF15171E) : const Color(0xFFF8F9FA);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final Color subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final Color primaryBlue = const Color(0xFF0094FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.genreName,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<Drama>>(
        future: _mediaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: primaryBlue),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Gagal memuat film untuk genre ${widget.genreName}',
                style: TextStyle(color: subTextColor, fontSize: 14),
              ),
            );
          }

          final List<Drama> mediaList = snapshot.data ?? [];

          if (mediaList.isEmpty) {
            return Center(
              child: Text(
                'Tidak ada film untuk genre ${widget.genreName}',
                style: TextStyle(color: subTextColor, fontSize: 14),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            itemCount: mediaList.length,
            itemBuilder: (context, index) {
              final Drama item = mediaList[index];
              final String releaseYear = item.releaseDate.length >= 4
                  ? item.releaseDate.substring(0, 4)
                  : (item.date.isNotEmpty ? item.date : '-');
              final String heroTag = 'genre_${widget.genreId}_${item.id > 0 ? item.id : item.title}';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailPage(
                        drama: item,
                        apiService: _apiService,
                        heroTag: heroTag,
                        posterUrl: item.image,
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Hero(
                        tag: heroTag,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (item.image.isNotEmpty)
                              ? Image.network(
                                  item.image,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: isDark
                                        ? const Color(0xFF222734)
                                        : Colors.grey.shade300,
                                    child: const Center(
                                      child: Icon(
                                        Icons.movie_rounded,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: isDark
                                      ? const Color(0xFF222734)
                                      : Colors.grey.shade300,
                                  child: const Center(
                                    child: Icon(
                                      Icons.movie_rounded,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$releaseYear • ★ ${item.rating.toStringAsFixed(1)}',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

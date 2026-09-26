class Drama {
  String title;
  String koreanTitle;
  String genre;
  double rating;
  int episodes;
  int watchedEpisodes;
  String status;
  String priority;
  String startDate;
  String endDate;
  String date;
  String image;
  String rank;
  String popularity;
  String watchers;
  String synopsis;
  String aired;
  String duration;
  String contentRating;
  List<String> genresList;
  List<String> tagsList;

  // Constructor (Pembangun Objek)
  Drama({
    required this.title,
    required this.koreanTitle,
    required this.genre,
    required this.rating,
    required this.episodes,
    required this.watchedEpisodes,
    required this.status,
    required this.priority,
    required this.startDate,
    required this.endDate,
    required this.date,
    required this.image,
    required this.rank,
    required this.popularity,
    required this.watchers,
    required this.synopsis,
    required this.aired,
    required this.duration,
    required this.contentRating,
    required this.genresList,
    required this.tagsList,
  });

  // METHOD PBO (Logika Cerdas di dalam Objek)
  // Ini yang akan dipuji oleh dosenmu! Logika tidak lagi ditaruh di UI.
  void updateProgress(int eps) {
    watchedEpisodes = eps;
    if (watchedEpisodes >= episodes) {
      status = 'Selesai';
    } else if (watchedEpisodes > 0) {
      status = 'Sedang Menonton';
    } else {
      status = 'Rencana Ditonton';
    }
  }

  void tandaiSelesai() {
    watchedEpisodes = episodes;
    status = 'Selesai';
  }
}
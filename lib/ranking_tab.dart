import 'package:flutter/material.dart';
import 'app_drawer.dart';
import 'detail_page.dart';
import 'models/drama.dart';
import 'data/shared_data.dart';

class RankingTab extends StatefulWidget {
  const RankingTab({super.key});

  @override
  State<RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends State<RankingTab> {
  // Set untuk menyimpan judul drama yang telah disimpan/dibookmark
  final Set<String> _savedDramaTitles = <String>{};

  // ==========================================
  // DUMMY DATA: RATING TERTINGGI (10 JUDUL)
  // ==========================================
  final List<Drama> _topRatedDramas = [
    Drama(
      title: 'Reply 1988',
      koreanTitle: '응답하라 1988',
      genre: 'Drama Korea',
      rating: 9.8,
      episodes: 20,
      watchedEpisodes: 0,
      status: 'Rencana Ditonton',
      priority: 'Tinggi',
      startDate: '',
      endDate: '',
      date: '2015',
      image: 'https://picsum.photos/seed/reply1988/500/750',
      rank: '#1',
      popularity: '#1',
      watchers: '250.5K',
      synopsis:
          'Kisah kehangatan persahabatan dan keharmonisan lima keluarga yang bertetangga di kawasan Ssangmun-dong pada tahun 1988.',
      aired: 'Nov 2015 - Jan 2016',
      duration: '1 jam 30 menit',
      contentRating: '15+',
      genresList: ['Comedy', 'Romance', 'Life', 'Family'],
      tagsList: ['Nostalgia', 'Neighborhood', 'Youth'],
    ),
    Drama(
      title: 'Parasite',
      koreanTitle: '기생충',
      genre: 'Film Korea',
      rating: 9.6,
      episodes: 1,
      watchedEpisodes: 0,
      status: 'Rencana Ditonton',
      priority: 'Tinggi',
      startDate: '',
      endDate: '',
      date: '2019',
      image: 'https://picsum.photos/seed/parasitefilm/500/750',
      rank: '#2',
      popularity: '#2',
      watchers: '310.2K',
      synopsis:
          'Keluarga Kim yang hidup dalam kemiskinan merancang skema cerdik untuk bekerja pada keluarga kaya raya Park.',
      aired: 'Mei 2019',
      duration: '2 jam 12 menit',
      contentRating: '18+',
      genresList: ['Thriller', 'Black Comedy', 'Drama'],
      tagsList: ['Oscar Winner', 'Social Commentary', 'Suspense'],
    ),
    Drama(
      title: 'Hospital Playlist',
      koreanTitle: '슬기로운 의사생활',
      genre: 'Drama Korea',
      rating: 9.5,
      episodes: 12,
      watchedEpisodes: 0,
      status: 'Rencana Ditonton',
      priority: 'Tinggi',
      startDate: '',
      endDate: '',
      date: '2020',
      image: 'https://picsum.photos/seed/hospitalplaylist/500/750',
      rank: '#3',
      popularity: '#5',
      watchers: '190.8K',
      synopsis:
          'Kehidupan lima dokter bersahabat sejak masa kuliah yang berbagi cinta pada musik dan berjuang merawat pasien bersama di rumah sakit.',
      aired: 'Mar 2020 - Mei 2020',
      duration: '1 jam 25 menit',
      contentRating: '15+',
      genresList: ['Medical', 'Friendship', 'Romance', 'Life'],
      tagsList: ['Band', 'Doctors', 'Heartwarming'],
    ),
    Drama(
      title: 'My Mister',
      koreanTitle: '나의 아저씨',
      genre: 'Drama Korea',
      rating: 9.5,
      episodes: 16,
      watchedEpisodes: 0,
      status: 'Rencana Ditonton',
      priority: 'Tinggi',
      startDate: '',
      endDate: '',
      date: '2018',
      image: 'https://picsum.photos/seed/mymister/500/750',
      rank: '#4',
      popularity: '#8',
      watchers: '145.0K',
      synopsis:
          'Seorang pria paruh baya yang terbebani kehidupan dan wanita muda yang dingin saling menyembuhkan luka batin satu sama lain.',
      aired: 'Mar 2018 - Mei 2018',
      duration: '1 jam 15 menit',
      contentRating: '15+',
      genresList: ['Psychological', 'Life', 'Drama'],
      tagsList: ['Healing', 'Melodrama', 'Masterpiece'],
    ),
    Drama(
      title: 'Crash Landing on You',
      koreanTitle: '사랑의 불시착',
      genre: 'Drama Korea',
      rating: 9.4,
      episodes: 16,
      watchedEpisodes: 0,
      status: 'Rencana Ditonton',
      priority: 'Tinggi',
      startDate: '',
      endDate: '',
      date: '2019',
      image: 'https://picsum.photos/seed/crashlanding/500/750',
      rank: '#5',
      popularity: '#3',
      watchers: '380.0K',
      synopsis:
          'Seorang pewaris kaya Korea Selatan mendarat darurat di Korea Utara akibat insiden paralayang dan diselamatkan oleh perwira militer.',
      aired: 'Des 2019 - Feb 2020',
      duration: '1 jam 20 menit',
      contentRating: '15+',
      genresList: ['Military', 'Comedy', 'Romance'],
      tagsList: ['North Korea', 'Star-Crossed Lovers', 'Popular'],
    ),
    Drama(
      title: 'Spirited Away',
      koreanTitle: '千と千尋の神隠し',
      genre: 'Film Jepang',
      rating: 9.4,
      episodes: 1,
      watchedEpisodes: 0,
      status: 'Rencana Ditonton',
      priority: 'Tinggi',
      startDate: '',
      endDate: '',
      date: '2001',
      image: 'https://picsum.photos/seed/spiritedaway/500/750',
      rank: '#6',
      popularity: '#4',
      watchers: '420.0K',
      synopsis:
          'Chihiro terjebak di dunia roh misterius dan harus bekerja di pemandian para dewa untuk menyelamatkan kedua orang tuanya.',
      aired: 'Jul 2001',
      duration: '2 jam 5 menit',
      contentRating: 'PG',
      genresList: ['Animation', 'Adventure', 'Fantasy'],
      tagsList: ['Studio Ghibli', 'Classic', 'Spirits'],
    ),
    Drama(
      title: 'Move to Heaven',
      koreanTitle: '무브 투 헤븐',
      genre: 'Drama Korea',
      rating: 9.3,
      episodes: 10,
      watchedEpisodes: 0,
      status: 'Rencana Ditonton',
      priority: 'Tinggi',
      startDate: '',
      endDate: '',
      date: '2021',
      image: 'https://picsum.photos/seed/movetoheaven/500/750',
      rank: '#7',
      popularity: '#12',
      watchers: '160.4K',
      synopsis:
          'Seorang pemuda dengan sindrom Asperger dan mantan pamannya mengelola bisnis pembersih trauma dan mengungkap pesan terakhir orang yang meninggal.',
      aired: 'Mei 2021',
      duration: '55 menit',
      contentRating: '18+',
      genresList: ['Life', 'Drama', 'Family'],
      tagsList: ['Autism', 'Tearjerker', 'Emotional'],
    ),
    Drama(
      title: 'Mr. Sunshine',
      koreanTitle: '미스터 션샤인',
      genre: 'Drama Korea',
      rating: 9.3,
      episodes: 24,
      watchedEpisodes: 0,
      status: 'Rencana Ditonton',
      priority: 'Tinggi',
      startDate: '',
      endDate: '',
      date: '2018',
      image: 'https://picsum.photos/seed/mrsunshine/500/750',
      rank: '#8',
      popularity: '#15',
      watchers: '135.0K',
      synopsis:
          'Seorang pria Joseon yang tumbuh di Amerika kembali ke tanah air sebagai perwira marinir di era pergolakan menjelang penjajahan Jepang.',
      aired: 'Jul 2018 - Sep 2018',
      duration: '1 jam 15 menit',
      contentRating: '15+',
      genresList: ['Historical', 'Romance', 'Melodrama'],
      tagsList: ['Patriotism', 'Joseon', 'Epic'],
    ),
    Drama(
      title: 'Twenty-Five Twenty-One',
      koreanTitle: '스물다섯 스물하나',
      genre: 'Drama Korea',
      rating: 9.2,
      episodes: 16,
      watchedEpisodes: 0,
      status: 'Rencana Ditonton',
      priority: 'Sedang',
      startDate: '',
      endDate: '',
      date: '2022',
      image: 'https://picsum.photos/seed/twentyfivetwentyone/500/750',
      rank: '#9',
      popularity: '#7',
      watchers: '210.0K',
      synopsis:
          'Di masa krisis ekonomi Asia 1998, seorang atlet anggar muda dan seorang pemuda pekerja keras berjuang menggapai impian masa muda mereka.',
      aired: 'Feb 2022 - Apr 2022',
      duration: '1 jam 15 menit',
      contentRating: '15+',
      genresList: ['Romance', 'Youth', 'Drama', 'Sports'],
      tagsList: ['Fencing', 'First Love', 'Coming of Age'],
    ),
    Drama(
      title: 'Signal',
      koreanTitle: '시그널',
      genre: 'Drama Korea',
      rating: 9.2,
      episodes: 16,
      watchedEpisodes: 0,
      status: 'Rencana Ditonton',
      priority: 'Sedang',
      startDate: '',
      endDate: '',
      date: '2016',
      image: 'https://picsum.photos/seed/signaldrama/500/750',
      rank: '#10',
      popularity: '#9',
      watchers: '175.0K',
      synopsis:
          'Dua detektif dari masa kini dan masa lalu berkomunikasi menggunakan walkie-talkie kuno untuk memecahkan kasus-kasus pembunuhan berantai tak terpecahkan.',
      aired: 'Jan 2016 - Mar 2016',
      duration: '1 jam 10 menit',
      contentRating: '15+',
      genresList: ['Thriller', 'Mystery', 'Sci-Fi'],
      tagsList: ['Time Slip', 'Cold Case', 'Investigation'],
    ),
  ];

  // ==========================================
  // DUMMY DATA: SEDANG TREN (10 JUDUL)
  // ==========================================
  final List<Drama> _trendingDramas = [
    Drama(
      title: 'Queen of Tears',
      koreanTitle: '눈물의 여왕',
      genre: 'Drama Korea',
      rating: 9.3,
      episodes: 16,
      watchedEpisodes: 0,
      status: 'Rencana Ditonton',
      priority: 'Tinggi',
      startDate: '',
      endDate: '',
      date: '2024',
      image: 'https://picsum.photos/seed/queentears/500/750',
      rank: '#1',
      popularity: '#1',
      watchers: '290.0K',
      synopsis:
          'Kisah pernikahan pewaris chaebol yang dingin dan pengacara cerdas dari desa yang kembali menemukan cinta di tengah badai krisis perkawinan.',
      aired: 'Mar 2024 - Apr 2024',
      duration: '1 jam 25 menit',
      contentRating: '15+',
      genresList: ['Romance', 'Comedy', 'Family'],
      tagsList: ['Chaebol', 'Married Couple', 'Top Trending'],
    ),
    Drama(
      title: 'Lovely Runner',
      koreanTitle: '선재 업고 튀어',
      genre: 'Drama Korea',
      rating: 9.2,
      episodes: 16,
      watchedEpisodes: 0,
      status: 'Rencana Ditonton',
      priority: 'Tinggi',
      startDate: '',
      endDate: '',
      date: '2024',
      image: 'https://picsum.photos/seed/lovelyrunner/500/750',
      rank: '#2',
      popularity: '#2',
      watchers: '230.5K',
      synopsis:
          'Seorang penggemar berat kembali ke masa lalu tahun 2008 demi menyelamatkan sang idola favoritnya dari takdir kematian tragis.',
      aired: 'Apr 2024 - Mei 2024',
      duration: '1 jam 10 menit',
      contentRating: '15+',
      genresList: ['Romance', 'Fantasy', 'Comedy'],
      tagsList: ['Time Travel', 'Idol', 'High School'],
    ),
    Drama(
      title: 'Exhuma',
      koreanTitle: '파묘',
      genre: 'Film Korea',
      rating: 9.0,
      episodes: 1,
      watchedEpisodes: 0,
      status: 'Rencana Ditonton',
      priority: 'Tinggi',
      startDate: '',
      endDate: '',
      date: '2024',
      image: 'https://picsum.photos/seed/exhumamovie/500/750',
      rank: '#3',
      popularity: '#3',
      watchers: '180.0K',
      synopsis:
          'Dua dukun muda, seorang ahli geomansi, dan petugas pemakaman menggali kuburan misterius demi imbalan besar, namun melepaskan kekuatan jahat kuno.',
      aired: 'Feb 2024',
      duration: '2 jam 14 menit',
      contentRating: '18+',
      genresList: ['Horror', 'Mystery', 'Thriller'],
      tagsList: ['Shamanism', 'Supernatural', 'Box Office Hit'],
    ),
    Drama(
      title: 'Marry My Husband',
      koreanTitle: '내 남편과 결혼해줘',
      genre: 'Drama Korea',
      rating: 8.9,
      episodes: 16,
      watchedEpisodes: 0,
      status: 'Rencana Ditonton',
      priority: 'Sedang',
      startDate: '',
      endDate: '',
      date: '2024',
      image: 'https://picsum.photos/seed/marrymyhusband/500/750',
      rank: '#4',
      popularity: '#4',
      watchers: '205.0K',
      synopsis:
          'Seorang wanita yang dikhianati dan dibunuh oleh suami serta sahabatnya terbangun 10 tahun di masa lalu untuk membalaskan dendamnya.',
      aired: 'Jan 2024 - Feb 2024',
      duration: '1 jam 10 menit',
      contentRating: '15+',
      genresList: ['Revenge', 'Romance', 'Fantasy'],
      tagsList: ['Reincarnation', 'Karma', 'Office'],
    ),
    Drama(
      title: 'A Killer Paradox',
      koreanTitle: '살인자ㅇ난감',
      genre: 'Drama Korea',
      rating: 8.8,
      episodes: 8,
      watchedEpisodes: 0,
      status: 'Rencana Ditonton',
      priority: 'Sedang',
      startDate: '',
      endDate: '',
      date: '2024',
      image: 'https://picsum.photos/seed/killerparadox/500/750',
      rank: '#5',
      popularity: '#6',
      watchers: '120.0K',
      synopsis:
          'Mahasiswa biasa yang tak sengaja membunuh orang jahat menyadari ia memiliki kemampuan supranatural mendeteksi penjahat.',
      aired: 'Feb 2024',
      duration: '50 menit',
      contentRating: '18+',
      genresList: ['Thriller', 'Crime', 'Dark Comedy'],
      tagsList: ['Vigilante', 'Cat and Mouse', 'Netflix'],
    ),
    Drama(
      title: 'Parasyte: The Grey',
      koreanTitle: '기생수: 더 그레이',
      genre: 'Drama Korea',
      rating: 8.7,
      episodes: 6,
      watchedEpisodes: 0,
      status: 'Rencana Ditonton',
      priority: 'Sedang',
      startDate: '',
      endDate: '',
      date: '2024',
      image: 'https://picsum.photos/seed/parasytethegrey/500/750',
      rank: '#6',
      popularity: '#8',
      watchers: '115.0K',
      synopsis:
          'Ketika parasit misterius jatuh dari luar angkasa dan menguasai tubuh manusia, sekelompok pejuang bersatu membasmi ancaman kepunahan.',
      aired: 'Apr 2024',
      duration: '50 menit',
      contentRating: '18+',
      genresList: ['Action', 'Sci-Fi', 'Horror'],
      tagsList: ['Alien', 'Body Horror', 'Survival'],
    ),
    Drama(
      title: 'Chief Detective 1958',
      koreanTitle: '수사반장 1958',
      genre: 'Drama Korea',
      rating: 8.7,
      episodes: 10,
      watchedEpisodes: 0,
      status: 'Rencana Ditonton',
      priority: 'Sedang',
      startDate: '',
      endDate: '',
      date: '2024',
      image: 'https://picsum.photos/seed/detective1958/500/750',
      rank: '#7',
      popularity: '#10',
      watchers: '95.0K',
      synopsis:
          'Prequel kisah legendaris detektif Park Yeong-han yang berjiwa keadilan dan rekan-rekannya menegakkan hukum di era korup pasca perang 1958.',
      aired: 'Apr 2024 - Mei 2024',
      duration: '1 jam 15 menit',
      contentRating: '15+',
      genresList: ['Action', 'Period', 'Crime'],
      tagsList: ['1950s', 'Detective', 'Justice'],
    ),
    Drama(
      title: 'The 8 Show',
      koreanTitle: '더 에이트 쇼',
      genre: 'Drama Korea',
      rating: 8.6,
      episodes: 8,
      watchedEpisodes: 0,
      status: 'Rencana Ditonton',
      priority: 'Sedang',
      startDate: '',
      endDate: '',
      date: '2024',
      image: 'https://picsum.photos/seed/the8show/500/750',
      rank: '#8',
      popularity: '#9',
      watchers: '105.0K',
      synopsis:
          'Delapan peserta terkurung dalam gedung 8 lantai untuk reality show berbahaya di mana mereka menghasilkan uang seiring berjalannya waktu.',
      aired: 'Mei 2024',
      duration: '55 menit',
      contentRating: '18+',
      genresList: ['Thriller', 'Psychological', 'Survival'],
      tagsList: ['Game Show', 'Greed', 'Social Hierarchy'],
    ),
    Drama(
      title: 'Doctor Slump',
      koreanTitle: '닥터 슬럼프',
      genre: 'Drama Korea',
      rating: 8.5,
      episodes: 16,
      watchedEpisodes: 0,
      status: 'Rencana Ditonton',
      priority: 'Sedang',
      startDate: '',
      endDate: '',
      date: '2024',
      image: 'https://picsum.photos/seed/doctorslump/500/750',
      rank: '#9',
      popularity: '#11',
      watchers: '140.0K',
      synopsis:
          'Dua rival masa sekolah yang kini menjadi dokter sukses sama-sama mengalami titik terendah dalam karir dan menemukan kenyamanan satu sama lain.',
      aired: 'Jan 2024 - Mar 2024',
      duration: '1 jam 10 menit',
      contentRating: '15+',
      genresList: ['Romance', 'Comedy', 'Medical'],
      tagsList: ['Healing', 'Enemies to Lovers', 'Rivalry'],
    ),
    Drama(
      title: 'Hierarchy',
      koreanTitle: '하이라키',
      genre: 'Drama Korea',
      rating: 8.4,
      episodes: 7,
      watchedEpisodes: 0,
      status: 'Rencana Ditonton',
      priority: 'Sedang',
      startDate: '',
      endDate: '',
      date: '2024',
      image: 'https://picsum.photos/seed/hierarchykorea/500/750',
      rank: '#10',
      popularity: '#13',
      watchers: '88.0K',
      synopsis:
          'Siswa pindahan dengan rahasia misterius mulai meretakkan tatanan hierarki ketat di SMA Jooshin yang dihuni 0,01% anak konglomerat elit.',
      aired: 'Jun 2024',
      duration: '1 jam',
      contentRating: '15+',
      genresList: ['Youth', 'Mystery', 'Drama'],
      tagsList: ['Elite School', 'Bullying', 'Secrets'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor = isDark ? const Color(0xFF15171E) : const Color(0xFFF8F9FA);
    Color cardBg = isDark ? const Color(0xFF1F222B) : Colors.white;
    Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    Color subTextColor = isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade600;
    Color borderColor = isDark ? const Color(0xFF2A2E3D) : Colors.grey.shade200;
    Color primaryBlue = const Color(0xFF0094FF);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgColor,
        drawer: const AppDrawer(),
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: textColor),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              color: textColor,
              tooltip: 'Menu Navigasi',
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Text(
            'Papan Peringkat',
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          bottom: TabBar(
            indicatorColor: primaryBlue,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: primaryBlue,
            unselectedLabelColor: subTextColor,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: const [
              Tab(
                icon: Icon(Icons.star_rounded, size: 20),
                text: 'Rating Tertinggi',
              ),
              Tab(
                icon: Icon(Icons.local_fire_department_rounded, size: 20),
                text: 'Sedang Tren',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Rating Tertinggi
            _buildRankingList(
              context,
              _topRatedDramas,
              isDark,
              cardBg,
              textColor,
              subTextColor,
              primaryBlue,
              borderColor,
            ),
            // Tab 2: Sedang Tren
            _buildRankingList(
              context,
              _trendingDramas,
              isDark,
              cardBg,
              textColor,
              subTextColor,
              primaryBlue,
              borderColor,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET BUILDER: LISTVIEW PERINGKAT
  // ==========================================
  Widget _buildRankingList(
    BuildContext context,
    List<Drama> dramas,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subTextColor,
    Color primaryBlue,
    Color borderColor,
  ) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: dramas.length,
      itemBuilder: (context, index) {
        final drama = dramas[index];
        final rank = index + 1;
        return _buildRankingCard(
          context,
          drama,
          rank,
          isDark,
          cardBg,
          textColor,
          subTextColor,
          primaryBlue,
          borderColor,
        );
      },
    );
  }

  // ==========================================
  // WIDGET BUILDER: CARD BARIS PER FILM
  // ==========================================
  Widget _buildRankingCard(
    BuildContext context,
    Drama drama,
    int rank,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subTextColor,
    Color primaryBlue,
    Color borderColor,
  ) {
    final bool isSaved = _savedDramaTitles.contains(drama.title);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank <= 3
              ? _getRankColor(rank, isDark).withValues(alpha: 0.35)
              : borderColor,
          width: rank <= 3 ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPage(drama: drama),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // ------------------------------------
                // KIRI: ANGKA PERINGKAT TEBAL & BESAR
                // ------------------------------------
                _buildRankNumber(rank, isDark),

                const SizedBox(width: 12),

                // ------------------------------------
                // TENGAH: POSTER, JUDUL, TAHUN & SKOR
                // ------------------------------------
                // Gambar Poster
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 62,
                    height: 88,
                    child: Image.network(
                      drama.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: isDark ? const Color(0xFF282C37) : Colors.grey.shade300,
                        child: Icon(Icons.movie, color: subTextColor, size: 28),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: isDark ? const Color(0xFF282C37) : Colors.grey.shade200,
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryBlue,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Judul, Tahun, dan Skor Rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Judul Utama
                      Text(
                        drama.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Tahun & Genre
                      Text(
                        '${drama.date} • ${drama.genre}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Skor Rating dengan Bintang Kuning & Badge Episode/Film
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB800),
                            size: 17,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            drama.formattedRating,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF282C38)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              drama.episodes > 1 ? '${drama.episodes} Eps' : 'Film',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ------------------------------------
                // KANAN: TOMBOL CALL TO ACTION (SIMPAN/TAMBAH)
                // ------------------------------------
                Container(
                  decoration: BoxDecoration(
                    color: isSaved
                        ? primaryBlue.withValues(alpha: 0.15)
                        : (isDark ? const Color(0xFF262A37) : Colors.grey.shade100),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSaved
                          ? primaryBlue.withValues(alpha: 0.5)
                          : (isDark ? const Color(0xFF33384A) : Colors.grey.shade300),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    iconSize: 20,
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_add_outlined,
                      color: isSaved ? primaryBlue : subTextColor,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_savedDramaTitles.contains(drama.title)) {
                          _savedDramaTitles.remove(drama.title);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${drama.title} dihapus dari daftar simpan',
                              ),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          _savedDramaTitles.add(drama.title);
                          // Sinkronkan ke notifier daftar tontonan bila belum ada
                          if (!SharedData.dramaListNotifier.value
                              .any((d) => d.title == drama.title)) {
                            SharedData.dramaListNotifier.value = [
                              drama,
                              ...SharedData.dramaListNotifier.value
                            ];
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${drama.title} berhasil ditambahkan ke daftar tontonan!',
                              ),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      });
                    },
                    tooltip: isSaved ? 'Tersimpan' : 'Simpan ke Daftar',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HELPER LOGIKA WARNA & FORMAT ANGKA PERINGKAT
  // ==========================================
  Color _getRankColor(int rank, bool isDark) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Emas / Kuning
      case 2:
        return const Color(0xFFC0C0C0); // Perak / Abu terang
      case 3:
        return const Color(0xFFCD7F32); // Perunggu / Oranye kecoklatan
      default:
        return isDark ? Colors.grey.shade400 : Colors.grey.shade600; // Standar
    }
  }

  Widget _buildRankNumber(int rank, bool isDark) {
    Color color = _getRankColor(rank, isDark);

    return SizedBox(
      width: 38,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ikon medali khusus untuk 3 besar
          if (rank == 1)
            const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 14)
          else if (rank == 2)
            const Icon(Icons.military_tech_rounded, color: Color(0xFFC0C0C0), size: 14)
          else if (rank == 3)
            const Icon(Icons.military_tech_rounded, color: Color(0xFFCD7F32), size: 14),

          Text(
            '$rank',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: rank <= 3 ? 24 : 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
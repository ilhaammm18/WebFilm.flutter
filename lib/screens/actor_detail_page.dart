import 'package:flutter/material.dart';
import '../models/actor.dart';
import '../services/api_service.dart';

class ActorDetailPage extends StatefulWidget {
  final Actor actor;
  final ApiService? apiService;
  final String? heroTag;
  final String? imageUrl;

  const ActorDetailPage(
    this.actor, {
    super.key,
    this.apiService,
    this.heroTag,
    this.imageUrl,
  });

  @override
  State<ActorDetailPage> createState() => _ActorDetailPageState();
}

class _ActorDetailPageState extends State<ActorDetailPage> {
  late final ApiService _apiService;
  late Future<List<ActorCredit>> _creditsFuture;
  late Actor _actor;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _actor = widget.actor;
    if (widget.actor.id > 0) {
      _creditsFuture = _apiService.getActorCredits(widget.actor.id);
      _fetchActorDetail();
    } else {
      _creditsFuture = Future.value(<ActorCredit>[]);
    }
  }

  Future<void> _fetchActorDetail() async {
    try {
      final detailedActor = await _apiService.getActorDetail(widget.actor.id);
      if (mounted) {
        setState(() {
          _actor = detailedActor;
        });
      }
    } catch (_) {
      // Abaikan jika offline / mock, data awal tetap tampil
    }
  }

  String _formatDepartment(String? department) {
    if (department == null || department.trim().isEmpty) return '-';
    if (department.toLowerCase() == 'acting') return 'Aktor / Pemeran';
    if (department.toLowerCase() == 'directing') return 'Sutradara';
    if (department.toLowerCase() == 'production') return 'Produser';
    if (department.toLowerCase() == 'writing') return 'Penulis Skenario';
    return department;
  }

  String _formatBirthday(String? bday) {
    if (bday == null || bday.trim().isEmpty || bday == '-') return '-';
    try {
      final DateTime date = DateTime.parse(bday.trim());
      const List<String> months = [
        '',
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${date.day} ${months[date.month]} ${date.year}';
    } catch (_) {
      return bday;
    }
  }

  String _calculateAge(String? bday) {
    if (bday == null || bday.trim().isEmpty || bday == '-') return '-';
    try {
      DateTime birthDateTime;
      if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(bday.trim())) {
        birthDateTime = DateTime.parse(bday.trim());
      } else {
        const Map<String, int> monthMap = {
          'januari': 1, 'februari': 2, 'maret': 3, 'april': 4,
          'mei': 5, 'juni': 6, 'juli': 7, 'agustus': 8,
          'september': 9, 'oktober': 10, 'november': 11, 'desember': 12,
          'january': 1, 'february': 2, 'march': 3,
          'may': 5, 'june': 6, 'july': 7, 'august': 8,
          'october': 10, 'december': 12,
        };
        final parts = bday.trim().split(' ');
        if (parts.length >= 3) {
          final day = int.tryParse(parts[0]) ?? 1;
          final month = monthMap[parts[1].toLowerCase()] ?? 1;
          final year = int.tryParse(parts[2]) ?? 2000;
          birthDateTime = DateTime(year, month, day);
        } else {
          birthDateTime = DateTime.parse(bday.trim());
        }
      }

      final DateTime now = DateTime.now();
      int age = now.year - birthDateTime.year;

      if (now.month < birthDateTime.month ||
          (now.month == birthDateTime.month && now.day < birthDateTime.day)) {
        age--;
      }

      return age >= 0 ? '$age Tahun' : '-';
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isDark ? const Color(0xFF14161D) : const Color(0xFFF8F9FA);
    final Color cardColor = isDark ? const Color(0xFF1C1F28) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final Color subTextColor = isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade600;
    final Color dividerColor = isDark ? const Color(0xFF262A36) : Colors.grey.shade200;
    final Color primaryBlue = const Color(0xFF0094FF);

    final Actor actor = _actor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Profil Aktor',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ==========================================
            // BAGIAN ATAS: Foto Bulat (CircleAvatar) + Nama
            // ==========================================
            Center(
              child: Column(
                children: [
                  Hero(
                    tag: widget.heroTag ??
                        (actor.id > 0
                            ? 'actor_${actor.id}'
                            : 'actor_${actor.name}'),
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: isDark
                          ? const Color(0xFF262A36)
                          : Colors.grey.shade300,
                      backgroundImage: (widget.imageUrl != null &&
                              widget.imageUrl!.isNotEmpty)
                          ? NetworkImage(widget.imageUrl!)
                          : (actor.imageUrl.isNotEmpty
                              ? NetworkImage(actor.imageUrl)
                              : null),
                      onBackgroundImageError: (widget.imageUrl != null &&
                                  widget.imageUrl!.isNotEmpty) ||
                              actor.imageUrl.isNotEmpty
                          ? (error, stackTrace) {}
                          : null,
                      child: ((widget.imageUrl == null ||
                                  widget.imageUrl!.isEmpty) &&
                              actor.imageUrl.isEmpty)
                          ? Icon(Icons.person, size: 54, color: subTextColor)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      actor.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (actor.koreanName.isNotEmpty && actor.koreanName != actor.name) ...[
                    const SizedBox(height: 4),
                    Text(
                      actor.koreanName,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==========================================
            // BAGIAN TENGAH: Biodata (Deretan ListTile Sederhana)
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Biodata',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dividerColor),
              ),
              child: Column(
                children: [
                  // 1. Nama Asli
                  _buildBiodataRow(
                    Icons.person_outline,
                    'Nama Asli',
                    actor.name.isNotEmpty ? actor.name : '-',
                    textColor,
                    subTextColor,
                  ),
                  Divider(height: 1, thickness: 1, color: dividerColor, indent: 16, endIndent: 16),

                  // 2. Profesi
                  _buildBiodataRow(
                    Icons.work_outline,
                    'Profesi',
                    _formatDepartment(actor.knownForDepartment),
                    textColor,
                    subTextColor,
                  ),
                  Divider(height: 1, thickness: 1, color: dividerColor, indent: 16, endIndent: 16),

                  // 3. Tempat Lahir
                  _buildBiodataRow(
                    Icons.location_on_outlined,
                    'Tempat Lahir',
                    (actor.placeOfBirth != null && actor.placeOfBirth!.isNotEmpty)
                        ? actor.placeOfBirth!
                        : '-',
                    textColor,
                    subTextColor,
                  ),
                  Divider(height: 1, thickness: 1, color: dividerColor, indent: 16, endIndent: 16),

                  // 4. Tanggal Lahir
                  _buildBiodataRow(
                    Icons.cake_outlined,
                    'Tanggal Lahir',
                    _formatBirthday(actor.birthday ?? (actor.birthDate != '-' ? actor.birthDate : null)),
                    textColor,
                    subTextColor,
                  ),
                  Divider(height: 1, thickness: 1, color: dividerColor, indent: 16, endIndent: 16),

                  // 5. Usia (Dihitung Otomatis)
                  _buildBiodataRow(
                    Icons.assignment_ind_outlined,
                    'Usia',
                    _calculateAge(actor.birthday ?? (actor.birthDate != '-' ? actor.birthDate : null)),
                    textColor,
                    subTextColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ==========================================
            // BAGIAN BAWAH: Section 'Drama / Filmografi'
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Drama / Filmografi',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            FutureBuilder<List<ActorCredit>>(
              future: _creditsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF0094FF)),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    child: Center(
                      child: Text(
                        'Gagal memuat filmografi dari TMDB',
                        style: TextStyle(color: subTextColor, fontSize: 13),
                      ),
                    ),
                  );
                }

                final credits = snapshot.data ?? [];

                if (credits.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    child: Center(
                      child: Text(
                        'Belum ada data drama/film untuk aktor ini',
                        style: TextStyle(color: subTextColor, fontSize: 13),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: credits.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final credit = credits[index];
                    return _buildCreditCard(
                      credit,
                      isDark,
                      cardColor,
                      textColor,
                      subTextColor,
                      dividerColor,
                      primaryBlue,
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBiodataRow(
    IconData icon,
    String label,
    String value,
    Color textColor,
    Color subTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[400] ?? subTextColor,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400] ?? subTextColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: textColor,
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCard(
    ActorCredit credit,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color dividerColor,
    Color primaryBlue,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: dividerColor),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster film di kiri (kotak kecil memanjang ke bawah)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 55,
              height: 80,
              child: credit.posterUrl.isNotEmpty
                  ? Image.network(
                      credit.posterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: isDark ? const Color(0xFF262A36) : Colors.grey.shade300,
                        child: Icon(Icons.movie_outlined, color: subTextColor, size: 24),
                      ),
                    )
                  : Container(
                      color: isDark ? const Color(0xFF262A36) : Colors.grey.shade300,
                      child: Icon(Icons.movie_outlined, color: subTextColor, size: 24),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Detail di kanan: Judul di kanan atas, Tahun rilis di bawahnya, dan Nama Peran (character) di paling bawah
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Judul di kanan atas
                Text(
                  credit.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Tahun rilis di bawahnya
                Text(
                  credit.releaseYear,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),

                // Nama Peran (character) di paling bawah
                Row(
                  children: [
                    Icon(
                      Icons.person_pin_rounded,
                      size: 13,
                      color: primaryBlue,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        credit.character,
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


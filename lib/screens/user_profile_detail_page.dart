import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../routes/app_router.dart';
import '../models/drama.dart';

class UserProfileDetailPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? initialProfile;

  const UserProfileDetailPage({
    super.key,
    required this.userId,
    this.initialProfile,
  });

  @override
  State<UserProfileDetailPage> createState() => _UserProfileDetailPageState();
}

class _UserProfileDetailPageState extends State<UserProfileDetailPage> {
  bool _isLoading = true;
  String _fullName = '';
  String _username = '';
  String _bio = '';
  String _avatarUrl = '';

  int _followersCount = 0;
  int _followingCount = 0;
  bool _isFollowing = false;
  bool _isTogglingFollow = false;

  List<Drama> _watchlist = [];
  String _selectedStatusFilter = 'Semua';

  // Statistik Waktu Tonton
  int _totalDays = 0;
  int _totalHours = 0;
  int _totalMinutes = 0;
  int _totalWatchedItems = 0;
  int _totalEpisodes = 0;
  int _dramaCount = 0;
  int _movieCount = 0;

  @override
  void initState() {
    super.initState();
    _initInitialData();
    _fetchUserData();
  }

  void _initInitialData() {
    if (widget.initialProfile != null) {
      final p = widget.initialProfile!;
      _fullName = p['full_name'] ?? p['username'] ?? '';
      _username = p['username'] ?? '';
      _bio = p['bio'] ?? '';
      _avatarUrl = p['avatar_url'] ?? '';
    }
  }

  SupabaseClient? get _supabaseClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchUserData() async {
    final client = _supabaseClient;
    if (client == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUserId = client.auth.currentUser?.id;

      // 1. Ambil data profil dari tabel profiles
      try {
        final profile = await client
            .from('profiles')
            .select()
            .eq('id', widget.userId)
            .maybeSingle();

        if (profile != null) {
          _fullName = profile['full_name'] ?? _fullName;
          _username = profile['username'] ?? _username;
          _bio = profile['bio'] ?? _bio;
          _avatarUrl = profile['avatar_url'] ?? _avatarUrl;
        }
      } catch (_) {}

      // 2. Ambil data Pengikut & Mengikuti
      try {
        final followersRes = await client
            .from('follows')
            .select('follower_id')
            .eq('following_id', widget.userId);
        _followersCount = (followersRes as List).length;

        final followingRes = await client
            .from('follows')
            .select('following_id')
            .eq('follower_id', widget.userId);
        _followingCount = (followingRes as List).length;

        // Cek apakah current user mengikuti user ini
        if (currentUserId != null && currentUserId != widget.userId) {
          final isFollowRes = await client
              .from('follows')
              .select('id')
              .eq('follower_id', currentUserId)
              .eq('following_id', widget.userId)
              .maybeSingle();
          _isFollowing = isFollowRes != null;
        }
      } catch (_) {}

      // 3. Ambil watchlist user target
      try {
        final watchlistRes = await client
            .from('watchlists')
            .select()
            .eq('user_id', widget.userId);

        final items = (watchlistRes as List)
            .map((item) => Drama.fromSupabase(item as Map<String, dynamic>))
            .toList();

        _watchlist = items;
        _calculateWatchStatistics(items);
      } catch (_) {}
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateWatchStatistics(List<Drama> items) {
    int totalRuntimeMinutes = 0;
    int watchedCount = 0;
    int epCount = 0;
    int dramaCount = 0;
    int movieCount = 0;

    for (var drama in items) {
      final status = drama.status.toLowerCase();
      final isWatched = status == 'selesai' || status == 'sedang menonton';
      if (!isWatched) continue;

      watchedCount++;
      final isMovie = drama.mediaType == 'movie' ||
          drama.genre.toLowerCase().contains('film') ||
          drama.episodes == 1;

      if (isMovie) {
        movieCount++;
        final dur = drama.runtime ?? 115;
        totalRuntimeMinutes += dur;
      } else {
        dramaCount++;
        final episodesWatched =
            drama.watchedEpisodes > 0 ? drama.watchedEpisodes : (drama.episodes > 0 ? drama.episodes : 16);
        epCount += episodesWatched;
        final durPerEp = drama.runtime ?? 60;
        totalRuntimeMinutes += (episodesWatched * durPerEp);
      }
    }

    _totalDays = totalRuntimeMinutes ~/ 1440;
    _totalHours = (totalRuntimeMinutes % 1440) ~/ 60;
    _totalMinutes = totalRuntimeMinutes % 60;
    _totalWatchedItems = watchedCount;
    _totalEpisodes = epCount;
    _dramaCount = dramaCount;
    _movieCount = movieCount;
  }

  Future<void> _toggleFollow() async {
    final client = _supabaseClient;
    final currentUserId = client?.auth.currentUser?.id;

    if (client == null || currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu untuk mengikuti teman.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (currentUserId == widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak dapat mengikuti akun Anda sendiri.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isTogglingFollow = true);

    try {
      if (_isFollowing) {
        await client
            .from('follows')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('following_id', widget.userId);

        setState(() {
          _isFollowing = false;
          _followersCount = (_followersCount - 1).clamp(0, 999999);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Berhenti mengikuti @$_username'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        await client.from('follows').insert({
          'follower_id': currentUserId,
          'following_id': widget.userId,
        });

        setState(() {
          _isFollowing = true;
          _followersCount++;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Berhasil mengikuti @$_username!'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui status ikuti: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingFollow = false);
      }
    }
  }

  Widget _buildAvatarWidget(String? url, {double radius = 42}) {
    final isNetwork = url != null && (url.startsWith('http://') || url.startsWith('https://'));
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: isNetwork
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF0094FF).withValues(alpha: 0.15),
                  child: Icon(Icons.person, color: const Color(0xFF0094FF), size: radius),
                ),
              )
            : Image.asset(
                (url != null && url.isNotEmpty) ? url : 'assets/profile.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF0094FF).withValues(alpha: 0.15),
                  child: Icon(Icons.person, color: const Color(0xFF0094FF), size: radius),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF16181F) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF1E212B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade600;
    final borderColor = isDark ? const Color(0xFF2E3344) : Colors.grey.shade200;
    const primaryBlue = Color(0xFF0094FF);

    final currentUserId = _supabaseClient?.auth.currentUser?.id;
    final isOwnProfile = currentUserId == widget.userId;

    final filteredWatchlist = _watchlist.where((d) {
      if (_selectedStatusFilter == 'Semua') return true;
      return d.status.toLowerCase() == _selectedStatusFilter.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          _username.isNotEmpty ? '@$_username' : 'Profil Teman',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: cardBg,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
              onRefresh: _fetchUserData,
              color: primaryBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    // 1. HEADER PROFIL
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0094FF), Color(0xFF00D2FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: _buildAvatarWidget(_avatarUrl, radius: 46),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _fullName.isNotEmpty ? _fullName : 'Pengguna MyWatchList',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${_username.isNotEmpty ? _username : 'user'}',
                            style: const TextStyle(
                              color: primaryBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Tombol Ikuti / Mengikuti (Jika bukan profil sendiri)
                          if (!isOwnProfile)
                            SizedBox(
                              width: 160,
                              child: ElevatedButton.icon(
                                onPressed: _isTogglingFollow ? null : _toggleFollow,
                                icon: _isTogglingFollow
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Icon(
                                        _isFollowing ? Icons.check_rounded : Icons.person_add_rounded,
                                        size: 16,
                                      ),
                                label: Text(
                                  _isFollowing ? 'Mengikuti' : 'Ikuti',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isFollowing
                                      ? (isDark ? const Color(0xFF2E3344) : Colors.grey.shade300)
                                      : primaryBlue,
                                  foregroundColor: _isFollowing
                                      ? (isDark ? Colors.white70 : Colors.black87)
                                      : Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 2. STATISTIK PENGIKUT & MENGIKUTI
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildFollowStatItem(
                              _followersCount.toString(),
                              'Pengikut',
                              textColor,
                              subTextColor,
                            ),
                          ),
                          Container(
                            height: 28,
                            width: 1,
                            color: isDark ? Colors.white10 : Colors.grey.shade300,
                          ),
                          Expanded(
                            child: _buildFollowStatItem(
                              _followingCount.toString(),
                              'Mengikuti',
                              textColor,
                              subTextColor,
                            ),
                          ),
                          Container(
                            height: 28,
                            width: 1,
                            color: isDark ? Colors.white10 : Colors.grey.shade300,
                          ),
                          Expanded(
                            child: _buildFollowStatItem(
                              _watchlist.length.toString(),
                              'Tontonan',
                              textColor,
                              subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 3. TENTANG SAYA / BIO
                    if (_bio.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: primaryBlue),
                                const SizedBox(width: 6),
                                Text(
                                  'Tentang Saya',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _bio,
                              style: TextStyle(
                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                fontSize: 13.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // 4. STATISTIK WAKTU TONTON
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Statistik Waktu Tonton',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.45,
                        children: [
                          _buildStatCard(
                            title: 'Total Waktu Tonton',
                            value: '$_totalDays h $_totalHours j $_totalMinutes m',
                            icon: Icons.timer_outlined,
                            iconColor: const Color(0xFF0094FF),
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                          ),
                          _buildStatCard(
                            title: 'Total Tontonan',
                            value: '$_totalWatchedItems judul',
                            icon: Icons.playlist_add_check_circle_outlined,
                            iconColor: const Color(0xFF10B981),
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                          ),
                          _buildStatCard(
                            title: 'Total Episode',
                            value: '$_totalEpisodes episode',
                            icon: Icons.tv_rounded,
                            iconColor: const Color(0xFFFFB800),
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                          ),
                          _buildStatCard(
                            title: 'Rasio Film & Drama',
                            value: '$_movieCount Film â€¢ $_dramaCount Drama',
                            icon: Icons.movie_filter_outlined,
                            iconColor: const Color(0xFFA855F7),
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 5. DAFTAR TONTONAN TEMAN
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daftar Tontonan (${_watchlist.length})',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filter Status Watchlist
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          'Semua',
                          'Selesai',
                          'Sedang Menonton',
                          'Rencana Ditonton',
                        ].map((status) {
                          final isSelected = _selectedStatusFilter == status;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(status),
                              selected: isSelected,
                              selectedColor: primaryBlue,
                              backgroundColor: cardBg,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : subTextColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                              side: BorderSide(
                                color: isSelected ? primaryBlue : borderColor,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _selectedStatusFilter = status;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (filteredWatchlist.isEmpty)
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.movie_creation_outlined, size: 48, color: subTextColor),
                              const SizedBox(height: 10),
                              Text(
                                'Belum ada tontonan di kategori ini',
                                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pengguna belum menambahkan film ke kategori ini.',
                                style: TextStyle(color: subTextColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredWatchlist.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final drama = filteredWatchlist[index];
                          return InkWell(
                            onTap: () {
                              context.push(
                                '/movie/${drama.id}',
                                extra: drama,
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  // Poster
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 50,
                                      height: 75,
                                      child: drama.image.isNotEmpty
                                          ? Image.network(
                                              drama.image,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: Colors.grey.shade300,
                                                child: const Icon(Icons.movie, size: 24),
                                              ),
                                            )
                                          : Container(
                                              color: Colors.grey.shade300,
                                              child: const Icon(Icons.movie, size: 24),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Detail info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          drama.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${drama.genre} â€¢ ${drama.date.isNotEmpty ? drama.date : 'N/A'}',
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            // Badge Status
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(drama.status).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                drama.status,
                                                style: TextStyle(
                                                  color: _getStatusColor(drama.status),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (drama.rating > 0)
                                              Row(
                                                children: [
                                                  const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    drama.rating.toStringAsFixed(1),
                                                    style: const TextStyle(
                                                      color: Color(0xFFFFB800),
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return const Color(0xFF10B981);
      case 'sedang menonton':
        return const Color(0xFF0094FF);
      case 'rencana ditonton':
        return const Color(0xFFFFB800);
      default:
        return Colors.grey;
    }
  }

  Widget _buildFollowStatItem(
    String count,
    String label,
    Color textColor,
    Color subTextColor,
  ) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: subTextColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

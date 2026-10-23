import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../routes/app_router.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  // Daftar user yang diikuti dan pengikut (sinkron real-time dengan Supabase)
  final List<Map<String, dynamic>> _followingList = [];
  final List<Map<String, dynamic>> _followersList = [];
  Set<String> _followingUserIds = {};

  // Hasil pencarian pengguna
  List<Map<String, dynamic>> _searchResults = [];

  // Data pengguna default untuk demo offline dan widget testing
  final List<Map<String, dynamic>> _curatedUsers = const [
    {
      'id': 'curated-1',
      'username': 'moviefreak',
      'full_name': 'Rian Pratama',
      'bio': 'Pecinta film sci-fi dan thriller psikologis.',
      'avatar_url': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
    },
    {
      'id': 'curated-2',
      'username': 'dramalover_id',
      'full_name': 'Siti Rahma',
      'bio': 'K-Drama & J-Drama enthusiast selamanya!',
      'avatar_url': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
    },
    {
      'id': 'curated-3',
      'username': 'cinephile_andi',
      'full_name': 'Andi Wijaya',
      'bio': 'Reviewer film lepas di Letterboxd & MyWatchList.',
      'avatar_url': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=400',
    },
    {
      'id': 'curated-4',
      'username': 'anime_otaku99',
      'full_name': 'Dimas Anggara',
      'bio': 'Penggemar anime musiman dan manga klasik.',
      'avatar_url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchFriendsData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  SupabaseClient? get _supabaseClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchFriendsData() async {
    try {
      final client = _supabaseClient;
      final currentUserId = client?.auth.currentUser?.id;
      if (client == null || currentUserId == null) return;

      // 1. Ambil daftar pengguna yang sedang diikuti oleh current user (Tab Mengikuti)
      try {
        final followingRes = await client
            .from('follows')
            .select('following_id')
            .eq('follower_id', currentUserId);

        final followingIds = (followingRes as List)
            .map((item) => (item['following_id'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toList();

        _followingUserIds = followingIds.toSet();

        if (followingIds.isNotEmpty) {
          final profilesRes = await client
              .from('profiles')
              .select()
              .inFilter('id', followingIds);

          _followingList.clear();
          for (var p in profilesRes) {
            _followingList.add(Map<String, dynamic>.from(p));
          }
        } else {
          _followingList.clear();
        }
      } catch (_) {}

      // 2. Ambil daftar pengguna yang mengikuti current user (Tab Pengikut)
      try {
        final followersRes = await client
            .from('follows')
            .select('follower_id')
            .eq('following_id', currentUserId);

        final followerIds = (followersRes as List)
            .map((item) => (item['follower_id'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toList();

        if (followerIds.isNotEmpty) {
          final profilesRes = await client
              .from('profiles')
              .select()
              .inFilter('id', followerIds);

          _followersList.clear();
          for (var p in profilesRes) {
            _followersList.add(Map<String, dynamic>.from(p));
          }
        } else {
          _followersList.clear();
        }
      } catch (_) {}

      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _searchUsers(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      setState(() {
        _searchQuery = '';
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _searchQuery = cleanQuery;
      _isSearching = true;
    });

    List<Map<String, dynamic>> results = [];

    // 1. Cari pengguna di tabel public.profiles di Supabase
    try {
      final client = _supabaseClient;
      if (client != null) {
        final currentUserId = client.auth.currentUser?.id;

        var queryBuilder = client
            .from('profiles')
            .select()
            .or('username.ilike.%$cleanQuery%,full_name.ilike.%$cleanQuery%');

        if (currentUserId != null) {
          queryBuilder = queryBuilder.neq('id', currentUserId);
        }

        final data = await queryBuilder.limit(20);

        for (var item in data) {
          results.add(Map<String, dynamic>.from(item));
        }
      }
    } catch (_) {}

    // 2. Jika tidak ada hasil dari Supabase atau dalam mode testing/offline, cari di curatedUsers
    if (results.isEmpty) {
      results = _curatedUsers.where((u) {
        final uname = (u['username'] ?? '').toString().toLowerCase();
        final name = (u['full_name'] ?? '').toString().toLowerCase();
        return uname.contains(cleanQuery) || name.contains(cleanQuery);
      }).map((u) => Map<String, dynamic>.from(u)).toList();
    }

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  bool _isFollowing(Map<String, dynamic> targetUser) {
    final targetId = targetUser['id']?.toString();
    if (targetId != null && _followingUserIds.contains(targetId)) {
      return true;
    }
    final targetUname = (targetUser['username'] ?? '').toString().toLowerCase();
    return _followingList.any(
        (u) => (u['username'] ?? '').toString().toLowerCase() == targetUname);
  }

  Future<void> _toggleFollow(Map<String, dynamic> targetUser) async {
    final client = _supabaseClient;
    final currentUserId = client?.auth.currentUser?.id;
    final targetUserId = targetUser['id']?.toString();
    final username = targetUser['username'] ?? 'user';
    final alreadyFollowing = _isFollowing(targetUser);

    setState(() {
      if (alreadyFollowing) {
        if (targetUserId != null) {
          _followingUserIds.remove(targetUserId);
        }
        _followingList.removeWhere((u) =>
            (targetUserId != null && u['id']?.toString() == targetUserId) ||
            u['username'] == username);
      } else {
        if (targetUserId != null) {
          _followingUserIds.add(targetUserId);
        }
        if (!_followingList.any((u) => u['username'] == username)) {
          _followingList.add(targetUser);
        }
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(alreadyFollowing
              ? 'Berhenti mengikuti @$username'
              : 'Mulai mengikuti @$username!'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: alreadyFollowing ? null : const Color(0xFF10B981),
        ),
      );
    }

    // Sinkronkan ke database public.follows Supabase jika client aktif
    if (client != null && currentUserId != null && targetUserId != null) {
      try {
        if (alreadyFollowing) {
          await client
              .from('follows')
              .delete()
              .eq('follower_id', currentUserId)
              .eq('following_id', targetUserId);
        } else {
          await client.from('follows').insert({
            'follower_id': currentUserId,
            'following_id': targetUserId,
          });
        }
      } catch (e) {
        debugPrint('Error toggle follow in Supabase: $e');
      }
    }
  }

  void _openUserProfile(Map<String, dynamic> user) {
    final userId = (user['id'] ?? user['username']).toString();
    context.push(
      '/user/$userId',
      extra: user,
    ).then((_) {
      _fetchFriendsData();
    });
  }

  Widget _buildAvatarWidget(String? url, {double radius = 26}) {
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
    final cardColor = isDark ? const Color(0xFF1E212B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade600;
    const primaryBlue = Color(0xFF0094FF);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text(
            'Teman',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: cardColor,
          foregroundColor: textColor,
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: primaryBlue,
            indicatorWeight: 3,
            labelColor: primaryBlue,
            unselectedLabelColor: subTextColor,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: const [
              Tab(text: 'Mengikuti'),
              Tab(text: 'Pengikut'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Kolom Pencarian Username di Bagian Atas
            Container(
              color: cardColor,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: TextField(
                controller: _searchController,
                onChanged: _searchUsers,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari pengguna berdasarkan username...',
                  hintStyle: TextStyle(color: subTextColor, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: primaryBlue),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: subTextColor,
                          onPressed: () {
                            _searchController.clear();
                            _searchUsers('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF262A37) : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Konten Utama: Hasil Pencarian atau TabBarView
            Expanded(
              child: _searchQuery.isNotEmpty
                  ? _buildSearchResults(
                      isDark: isDark,
                      cardColor: cardColor,
                      textColor: textColor,
                      subTextColor: subTextColor,
                    )
                  : TabBarView(
                      children: [
                        // Tab 1: Mengikuti
                        _buildFollowingTab(
                          isDark: isDark,
                          cardColor: cardColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),

                        // Tab 2: Pengikut
                        _buildFollowersTab(
                          isDark: isDark,
                          cardColor: cardColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    const primaryBlue = Color(0xFF0094FF);

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_outlined, size: 64, color: subTextColor),
            const SizedBox(height: 12),
            Text(
              'Tidak ada pengguna ditemukan',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Coba cari dengan username atau nama yang berbeda.',
              style: TextStyle(color: subTextColor, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final u = _searchResults[index];
        final username = u['username'] ?? 'user';
        final fullName = u['full_name'] ?? username;
        final bio = u['bio'] ?? '';
        final avatarUrl = u['avatar_url'] as String?;
        final isFollowing = _isFollowing(u);

        return InkWell(
          onTap: () => _openUserProfile(u),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF2E3344) : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                _buildAvatarWidget(avatarUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: const TextStyle(
                          color: primaryBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          bio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: subTextColor, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _toggleFollow(u),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing
                        ? (isDark ? const Color(0xFF2E3344) : Colors.grey.shade200)
                        : primaryBlue,
                    foregroundColor: isFollowing
                        ? (isDark ? Colors.white70 : Colors.black87)
                        : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isFollowing ? 'Mengikuti' : 'Ikuti',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFollowingTab({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    const primaryBlue = Color(0xFF0094FF);

    if (_followingList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_outline,
                  size: 56,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Belum Mengikuti Siapa Pun',
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Temukan teman nonton dan bagikan ulasan film favoritmu dengan mencari username mereka di kolom pencarian di atas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _followingList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final u = _followingList[index];
        final username = u['username'] ?? 'user';
        final fullName = u['full_name'] ?? username;
        final avatarUrl = u['avatar_url'] as String?;

        return InkWell(
          onTap: () => _openUserProfile(u),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF2E3344) : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                _buildAvatarWidget(avatarUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: const TextStyle(
                          color: primaryBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _toggleFollow(u),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Mengikuti', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFollowersTab({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    const primaryBlue = Color(0xFF0094FF);

    if (_followersList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.group_outlined,
                  size: 56,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Belum Memiliki Pengikut',
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ajak teman-temanmu bergabung di MyWatchList untuk saling melihat ulasan dan daftar tontonan!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _followersList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final u = _followersList[index];
        final username = u['username'] ?? 'user';
        final fullName = u['full_name'] ?? username;
        final avatarUrl = u['avatar_url'] as String?;
        final isFollowing = _isFollowing(u);

        return InkWell(
          onTap: () => _openUserProfile(u),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF2E3344) : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                _buildAvatarWidget(avatarUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: const TextStyle(
                          color: primaryBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _toggleFollow(u),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing
                        ? (isDark ? const Color(0xFF2E3344) : Colors.grey.shade200)
                        : primaryBlue,
                    foregroundColor: isFollowing
                        ? (isDark ? Colors.white70 : Colors.black87)
                        : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isFollowing ? 'Mengikuti' : 'Ikuti Balik',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

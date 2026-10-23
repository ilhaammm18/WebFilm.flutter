import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../routes/app_router.dart';
import '../data/shared_data.dart';
import 'main_navigation.dart';

/// Halaman CompleteProfilePage: Halaman pengisian biodata wajib setelah register
/// atau login pertama kali jika profil belum lengkap.
class CompleteProfilePage extends StatefulWidget {
  final SupabaseClient? supabaseClient;
  final Widget? nextScreen;

  const CompleteProfilePage({
    super.key,
    this.supabaseClient,
    this.nextScreen,
  });

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = false;

  // Pilihan avatar keren yang dapat langsung dipilih pengguna
  static const List<String> _presetAvatars = [
    'assets/profile.jpg',
    'https://api.dicebear.com/7.x/bottts/png?seed=cinephile',
    'https://api.dicebear.com/7.x/adventurer/png?seed=actionfan',
    'https://api.dicebear.com/7.x/adventurer/png?seed=dramalover',
    'https://api.dicebear.com/7.x/avataaars/png?seed=moviestar',
    'https://api.dicebear.com/7.x/bottts/png?seed=scififan',
  ];

  String _selectedAvatar = 'assets/profile.jpg';

  @override
  void initState() {
    super.initState();
    try {
      final client = widget.supabaseClient ?? Supabase.instance.client;
      final metadata = client.auth.currentUser?.userMetadata ?? {};
      if (metadata['full_name'] != null &&
          (metadata['full_name'] as String).trim().isNotEmpty) {
        _fullNameController.text = (metadata['full_name'] as String).trim();
      }
      if (metadata['username'] != null &&
          (metadata['username'] as String).trim().isNotEmpty) {
        _usernameController.text = (metadata['username'] as String).trim();
      }
      if (metadata['bio'] != null &&
          (metadata['bio'] as String).trim().isNotEmpty) {
        _bioController.text = (metadata['bio'] as String).trim();
      }
      if (metadata['avatar_url'] != null &&
          (metadata['avatar_url'] as String).trim().isNotEmpty) {
        _selectedAvatar = (metadata['avatar_url'] as String).trim();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();
    final avatar = _selectedAvatar.trim();

    try {
      final client = widget.supabaseClient ?? Supabase.instance.client;

      // 1. Simpan data ke Supabase Auth Metadata
      await client.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': fullName,
            'username': username,
            'bio': bio,
            'avatar_url': avatar,
          },
        ),
      );

      // 2. Simpan / upsert ke tabel profiles jika tabel tersedia di Supabase
      try {
        final currentUser = client.auth.currentUser;
        if (currentUser != null) {
          await client.from('profiles').upsert({
            'id': currentUser.id,
            'full_name': fullName,
            'username': username,
            'bio': bio,
            'avatar_url': avatar,
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      } catch (_) {
        // Abaikan jika tabel profiles belum dibuat di remote database
      }

      // 3. Muat data watchlist pengguna
      try {
        await SharedData.fetchUserWatchlist(client: client);
        // await SharedData.fetchUserRiwayat(client: client); // Riwayat dinonaktifkan
      } catch (_) {}

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil disimpan! Selamat menjelajahi film.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      globalNavIndex.value = 0;
      if (widget.nextScreen != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => widget.nextScreen!,
          ),
        );
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan profil: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor =
        isDark ? const Color(0xFF15171E) : const Color(0xFFF8F9FA);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final Color subTextColor =
        isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade600;
    final Color fieldBg =
        isDark ? const Color(0xFF262A37) : Colors.grey.shade100;
    const Color primaryBlue = Color(0xFF008CFF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. JUDUL & SUBJUDUL
                Text(
                  'Lengkapi Profilmu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Beritahu kami sedikit tentang dirimu sebelum mulai menjelajahi film.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // 2. PILIHAN AVATAR / FOTO PROFIL
                _buildAvatarSelector(
                  isDark: isDark,
                  primaryBlue: primaryBlue,
                  subTextColor: subTextColor,
                ),
                const SizedBox(height: 28),

                // 3. INPUT NAMA LENGKAP (Wajib)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Nama Lengkap',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('full_name_field'),
                  controller: _fullNameController,
                  style: TextStyle(color: textColor, fontSize: 14.5),
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama lengkapmu',
                    hintStyle: TextStyle(
                      color: subTextColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: primaryBlue,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: fieldBg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: primaryBlue, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama lengkap wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 4. INPUT USERNAME (Wajib, Tanpa Spasi)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Username',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('username_field'),
                  controller: _usernameController,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  style: TextStyle(color: textColor, fontSize: 14.5),
                  decoration: InputDecoration(
                    hintText: 'Contoh: ilham_film (tanpa spasi)',
                    hintStyle: TextStyle(
                      color: subTextColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.alternate_email_rounded,
                      color: primaryBlue,
                      size: 19,
                    ),
                    filled: true,
                    fillColor: fieldBg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: primaryBlue, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username wajib diisi';
                    }
                    if (value.contains(' ')) {
                      return 'Username tidak boleh mengandung spasi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 5. INPUT TENTANG SAYA / BIO (Opsional)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tentang Saya / Bio (Opsional)',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('bio_field'),
                  controller: _bioController,
                  maxLines: 3,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Tulis bio anda',
                    hintStyle: TextStyle(
                      color: subTextColor.withValues(alpha: 0.7),
                      fontSize: 13.5,
                    ),
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(
                        Icons.movie_filter_outlined,
                        color: primaryBlue,
                        size: 20,
                      ),
                    ),
                    filled: true,
                    fillColor: fieldBg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: primaryBlue, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 6. TOMBOL BIRU PENUH 'Simpan & Mulai Jelajahi'
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    key: const Key('save_profile_button'),
                    onPressed: _isLoading ? null : _handleSaveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      disabledBackgroundColor:
                          primaryBlue.withValues(alpha: 0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : const Text(
                            'Simpan & Mulai Jelajahi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.1,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSelector({
    required bool isDark,
    required Color primaryBlue,
    required Color subTextColor,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryBlue, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: isDark ? 0.35 : 0.18),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: _buildAvatarImage(
                url: _selectedAvatar,
                size: 96,
                isDark: isDark,
                subTextColor: subTextColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryBlue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF15171E) : Colors.white,
                  width: 2.5,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 15,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Pilih Avatar Favorit:',
          style: TextStyle(
            color: subTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: _presetAvatars.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final avatar = _presetAvatars[index];
              final bool isSelected = avatar == _selectedAvatar;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatar = avatar;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? primaryBlue : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: _buildAvatarImage(
                    url: avatar,
                    size: 44,
                    isDark: isDark,
                    subTextColor: subTextColor,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarImage({
    required String url,
    required double size,
    required bool isDark,
    required Color subTextColor,
  }) {
    if (url.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: size,
            height: size,
            color: isDark ? const Color(0xFF262A36) : Colors.grey.shade300,
            alignment: Alignment.center,
            child: Icon(
              Icons.person,
              color: subTextColor,
              size: size * 0.5,
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: isDark ? const Color(0xFF262A36) : Colors.grey.shade300,
      backgroundImage: AssetImage(url.isNotEmpty ? url : 'assets/profile.jpg'),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../routes/app_router.dart';
import '../data/shared_data.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  String _avatarUrl = 'assets/profile.jpg';
  bool _isLoading = false;

  final List<String> _avatarPresets = const [
    'assets/profile.jpg',
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=400&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&auto=format&fit=crop&q=80',
  ];

  @override
  void initState() {
    super.initState();
    final current = SharedData.userProfileNotifier.value;
    String name = current.fullName;
    String username = current.username;
    String bio = current.bio;
    _avatarUrl = current.avatarUrl;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final metadata = user.userMetadata ?? {};
        if (metadata['full_name'] != null &&
            (metadata['full_name'] as String).trim().isNotEmpty) {
          name = (metadata['full_name'] as String).trim();
        }
        if (metadata['username'] != null &&
            (metadata['username'] as String).trim().isNotEmpty) {
          username = (metadata['username'] as String).trim();
        }
        if (metadata['bio'] != null &&
            (metadata['bio'] as String).trim().isNotEmpty) {
          bio = (metadata['bio'] as String).trim();
        }
        if (metadata['avatar_url'] != null &&
            (metadata['avatar_url'] as String).trim().isNotEmpty) {
          _avatarUrl = (metadata['avatar_url'] as String).trim();
        }
      }
    } catch (_) {}

    _nameController = TextEditingController(text: name);
    _usernameController = TextEditingController(text: username);
    _bioController = TextEditingController(text: bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Widget _buildAvatarWidget(String url, {double radius = 48}) {
    const primaryBlue = Color(0xFF0094FF);
    final isNetwork = url.startsWith('http://') || url.startsWith('https://');
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: isNetwork
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: primaryBlue.withValues(alpha: 0.15),
                  child: Icon(Icons.person, color: primaryBlue, size: radius),
                ),
              )
            : Image.asset(
                url.isNotEmpty ? url : 'assets/profile.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: primaryBlue.withValues(alpha: 0.15),
                  child: Icon(Icons.person, color: primaryBlue, size: radius),
                ),
              ),
      ),
    );
  }

  void _showAvatarPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E212B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final fieldBg = isDark ? const Color(0xFF262A37) : Colors.grey.shade100;
    const primaryBlue = Color(0xFF0094FF);
    final urlController = TextEditingController(
      text: _avatarUrl.startsWith('http') ? _avatarUrl : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pilih Foto Profil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pilih salah satu avatar di bawah atau masukkan URL gambar khusus.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grid Pilihan Avatar
                  SizedBox(
                    height: 140,
                    child: GridView.builder(
                      scrollDirection: Axis.horizontal,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: _avatarPresets.length,
                      itemBuilder: (context, index) {
                        final preset = _avatarPresets[index];
                        final isSelected = _avatarUrl == preset;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _avatarUrl = preset;
                            });
                            setModalState(() {});
                            context.pop();
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? primaryBlue : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: _buildAvatarWidget(preset, radius: 28),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Atau Masukkan URL Gambar:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: urlController,
                          style: TextStyle(color: textColor, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'https://example.com/avatar.jpg',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                            ),
                            prefixIcon: const Icon(Icons.link, color: primaryBlue, size: 20),
                            filled: true,
                            fillColor: fieldBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final input = urlController.text.trim();
                          if (input.isNotEmpty) {
                            setState(() {
                              _avatarUrl = input;
                            });
                            context.pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Gunakan'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleSave() async {
    final newName = _nameController.text.trim();
    final newUsername = _usernameController.text.trim();
    final newBio = _bioController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final client = Supabase.instance.client;
      // 1. Update Supabase Auth user metadata
      await client.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': newName,
            'username': newUsername,
            'bio': newBio,
            'avatar_url': _avatarUrl,
          },
        ),
      );

      // 2. Upsert ke tabel profiles jika tersedia
      final user = client.auth.currentUser;
      if (user != null) {
        try {
          await client.from('profiles').upsert({
            'id': user.id,
            'full_name': newName,
            'username': newUsername,
            'bio': newBio,
            'avatar_url': _avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}
      }
    } catch (_) {}

    // 3. Update global profile state agar Drawer & ProfilePage langsung ter-refresh
    SharedData.userProfileNotifier.value = UserProfileData(
      fullName: newName.isNotEmpty ? newName : 'Pengguna',
      username: newUsername.isNotEmpty ? newUsername : 'user',
      bio: newBio,
      avatarUrl: _avatarUrl,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    context.pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil berhasil disimpan!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF16181F) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E212B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final fieldBg = isDark ? const Color(0xFF262A37) : Colors.grey.shade100;
    const primaryBlue = Color(0xFF0094FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar edit preview (Interactive click)
              Center(
                child: GestureDetector(
                  onTap: _showAvatarPicker,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryBlue, width: 3),
                        ),
                        child: _buildAvatarWidget(_avatarUrl, radius: 50),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _showAvatarPicker,
                  icon: const Icon(Icons.photo_library_outlined, size: 16, color: primaryBlue),
                  label: const Text(
                    'Ubah Foto Profil',
                    style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Form fields
              Text(
                'Informasi Pribadi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _nameController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  hintText: 'Masukkan nama lengkap',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                  prefixIcon: const Icon(Icons.person_outline, color: primaryBlue),
                  filled: true,
                  fillColor: fieldBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _usernameController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'Masukkan username atau NIM',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                  prefixIcon: const Icon(Icons.badge_outlined, color: primaryBlue),
                  filled: true,
                  fillColor: fieldBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _bioController,
                maxLines: 4,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Tentang Saya / Bio (Opsional)',
                  hintText: 'Tulis bio singkatmu',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 50),
                    child: Icon(Icons.info_outline, color: primaryBlue),
                  ),
                  filled: true,
                  fillColor: fieldBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

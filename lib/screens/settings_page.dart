import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../routes/app_router.dart';
import '../data/shared_data.dart';
import '../main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;

  void _showChangePasswordDialog() {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;
    String? errorMessage;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E212B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final fieldBg = isDark ? const Color(0xFF262A37) : Colors.grey.shade100;
    const primaryBlue = Color(0xFF0094FF);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock_reset_rounded, color: primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Ubah Kata Sandi',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Masukkan kata sandi baru untuk akun Anda (minimal 6 karakter).',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Field Password Baru
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi Baru',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                        prefixIcon: const Icon(Icons.lock_outline, color: primaryBlue, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureNew = !obscureNew;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: fieldBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Field Konfirmasi Password
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Kata Sandi Baru',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                        prefixIcon: const Icon(Icons.lock_clock_outlined, color: primaryBlue, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureConfirm = !obscureConfirm;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: fieldBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => context.pop(),
                  child: Text(
                    'Batal',
                    style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final newPass = newPasswordController.text.trim();
                          final confirmPass = confirmPasswordController.text.trim();

                          if (newPass.isEmpty) {
                            setDialogState(() {
                              errorMessage = 'Kata sandi baru tidak boleh kosong.';
                            });
                            return;
                          }
                          if (newPass.length < 6) {
                            setDialogState(() {
                              errorMessage = 'Kata sandi minimal 6 karakter.';
                            });
                            return;
                          }
                          if (newPass != confirmPass) {
                            setDialogState(() {
                              errorMessage = 'Konfirmasi kata sandi tidak cocok.';
                            });
                            return;
                          }

                          setDialogState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          try {
                            final client = Supabase.instance.client;
                            await client.auth.updateUser(
                              UserAttributes(password: newPass),
                            );

                            if (context.mounted) {
                              context.pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Kata sandi berhasil diperbarui!'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isLoading = false;
                              errorMessage = 'Gagal mengubah kata sandi: $e';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Future<void> _handleLogout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E212B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Konfirmasi Keluar',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun MyWatchList?',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(
              'Batal',
              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}

    SharedData.dramaListNotifier.value = [];

    if (!mounted) return;
    context.go('/login');
  }

  Widget _buildLeadingIcon(IconData icon, Color color) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 20),
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            // Kategori Keamanan & Akun (Di bagian atas)
            Text(
              'Keamanan & Akun',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            Material(
              color: cardColor,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? const Color(0xFF33384A) : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  // 1. Menu Edit Profil
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: _buildLeadingIcon(Icons.person_outline_rounded, primaryBlue),
                    title: Text(
                      'Edit Profil',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      'Kelola foto profil, nama pengguna, dan bio',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subTextColor),
                    onTap: () {
                      context.push('/settings/edit-profile');
                    },
                  ),
                  Divider(color: isDark ? Colors.white10 : Colors.grey.shade200, height: 1),

                  // 2. Ubah Kata Sandi
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: _buildLeadingIcon(Icons.lock_outline, primaryBlue),
                    title: Text(
                      'Ubah Kata Sandi',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      'Perbarui kata sandi akun Supabase Anda',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subTextColor),
                    onTap: _showChangePasswordDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Kategori Tampilan & Notifikasi
            Text(
              'Tampilan & Notifikasi',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            Material(
              color: cardColor,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? const Color(0xFF33384A) : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  // Mode Gelap
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: _buildLeadingIcon(Icons.dark_mode_outlined, primaryBlue),
                    title: Text(
                      'Mode Gelap',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      isDark ? 'Tema gelap aktif' : 'Tema terang aktif',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                    trailing: Switch(
                      value: isDark,
                      activeThumbColor: primaryBlue,
                      onChanged: (val) {
                        MyApp.themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                  ),
                  Divider(color: isDark ? Colors.white10 : Colors.grey.shade200, height: 1),

                  // Notifikasi Pembaruan
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: _buildLeadingIcon(Icons.notifications_none_outlined, primaryBlue),
                    title: Text(
                      'Notifikasi Pembaruan',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      'Pemberitahuan episode dan rilis film baru',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                    trailing: Switch(
                      value: _notifications,
                      activeThumbColor: primaryBlue,
                      onChanged: (val) {
                        setState(() {
                          _notifications = val;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Info Aplikasi
            Material(
              color: cardColor,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? const Color(0xFF33384A) : Colors.grey.shade200,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: _buildLeadingIcon(Icons.info_outline, primaryBlue),
                title: Text(
                  'Versi Aplikasi',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                trailing: Text(
                  '1.0.0',
                  style: TextStyle(
                    color: subTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 36),

            // Tombol Merah Keluar (Logout) di Bagian Bawah
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                label: const Text(
                  'Keluar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

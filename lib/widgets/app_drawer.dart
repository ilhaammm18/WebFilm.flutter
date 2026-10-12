import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../screens/customer_service_page.dart';
import '../screens/edit_profile_page.dart';
import '../screens/friends_page.dart';
import '../screens/login_page.dart';
import '../main.dart';
import '../screens/main_navigation.dart';
import '../screens/settings_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _showComingSoonSnackBar(BuildContext context, String menuName) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context); // Tutup drawer
    messenger.showSnackBar(
      SnackBar(
        content: Text('Halaman $menuName sedang dikembangkan'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Warna Latar Belakang dan Teks
    Color bgColor = isDark ? const Color(0xFF1C1F27) : Colors.white;
    Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    Color subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Drawer(
      backgroundColor: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            // Expanded memastikan menu dapat di-scroll jika layar kecil,
            // dan sekaligus mendorong tombol Keluar ke bagian paling bawah.
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // HEADER PROFIL (Dapat diklik untuk menuju Profil / About Me)
                    InkWell(
                      onTap: () {
                        Navigator.pop(context); // Tutup drawer
                        globalNavIndex.value = 3; // Pindah ke Tab Profil (About Me)
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 40,
                              backgroundImage: AssetImage('assets/profile.jpg'),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Muhammad Nur Ilham',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'NIM : 25051204433',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // GARIS PEMISAH HEADER
                    const Divider(color: Colors.white24, thickness: 1, height: 1),

                    const SizedBox(height: 8),

                    // 1. Edit Profil (Ikon: Icons.edit_outlined)
                    ListTile(
                      leading: Icon(Icons.edit_outlined, color: textColor),
                      title: Text(
                        'Edit Profil',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(builder: (context) => const EditProfilePage()),
                        );
                      },
                    ),

                    // 2. Mode Gelap (Ikon: Icons.dark_mode_outlined, dengan switch toggle)
                    ListTile(
                      leading: Icon(Icons.dark_mode_outlined, color: textColor),
                      title: Text(
                        'Mode Gelap',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Switch(
                        value: isDark,
                        activeThumbColor: const Color(0xFF0094FF),
                        onChanged: (value) {
                          MyApp.themeNotifier.value =
                              value ? ThemeMode.dark : ThemeMode.light;
                        },
                      ),
                    ),

                    // 3. Jadwal Tayang (Ikon: Icons.calendar_month_outlined)
                    ListTile(
                      leading: Icon(Icons.calendar_month_outlined, color: textColor),
                      title: Text(
                        'Jadwal Tayang',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => _showComingSoonSnackBar(context, 'Jadwal Tayang'),
                    ),

                    // 4. Favorit (Ikon: Icons.star_border_rounded)
                    ListTile(
                      leading: Icon(Icons.star_border_rounded, color: textColor),
                      title: Text(
                        'Favorit',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => _showComingSoonSnackBar(context, 'Favorit'),
                    ),

                    // 5. Teman (Ikon: Icons.people_alt_outlined)
                    ListTile(
                      leading: Icon(Icons.people_alt_outlined, color: textColor),
                      title: Text(
                        'Teman',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(builder: (context) => const FriendsPage()),
                        );
                      },
                    ),

                    // PEMISAH TENGAH
                    const Divider(color: Colors.white24),

                    // 5. Pengaturan (Ikon: Icons.settings_outlined)
                    ListTile(
                      leading: Icon(Icons.settings_outlined, color: textColor),
                      title: Text(
                        'Pengaturan',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(builder: (context) => const SettingsPage()),
                        );
                      },
                    ),

                    // 6. Customer Service (Ikon: Icons.support_agent)
                    ListTile(
                      leading: Icon(Icons.support_agent, color: textColor),
                      title: Text(
                        'Customer Service',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(builder: (context) => const CustomerServicePage()),
                        );
                      },
                    ),

                    // 7. Tentang (Ikon: Icons.info_outline)
                    ListTile(
                      leading: Icon(Icons.info_outline, color: textColor),
                      title: Text(
                        'Tentang',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => _showComingSoonSnackBar(context, 'Tentang'),
                    ),
                  ],
                ),
              ),
            ),

            // GARIS PEMISAH SEBELUM KELUAR
            const Divider(color: Colors.white24, thickness: 1, height: 1),

            // Keluar (Ikon: Icons.logout, teks dan ikon warna merah)
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Keluar',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  CupertinoPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
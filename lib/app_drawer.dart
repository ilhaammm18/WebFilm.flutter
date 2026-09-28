import 'package:flutter/material.dart';
import 'main.dart';
import 'login_page.dart';
import 'main_navigation.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Warna Latar Belakang dan Teks
    Color bgColor = isDark ? const Color(0xFF1C1F27) : Colors.white;
    Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    Color subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    
    // WARNA GARIS PEMISAH: Diubah menjadi sangat halus dan transparan
    Color dividerColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);

    return Drawer(
      backgroundColor: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // FOTO PROFIL & IDENTITAS (Dapat diklik untuk menuju Profil / About Me)
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
            
            // GARIS PEMISAH YANG SUDAH DIPERHALUS
            Divider(color: dividerColor, thickness: 1, height: 1),
            
            const SizedBox(height: 12),
            
            // MENU: Profil / Tentang Saya (About Me)
            ListTile(
              leading: Icon(Icons.person_outline, color: textColor),
              title: Text('Profil', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
              trailing: Icon(Icons.arrow_forward_ios, size: 14, color: subTextColor),
              onTap: () {
                Navigator.pop(context); // Tutup drawer
                globalNavIndex.value = 3; // Pindah ke Tab Profil (About Me)
              },
            ),
            
            // MENU: Mode Gelap
            ListTile(
              leading: Icon(Icons.dark_mode, color: textColor),
              title: Text('Mode Gelap', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
              trailing: Switch(
                value: isDark,
                activeThumbColor: const Color(0xFF0094FF),
                onChanged: (value) {
                  MyApp.themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                },
              ),
            ),
            
            // MENU: Kotak Masuk
            ListTile(
              leading: Icon(Icons.mail_outline, color: textColor),
              title: Text('Kotak Masuk', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
              onTap: () {},
            ),
            
            // MENU: Teman
            ListTile(
              leading: Icon(Icons.people_outline, color: textColor),
              title: Text('Teman', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
              onTap: () {},
            ),
            
            // MENU: Favorit
            ListTile(
              leading: Icon(Icons.favorite_outline, color: textColor),
              title: Text('Favorit', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
              onTap: () {},
            ),
            
            // MENU: Kalender
            ListTile(
              leading: Icon(Icons.calendar_today_outlined, color: textColor),
              title: Text('Kalender', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
              onTap: () {},
            ),
            
            const Spacer(),
            
            // GARIS PEMISAH SEBELUM KELUAR
            Divider(color: dividerColor, thickness: 1, height: 1),
            
            // MENU: Keluar (Log Out)
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Keluar', style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
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
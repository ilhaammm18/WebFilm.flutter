import 'package:flutter/material.dart';
import '../routes/app_router.dart';
import '../data/shared_data.dart';
import '../main.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  ImageProvider _resolveAvatarImage(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    }
    return AssetImage(url.isNotEmpty ? url : 'assets/profile.jpg');
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
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // HEADER PROFIL (Dapat diklik untuk menuju Profil / About Me)
                    ValueListenableBuilder<UserProfileData>(
                      valueListenable: SharedData.userProfileNotifier,
                      builder: (context, userProfile, _) {
                        final String displayUsername = userProfile.username.contains(RegExp(r'^[0-9]+$'))
                            ? 'NIM : ${userProfile.username}'
                            : (userProfile.username.startsWith('@')
                                ? userProfile.username
                                : '@${userProfile.username}');

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              context.pop(); // Tutup drawer
                              context.push('/settings/edit-profile');
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 40,
                                          backgroundImage: _resolveAvatarImage(userProfile.avatarUrl),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          userProfile.fullName,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          displayUsername,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                      color: subTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // GARIS PEMISAH HEADER
                    const Divider(color: Colors.white24, thickness: 1, height: 1),

                    const SizedBox(height: 8),

                    // 1. Mode Gelap (Ikon: Icons.dark_mode_outlined, dengan switch toggle)
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

                    // 2. Jadwal Tayang (Ikon: Icons.calendar_month_outlined)
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
                      onTap: () {
                        context.push('/schedule');
                      },
                    ),

                    // 3. Teman (Ikon: Icons.people_alt_outlined)
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
                        context.push('/friends');
                      },
                    ),

                    // PEMISAH TENGAH
                    const Divider(color: Colors.white24),

                    // 4. Pengaturan (Ikon: Icons.settings_outlined)
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
                        context.push('/settings');
                      },
                    ),

                    // 5. Customer Service (Ikon: Icons.support_agent)
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
                        context.push('/customer-service');
                      },
                    ),

                    // 6. Tentang (Ikon: Icons.info_outline)
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
                      onTap: () {
                        context.push('/about');
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

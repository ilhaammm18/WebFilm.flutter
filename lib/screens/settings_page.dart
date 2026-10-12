import 'package:flutter/material.dart';
import '../main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF16181F) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E212B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
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
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF33384A) : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.dark_mode_outlined, color: primaryBlue),
                    title: const Text('Mode Gelap', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Switch(
                      value: isDark,
                      activeThumbColor: primaryBlue,
                      onChanged: (val) {
                        MyApp.themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                  ),
                  Divider(color: isDark ? Colors.white10 : Colors.grey.shade200, height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_none_outlined, color: primaryBlue),
                    title: const Text('Notifikasi Pembaruan', style: TextStyle(fontWeight: FontWeight.w600)),
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
                  Divider(color: isDark ? Colors.white10 : Colors.grey.shade200, height: 1),
                  const ListTile(
                    leading: Icon(Icons.info_outline, color: primaryBlue),
                    title: Text('Versi Aplikasi', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Text('1.0.0+1', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

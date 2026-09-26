import 'package:flutter/material.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF15171E) : const Color(0xFFF8F9FA),
      body: Center(
        child: Text(
          'Halaman Profil Belum Tersedia',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
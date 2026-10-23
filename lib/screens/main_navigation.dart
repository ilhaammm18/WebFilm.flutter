import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'explore_tab.dart'; // Tab 1: Jelajahi
// Pastikan kamu punya file ini. Jika belum ada isinya, buat dummy sementara.
import 'watchlist_tab.dart'; // Tab 2: Daftar
import 'ranking_tab.dart'; // Tab 3: Peringkat
import 'profile_tab.dart'; // Tab 4: Profil
import '../data/shared_data.dart';

// Variabel global agar kita bisa berpindah tab dari halaman mana saja (misalnya dari tombol "Lihat Semua")
ValueNotifier<int> globalNavIndex = ValueNotifier<int>(0);

class MainNavigation extends StatefulWidget {
  final List<Widget>? pages;
  const MainNavigation({super.key, this.pages});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // Daftar halaman yang akan ditampilkan pada setiap tab
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = widget.pages ??
        const [
          ExploreTab(),
          WatchlistTab(),
          RankingTab(), // Menggunakan Ranking sebagai pengganti Feed sesuai kesepakatan
          ProfileTab(),
        ];

    // Jika user sedang aktif login di Supabase, ambil data watchlist & riwayat miliknya saja
    if (widget.pages == null) {
      String? userId;
      try {
        userId = Supabase.instance.client.auth.currentUser?.id;
      } catch (_) {}

      if (userId != null) {
        SharedData.fetchUserWatchlist();
        // SharedData.fetchUserRiwayat(); // Riwayat dinonaktifkan
        SharedData.fetchUserProfile();
      } else {
        SharedData.syncWithTmdb();
      }
    }

    // Mendengarkan perubahan pada globalNavIndex
    globalNavIndex.addListener(_onNavIndexChanged);
  }

  void _onNavIndexChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    globalNavIndex.removeListener(_onNavIndexChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Warna latar belakang navigasi yang solid menyesuaikan tema
    final Color bgColor = Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
        (isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white);

    // 2. Aksen Biru untuk menu yang aktif (selected)
    const Color selectedColor = Color(0xFF0094FF);

    // 3. Kontras warna abu-abu adaptif yang lebih gelap untuk menu tidak aktif (unselected)
    final Color unselectedColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    // Warna pembatas atas tipis untuk mempertegas batas konten
    final Color topBorderColor =
        isDark ? const Color(0xFF2A2E39) : Colors.grey.shade300;

    return Scaffold(
      body: _pages[globalNavIndex.value],

      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          // Mempertegas batas antara konten halaman dengan navigasi bawah
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              top: BorderSide(
                color: topBorderColor,
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: globalNavIndex.value,
            onTap: (index) {
              globalNavIndex.value = index;
            },
            backgroundColor: bgColor,
            type: BottomNavigationBarType.fixed, // Pastikan fixed agar semua ikon muncul dan tidak goyang
            elevation: 8, // Memberikan elevasi untuk mempertegas batas navigasi
            selectedItemColor: selectedColor,
            unselectedItemColor: unselectedColor,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                activeIcon: Icon(Icons.explore),
                label: 'Jelajahi',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_outlined),
                activeIcon: Icon(Icons.list_alt),
                label: 'Daftar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events_outlined),
                activeIcon: Icon(Icons.emoji_events),
                label: 'Peringkat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'explore_tab.dart'; // Tab 1: Jelajahi
// Pastikan kamu punya file ini. Jika belum ada isinya, buat dummy sementara.
import 'watchlist_tab.dart'; // Tab 2: Daftar
import 'ranking_tab.dart'; // Tab 3: Peringkat
import 'profile_tab.dart'; // Tab 4: Profil

// Variabel global agar kita bisa berpindah tab dari halaman mana saja (misalnya dari tombol "Lihat Semua")
ValueNotifier<int> globalNavIndex = ValueNotifier<int>(0);

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // Daftar halaman yang akan ditampilkan pada setiap tab
  final List<Widget> _pages = const [
    ExploreTab(),
    WatchlistTab(),
    RankingTab(), // Menggunakan Ranking sebagai pengganti Feed sesuai kesepakatan
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    // Mendengarkan perubahan pada globalNavIndex
    globalNavIndex.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // globalNavIndex TIDAK di-dispose di sini karena ia adalah variabel global yang dipakai berulang kali
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Warna untuk menu bawah
    Color bgColor = isDark ? const Color(0xFF15171E) : Colors.white;
    Color selectedColor = const Color(0xFF0094FF); // Biru primary
    Color unselectedColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;

    return Scaffold(
      body: _pages[globalNavIndex.value],
      
      // MENGHILANGKAN GARIS NAVIGASI BAWAH
      // Kita bungkus dengan Theme untuk memodifikasi pengaturan bawaan Material
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          // Memastikan background navigasinya menyatu tanpa garis pemisah di atasnya
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          // Menambahkan border transparan atau shadow sangat halus untuk menghindari garis kaku
          decoration: BoxDecoration(
            color: bgColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.05),
                blurRadius: 10,
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
            elevation: 0, // KUNCI UTAMA menghilangkan garis bayangan bawaan
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
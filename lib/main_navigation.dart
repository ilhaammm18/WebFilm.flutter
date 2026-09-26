import 'package:flutter/material.dart';
import 'explore_tab.dart';
import 'watchlist_tab.dart';
import 'feed_tab.dart'; 
import 'home_page.dart';

// 1. Variabel ajaib agar tab bisa dipindah-pindah dari file mana pun!
final ValueNotifier<int> globalNavIndex = ValueNotifier<int>(3);

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final List<Widget> _pages = const [
    ExploreTab(),    // Indeks 0: Tab Jelajahi
    WatchlistTab(),  // Indeks 1: Tab Daftar
    FeedTab(),       // Indeks 2: Tab Feed
    HomePage(),      // Indeks 3: Tab Profil
  ];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color selectedColor = const Color(0xFF0094FF); 
    Color unselectedColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;

    // 2. Bungkus dengan ValueListenableBuilder agar reaktif terhadap perubahan indeks
    return ValueListenableBuilder<int>(
      valueListenable: globalNavIndex,
      builder: (context, currentIndex, _) {
        return Scaffold(
          body: IndexedStack(index: currentIndex, children: _pages),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedItemColor: selectedColor,
              unselectedItemColor: unselectedColor,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              currentIndex: currentIndex,
              onTap: (index) {
                globalNavIndex.value = index; // Ubah indeks saat diklik
              },
              elevation: 0,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Jelajahi'),
                BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'Daftar'),
                BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), activeIcon: Icon(Icons.forum), label: 'Feed'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
              ],
            ),
          ),
        );
      },
    );
  }
}
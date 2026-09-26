import 'package:flutter/material.dart';
import 'app_drawer.dart'; // Mengimpor file drawer agar ikon garis tiga (hamburger menu) tetap berfungsi

class FeedTab extends StatelessWidget {
  const FeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Deteksi tema aktif (Terang atau Gelap) untuk menyesuaikan warna teks
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Feed Aktivitas', 
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        elevation: 0, // Menghilangkan bayangan garis bawah pada AppBar
      ),
      
      // Menyertakan AppDrawer agar tombol garis tiga di pojok kiri atas memunculkan menu samping
      drawer: const AppDrawer(), 
      
      // Bagian isi halaman (Body) dikosongkan dan diberi teks informasi di tengah
      body: const Center(
        child: Text(
          'Halaman Feed Aktivitas Kosong',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
    );
  }
}
# 🎬 MyWatchList - Web Movie & Drama Tracker

<p align="center">
  <b>Aplikasi pelacak film, animasi, dan serial drama berbasis web yang dibangun dengan Flutter, Supabase, dan TMDB API.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Vercel-000000?style=for-the-badge&logo=vercel&logoColor=white" />
</p>

---

## 📌 Tentang Proyek
**MyWatchList** adalah solusi digital terpusat yang dirancang untuk mengatasi masalah *information overload* bagi para penikmat film dan drama. Aplikasi ini memudahkan pengguna dalam mengelola riwayat tontonan, melacak progres episode secara *real-time*, memberikan penilaian subjektif, hingga menjelajahi katalog sinema global lintas dekade dan genre tanpa terikat pada satu platform *Video-on-Demand* (VOD) tertentu.

Proyek ini dikembangkan guna memenuhi penugasan mata kuliah **Pemrograman Berbasis Platform (PBP)** Program Studi S1 Teknik Informatika, Universitas Negeri Surabaya.

---

## ✨ Fitur Utama
1. **Portal Jelajahi (`ExploreTab`):** Katalog VOD modern dengan *Hero Carousel Banner*, kategori tren mingguan & harian, jadwal rilis mendatang (*Release Schedule*), serta filter genre global.
2. **Daftar Pantau Personal (`WatchlistTab`):** Manajemen status tontonan (*Sedang Menonton*, *Selesai*, *Rencana Ditonton*) dilengkapi bilah progres episode (*progress bar*), pemberian skor/rating pribadi, dan modal edit interaktif yang tersinkronisasi ke *cloud*.
3. **Papan Peringkat (`RankingTab`):** Komparasi 30 karya sinema terbaik berdasarkan rating global dan indeks popularitas dengan penyaring multi-kriteria & negara asal.
4. **Eksplorasi Dekade, Detail Aktor & Pencarian Universal:** Fitur penjelajahan film berdasarkan kurun waktu historis (1980-an hingga 2020-an), halaman detail film beserta *trailer* & kredit pemeran lengkap, serta pencarian instan judul film maupun profil aktor.
5. **Jejaring Teman & Profil Pengguna (`FriendsPage` & `ProfileTab`):** Fitur pencarian sesama pengguna, sistem *Follow/Unfollow* (Pengikut & Mengikuti), melihat koleksi tontonan pengguna lain, serta dasbor analitik statistik durasi tontonan pribadi.
6. **Autentikasi Modern & Tema Adaptif:** Didukung oleh *Supabase Auth* (Login/Register Email & Password, **Google Sign-In OAuth 2.0**, pengecekan kelengkapan profil otomatis, dan pemulihan *Lupa Kata Sandi*) dengan dukungan tampilan **Dark Mode & Light Mode**.

---

## 🛠️ Tech Stack & Arsitektur
* **Frontend:** Flutter Web (Single Page Application dengan *Clean Architecture* & navigasi deklaratif `go_router`).
* **Backend-as-a-Service (BaaS):** Supabase (PostgreSQL Database, Supabase Auth & Google OAuth 2.0, serta PostgREST API).
* **External Data Provider:** The Movie Database (TMDB) RESTful API.
* **Deployment:** Vercel Hosting.
* **Paradigma Pemrograman:** Pemrograman Berorientasi Objek (PBO) ketat dengan penerapan Enkapsulasi (*Getters/Setters*), *Blueprint Model*, manajemen *state* reaktif (`ValueNotifier`), serta *Lazy Loading* menggunakan `ListView.builder`.

---

## 📂 Struktur Direktori Utama
```text
lib/
├── data/        # State management global & sinkronisasi data Supabase/TMDB
├── models/      # Blueprint model berorientasi objek (Drama, Actor, User)
├── routes/      # Konfigurasi rute deklaratif (GoRouter) & auth guard
├── screens/     # Halaman UI aplikasi (Explore, Watchlist, Ranking, Profile, Auth, dll.)
├── services/    # Integrasi RESTful API TMDB (ApiService)
├── widgets/     # Komponen UI reusable (Modal Edit, Drawer, Custom Logo)
└── main.dart    # Entry point aplikasi & inisialisasi tema/Supabase
```

---

## 🚀 Cara Menjalankan Proyek secara Lokal

1. **Clone repositori ini:**
   ```bash
   git clone https://github.com/ilhaammm18/WebFilm.flutter.git
   cd WebFilm.flutter
   ```
2. **Pasang dependensi Flutter:**
   ```bash
   flutter pub get
   ```
3. **Konfigurasi variabel lingkungan (`env.json`):**
   Salin file `env.example.json` menjadi `env.json` di direktori *root* proyek, lalu isi dengan kredensial Anda:
   ```json
   {
     "TMDB_API_KEY": "ISI_DENGAN_API_KEY_TMDB",
     "SUPABASE_URL": "ISI_DENGAN_URL_PROJECT_SUPABASE",
     "SUPABASE_ANON_KEY": "ISI_DENGAN_ANON_KEY_SUPABASE"
   }
   ```

---

## 🌐 Tautan Akses Aplikasi
* **Live Demo (Vercel):** [https://web-film-flutter.vercel.app/](https://web-film-flutter.vercel.app/)
* **Repositori GitHub:** [https://github.com/ilhaammm18/WebFilm.flutter](https://github.com/ilhaammm18/WebFilm.flutter)

---

## 👨‍💻 Pengembang
* **Nama:** Muhammad Nur Ilham  
* **NIM:** 25051204433  
* **Program Studi:** S1 Teknik Informatika (Kelas 2025I)  
* **Institusi:** Universitas Negeri Surabaya (UNESA)  

---
*© 2026 MyWatchList. Developed for Academic Project.*

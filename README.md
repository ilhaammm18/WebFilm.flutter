# 🎬 MyWatchList - Web Movie, Anime & Drama Tracker

<p align="center">
  <b>Aplikasi web pelacak film, animasi, dan serial drama terpadu dengan analitik waktu tonton serta jejaring sosial sinema yang dibangun menggunakan Flutter Web, Supabase, dan TMDB API.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase" />
  <img src="https://img.shields.io/badge/TMDB_API-01B4E4?style=for-the-badge&logo=themoviedatabase&logoColor=white" alt="TMDB API" />
  <img src="https://img.shields.io/badge/Vercel-000000?style=for-the-badge&logo=vercel&logoColor=white" alt="Vercel" />
</p>

---

## 📌 Tentang Proyek

**MyWatchList** adalah platform digital berbasis web (*Single Page Application*) yang dirancang untuk mengatasi masalah *information overload* bagi para penikmat film, drama Asia, serial Barat, dan anime. Di tengah banyaknya layanan *Video-on-Demand* (VOD) yang terfragmentasi, aplikasi ini hadir sebagai buku catatan sinema pintar yang memungkinkan pengguna mencatat riwayat tontonan, memantau progres episode secara *real-time*, memberikan penilaian subjektif (rating pribadi), menghitung statistik akumulasi waktu menonton, hingga saling terhubung dengan sesama pecinta film.

Proyek ini dikembangkan untuk memenuhi penugasan mata kuliah **Pemrograman Berbasis Platform (PBP)** pada Program Studi **S1 Teknik Informatika**, Fakultas Teknik, **Universitas Negeri Surabaya (UNESA)**.

---

## ✨ Fitur Lengkap Aplikasi

### 1. 🔐 Sistem Autentikasi Multi-Metode & Onboarding Pintar
* **Login & Registrasi Manual:** Autentikasi berbasis surel (*email*) dan kata sandi menggunakan *Supabase Auth* dengan validasi input secara langsung.
* **Google Sign-In (OAuth 2.0):** Masuk secara instan menggunakan akun Google dengan alur *redirect* yang telah disesuaikan untuk lingkungan lokal maupun produksi (Vercel).
* **Deteksi Otomatis Status Profil & Penanganan Akun Ganda:**
  * Jika pengguna mendaftar atau masuk dengan Google untuk pertama kali (data belum ada di tabel `profiles`), sistem otomatis mengarahkan pengguna ke halaman onboarding **Lengkapi Profilmu**.
  * Jika pengguna sempat membuat akun di tahap registrasi namun menekan tombol kembali (`<`) sebelum menyelesaikan pengisian biodata, percobaan registrasi berikutnya otomatis melakukan *sign-in* di balik layar dan mengarahkan kembali ke halaman **Lengkapi Profilmu** tanpa memunculkan pesan error merah *User already registered*.
  * Jika pengguna mencoba login manual menggunakan email yang terdaftar lewat Google OAuth, aplikasi mendeteksinya secara otomatis dan mengalihkan ke alur login Google.
* **Halaman Onboarding (`CompleteProfilePage`):** Formulir pengisian Nama Lengkap, Username unik (`@username`) atau NIM, Bio singkat, serta pemilih Avatar favorit, dilengkapi tombol kembali (`<`) yang mempertahankan *state* isian email dan kata sandi pada halaman sebelumnya.
* **Pemulihan Kata Sandi (*Forgot Password*):** Fitur pengiriman tautan atur ulang kata sandi langsung ke email pengguna melalui dialog modal interaktif.

### 2. 🧭 Portal Jelajahi Sinema (`ExploreTab`)
* **Hero Carousel Banner:** Banner geser otomatis di bagian atas halaman yang menampilkan tayangan paling populer lengkap dengan tombol akses cepat ke detail film.
* **Katalog Kategori Kurasi:** Menampilkan deretan poster horizontal untuk *Trending Hari Ini*, *Trending Minggu Ini*, *Drama Korea Populer*, *Serial Anime Terbaik*, dan *Film Populer*.
* **Eksplorasi Berdasarkan Genre (`GenreDetailPage`):** Penyaringan tayangan lintas genre global seperti *Action*, *Drama*, *Romance*, *Comedy*, *Thriller*, *Horror*, *Sci-Fi & Fantasy*, hingga *Animation*.
* **Eksplorasi Lintas Dekade (`DecadeExplorePage`):** Menjelajahi karya sinema ikonik berdasarkan kurun waktu rilis historis (**1980-an**, **1990-an**, **2000-an**, **2010-an**, hingga **2020-an**) beserta filter per tahun.
* **Jadwal Rilis & Tayangan Mendatang (`ReleaseSchedulePage`):** Memantau daftar film dan serial TV yang sedang tayang (*Sedang Tayang / On The Air*) maupun yang akan segera rilis (*Segera Hadir / Upcoming*).
* **Direktori Aktor & Aktris Kurasi VIP (`ActorDetailPage`):** Menampilkan profil bintang ternama Korea, Jepang, dan Internasional lengkap dengan foto, biografi, tanggal lahir, serta daftar filmografi yang pernah dibintangi.

### 3. 📋 Manajemen Daftar Pantau Personal (`WatchlistTab`)
* **Tiga Kategori Status Utama:** Mengorganisir koleksi tontonan ke dalam tab **Sedang Menonton**, **Selesai**, dan **Rencana Ditonton**.
* **Pelacakan Progres Episode Real-Time:** Dilengkapi bilah progres (*LinearProgressIndicator*) dan persentase penyelesaian (`watchedEpisodes / episodes`) khusus untuk serial drama dan anime.
* **Modal Edit Interaktif (`EditDramaModal`):** Memudahkan pengguna memperbarui status tontonan, menambah/mengurangi episode yang telah ditonton, memberikan **Rating Pribadi (skala 0.0 – 10.0)** dengan *slider* interaktif, serta mencatat tanggal selesai menonton.
* **Penyaringan & Pencarian Koleksi:** Dilengkapi fitur pencarian judul di dalam daftar pribadi serta *bottom sheet* filter kategori ketat (*Semua*, *Film*, *Drama*, *Animasi*).
* **Sinkronisasi Cloud & Enrich TMDB Otomatis:** Seluruh perubahan tersimpan di tabel `watchlists` Supabase per `user_id` dan diperkaya otomatis dengan metadata poster serta episode terbaru dari TMDB API.

### 4. 🏆 Papan Peringkat Global (`RankingTab`)
* **Komparasi 30 Karya Sinema Terbaik:** Menampilkan peringkat 1 hingga 30 dengan lencana medali khusus untuk peringkat 3 teratas.
* **Dua Mode Pengurutan:**
  * **Rating Tertinggi (*Top Rated*):** Mengurutkan tayangan berdasarkan nilai `vote_average` tertinggi dengan ambang batas jumlah suara (*vote count*) yang valid.
  * **Sedang Tren (*Most Popular*):** Mengurutkan tayangan berdasarkan indeks popularitas global saat ini.
* **Filter Multi-Kriteria & Negara:** Mendukung penyaringan spesifik untuk *Semua*, *Drama Korea*, *Film Korea*, *Anime*, *Film Indonesia*, *Film Barat*, *Drama Barat*, *Drama China*, dan *Drama Jepang*, dikombinasikan dengan filter genre.

### 5. 🎞️ Halaman Detail Sinema & Pencarian Universal (`DetailPage` & `SearchPage`)
* **Informasi Sinema Komprehensif:** Menampilkan poster dan *backdrop* resolusi tinggi, judul asli, kategori otomatis (*Drama Korea*, *Anime*, *Film Barat*, dll.), tahun rilis, durasi/jumlah episode, rating global TMDB, serta sinopsis lengkap.
* **Integrasi Trailer YouTube:** Menarik kunci video resmi (*Trailer* / *Teaser*) dari endpoint `/videos` TMDB agar pengguna dapat langsung menonton cuplikan tayangan.
* **Daftar Pemeran & Kru Produksi (`FullCreditsPage`):** Menampilkan jajaran aktor pemeran beserta nama karakter dan tim balik layar dengan kamus terjemahan jabatan ke Bahasa Indonesia (*Sutradara*, *Penulis Skenario*, *Produser*, *Komposer*, *Sinematografer*, dll.).
* **Pencarian Universal (`SearchPage`):** Mencari judul film, serial drama/anime, maupun nama aktor secara bersamaan melalui fitur pencarian global TMDB.

### 6. 📊 Profil Pengguna & Dasbor Analitik Waktu Tonton (`ProfileTab`)
* **Identitas & Statistik Sosial:** Menampilkan foto profil/avatar, nama lengkap, `@username` / NIM, jumlah **Pengikut**, **Mengikuti**, serta kartu **Tentang Saya (Bio)**.
* **Kartu Analitik Waktu Tonton (Susunan 2x2):** Menghitung akumulasi durasi menonton (`...d ...h ...m` atau `...h ...m`) secara presisi berdasarkan durasi asli tayangan dan jumlah episode yang telah ditonton, terbagi ke dalam 4 kartu:
  1. **DRAMA:** Total waktu tonton serial drama beserta jumlah episode dan judul drama.
  2. **FILM:** Total waktu tonton film layar lebar beserta jumlah judul film yang diselesaikan.
  3. **ANIMASI:** Total waktu tonton serial anime/animasi beserta jumlah episode dan judul animasi.
  4. **TOTAL KESELURUHAN:** Gabungan seluruh waktu tonton dan total judul tontonan aktif/selesai.
* **Karusel Pembaruan Terakhir:** Menampilkan deretan kartu tontonan yang baru saja diperbarui atau diselesaikan pengguna.

### 7. 🤝 Jejaring Teman & Detail Profil Pengguna Lain (`FriendsPage` & `UserProfileDetailPage`)
* **Pencarian Pengguna:** Mencari teman berdasarkan `@username` atau nama lengkap secara langsung dari tabel `profiles` Supabase.
* **Sistem Follow / Unfollow Real-Time:** Mengikuti atau berhenti mengikuti pengguna lain dengan pengelolaan daftar pada tab **Mengikuti** dan **Pengikut**.
* **Halaman Detail Profil Pengguna Lain (`UserProfileDetailPage`):**
  * Menampilkan kartu profil, jumlah pengikut/mengikuti/tontonan, serta bio pengguna tersebut.
  * Menampilkan **Kartu Statistik Waktu Tonton 2x2** (*DRAMA*, *FILM*, *ANIMASI*, *TOTAL KESELURUHAN*) yang seragam dan proporsional dengan halaman Profil utama.
  * Menampilkan **Daftar Tontonan Pengguna** dengan filter status (*Semua*, *Selesai*, *Sedang Menonton*, *Rencana Ditonton*), lengkap dengan poster asli dari TMDB, kategori/genre valid beserta tahun rilis, lencana status berwarna, rating, serta progres episode.

### 8. ⚙️ Pengaturan, Edit Profil & Tema Adaptif
* **Mode Gelap & Mode Terang (*Dark Mode & Light Mode*):** Dukungan penuh tema adaptif yang dapat diubah kapan saja melalui *Drawer* navigasi maupun halaman **Pengaturan (`SettingsPage`)**.
* **Edit Profil (`EditProfilePage`):** Mengubah nama lengkap, username, bio, dan pilihan avatar dengan sinkronisasi dua arah ke Supabase Auth Metadata dan tabel `profiles`.
* **Pusat Bantuan & Tentang Aplikasi (`CustomerServicePage` & `AboutAppPage`):** Informasi versi aplikasi, pengembang, serta kanal bantuan pengguna.

---

## 🛠️ Tech Stack & Arsitektur

| Komponen | Teknologi yang Digunakan |
| :--- | :--- |
| **Framework Frontend** | Flutter Web (Dart SDK `^3.10.7`) |
| **Manajemen Rute & Navigasi** | `go_router` (Navigasi deklaratif dengan *Async Auth & Profile Redirect Guard*) |
| **Backend-as-a-Service (BaaS)** | Supabase (`supabase_flutter` — PostgreSQL Database, Auth, Google OAuth 2.0, PostgREST) |
| **Penyedia Data Eksternal** | The Movie Database (TMDB) RESTful API v3 (`http`) |
| **Manajemen State** | `ValueNotifier` & `ValueListenableBuilder` terpusat (`SharedData`, `ThemeModeNotifier`) |
| **Penyimpanan Lokal** | `shared_preferences` (Persistensi sesi dan preferensi pengguna) |
| **Hosting & CI/CD** | Vercel (Terintegrasi langsung dengan cabang `main` GitHub) |

---

## 🧱 Penerapan Pemrograman Berorientasi Objek (PBO / OOP)

Proyek ini menerapkan prinsip-prinsip **Pemrograman Berorientasi Objek (PBO)** secara ketat pada lapisan model data:
1. **Enkapsulasi (*Encapsulation*):** Seluruh atribut pada kelas [`Drama`](lib/models/drama.dart), [`Actor`](lib/models/actor.dart), dan [`User`](lib/models/user.dart) dideklarasikan secara privat (menggunakan awalan *underscore* `_`) untuk menjaga integritas data.
2. **Validasi pada *Getter* & *Setter*:** Manipulasi properti wajib melalui *setter* yang dilengkapi aturan bisnis, seperti pembatasan rentang nilai rating (`0.0 – 10.0`), pencegahan angka episode negatif, serta sinkronisasi status otomatis ketika `watchedEpisodes` diubah.
3. **Properti Terhitung (*Computed Getters*) & *Custom Methods*:** Menyediakan metode perilaku objek seperti `hitungPersentaseSelesai()`, `hitungSisaEpisode()`, `updateProgress()`, `tambahSatuEpisode()`, `tandaiSelesai()`, `copyWith()`, serta klasifikasi kategori dinamis `Drama.getCategoryLabel()`.
4. **Polimorfisme Pemetaan Data (*Factory Constructors*):** Memiliki *factory constructor* `Drama.fromTmdbJson()` untuk memetakan respons JSON dari TMDB API dan `Drama.fromSupabase()` untuk memetakan baris data dari tabel PostgreSQL Supabase.

---

## 🗄️ Skema Tabel Database Supabase

Aplikasi ini menggunakan tiga tabel utama pada skema `public` PostgreSQL di Supabase:
1. **`profiles`**: Menyimpan biodata publik pengguna (`id` UUID yang berelasi dengan `auth.users`, `username`, `full_name`, `bio`, `avatar_url`, `updated_at`).
2. **`watchlists`**: Menyimpan daftar tontonan masing-masing pengguna (`id`, `user_id`, `tmdb_id`, `judul_film` / `title`, `media_type`, `original_language`, `episodes`, `watched_episodes`, `status`, `rating`, `date_completed`).
3. **`follows`**: Menyimpan relasi sosial antar pengguna (`id`, `follower_id`, `following_id`, `created_at`).

---

## 📂 Struktur Direktori Proyek

```text
lib/
├── data/
│   └── shared_data.dart              # State global, cache profil/watchlist, & helper autentikasi
├── models/
│   ├── actor.dart                    # Model PBO untuk entitas Aktor & Kredit Filmografi
│   ├── drama.dart                    # Model PBO utama untuk Film, Drama, dan Anime
│   └── user.dart                     # Model PBO untuk Pengguna & Ulasan
├── routes/
│   └── app_router.dart               # Konfigurasi rute GoRouter & Auth/Profile Guard
├── screens/
│   ├── about_app_page.dart           # Halaman informasi tentang aplikasi
│   ├── actor_detail_page.dart        # Halaman detail biografi & filmografi aktor
│   ├── complete_profile_page.dart    # Halaman onboarding pengisian biodata pengguna baru
│   ├── customer_service_page.dart    # Halaman layanan bantuan pengguna
│   ├── decade_explore_page.dart      # Eksplorasi sinema berdasarkan dekade (1980s - 2020s)
│   ├── detail_page.dart              # Halaman detail film/drama, trailer, pemeran & ulasan
│   ├── edit_profile_page.dart        # Halaman ubah profil & avatar pengguna
│   ├── explore_tab.dart              # Tab 1: Beranda eksplorasi katalog sinema
│   ├── friends_page.dart             # Halaman pencarian teman, pengikut & mengikuti
│   ├── genre_detail_page.dart        # Halaman daftar tayangan berdasarkan genre
│   ├── main_navigation.dart          # Kerangka utama BottomNavigationBar 4 tab
│   ├── profile_tab.dart              # Tab 4: Profil pengguna & statistik waktu tonton 2x2
│   ├── ranking_tab.dart              # Tab 3: Papan peringkat 30 tayangan terbaik
│   ├── release_schedule_page.dart    # Halaman jadwal tayang & film segera hadir
│   ├── search_page.dart              # Halaman pencarian universal (Film, Drama, Aktor)
│   ├── see_all_page.dart             # Halaman tampilan penuh daftar kategori
│   ├── settings_page.dart            # Halaman pengaturan tema & akun
│   ├── splash_screen.dart            # Layar pembuka animasi aplikasi
│   ├── user_profile_detail_page.dart # Halaman detail profil & daftar tontonan pengguna lain
│   ├── watchlist_tab.dart            # Tab 2: Manajemen daftar tontonan pribadi
│   └── welcome_login_page.dart       # Halaman Login, Register, Google OAuth & Lupa Sandi
├── services/
│   └── api_service.dart              # Layanan komunikasi HTTP ke RESTful API TMDB
├── utils/
│   └── helpers.dart                  # Fungsi utilitas format tanggal, warna rating & kategori
├── widgets/
│   ├── app_drawer.dart               # Drawer navigasi samping
│   ├── custom_logo.dart              # Widget logo vektor MyWatchList
│   └── edit_drama_modal.dart         # Modal bottom sheet untuk update progres & rating
└── main.dart                         # Titik masuk aplikasi, inisialisasi environment & Supabase
```

## ☁️ Konfigurasi Deployment di Vercel

Untuk melakukan *deployment* Flutter Web di **Vercel**:
1. Tambahkan variabel lingkungan (`TMDB_API_KEY`, `SUPABASE_URL`, dan `SUPABASE_ANON_KEY`) pada menu **Settings > Environment Variables** di proyek Vercel.
2. Pada menu **Settings > Build and Deployment**, atur:
   * **Build Command:**
     ```bash
     git clone https://github.com/flutter/flutter.git -b stable --depth 1 && ./flutter/bin/flutter build web --release --dart-define=TMDB_API_KEY=$TMDB_API_KEY --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
     ```
   * **Output Directory:** `build/web`
3. Pastikan URL domain produksi (`https://web-film-flutter.vercel.app`) telah didaftarkan pada menu **Authentication > URL Configuration** (*Site URL* & *Redirect URLs*) di dasbor Supabase agar fitur Google Sign-In berjalan lancar.

---

## 🌐 Tautan Akses Aplikasi

* **Live Demo (Vercel):** [https://web-film-flutter.vercel.app/](https://web-film-flutter.vercel.app/)
  Masuk bisa pakai Email ini atau buat sendiri, Email : ilhampbp@gmail.com, Pw : 87654321
* **Repositori GitHub:** [https://github.com/ilhaammm18/WebFilm.flutter](https://github.com/ilhaammm18/WebFilm.flutter)

---

## 👨‍💻 Pengembang

* **Nama Lengkap:** Muhammad Nur Ilham  
* **NIM:** 25051204433  
* **Program Studi / Kelas:** S1 Teknik Informatika (Kelas 2025H)  
* **Institusi:** Universitas Negeri Surabaya (UNESA)  

---
*© 2026 MyWatchList. Developed for Academic Project — Pemrograman Berbasis Platform.*

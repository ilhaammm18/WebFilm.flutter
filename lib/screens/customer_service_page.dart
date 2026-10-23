import 'package:flutter/material.dart';
import '../routes/app_router.dart';

class CustomerServicePage extends StatefulWidget {
  const CustomerServicePage({super.key});

  @override
  State<CustomerServicePage> createState() => _CustomerServicePageState();
}

class _CustomerServicePageState extends State<CustomerServicePage> {
  final List<Map<String, String>> _faqs = const [
    {
      'question': 'Bagaimana cara menambahkan film/drama ke Daftar Saya?',
      'answer':
          'Buka film atau serial yang Anda minati melalui halaman Jelajahi, Pencarian, atau Papan Peringkat, lalu tekan tombol aksi berikon tanda tambah (+) di kartu film atau pojok kanan bawah halaman detail. Pilih status tontonan Anda (Rencana Ditonton, Sedang Menonton, atau Selesai) lalu simpan.',
    },
    {
      'question': 'Bagaimana cara mencatat progres episode dan rating pribadi?',
      'answer':
          'Pada halaman detail film/drama atau tab Daftar Saya, tekan tombol edit berikon pensil. Anda dapat memperbarui jumlah episode yang sudah ditonton serta memberikan penilaian rating bintang (skala 1 - 10) yang langsung tersinkronisasi ke statistik profil Anda.',
    },
    {
      'question': 'Dari mana sumber data film, sinopsis, dan trailer diperoleh?',
      'answer':
          'Seluruh informasi metadata film, drama TV, anime, sinopsis, poster beresolusi tinggi, jadwal rilis, serta video trailer resmi diambil langsung secara real-time dari The Movie Database (TMDB) API.',
    },
    {
      'question': 'Apakah aplikasi MyWatchList menyediakan streaming film langsung?',
      'answer':
          'MyWatchList adalah aplikasi pelacak progres tontonan (personal watchlist & tracker). Aplikasi ini tidak menyiarkan streaming film berhak cipta secara penuh, namun Anda dapat menonton trailer resmi via integrasi YouTube dan melihat rekomendasi platform streaming resmi yang tersedia.',
    },
    {
      'question': 'Bagaimana cara mengubah foto profil, username, dan biodata?',
      'answer':
          'Buka halaman Pengaturan dari sidebar (Drawer), lalu pilih menu "Edit Profil". Anda dapat memilih avatar kurasi atau memasukkan URL gambar sendiri, mengubah Nama Lengkap, Username, dan Bio "Tentang Saya".',
    },
    {
      'question': 'Apakah daftar tontonan saya aman jika berganti perangkat?',
      'answer':
          'Ya, sangat aman! Seluruh riwayat tontonan, rating, dan biodata profil Anda tersimpan di cloud database Supabase yang terenkripsi dan terhubung langsung dengan akun login Anda.',
    },
  ];

  void _showFeedbackBugReportDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Laporan Bug';
    bool isSubmitting = false;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E212B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final fieldBg = isDark ? const Color(0xFF262A37) : Colors.grey.shade100;
    const primaryBlue = Color(0xFF0094FF);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.bug_report_outlined, color: Colors.redAccent, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Kirim Masukan & Lapor Bug',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bantu kami meningkatkan MyWatchList dengan melaporkan kendala atau memberikan saran fitur baru.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Kategori Laporan
                    Text(
                      'Kategori:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      dropdownColor: cardColor,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: fieldBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Laporan Bug', child: Text('Laporan Bug & Kendala')),
                        DropdownMenuItem(value: 'Saran Fitur', child: Text('Saran & Ide Fitur Baru')),
                        DropdownMenuItem(value: 'Pertanyaan', child: Text('Pertanyaan & Bantuan Akun')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedCategory = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Judul Laporan
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Judul Masukan / Masalah',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                        filled: true,
                        fillColor: fieldBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Deskripsi Laporan
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Deskripsi Rinci',
                        hintText: 'Jelaskan kronologi kendala atau ide saran Anda...',
                        alignLabelWithHint: true,
                        labelStyle: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: fieldBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol Kirim Laporan
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final title = titleController.text.trim();
                                final desc = descriptionController.text.trim();

                                if (title.isEmpty || desc.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Mohon isi judul dan deskripsi laporan Anda.'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() {
                                  isSubmitting = true;
                                });

                                await Future.delayed(const Duration(milliseconds: 600));

                                if (context.mounted) {
                                  context.pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Terima kasih! Laporan Anda telah berhasil kami terima.'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Kirim Laporan',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF16181F) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E212B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade600;
    const primaryBlue = Color(0xFF0094FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Customer Service',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner Customer Service
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.support_agent,
                      color: primaryBlue,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Service',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pusat Bantuan & Layanan Pengguna',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Kontak Cepat: WhatsApp & Email
              Material(
                color: cardColor,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF33384A) : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.chat_bubble_outline, color: primaryBlue),
                      ),
                      title: const Text(
                        'Masukan Via WA',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: Text(
                        '+62 812-3456-7890',
                        style: TextStyle(color: subTextColor, fontSize: 13),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Menghubungkan ke Customer Service WhatsApp...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    Divider(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                      height: 1,
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.mail_outline_rounded, color: primaryBlue),
                      ),
                      title: const Text(
                        'Email Dukungan',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: Text(
                        'support@mywatchlist.id',
                        style: TextStyle(color: subTextColor, fontSize: 13),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Membuka aplikasi email dukungan...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bagian FAQ / Pertanyaan Umum (ExpansionTile Accordion)
              Row(
                children: [
                  const Icon(Icons.help_outline_rounded, color: primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Pertanyaan Umum (FAQ)',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Material(
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF33384A) : Colors.grey.shade200,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _faqs.length,
                    separatorBuilder: (_, __) => Divider(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final item = _faqs[index];
                      return Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          iconColor: primaryBlue,
                          collapsedIconColor: subTextColor,
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: Text(
                            item['question']!,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Text(
                                item['answer']!,
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 28),

              // Tombol Kirim Masukan & Lapor Bug di Bagian Bawah
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showFeedbackBugReportDialog,
                  icon: const Icon(Icons.rate_review_outlined, size: 20),
                  label: const Text(
                    'Kirim Masukan & Lapor Bug',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 14, color: subTextColor),
                  const SizedBox(width: 6),
                  Text(
                    'Jam Layanan: Setiap Hari (08.00 - 22.00 WIB)',
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

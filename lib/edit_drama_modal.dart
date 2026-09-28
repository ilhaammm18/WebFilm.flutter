import 'package:flutter/material.dart';
import 'models/drama.dart';
import 'data/shared_data.dart';

class EditDramaModal extends StatefulWidget {
  final Drama drama;
  final int? index;

  const EditDramaModal({super.key, required this.drama, this.index});

  @override
  State<EditDramaModal> createState() => _EditDramaModalState();
}

class _EditDramaModalState extends State<EditDramaModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  static const List<String> _statusOptions = [
    'Sedang Menonton',
    'Selesai',
    'Rencana Ditonton',
    'Belum Ditonton',
  ];

  late String _status;
  late double _rating;
  late int _watchedEpisodes;
  late int _totalEpisodes;
  
  late String _priority;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    if (_statusOptions.contains(widget.drama.status)) {
      _status = widget.drama.status;
    } else {
      _status = 'Belum Ditonton';
    }
    _rating = (widget.drama.myRating != null && widget.drama.myRating! > 0)
        ? widget.drama.myRating!
        : (widget.drama.rating > 0 ? widget.drama.rating : 8.0);
    _watchedEpisodes = widget.drama.watchedEpisodes;
    _totalEpisodes = widget.drama.episodes;
    
    _priority = widget.drama.priority.isNotEmpty ? widget.drama.priority : 'Sedang';
    _startDateController = TextEditingController(text: widget.drama.startDate);
    _endDateController = TextEditingController(text: widget.drama.endDate);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  // Sinkronisasi status otomatis berdasarkan jumlah episode ditonton
  void _syncStatusFromEpisodes() {
    if (_totalEpisodes > 0 && _watchedEpisodes >= _totalEpisodes) {
      _status = 'Selesai';
    } else if (_watchedEpisodes > 0 && _watchedEpisodes < _totalEpisodes) {
      _status = 'Sedang Menonton';
    } else if (_watchedEpisodes == 0) {
      _status = 'Rencana Ditonton';
    }
  }

  // Dialog edit episode manual saat tombol pensil ditekan
  void _showEditEpisodeDialog(BuildContext context, Color textColor, Color inputBg, Color primaryBlue) {
    final TextEditingController textController = TextEditingController(text: '$_watchedEpisodes');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E2129) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Episode Ditonton',
          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan jumlah episode yang sudah selesai kamu tonton (0 - $_totalEpisodes):',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0 - $_totalEpisodes',
                filled: true,
                fillColor: inputBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final int? val = int.tryParse(textController.text.trim());
              if (val != null) {
                setState(() {
                  _watchedEpisodes = val.clamp(0, _totalEpisodes);
                  _syncStatusFromEpisodes();
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // FUNGSI SIMPAN PERUBAHAN: Terhubung 100% dengan State & Data Asli
  void _saveChanges() {
    // Terapkan aturan logika update status otomatis:
    // if (watchedEpisodes == 0) ➔ Ubah status menjadi 'Rencana Ditonton'.
    // if (watchedEpisodes > 0 && watchedEpisodes < totalEpisodes) ➔ Ubah status menjadi 'Sedang Menonton'.
    // if (watchedEpisodes == totalEpisodes) ➔ Ubah status menjadi 'Selesai'.
    _syncStatusFromEpisodes();

    // 1. Perbarui objek drama yang aktif
    widget.drama.watchedEpisodes = _watchedEpisodes;
    widget.drama.status = _status; 
    widget.drama.userRating = _rating; // Simpan nilai slider ke properti userRating
    widget.drama.priority = _priority;
    widget.drama.startDate = _startDateController.text;
    widget.drama.endDate = _endDateController.text;

    // 2. Perbarui list di SharedData.dramaListNotifier
    List<Drama> currentList = List<Drama>.from(SharedData.dramaListNotifier.value);
    
    int targetIndex = widget.index ?? currentList.indexWhere(
      (d) => d.title.trim().toLowerCase() == widget.drama.title.trim().toLowerCase(),
    );
    if (targetIndex != -1) {
      currentList[targetIndex].watchedEpisodes = _watchedEpisodes;
      currentList[targetIndex].status = _status; 
      currentList[targetIndex].userRating = _rating; // Simpan nilai slider ke properti userRating
      currentList[targetIndex].priority = _priority;
      currentList[targetIndex].startDate = _startDateController.text;
      currentList[targetIndex].endDate = _endDateController.text;
      
      // Pindahkan drama yang baru diedit ke urutan paling depan (index 0)
      Drama editedDrama = currentList.removeAt(targetIndex);
      currentList.insert(0, editedDrama);
    } else {
      currentList.insert(0, widget.drama);
    }
    
    // Perbarui ValueNotifier secara reaktif ke seluruh aplikasi
    SharedData.dramaListNotifier.value = List<Drama>.from(currentList);
    SharedData.dramaListNotifier.notifyListeners();
    
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _status == 'Belum Ditonton'
              ? '${widget.drama.title} dihapus dari daftar tontonan'
              : (widget.drama.status == 'Belum Ditonton'
                  ? '${widget.drama.title} berhasil ditambahkan ke daftar ($_status)!'
                  : 'Perubahan pada "${widget.drama.title}" berhasil disimpan!'),
        ),
        backgroundColor: _status == 'Belum Ditonton' ? Colors.grey.shade700 : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}-${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = isDark ? const Color(0xFF1E2129) : Colors.white;
    Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    Color subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    Color primaryBlue = const Color(0xFF0094FF);
    Color inputBg = isDark ? const Color(0xFF2A2E39) : Colors.grey.shade100;
    Color actionBtnBg = isDark ? const Color(0xFF2A2D3A) : Colors.grey.shade200;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER MODAL: FOTO, JUDUL, RATING, CLOSE
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.drama.image,
                    width: 60,
                    height: 85,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 85,
                      color: isDark ? const Color(0xFF2A2E39) : Colors.grey.shade300,
                      child: const Icon(Icons.movie_rounded, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.drama.title,
                              style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      Text(widget.drama.genre.split('•')[0].trim(), style: TextStyle(color: subTextColor, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                          const SizedBox(width: 4),
                          Text('${widget.drama.rating.toStringAsFixed(1)}   ', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                          Icon(Icons.list_alt, color: subTextColor, size: 16),
                          const SizedBox(width: 4),
                          Text('${widget.drama.watchedEpisodes}/${widget.drama.episodes}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          TabBar(
            controller: _tabController,
            labelColor: primaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryBlue,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'UMUM'),
              Tab(text: 'LANJUT'),
            ],
          ),
          
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUmumTab(textColor, subTextColor, primaryBlue, inputBg, actionBtnBg, isDark),
                _buildLanjutTab(textColor, inputBg),
              ],
            ),
          ),
          
          // TOMBOL SIMPAN PERUBAHAN
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  widget.drama.status == 'Belum Ditonton' ? 'Tambah ke Daftar' : 'Simpan Perubahan', 
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TAB UMUM (STATUS, KONTROL EPISODE, SLIDER PERINGKAT)
  Widget _buildUmumTab(
    Color textColor,
    Color subTextColor,
    Color primaryBlue,
    Color inputBg,
    Color actionBtnBg,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. DROPDOWN STATUS
          Text('Status', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _statusOptions.contains(_status) ? _status : 'Belum Ditonton',
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF1E2129) : Colors.white,
                style: TextStyle(color: textColor, fontSize: 14),
                items: _statusOptions.map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() { 
                      _status = newValue; 
                      if (_status == 'Selesai') {
                        _watchedEpisodes = _totalEpisodes;
                      } else if (_status == 'Belum Ditonton') {
                        _watchedEpisodes = 0;
                      }
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 22),
          
          // 2. BAGIAN EPISODE: TEKS PROGRES (0/16) + ICON BUTTON PENSIL, (-) DAN (+)
          Text('Episode', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              // Teks progres (contoh: 0/16)
              Text(
                '$_watchedEpisodes/$_totalEpisodes',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Icon button Edit (pensil)
              InkWell(
                onTap: () => _showEditEpisodeDialog(context, textColor, inputBg, primaryBlue),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: actionBtnBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Icon(Icons.edit_outlined, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              // Tombol (-) untuk mengurangi 1 episode
              InkWell(
                onTap: () {
                  if (_watchedEpisodes > 0) {
                    setState(() {
                      _watchedEpisodes--;
                      _syncStatusFromEpisodes();
                    });
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: actionBtnBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Icon(Icons.remove, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              // Tombol (+) untuk menambah 1 episode
              InkWell(
                onTap: () {
                  if (_watchedEpisodes < _totalEpisodes) {
                    setState(() {
                      _watchedEpisodes++;
                      _syncStatusFromEpisodes();
                    });
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: actionBtnBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Icon(Icons.add, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: _totalEpisodes > 0 ? _watchedEpisodes / _totalEpisodes : 0,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Episode terakhir ditonton Episode $_watchedEpisodes',
            style: TextStyle(color: subTextColor, fontSize: 12),
          ),
          
          const SizedBox(height: 22),
          
          // 3. BAGIAN PERINGKAT: TEKS ANGKA RATING (0.0 - 10.0) + IKON BINTANG (⭐) REAL-TIME DI ATAS SLIDER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Peringkat',
                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: actionBtnBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      _rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: primaryBlue,
              inactiveTrackColor: isDark ? const Color(0xFF2A2E39) : Colors.grey.shade300,
              thumbColor: Colors.white,
              overlayColor: primaryBlue.withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 2),
            ),
            child: Slider(
              value: _rating.clamp(0.0, 10.0),
              min: 0.0,
              max: 10.0,
              divisions: 100, // presisi desimal 0.0 sampai 10.0
              onChanged: (value) {
                setState(() {
                  // Berubah secara real-time saat slider digeser
                  _rating = double.parse(value.toStringAsFixed(1));
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // TAB LANJUT (PRIORITAS & TANGGAL)
  Widget _buildLanjutTab(Color textColor, Color inputBg) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prioritas', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _priority,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF1E2129) : Colors.white,
                style: TextStyle(color: textColor),
                items: ['Rendah', 'Sedang', 'Tinggi'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() { _priority = newValue; });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          Text('Tanggal Mulai', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _startDateController,
            readOnly: true,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              filled: true,
              fillColor: inputBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                    onPressed: () => _startDateController.clear(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
                    onPressed: () => _selectDate(context, _startDateController),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          Text('Tanggal Selesai', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _endDateController,
            readOnly: true,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              filled: true,
              fillColor: inputBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                    onPressed: () => _endDateController.clear(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
                    onPressed: () => _selectDate(context, _endDateController),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
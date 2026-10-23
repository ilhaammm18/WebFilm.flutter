import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/drama.dart';
import '../data/shared_data.dart';
import '../routes/app_router.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';

class EditDramaModal extends StatefulWidget {
  final Drama drama;
  final int? index;
  final String? initialStatus;
  final SupabaseClient? supabaseClient;
  final ApiService? apiService;

  const EditDramaModal({
    super.key,
    required this.drama,
    this.index,
    this.initialStatus,
    this.supabaseClient,
    this.apiService,
  });

  @override
  State<EditDramaModal> createState() => _EditDramaModalState();
}

class _EditDramaModalState extends State<EditDramaModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final ApiService _apiService;
  static final Map<int, String> _mediaTypeCache = {};
  static final Map<int, String> _genreCache = {};
  
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
  DateTime? _dateCompleted;
  
  late String _priority;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _apiService = widget.apiService ?? ApiService();

    // Pulihkan dari cache lokal jika pernah di-fetch sebelumnya
    if (widget.drama.id > 0) {
      if (_mediaTypeCache.containsKey(widget.drama.id)) {
        widget.drama.mediaType = _mediaTypeCache[widget.drama.id]!;
      }
      if (_genreCache.containsKey(widget.drama.id) &&
          (widget.drama.genre == 'General' || widget.drama.genre.isEmpty)) {
        widget.drama.genre = _genreCache[widget.drama.id]!;
      }
      _fetchTmdbDetail();
    }
    
    if (widget.initialStatus != null && _statusOptions.contains(widget.initialStatus)) {
      _status = widget.initialStatus!;
    } else if (widget.index != null && _statusOptions.contains(widget.drama.status)) {
      _status = widget.drama.status;
    } else if (_statusOptions.contains(widget.drama.status)) {
      _status = widget.drama.status;
    } else {
      _status = 'Belum Ditonton';
    }
    final bool isAdding = widget.initialStatus == 'Belum Ditonton' || _status == 'Belum Ditonton';
    if (isAdding) {
      _rating = 0.0;
    } else {
      _rating = widget.drama.userRating ?? widget.drama.myRating ?? 0.0;
    }
    _watchedEpisodes = (_status == 'Belum Ditonton' || _status == 'Rencana Ditonton')
        ? 0
        : widget.drama.watchedEpisodes;
    _totalEpisodes = widget.drama.episodes;
    
    _priority = widget.drama.priority.isNotEmpty ? widget.drama.priority : 'Sedang';
    _dateCompleted = widget.drama.dateCompleted;
    _startDateController = TextEditingController(text: widget.drama.startDate);
    _endDateController = TextEditingController(text: widget.drama.endDate);
  }

  Future<void> _fetchTmdbDetail() async {
    if (widget.drama.id <= 0) return;
    try {
      final detail = await _apiService.getMovieDetails(
        widget.drama.id,
        mediaType: widget.drama.mediaType.isNotEmpty ? widget.drama.mediaType : null,
      );
      if (detail.mediaType.isNotEmpty) {
        _mediaTypeCache[widget.drama.id] = detail.mediaType;
        widget.drama.mediaType = detail.mediaType;
      }
      if (detail.genre.isNotEmpty && detail.genre != 'General') {
        _genreCache[widget.drama.id] = detail.genre;
        widget.drama.genre = detail.genre;
      } else if (widget.drama.genre == 'General' || widget.drama.genre.isEmpty) {
        widget.drama.genre = detail.mediaType == 'tv' ? 'Serial TV' : 'Film';
      }
      if (detail.originalLanguage.isNotEmpty && widget.drama.originalLanguage.isEmpty) {
        widget.drama.originalLanguage = detail.originalLanguage;
      }
      if (detail.genresList.isNotEmpty) {
        widget.drama.genresList = detail.genresList;
      }
      if (detail.genreIds.isNotEmpty) {
        widget.drama.genreIds = detail.genreIds;
      }
      if (detail.image.isNotEmpty && widget.drama.image.isEmpty) {
        widget.drama.image = detail.image;
      }
      if (detail.backdrop.isNotEmpty && widget.drama.backdrop.isEmpty) {
        widget.drama.backdrop = detail.backdrop;
      }
      if (detail.episodes > 0 && widget.drama.episodes == 0) {
        widget.drama.episodes = detail.episodes;
        _totalEpisodes = detail.episodes;
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error fetch TMDB detail in EditDramaModal: $e');
    }
  }

  /// Label kategori dinamis (tipe tayangan seperti 'Film' atau 'Serial TV')
  String get _displayCategory {
    final label = getDynamicLabel(drama: widget.drama);
    if (label.isNotEmpty && label != 'General') {
      return label;
    }
    if (widget.drama.isMovie || widget.drama.mediaType == 'movie') {
      return 'Film';
    }
    return 'Serial TV';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  /// Input 'Episode' & 'Peringkat' hanya ditampilkan jika status BUKAN 'Rencana Ditonton' DAN BUKAN 'Belum Ditonton'
  bool get _showProgressInputs =>
      _status != 'Rencana Ditonton' && _status != 'Belum Ditonton';

  /// Logika kondisional: Jika episode_count bernilai 0, null, atau jika tipe medianya adalah 'Film' (Movie),
  /// sembunyikan keseluruhan widget ikon list dan teks '0/0' tersebut agar UI tidak terlihat janggal.
  bool get _shouldShowEpisodeInfo {
    final bool isMovie = widget.drama.mediaType == 'movie' ||
        widget.drama.isMovie ||
        widget.drama.genre.toLowerCase().contains('film');
    final bool hasValidEpisodes = widget.drama.episodes > 0;
    return !isMovie && hasValidEpisodes;
  }

  // Sinkronisasi status otomatis berdasarkan jumlah episode ditonton
  void _syncStatusFromEpisodes() {
    if (_totalEpisodes > 0 && _watchedEpisodes >= _totalEpisodes) {
      if (_status != 'Selesai') {
        _dateCompleted = DateTime.now();
      }
      _status = 'Selesai';
    } else if (_watchedEpisodes > 0 && _watchedEpisodes < _totalEpisodes) {
      _status = 'Sedang Menonton';
    } else if (_watchedEpisodes == 0 && _status != 'Sedang Menonton') {
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
            onPressed: () => ctx.pop(),
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
              ctx.pop();
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  SupabaseClient? get _supabase {
    if (widget.supabaseClient != null) return widget.supabaseClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // FUNGSI SIMPAN PERUBAHAN: Terhubung 100% dengan State, Data Asli, dan Supabase
  void _saveChanges() async {
    // Simpan snapshot status dan state sebelumnya untuk rollback jika simpan ke Supabase gagal
    final previousList = List<Drama>.from(SharedData.dramaListNotifier.value);
    final previousStatus = widget.drama.status;
    final previousWatchedEpisodes = widget.drama.watchedEpisodes;
    final previousRating = widget.drama.rating;
    final previousUserRating = widget.drama.userRating;
    final previousMyRating = widget.drama.myRating;
    final previousPriority = widget.drama.priority;
    final previousStartDate = widget.drama.startDate;
    final previousEndDate = widget.drama.endDate;
    final previousDateCompleted = widget.drama.dateCompleted;

    // Menggunakan value status yang benar-benar dipilih pengguna dari UI (_status)
    String newStatus = _status;
    int newWatchedEpisodes = _watchedEpisodes;
    DateTime? newDateCompleted = _dateCompleted;

    if (widget.drama.mediaType != 'movie') {
      if (newStatus == 'Selesai') {
        if (_totalEpisodes > 0 && newWatchedEpisodes < _totalEpisodes) {
          newWatchedEpisodes = _totalEpisodes;
        }
        newDateCompleted ??= DateTime.now();
      } else {
        newDateCompleted = null;
      }
    } else {
      newWatchedEpisodes = (newStatus == 'Selesai') ? 1 : 0;
      if (newStatus == 'Selesai') {
        newDateCompleted ??= DateTime.now();
      } else {
        newDateCompleted = null;
      }
    }

    // 1. Simpan Data ke Supabase dengan User ID (Insert/Update)
    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    bool isDbSuccess = true;
    String? dbErrorMessage;

    if (client != null && userId != null) {
      String originalLanguage = widget.drama.originalLanguage;
      if (originalLanguage.isEmpty) {
        final g = widget.drama.genre.toLowerCase();
        if (g.contains('korea')) {
          originalLanguage = 'ko';
        } else if (g.contains('jepang') || g.contains('japan') || g.contains('anime')) {
          originalLanguage = 'ja';
        } else if (g.contains('barat') || g.contains('western')) {
          originalLanguage = 'en';
        }
      }
      widget.drama.originalLanguage = originalLanguage;

      final Map<String, dynamic> payload = {
        'user_id': userId,
        'judul_film': widget.drama.title,
        'status': newStatus,
        'tmdb_id': widget.drama.id,
        'rating': _rating,
      };

      try {
        if (newStatus == 'Belum Ditonton') {
          try {
            await client
                .from('watchlists')
                .delete()
                .eq('user_id', userId)
                .eq('tmdb_id', widget.drama.id);
          } catch (_) {
            await client
                .from('watchlists')
                .delete()
                .eq('user_id', userId)
                .eq('drama_id', widget.drama.id);
          }
        } else {
          Map<String, dynamic> currentPayload = Map<String, dynamic>.from(payload);
          bool upsertSuccess = false;
          dynamic lastError;

          for (int attempt = 0; attempt < 5; attempt++) {
            try {
              // 1. Cek apakah row sudah ada berdasarkan user_id dan tmdb_id / drama_id
              dynamic existingRow;
              try {
                final queryCol = currentPayload.containsKey('tmdb_id') ? 'tmdb_id' : 'drama_id';
                existingRow = await client
                    .from('watchlists')
                    .select('id')
                    .eq('user_id', userId)
                    .eq(queryCol, widget.drama.id)
                    .maybeSingle();
              } catch (_) {
                existingRow = null;
              }

              if (existingRow != null && existingRow['id'] != null) {
                // Baris sudah ada: perbarui (update) berdasarkan ID
                await client
                    .from('watchlists')
                    .update(currentPayload)
                    .eq('id', existingRow['id']);
              } else {
                // Baris belum ada: simpan dengan insert atau upsert
                try {
                  await client.from('watchlists').insert(currentPayload);
                } catch (_) {
                  await client.from('watchlists').upsert(currentPayload);
                }
              }

              upsertSuccess = true;
              break;
            } catch (err) {
              lastError = err;
              final errStr = err.toString();

              // Deteksi jika PostgREST menolak karena kolom tidak ada di skema database (code: PGRST204)
              final match = RegExp(r"Could not find the '([^']+)' column", caseSensitive: false).firstMatch(errStr);
              if (match != null) {
                final missingCol = match.group(1);
                if (missingCol != null && currentPayload.containsKey(missingCol)) {
                  currentPayload.remove(missingCol);
                  // Fleksibilitas skema: jika judul_film tidak ada, coba gunakan title
                  if (missingCol == 'judul_film') {
                    currentPayload['title'] = widget.drama.title;
                  } else if (missingCol == 'title') {
                    currentPayload['judul_film'] = widget.drama.title;
                  } else if (missingCol == 'tmdb_id') {
                    currentPayload['drama_id'] = widget.drama.id;
                  }
                  continue;
                }
              }

              rethrow;
            }
          }

          if (!upsertSuccess && lastError != null) {
            throw lastError;
          }
        }
      } catch (e) {
        isDbSuccess = false;
        dbErrorMessage = e.toString();
        debugPrint('Gagal menyimpan data ke Supabase: $e');
      }
    }

    // Jika simpan ke Supabase gagal:
    // Kembalikan status UI ke bentuk awal (ikon '+') dan munculkan SnackBar peringatan
    if (!isDbSuccess) {
      widget.drama.watchedEpisodes = previousWatchedEpisodes;
      widget.drama.status = previousStatus;
      widget.drama.rating = previousRating;
      widget.drama.userRating = previousUserRating;
      widget.drama.myRating = previousMyRating;
      widget.drama.priority = previousPriority;
      widget.drama.startDate = previousStartDate;
      widget.drama.endDate = previousEndDate;
      widget.drama.dateCompleted = previousDateCompleted;

      SharedData.dramaListNotifier.value = List<Drama>.from(previousList);
      SharedData.dramaListNotifier.notifyListeners();

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              dbErrorMessage != null && dbErrorMessage.isNotEmpty
                  ? 'Gagal menyimpan ke database: $dbErrorMessage'
                  : 'Gagal menyimpan ke database. Data tidak berhasil disimpan.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // 2. Jika sukses: Perbarui objek drama yang aktif
    widget.drama.watchedEpisodes = newWatchedEpisodes;
    widget.drama.status = newStatus; 
    widget.drama.userRating = _rating;
    widget.drama.myRating = _rating;
    widget.drama.rating = _rating;
    widget.drama.priority = _priority;
    widget.drama.startDate = _startDateController.text;
    widget.drama.endDate = _endDateController.text;
    widget.drama.dateCompleted = newDateCompleted;

    // 3. Perbarui list di SharedData.dramaListNotifier
    List<Drama> currentList = List<Drama>.from(SharedData.dramaListNotifier.value);
    
    int targetIndex = widget.index ?? currentList.indexWhere(
      (d) => widget.drama.id > 0
          ? d.id == widget.drama.id
          : d.title.trim().toLowerCase() == widget.drama.title.trim().toLowerCase(),
    );
    if (targetIndex != -1) {
      currentList[targetIndex].watchedEpisodes = newWatchedEpisodes;
      currentList[targetIndex].status = newStatus; 
      currentList[targetIndex].userRating = _rating;
      currentList[targetIndex].myRating = _rating;
      currentList[targetIndex].rating = _rating;
      currentList[targetIndex].priority = _priority;
      currentList[targetIndex].startDate = _startDateController.text;
      currentList[targetIndex].endDate = _endDateController.text;
      currentList[targetIndex].dateCompleted = newDateCompleted;
      
      // Pindahkan drama yang baru diedit ke urutan paling depan (index 0)
      Drama editedDrama = currentList.removeAt(targetIndex);
      currentList.insert(0, editedDrama);
    } else {
      currentList.insert(0, widget.drama);
    }
    
    // Perbarui ValueNotifier secara reaktif ke seluruh aplikasi
    SharedData.dramaListNotifier.value = List<Drama>.from(currentList);
    SharedData.dramaListNotifier.notifyListeners();

    if (mounted) {
      context.pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'Belum Ditonton'
                ? '${widget.drama.title} dihapus dari daftar tontonan'
                : (previousStatus == 'Belum Ditonton'
                    ? '${widget.drama.title} berhasil ditambahkan ke daftar ($newStatus)!'
                    : 'Perubahan pada "${widget.drama.title}" berhasil disimpan!'),
          ),
          backgroundColor: newStatus == 'Belum Ditonton' ? Colors.grey.shade700 : const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
                            onPressed: () => context.pop(),
                          ),
                        ],
                      ),
                      Text(
                        _displayCategory,
                        style: TextStyle(color: subTextColor, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${(widget.drama.userRating ?? widget.drama.myRating ?? 0.0).toStringAsFixed(1)}   ',
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                          ),
                          if (_shouldShowEpisodeInfo) ...[
                            Icon(Icons.list_alt, color: subTextColor, size: 16),
                            const SizedBox(width: 4),
                            Text('${widget.drama.watchedEpisodes}/${widget.drama.episodes}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                          ],
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
                      if (_status == 'Sedang Menonton' || _status == 'Selesai') {
                        _rating = 0.0;
                      }
                      if (_status == 'Selesai') {
                        _watchedEpisodes = _totalEpisodes;
                        _dateCompleted = DateTime.now();
                      } else if (_status == 'Belum Ditonton' ||
                          _status == 'Rencana Ditonton') {
                        // Reset progres agar auto-sync saat simpan tidak
                        // mengubah status kembali ke 'Sedang Menonton'
                        _watchedEpisodes = 0;
                        _dateCompleted = null;
                      } else {
                        _dateCompleted = null;
                      }
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 22),
          
          // 2. BAGIAN EPISODE: TEKS PROGRES (0/16) + ICON BUTTON PENSIL, (-) DAN (+)
          if (_shouldShowEpisodeInfo && _showProgressInputs) ...[
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
          ],
          
          // 3. BAGIAN PERINGKAT: TEKS ANGKA RATING (0.0 - 10.0) + IKON BINTANG (â­) REAL-TIME DI ATAS SLIDER
          if (_showProgressInputs) ...[
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

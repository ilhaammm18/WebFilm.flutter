import 'package:flutter/material.dart';
import 'models/drama.dart';
import 'data/shared_data.dart'; // Import ini sudah ditambahkan

class DetailPage extends StatelessWidget {
  final Drama drama;

  const DetailPage({super.key, required this.drama});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color bgColor = isDark ? const Color(0xFF222228) : const Color(0xFFF8F9FA);
    Color cardBg = isDark ? const Color(0xFF2C2C34) : Colors.white;
    Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    Color subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    Color primaryBlue = const Color(0xFF0094FF); 
    Color ratingTeal = const Color(0xFF11B199); 
    
    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  color: Colors.amber, 
                  child: Image.network(
                    drama.image, 
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    color: Colors.black.withValues(alpha: 0.3),
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
                
                Positioned(
                  top: 40,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: -40,
                  left: 20,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      drama.image,
                      width: 100,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.only(left: 140, right: 16, top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drama.title,
                    style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    drama.koreanTitle,
                    style: TextStyle(color: subTextColor, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${drama.genre.split('•')[0].trim()}  •  2023',
                    style: TextStyle(color: subTextColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    _buildStatItem(Icons.trending_up, primaryBlue, drama.rank, 'Peringkat', subTextColor),
                    _buildDivider(subTextColor),
                    _buildStatItem(Icons.local_fire_department, primaryBlue, drama.popularity, 'Popularitas', subTextColor),
                    _buildDivider(subTextColor),
                    _buildStatItem(Icons.remove_red_eye, primaryBlue, drama.watchers, 'Penonton', subTextColor),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: ratingTeal, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        drama.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: List.generate(5, (index) => const Icon(Icons.star, color: Colors.amber, size: 16))),
                        const SizedBox(height: 4),
                        Text('dari 10.3K pengguna', style: TextStyle(color: subTextColor, fontSize: 11)),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fitur penilaian akan segera hadir!')),
                        );
                      },
                      child: Text('Berikan Penilaian\nSekarang', textAlign: TextAlign.right, style: TextStyle(color: primaryBlue, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                drama.synopsis,
                style: TextStyle(color: textColor.withValues(alpha: 0.9), fontSize: 14, height: 1.6),
              ),
            ),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => EditDramaModal(drama: drama),
          );
        },
        backgroundColor: primaryBlue,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color iconColor, String value, String label, Color subTextColor) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: subTextColor, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Container(height: 30, width: 1, color: color.withValues(alpha: 0.2));
  }
}


// ============================================================================
// BOTTOM SHEET MODAL DENGAN KONTROL EPISODE DI DALAMNYA
// ============================================================================
class EditDramaModal extends StatefulWidget {
  final Drama drama;
  const EditDramaModal({super.key, required this.drama});

  @override
  State<EditDramaModal> createState() => _EditDramaModalState();
}

class _EditDramaModalState extends State<EditDramaModal> {
  late String _selectedStatus;
  double _ratingValue = 0.0;
  int _tabIndex = 0; 
  bool _isInList = true; 
  
  late int _currentWatched;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.drama.status.isNotEmpty ? widget.drama.status : 'Sedang Menonton';
    _currentWatched = widget.drama.watchedEpisodes;
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color bgColor = isDark ? const Color(0xFF22242D) : Colors.white;
    Color bottomBarColor = isDark ? const Color(0xFF1E1F28) : Colors.grey.shade100;
    Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    Color subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    Color primaryBlue = const Color(0xFF2094FA);
    Color inputBg = isDark ? const Color(0xFF22242D) : Colors.white;
    Color borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300;
    Color actionBtnBg = isDark ? const Color(0xFF2A2D3A) : Colors.grey.shade200;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER MODAL
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    widget.drama.image,
                    width: 50, height: 75, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(width: 50, height: 75, color: Colors.grey.shade800),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.drama.title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('${widget.drama.genre.split('•')[0].trim()} • 2026', style: TextStyle(color: subTextColor, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(widget.drama.rating.toStringAsFixed(1), style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          Icon(Icons.list_alt, color: subTextColor, size: 14),
                          const SizedBox(width: 4),
                          Text('${widget.drama.episodes}', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: subTextColor, size: 20),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),

          // 2. TAB MENU
          Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderColor))),
            child: Row(
              children: [
                _buildTabBtn('UMUM', 0, primaryBlue, textColor, subTextColor),
                _buildTabBtn('LANJUT', 1, primaryBlue, textColor, subTextColor),
              ],
            ),
          ),

          // 3. KONTEN FORM
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DROPDOWN STATUS
                  Text('Status', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        dropdownColor: bgColor,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down, color: subTextColor),
                        style: TextStyle(color: textColor, fontSize: 14),
                        items: ['Sedang Menonton', 'Selesai', 'Rencana Ditonton']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() => _selectedStatus = newValue);
                          }
                        },
                      ),
                    ),
                  ),

                  // ===========================================================
                  // KONTROL EPISODE
                  // ===========================================================
                  if (_selectedStatus == 'Sedang Menonton') ...[
                    const SizedBox(height: 24),
                    Text('Episode', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '$_currentWatched/${widget.drama.episodes}',
                          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: actionBtnBg, borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.edit_outlined, color: subTextColor, size: 18),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            if (_currentWatched > 0) {
                              setState(() => _currentWatched--);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: actionBtnBg, borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.remove, color: subTextColor, size: 18),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            if (_currentWatched < widget.drama.episodes) {
                              setState(() => _currentWatched++);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: actionBtnBg, borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.add, color: subTextColor, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // SLIDER PERINGKAT
                  Text('Peringkat', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      activeTrackColor: subTextColor.withValues(alpha: 0.5),
                      inactiveTrackColor: borderColor,
                      thumbColor: Colors.white,
                      overlayColor: primaryBlue.withValues(alpha: 0.2),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 2),
                    ),
                    child: Slider(
                      value: _ratingValue,
                      min: 0,
                      max: 10,
                      divisions: 20,
                      onChanged: (value) {
                        setState(() => _ratingValue = value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. BAGIAN BAWAH
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bottomBarColor,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                if (_isInList) ...[
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Berhasil dihapus dari daftar')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2F3A) : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Simpan perubahan ke shared data
                        widget.drama.status = _selectedStatus;
                        widget.drama.watchedEpisodes = _currentWatched;
                        SharedData.dramaListNotifier.notifyListeners(); // Sekarang tidak akan error lagi

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Perubahan pada "${widget.drama.title}" disimpan!')),
                        );
                      },
                      style: ElevatedButton.styleFrom( // Typo styleForm sudah diperbaiki
                        backgroundColor: primaryBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBtn(String title, int index, Color primaryBlue, Color textColor, Color subTextColor) {
    bool isActive = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: isActive ? primaryBlue : Colors.transparent, width: 2),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? primaryBlue : subTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
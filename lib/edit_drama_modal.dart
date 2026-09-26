import 'package:flutter/material.dart';
import 'models/drama.dart';
import 'data/shared_data.dart';

class EditDramaModal extends StatefulWidget {
  final Drama drama;
  final int index;

  const EditDramaModal({super.key, required this.drama, required this.index});

  @override
  State<EditDramaModal> createState() => _EditDramaModalState();
}

class _EditDramaModalState extends State<EditDramaModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
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
    
    _status = widget.drama.status;
    _rating = widget.drama.rating;
    _watchedEpisodes = widget.drama.watchedEpisodes;
    _totalEpisodes = widget.drama.episodes;
    
    _priority = widget.drama.priority;
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

  void _saveChanges() {
    List<Drama> currentList = List.from(SharedData.dramaListNotifier.value);
    
    // Perbarui data film
    currentList[widget.index].updateProgress(_watchedEpisodes);
    currentList[widget.index].status = _status; 
    currentList[widget.index].rating = _rating;
    currentList[widget.index].priority = _priority;
    currentList[widget.index].startDate = _startDateController.text;
    currentList[widget.index].endDate = _endDateController.text;
    
    // LOGIKA PEMBARUAN TERAKHIR: 
    // Pindahkan film yang baru diedit ini ke urutan paling depan (index 0)
    Drama editedDrama = currentList.removeAt(widget.index);
    currentList.insert(0, editedDrama);
    
    // Simpan ke database sementara
    SharedData.dramaListNotifier.value = [];
    SharedData.dramaListNotifier.value = currentList;
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perubahan berhasil disimpan!'), backgroundColor: Colors.green),
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
    Color textColor = isDark ? Colors.white : Colors.black;
    Color primaryBlue = const Color(0xFF0094FF);
    Color inputBg = isDark ? const Color(0xFF2A2E39) : Colors.grey.shade100;

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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(widget.drama.image, width: 60, height: 85, fit: BoxFit.cover),
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
                              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      Text(widget.drama.genre.split('•')[0].trim(), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text('${widget.drama.rating.toStringAsFixed(1)}   ', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                          const Icon(Icons.list_alt, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text('${widget.drama.watchedEpisodes}/${widget.drama.episodes}', style: TextStyle(color: textColor)),
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
            tabs: const [
              Tab(text: 'UMUM'),
              Tab(text: 'LANJUT'),
            ],
          ),
          
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUmumTab(textColor, primaryBlue, inputBg),
                _buildLanjutTab(textColor, inputBg),
              ],
            ),
          ),
          
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUmumTab(Color textColor, Color primaryBlue, Color inputBg) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _status,
                isExpanded: true,
                dropdownColor: inputBg,
                style: TextStyle(color: textColor),
                items: ['Sedang Menonton', 'Selesai', 'Rencana Ditonton'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) {
                  setState(() { 
                    _status = newValue!; 
                    if (_status == 'Selesai') {
                      _watchedEpisodes = _totalEpisodes;
                    }
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          Text('Episode', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _totalEpisodes > 0 ? _watchedEpisodes / _totalEpisodes : 0,
                  backgroundColor: Colors.grey.shade800,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                ),
              ),
              const SizedBox(width: 12),
              Text('$_watchedEpisodes/$_totalEpisodes', style: TextStyle(color: textColor)),
              IconButton(icon: const Icon(Icons.remove, color: Colors.grey), onPressed: () {
                if (_watchedEpisodes > 0) setState(() => _watchedEpisodes--);
              }),
              IconButton(icon: const Icon(Icons.add, color: Colors.grey), onPressed: () {
                if (_watchedEpisodes < _totalEpisodes) {
                  setState(() {
                    _watchedEpisodes++;
                    if (_watchedEpisodes == _totalEpisodes) _status = 'Selesai';
                  });
                }
              }),
            ],
          ),
          Text('Episode terakhir ditonton Episode $_watchedEpisodes', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Peringkat', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(_rating.toStringAsFixed(1), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          Slider(
            value: _rating,
            min: 0.0,
            max: 10.0,
            divisions: 20, 
            activeColor: primaryBlue,
            inactiveColor: Colors.grey.shade800,
            onChanged: (value) {
              setState(() { _rating = value; });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanjutTab(Color textColor, Color inputBg) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prioritas', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _priority,
                isExpanded: true,
                dropdownColor: inputBg,
                style: TextStyle(color: textColor),
                items: ['Rendah', 'Sedang', 'Tinggi'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) {
                  setState(() { _priority = newValue!; });
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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
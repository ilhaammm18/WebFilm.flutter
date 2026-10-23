import 'package:flutter/material.dart';
import '../models/actor.dart';
import '../models/drama.dart';

/// 1. Warna Kotak Rating Dinamis
/// Rating >= 8.5 : Hijau tua (Colors.green[700])
/// Rating >= 7.5 : Hijau muda atau Biru (Color(0xFF0094FF))
/// Rating >= 6.0 : Kuning / Oranye (Color(0xFFF57C00))
/// Rating < 6.0  : Merah (Color(0xFFD32F2F))
Color getRatingColor(double rating) {
  if (rating >= 8.5) {
    return Colors.green.shade700;
  } else if (rating >= 7.5) {
    return const Color(0xFF0094FF);
  } else if (rating >= 6.0) {
    return const Color(0xFFF57C00);
  } else {
    return const Color(0xFFD32F2F);
  }
}

/// 2. Fungsi getDynamicLabel() / getCustomCategory()
/// Aturan penentuan kategori kustom:
/// - Jika original_language adalah 'ko'/'kr' dan tipenya 'tv' -> 'Drama Korea'
/// - Jika original_language adalah 'ko'/'kr' dan tipenya 'movie' -> 'Film Korea'
/// - Jika original_language adalah 'en'/'us' (Inggris/Barat) dan tipenya 'tv' -> 'Drama Barat'
/// - Jika original_language adalah 'en'/'us' (Inggris/Barat) dan tipenya 'movie' -> 'Film Barat'
/// Serta mendukung kategori pendukung ('Anime', 'Drama Jepang', 'Film Jepang').
String getDynamicLabel({
  String? mediaType,
  String? originalLanguage,
  String? originCountry,
  List<dynamic>? genreIds,
  List<String>? genres,
  Drama? drama,
}) {
  return Drama.getCategoryLabel(
    mediaType: mediaType,
    originalLanguage: originalLanguage ?? originCountry,
    genreIds: genreIds?.map((e) => (e as num).toInt()).toList(),
    genres: genres,
    drama: drama,
  );
}

/// Helper untuk menentukan kategori kustom berdasarkan data TMDB atau Supabase
String getCustomCategory({
  Drama? drama,
  String? originalLanguage,
  String? mediaType,
}) {
  return getDynamicLabel(
    drama: drama,
    originalLanguage: originalLanguage,
    mediaType: mediaType,
  );
}

/// 3. Fungsi getActorNationality()
/// Aturan spesifikasi dari array known_for API:
/// 'ko' -> 'South Korean'
/// 'ja' -> 'Japanese'
/// 'zh' -> 'Cina'
String getActorNationality(dynamic source) {
  if (source is Actor) {
    if (source.knownFor != null && source.knownFor!.isNotEmpty) {
      final res = getActorNationality(source.knownFor);
      if (res != 'Internasional' && res != 'Aktor / Aktris') return res;
    }
    if (source.nationality.isNotEmpty &&
        source.nationality != 'Internasional' &&
        source.nationality != 'Aktor / Aktris') {
      return getActorNationality(source.nationality);
    }
    return 'South Korean';
  }

  if (source is List) {
    for (final item in source) {
      if (item is Map<String, dynamic>) {
        final lang = (item['original_language'] as String?)?.toLowerCase();
        if (lang == 'ko') return 'South Korean';
        if (lang == 'ja') return 'Japanese';
        if (lang == 'zh') return 'Cina';
      }
    }
  } else if (source is String) {
    final lower = source.toLowerCase().trim();
    if (lower == 'ko' || lower.contains('korea')) return 'South Korean';
    if (lower == 'ja' || lower.contains('japan') || lower.contains('jepang')) {
      return 'Japanese';
    }
    if (lower == 'zh' ||
        lower.contains('china') ||
        lower.contains('cina') ||
        lower.contains('tiongkok')) {
      return 'Cina';
    }
    if (lower.isNotEmpty &&
        lower != 'internasional' &&
        lower != 'aktor / aktris') {
      return source;
    }
  }

  return 'South Korean';
}

/// 4. Format Tanggal Selesai Tonton Bahasa Indonesia (misal: '16 Oktober 2026')
String formatIndonesianDate(DateTime date) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// 5. Format Tanggal MM/dd/yyyy (contoh: 09/18/2026)
String formatSlashDate(DateTime date) {
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  return '$mm/$dd/${date.year}';
}

/// 6. Format Tanggal Bulan/Tahun (contoh: 09/2026 atau 10/2026)
String formatMonthYear(DateTime date) {
  final mm = date.month.toString().padLeft(2, '0');
  return '$mm/${date.year}';
}

/// 7. Format Tanggal Lengkap dd/MM/yyyy (contoh: 18/09/2026 atau 16/10/2026)
String formatDate(dynamic date) {
  if (date == null) return '';
  DateTime? parsedDate;
  if (date is DateTime) {
    parsedDate = date;
  } else if (date is String) {
    parsedDate = DateTime.tryParse(date);
    if (parsedDate == null) {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[2].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[0]}';
      }
      return date;
    }
  }
  if (parsedDate == null) return date.toString();
  final dd = parsedDate.day.toString().padLeft(2, '0');
  final mm = parsedDate.month.toString().padLeft(2, '0');
  final yyyy = parsedDate.year.toString();
  return '$dd/$mm/$yyyy';
}

/// 8. Kamus Terjemahan Jabatan/Departemen Tim Produksi (Crew) TMDB ke Bahasa Indonesia
const Map<String, String> crewJobTranslations = {
  // Directing
  'Director': 'Sutradara',
  'Directing': 'Sutradara',
  'Co-Director': 'Ko-Sutradara',
  'Assistant Director': 'Asisten Sutradara',

  // Writing
  'Writer': 'Penulis',
  'Writing': 'Penulis',
  'Screenplay': 'Penulis Skenario',
  'Story': 'Penulis Cerita',
  'Novel': 'Penulis Novel',
  'Author': 'Penulis',
  'Characters': 'Karakter',

  // Producing
  'Producer': 'Produser',
  'Production': 'Produksi',
  'Executive Producer': 'Produser Eksekutif',
  'Co-Producer': 'Ko-Produser',
  'Line Producer': 'Produser Lini',
  'Associate Producer': 'Produser Madya',

  // Music & Sound
  'Original Music Composer': 'Komposer',
  'Composer': 'Komposer',
  'Music': 'Musik',
  'Sound': 'Tata Suara',
  'Sound Designer': 'Penata Suara',
  'Sound Mixer': 'Penata Suara',
  'Sound Editor': 'Editor Suara',

  // Editing
  'Editor': 'Editor',
  'Editing': 'Editor',

  // Camera & Cinematography
  'Director of Photography': 'Sinematografer',
  'Cinematography': 'Sinematografer',
  'Camera': 'Kamera',

  // Art & Design
  'Production Design': 'Desain Produksi',
  'Art Direction': 'Pengarah Artistik',
  'Costume Design': 'Desainer Kostum',
  'Costume Designer': 'Desainer Kostum',
  'Makeup Artist': 'Penata Rias',
  'Make-up Artist': 'Penata Rias',

  // Visual Effects
  'Visual Effects': 'Efek Visual',
  'VFX Supervisor': 'Pengawas Efek Visual',

  // Creator
  'Creator': 'Kreator',
};

/// Menerjemahkan jabatan atau departemen tim (kru) ke bahasa Indonesia.
/// Jika teks tidak ada di dalam kamus, teks aslinya akan ditampilkan.
String translateCrewRole(String? role) {
  if (role == null || role.trim().isEmpty) return '';
  final trimmed = role.trim();

  // 1. Cek exact match
  if (crewJobTranslations.containsKey(trimmed)) {
    return crewJobTranslations[trimmed]!;
  }

  // 2. Cek case-insensitive
  final lower = trimmed.toLowerCase();
  for (final entry in crewJobTranslations.entries) {
    if (entry.key.toLowerCase() == lower) {
      return entry.value;
    }
  }

  // 3. Fallback: tampilkan teks aslinya
  return trimmed;
}

/// Alias helper function untuk translateCrewRole
String translateCrewJob(String? job) => translateCrewRole(job);


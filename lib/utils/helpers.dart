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

/// 2. Fungsi getDynamicLabel()
/// Aturan spesifikasi:
/// - Jika 'tv' & 'KR' -> 'Drama Korea'
/// - Jika 'tv' & 'JP' & genre 16 -> 'Anime'
/// - Jika 'movie' & 'ko' -> 'Film Korea'
/// Serta mendukung kategori pendukung ('Film Jepang', 'Drama Jepang', 'Film Barat', 'Drama Barat').
String getDynamicLabel({
  String? mediaType,
  String? originalLanguage,
  String? originCountry,
  List<dynamic>? genreIds,
  List<String>? genres,
  Drama? drama,
}) {
  final String type =
      (drama != null ? drama.mediaType : (mediaType ?? 'tv')).toLowerCase();
  final String lang = (originalLanguage ??
          drama?.originalLanguage ??
          originCountry ??
          '')
      .toUpperCase();

  final List<dynamic> gIds = genreIds ?? drama?.genreIds ?? [];
  final bool hasAnimeGenre = gIds.contains(16) ||
      (genres?.any((g) => g.toLowerCase().contains('anime')) ?? false) ||
      (drama?.genre.toLowerCase().contains('anime') ?? false) ||
      (drama?.genresList.any((g) => g.toLowerCase().contains('anime')) ?? false);

  final bool isKorean = lang == 'KR' ||
      lang == 'KO' ||
      (drama?.genre.toLowerCase().contains('korea') ?? false);
  final bool isJapanese = lang == 'JP' ||
      lang == 'JA' ||
      (drama?.genre.toLowerCase().contains('jepang') ?? false) ||
      (drama?.genre.toLowerCase().contains('japan') ?? false) ||
      hasAnimeGenre;

  // 1. Jika 'tv' & 'KR' -> 'Drama Korea'
  if (type == 'tv' && isKorean) {
    return 'Drama Korea';
  }

  // 2. Jika 'tv' & 'JP' & genre 16 -> 'Anime'
  if (type == 'tv' &&
      (isJapanese || lang == 'JP' || lang == 'JA') &&
      hasAnimeGenre) {
    return 'Anime';
  }

  // 3. Jika 'movie' & 'ko' -> 'Film Korea'
  if (type == 'movie' && (lang == 'KO' || isKorean)) {
    return 'Film Korea';
  }

  // Tambahan kategori pendukung
  if (type == 'movie' && (lang == 'JA' || lang == 'JP' || isJapanese)) {
    return 'Film Jepang';
  }
  if (type == 'tv' && (lang == 'JA' || lang == 'JP' || isJapanese)) {
    return 'Drama Jepang';
  }
  if (type == 'movie' && (lang == 'EN' || lang == 'US')) {
    return 'Film Barat';
  }
  if (type == 'tv' && (lang == 'EN' || lang == 'US')) {
    return 'Drama Barat';
  }

  if (type == 'movie') {
    return 'Film';
  }
  return 'Drama';
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

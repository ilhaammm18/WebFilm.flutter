import 'package:flutter/material.dart';
import '../routes/app_router.dart';
import '../models/actor.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';

/// Halaman untuk menampilkan daftar lengkap pemeran (cast) atau tim (crew)
/// dalam bentuk Grid 3 kolom dengan desain Dark Mode.
class FullCreditsPage extends StatelessWidget {
  final String title;
  final List<dynamic>? cast;
  final List<dynamic>? crew;
  final List<dynamic>? items;
  final ApiService? apiService;

  const FullCreditsPage({
    super.key,
    required this.title,
    this.cast,
    this.crew,
    this.items,
    this.apiService,
  });

  List<_CreditItem> get _creditItems {
    final source = cast ?? crew ?? items ?? const [];
    return source.map((item) => _CreditItem.from(item)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final credits = _creditItems;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: credits.isEmpty
          ? Center(
              child: Text(
                'Tidak ada data yang tersedia',
                style: TextStyle(
                  color: isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width < 600
                    ? 3
                    : (MediaQuery.of(context).size.width / 120).floor(),
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.72,
              ),
              itemCount: credits.length,
              itemBuilder: (context, index) {
                final credit = credits[index];
                final bool hasPhoto = credit.photoUrl.isNotEmpty;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // a. Foto profil bulat dengan area klik khusus pada foto aktor
                    ClipOval(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (credit.id > 0) {
                              context.push(
                                '/actor/${credit.id}',
                                extra: {
                                  'actor': Actor(
                                    id: credit.id,
                                    name: credit.name,
                                    profilePath: credit.profilePath,
                                  ),
                                  'apiService': apiService,
                                  'imageUrl': credit.photoUrl,
                                },
                              );
                            }
                          },
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: isDark
                                ? const Color(0xFF262A36)
                                : const Color(0xFFE2E8F0),
                            backgroundImage:
                                hasPhoto ? NetworkImage(credit.photoUrl) : null,
                            onBackgroundImageError:
                                hasPhoto ? (_, _) {} : null,
                            child: !hasPhoto
                                ? Icon(
                                    Icons.person,
                                    size: 45,
                                    color: isDark
                                        ? const Color(0xFF9CA3AF)
                                        : Colors.grey.shade500,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // b. Teks nama asli aktor/kru
                    Text(
                      credit.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // c. Teks nama karakter/peran
                    Text(
                      credit.role,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        height: 1.2,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _CreditItem {
  final int id;
  final String name;
  final String role;
  final String photoUrl;
  final String? profilePath;
  final dynamic raw;

  const _CreditItem({
    this.id = 0,
    required this.name,
    required this.role,
    required this.photoUrl,
    this.profilePath,
    this.raw,
  });

  factory _CreditItem.from(dynamic item) {
    if (item is ActorCredit) {
      return _CreditItem(
        id: item.id,
        name: item.title,
        role: item.character.isNotEmpty ? item.character : 'Pemeran',
        photoUrl: item.profileUrl,
        profilePath: item.profilePath,
        raw: item,
      );
    } else if (item is MovieCrewMember) {
      final roleText = item.job.isNotEmpty
          ? item.job
          : (item.department.isNotEmpty ? item.department : 'Kru');
      return _CreditItem(
        id: item.id,
        name: item.name,
        role: translateCrewRole(roleText),
        photoUrl: item.profileUrl,
        profilePath: item.profilePath,
        raw: item,
      );
    } else if (item is Actor) {
      return _CreditItem(
        id: item.id,
        name: item.name,
        role: 'Pemeran',
        photoUrl: item.imageUrl,
        profilePath: item.profilePath,
        raw: item,
      );
    } else if (item is ({String name, String subtitle, String photoUrl})) {
      return _CreditItem(
        name: item.name,
        role: translateCrewRole(item.subtitle),
        photoUrl: item.photoUrl,
        raw: item,
      );
    } else if (item is Map) {
      final name = (item['name'] ?? item['title'] ?? '') as String;
      String role = (item['character'] ??
          item['job'] ??
          item['role'] ??
          item['subtitle'] ??
          '') as String;
      if (item.containsKey('job') || item.containsKey('department')) {
        role = translateCrewRole(role);
      }
      String photo = (item['profileUrl'] ??
          item['photoUrl'] ??
          item['imageUrl'] ??
          '') as String;
      final profilePath = item['profile_path'] as String?;
      if (photo.isEmpty && profilePath != null && profilePath.isNotEmpty) {
        photo = 'https://image.tmdb.org/t/p/w500$profilePath';
      }
      return _CreditItem(
        id: (item['id'] as int?) ?? 0,
        name: name,
        role: role,
        photoUrl: photo,
        profilePath: profilePath,
        raw: item,
      );
    } else if (item != null) {
      String name = '';
      String role = '';
      String photo = '';
      String? profilePath;
      int id = 0;
      try {
        name = (item as dynamic).name ?? '';
      } catch (_) {
        try {
          name = (item as dynamic).title ?? '';
        } catch (_) {}
      }
      try {
        role = (item as dynamic).character ?? '';
      } catch (_) {
        try {
          role = translateCrewRole((item as dynamic).job ?? '');
        } catch (_) {
          try {
            role = translateCrewRole((item as dynamic).role ?? '');
          } catch (_) {}
        }
      }
      try {
        photo = (item as dynamic).profileUrl ?? '';
      } catch (_) {
        try {
          photo = (item as dynamic).imageUrl ?? '';
        } catch (_) {}
      }
      try {
        profilePath = (item as dynamic).profilePath;
      } catch (_) {}
      try {
        id = (item as dynamic).id ?? 0;
      } catch (_) {}
      return _CreditItem(
        id: id,
        name: name.isNotEmpty ? name : item.toString(),
        role: role,
        photoUrl: photo,
        profilePath: profilePath,
        raw: item,
      );
    }
    return const _CreditItem(name: '', role: '', photoUrl: '');
  }
}

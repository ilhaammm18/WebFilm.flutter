class Actor {
  final int id;
  final String name;
  final String? profilePath;
  final String koreanName;
  final String nationality;
  final String? birthday;
  final String? placeOfBirth;
  final String birthDate;
  final int age;
  final String _imageUrl;
  final int flowers;
  final int likes;
  final String rank;
  final String? _firstName;
  final String? _familyName;
  final String? _nativeName;
  final double? popularity;
  final String? knownForDepartment;
  final List<dynamic>? knownFor;

  const Actor({
    this.id = 0,
    required this.name,
    this.profilePath,
    String? koreanName,
    String? nationality,
    String? birthDate,
    this.birthday,
    this.placeOfBirth,
    int? age,
    String? imageUrl,
    int? flowers,
    int? likes,
    String? rank,
    String? firstName,
    String? familyName,
    String? nativeName,
    this.popularity,
    this.knownForDepartment,
    this.knownFor,
  })  : koreanName = koreanName ?? '',
        nationality = nationality ?? 'Internasional',
        birthDate = birthDate ?? (birthday ?? '-'),
        age = age ?? 0,
        _imageUrl = imageUrl ?? '',
        flowers = flowers ?? 0,
        likes = likes ?? 0,
        rank = rank ?? '-',
        // ignore: prefer_initializing_formals
        _firstName = firstName,
        // ignore: prefer_initializing_formals
        _familyName = familyName,
        // ignore: prefer_initializing_formals
        _nativeName = nativeName;

  /// Properti profile_path sesuai spesifikasi TMDB
  // ignore: non_constant_identifier_names
  String? get profile_path => profilePath;

  /// Getter alias untuk place_of_birth sesuai spesifikasi TMDB
  // ignore: non_constant_identifier_names
  String? get place_of_birth => placeOfBirth;

  /// Getter alias untuk known_for_department sesuai spesifikasi TMDB
  // ignore: non_constant_identifier_names
  String? get known_for_department => knownForDepartment;

  /// URL lengkap gambar profil TMDB (https://image.tmdb.org/t/p/w500)
  String get imageUrl {
    if (profilePath != null && profilePath!.isNotEmpty) {
      return 'https://image.tmdb.org/t/p/w500$profilePath';
    }
    return _imageUrl;
  }

  /// Factory constructor untuk memetakan response JSON dari TMDB API
  factory Actor.fromJson(Map<String, dynamic> json) {
    final String? profilePath = json['profile_path'] as String?;
    final double? pop = (json['popularity'] as num?)?.toDouble();
    final String dept = json['known_for_department'] as String? ?? 'Acting';
    final List<dynamic>? knownFor = json['known_for'] as List<dynamic>?;
    final String? birthday = json['birthday'] as String?;
    final String? placeOfBirth = json['place_of_birth'] as String?;

    String nat = dept == 'Acting' ? 'Aktor / Aktris' : dept;
    if (knownFor != null && knownFor.isNotEmpty) {
      for (final item in knownFor) {
        if (item is Map<String, dynamic>) {
          final lang = (item['original_language'] as String?)?.toLowerCase();
          if (lang == 'ko') {
            nat = 'South Korean';
            break;
          }
          if (lang == 'ja') {
            nat = 'Japanese';
            break;
          }
          if (lang == 'zh') {
            nat = 'Cina';
            break;
          }
        }
      }
    }

    return Actor(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Tanpa Nama',
      profilePath: profilePath,
      koreanName:
          json['original_name'] as String? ?? (json['name'] as String? ?? ''),
      nationality: nat,
      birthDate: birthday ?? '-',
      birthday: birthday,
      placeOfBirth: placeOfBirth,
      age: 0,
      popularity: pop,
      knownForDepartment: dept,
      knownFor: knownFor,
      flowers: pop != null ? (pop * 100).toInt() : 1250,
      likes: pop != null ? (pop * 250).toInt() : 3500,
      rank: pop != null ? '#${pop.toInt()}' : '-',
    );
  }

  String get firstName =>
      _firstName ??
      (name.contains(' ') ? name.substring(name.indexOf(' ') + 1) : name);

  String get familyName =>
      _familyName ??
      (name.contains(' ') ? name.substring(0, name.indexOf(' ')) : name);

  String get nativeName =>
      _nativeName ?? (koreanName.isNotEmpty ? koreanName : name);
}

// ==========================================
// MODEL ACTOR CREDIT (FILMOGRAFI DARI TMDB)
// ==========================================
class ActorCredit {
  final int id;
  final String title;
  final String? posterPath;
  final String? profilePath;
  final String releaseDate;
  final String character;
  final double voteAverage;
  final String mediaType;

  const ActorCredit({
    required this.id,
    required this.title,
    this.posterPath,
    this.profilePath,
    required this.releaseDate,
    required this.character,
    this.voteAverage = 0.0,
    this.mediaType = 'movie',
  });

  String get name => title;

  String get posterUrl => (posterPath != null && posterPath!.isNotEmpty)
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : '';

  String get profileUrl {
    if (profilePath != null && profilePath!.isNotEmpty) {
      return 'https://image.tmdb.org/t/p/w500$profilePath';
    }
    return posterUrl;
  }

  String get releaseYear {
    if (releaseDate.isNotEmpty && releaseDate.length >= 4) {
      return releaseDate.substring(0, 4);
    }
    return releaseDate.isNotEmpty ? releaseDate : '-';
  }

  factory ActorCredit.fromJson(Map<String, dynamic> json) {
    final String title = json['title'] as String? ??
        (json['name'] as String? ?? 'Untitled');
    final String releaseDate = json['release_date'] as String? ??
        (json['first_air_date'] as String? ?? '');
    final String character = json['character'] as String? ?? 'Pemeran';

    return ActorCredit(
      id: json['id'] as int? ?? 0,
      title: title,
      posterPath: json['poster_path'] as String?,
      profilePath: json['profile_path'] as String?,
      releaseDate: releaseDate,
      character: character.isNotEmpty ? character : 'Pemeran',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      mediaType: json['media_type'] as String? ?? 'movie',
    );
  }

  factory ActorCredit.fromCastJson(Map<String, dynamic> json) {
    final String name = json['name'] as String? ?? 'Aktor';
    final String character = json['character'] as String? ?? 'Pemeran';
    final String? profilePath = json['profile_path'] as String?;

    return ActorCredit(
      id: json['id'] as int? ?? 0,
      title: name,
      posterPath: profilePath,
      profilePath: profilePath,
      releaseDate: '',
      character: character.isNotEmpty ? character : 'Pemeran',
      voteAverage: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      mediaType: 'person',
    );
  }
}

// ==========================================
// MOCK DATA (DATA DUMMY AKTOR TERKENAL DENGAN ID TMDB RIIL)
// ==========================================
final List<Actor> dummyActors = [
  const Actor(
    id: 135622, // TMDB ID Lee Jong Suk
    name: 'Lee Jong Suk',
    koreanName: '이종석',
    nationality: 'Korea Selatan',
    birthDate: '14 September 1989',
    birthday: '1989-09-14',
    placeOfBirth: 'Suwon, Gyeonggi Province, South Korea',
    knownForDepartment: 'Acting',
    age: 35,
    imageUrl:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500&auto=format&fit=crop&q=80',
    flowers: 15420,
    likes: 48900,
    rank: '#1',
    firstName: 'Jong Suk',
    familyName: 'Lee',
    nativeName: '이종석 (Lee Jong-suk)',
  ),
  const Actor(
    id: 1251915, // TMDB ID IU (Lee Ji-eun)
    name: 'IU (Lee Ji Eun)',
    koreanName: '이지은',
    nationality: 'Korea Selatan',
    birthDate: '16 Mei 1993',
    birthday: '1993-05-16',
    placeOfBirth: 'Songjeong-dong, Seoul, South Korea',
    knownForDepartment: 'Acting',
    age: 31,
    imageUrl:
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80',
    flowers: 24890,
    likes: 78200,
    rank: '#2',
    firstName: 'Ji Eun',
    familyName: 'Lee',
    nativeName: '이지은 (Lee Ji-eun)',
  ),
  const Actor(
    id: 1253424, // TMDB ID Ji Chang Wook
    name: 'Ji Chang Wook',
    koreanName: '지창욱',
    nationality: 'Korea Selatan',
    birthDate: '5 Juli 1987',
    birthday: '1987-07-05',
    placeOfBirth: 'Anyang, Gyeonggi Province, South Korea',
    knownForDepartment: 'Acting',
    age: 37,
    imageUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop&q=80',
    flowers: 12300,
    likes: 41200,
    rank: '#3',
    firstName: 'Chang Wook',
    familyName: 'Ji',
    nativeName: '지창욱 (Ji Chang-wook)',
  ),
  const Actor(
    id: 2366838, // TMDB ID Zhao Lusi
    name: 'Zhao Lu Si',
    koreanName: '조로사 (Zhao Lusi)',
    nationality: 'Tiongkok',
    birthDate: '9 November 1998',
    birthday: '1998-11-09',
    placeOfBirth: 'Chengdu, Sichuan, China',
    knownForDepartment: 'Acting',
    age: 26,
    imageUrl:
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop&q=80',
    flowers: 18750,
    likes: 52400,
    rank: '#4',
    firstName: 'Lu Si',
    familyName: 'Zhao',
    nativeName: '赵露思 (Zhào Lùsī)',
  ),
  const Actor(
    id: 104278, // TMDB ID Park Shin Hye
    name: 'Park Shin Hye',
    koreanName: '박신혜',
    nationality: 'Korea Selatan',
    birthDate: '18 Februari 1990',
    birthday: '1990-02-18',
    placeOfBirth: 'Gwangju, South Korea',
    knownForDepartment: 'Acting',
    age: 35,
    imageUrl:
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500&auto=format&fit=crop&q=80',
    flowers: 11200,
    likes: 38600,
    rank: '#5',
    firstName: 'Shin Hye',
    familyName: 'Park',
    nativeName: '박신혜 (Park Shin-hye)',
  ),
  const Actor(
    id: 2154406, // TMDB ID Song Kang
    name: 'Song Kang',
    koreanName: '송강',
    nationality: 'Korea Selatan',
    birthDate: '23 April 1994',
    birthday: '1994-04-23',
    placeOfBirth: 'Suwon, Gyeonggi Province, South Korea',
    knownForDepartment: 'Acting',
    age: 30,
    imageUrl:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=80',
    flowers: 14100,
    likes: 45000,
    rank: '#6',
    firstName: 'Kang',
    familyName: 'Song',
    nativeName: '송강 (Song Kang)',
  ),
  const Actor(
    id: 1253360, // TMDB ID Kim Soo Hyun
    name: 'Kim Soo Hyun',
    koreanName: '김수현',
    nationality: 'Korea Selatan',
    birthDate: '16 Februari 1988',
    birthday: '1988-02-16',
    placeOfBirth: 'Seoul, South Korea',
    knownForDepartment: 'Acting',
    age: 37,
    imageUrl:
        'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=500&auto=format&fit=crop&q=80',
    flowers: 22100,
    likes: 69400,
    rank: '#7',
    firstName: 'Soo Hyun',
    familyName: 'Kim',
    nativeName: '김수현 (Kim Soo-hyun)',
  ),
  const Actor(
    id: 2026135, // TMDB ID Han So Hee
    name: 'Han So Hee',
    koreanName: '한소희',
    nationality: 'Korea Selatan',
    birthDate: '18 November 1994',
    birthday: '1994-11-18',
    placeOfBirth: 'Ulsan, South Korea',
    knownForDepartment: 'Acting',
    age: 30,
    imageUrl:
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500&auto=format&fit=crop&q=80',
    flowers: 16800,
    likes: 53100,
    rank: '#8',
    firstName: 'So Hee',
    familyName: 'Han',
    nativeName: '이소희 (Lee So-hee)',
  ),
];

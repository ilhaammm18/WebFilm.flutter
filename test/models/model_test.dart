import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_pbp/models/drama.dart';
import 'package:tugas_pbp/models/user.dart';

void main() {
  group('PBO Unit Tests - Drama Model', () {
    test('Pengujian Blueprint Constructor Objek', () {
      final drama = Drama(
        title: 'Taxi Driver',
        koreanTitle: '모범택시',
        genre: 'Action, Crime',
        rating: 8.8,
        episodes: 16,
        watchedEpisodes: 8,
        status: 'Sedang Menonton',
        priority: 'Tinggi',
        startDate: '01/01/2026',
        endDate: '',
        date: '2026',
        image: 'https://example.com/image.jpg',
        rank: '#1',
        popularity: '#10',
        watchers: '50K',
        synopsis: 'Aksi balas dendam taksi mewah.',
        aired: '2021',
        duration: '60 menit',
        contentRating: '18+',
        genresList: ['Action', 'Crime'],
        tagsList: ['Revenge'],
      );

      expect(drama.title, 'Taxi Driver');
      expect(drama.episodes, 16);
      expect(drama.watchedEpisodes, 8);
    });

    test('Pengujian Getter PBO pada Drama', () {
      final drama = Drama(
        title: 'Move To Heaven',
        koreanTitle: '무브 투 헤븐',
        genre: 'Drama, Life',
        rating: 9.1,
        episodes: 10,
        watchedEpisodes: 5,
        status: 'Sedang Menonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2021',
        image: '',
        rank: '#2',
        popularity: '#20',
        watchers: '30K',
        synopsis: 'Pembersih trauma.',
        aired: '2021',
        duration: '50 menit',
        contentRating: '15+',
        genresList: ['Life'],
        tagsList: ['Touching'],
      );

      // Menguji Getter: progressPercentage
      expect(drama.progressPercentage, 0.5);

      // Menguji Getter: progressPercentInt
      expect(drama.progressPercentInt, 50);

      // Menguji Getter: remainingEpisodes
      expect(drama.remainingEpisodes, 5);

      // Menguji Getter: isCompleted
      expect(drama.isCompleted, false);

      // Menguji Getter: isStarted
      expect(drama.isStarted, true);

      // Menguji Getter: progressSummary
      expect(drama.progressSummary, '5/10 Eps');

      // Menguji Getter: formattedRating
      expect(drama.formattedRating, '9.1');
    });

    test('Pengujian Setter PBO dengan Validasi pada Drama', () {
      final drama = Drama(
        title: 'Weak Hero',
        koreanTitle: '약한영웅',
        genre: 'Action',
        rating: 8.5,
        episodes: 8,
        watchedEpisodes: 2,
        status: 'Sedang Menonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2022',
        image: '',
        rank: '#5',
        popularity: '#50',
        watchers: '25K',
        synopsis: 'Aksi siswa cerdas.',
        aired: '2022',
        duration: '45 menit',
        contentRating: '18+',
        genresList: ['Action'],
        tagsList: ['School'],
      );

      // Setter watchedEpisodes dengan nilai melebihi batas (harus di-clamp ke total episodes: 8)
      drama.watchedEpisodes = 15;
      expect(drama.watchedEpisodes, 8);

      // Setter watchedEpisodes dengan nilai negatif (harus di-clamp ke 0)
      drama.watchedEpisodes = -5;
      expect(drama.watchedEpisodes, 0);

      // Setter rating dengan nilai melebihi 10.0
      drama.rating = 12.0;
      expect(drama.rating, 10.0);

      // Setter rating dengan nilai negatif
      drama.rating = -3.0;
      expect(drama.rating, 0.0);

      // Setter myRating dan userRating dengan validasi clamping
      expect(drama.hasUserRating, false);
      drama.myRating = 7.7;
      expect(drama.myRating, 7.7);
      expect(drama.userRating, 7.7);
      expect(drama.hasUserRating, true);

      drama.userRating = 11.5;
      expect(drama.myRating, 10.0);
      expect(drama.userRating, 10.0);

      drama.myRating = -2.0;
      expect(drama.myRating, 0.0);

      drama.myRating = null;
      expect(drama.myRating, null);
      expect(drama.hasUserRating, false);
    });

    test('Pengujian Function / Method PBO pada Drama', () {
      final drama = Drama(
        title: 'Kingdom',
        koreanTitle: '킹덤',
        genre: 'Zombie, Thriller',
        rating: 8.9,
        episodes: 6,
        watchedEpisodes: 0,
        status: 'Rencana Ditonton',
        priority: 'Tinggi',
        startDate: '',
        endDate: '',
        date: '2019',
        image: '',
        rank: '#3',
        popularity: '#15',
        watchers: '80K',
        synopsis: 'Wabah zombie era Joseon.',
        aired: '2019',
        duration: '55 menit',
        contentRating: '18+',
        genresList: ['Zombie', 'Thriller'],
        tagsList: ['Historical'],
      );

      // Uji hitungPersentaseSelesai
      expect(drama.hitungPersentaseSelesai(), 0.0);

      // Uji updateProgress
      drama.updateProgress(3);
      expect(drama.watchedEpisodes, 3);
      expect(drama.status, 'Sedang Menonton');
      expect(drama.hitungPersentaseSelesai(), 50.0);
      expect(drama.hitungSisaEpisode(), 3);

      // Uji tambahSatuEpisode
      drama.tambahSatuEpisode();
      expect(drama.watchedEpisodes, 4);
      expect(drama.hitungSisaEpisode(), 2);

      // Uji kurangiSatuEpisode
      drama.kurangiSatuEpisode();
      expect(drama.watchedEpisodes, 3);

      // Uji tandaiSelesai
      drama.tandaiSelesai();
      expect(drama.watchedEpisodes, 6);
      expect(drama.status, 'Selesai');
      expect(drama.isCompleted, true);
      expect(drama.hitungPersentaseSelesai(), 100.0);
      expect(drama.hitungSisaEpisode(), 0);

      // Uji resetProgress
      drama.resetProgress();
      expect(drama.watchedEpisodes, 0);
      expect(drama.status, 'Rencana Ditonton');
    });
  });

  group('PBO Unit Tests - User Model', () {
    test('Pengujian Blueprint, Getter, Setter, dan Validasi User', () {
      final user = User(
        username: 'ilham',
        fullName: 'Ilham Pratama',
        email: 'ilham@test.com',
      );

      expect(user.displayName, 'Ilham Pratama');
      expect(user.email, 'ilham@test.com');

      // Uji Setter dengan validasi
      user.email = 'emailbaru@test.com';
      expect(user.email, 'emailbaru@test.com');

      // Setter email tanpa @ tidak akan diterima
      user.email = 'emailsalah';
      expect(user.email, 'emailbaru@test.com');

      // Uji Method recordWatchProgress
      user.recordWatchProgress(episodes: 4, isCompleted: true);
      expect(user.totalEpisodesWatched, 4);
      expect(user.totalDramasCompleted, 1);

      // Uji Method hitungRataRataEpisodePerDrama
      expect(user.hitungRataRataEpisodePerDrama(), 4.0);

      // Uji Method updateProfile
      user.updateProfile(fullName: 'Muhammad Nur Ilham', email: 'ilham@unesa.ac.id');
      expect(user.fullName, 'Muhammad Nur Ilham');
      expect(user.email, 'ilham@unesa.ac.id');
    });
  });
}

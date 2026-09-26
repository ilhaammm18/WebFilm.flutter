import 'package:flutter/material.dart';
import '../models/drama.dart';
import 'dart:math';

class SharedData {
  static final List<String> _filmKorea = [
    "Hijack 1971", "Time to Hunt", "Officer Black Belt", "Forgotten", "Colony", 
    "Escape", "Silenced", "Shark : The Beginning", "Brave Citizen", "Veteran", 
    "The Witch", "Midnight", "Midnight Runners", "Revelations", "Tunnel"
  ];
  
  static final List<String> _dramaKorea = [
    "Island", "Taxi Driver", "The First Responders", "Move To Heaven", "The Glory", 
    "My Name", "Weak Hero", "Kingdom", "Duty after school", "The Guest"
  ];

  static final List<String> _dramaJepang = [
    "Litre of Tears (Ichi Rittoru no Namida)", "Alice in Borderland", "Great Teacher Onizuka (GTO)", 
    "Nodame Cantabile", "Hana Yori Dango", "Tokyo Love Story", "Midnight Diner", 
    "Crow's Zero / Bossko", "Pahlawanku (My Boss My Hero)", "Orange Days"
  ];

  static final List<String> _filmJepang = [
    "Seven Samurai (1954)", "Tokyo Story (1953)", "Rashomon (1950)", "Spirited Away (2001)", 
    "Battle Royale (2000)", "Perfect Blue (1997)", "Nobody Knows (2004)", "Drive My Car (2021)", 
    "Tampopo (1985)", "Shoplifters (2018)"
  ];

  static List<Drama> _generateData() {
    List<Drama> generatedList = [];
    Random random = Random(42);

    void addToList(List<String> titles, String genreBase, bool isFilm) {
      for (var title in titles) {
        double rating = 7.5 + (random.nextDouble() * 2.4); 
        int episodes = isFilm ? 1 : 8 + random.nextInt(12); 
        
        // MENGACAK STATUS (Ditambahkan 'Belum Ditonton' agar ikon + muncul)
        List<String> statuses = ['Selesai', 'Sedang Menonton', 'Rencana Ditonton', 'Belum Ditonton', 'Belum Ditonton'];
        String randomStatus = statuses[random.nextInt(statuses.length)];
        
        String safeSeed = title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

        generatedList.add(Drama(
          title: title,
          koreanTitle: title, 
          genre: genreBase,
          rating: double.parse(rating.toStringAsFixed(1)),
          episodes: episodes,
          watchedEpisodes: randomStatus == 'Selesai' ? episodes : (randomStatus == 'Belum Ditonton' ? 0 : (isFilm ? 0 : random.nextInt(episodes))),
          status: randomStatus,
          priority: 'Sedang',
          startDate: '',
          endDate: '',
          date: '10/2026',
          image: 'https://picsum.photos/seed/$safeSeed/500/750',
          rank: '#${random.nextInt(500) + 1}',
          popularity: '#${random.nextInt(1000) + 1}',
          watchers: '${(10 + random.nextDouble() * 90).toStringAsFixed(1)}K',
          synopsis: 'Ini adalah sinopsis untuk $title. Sebuah kisah menarik yang penuh dengan emosi dan ketegangan.',
          aired: '2020 - 2026',
          duration: isFilm ? '2 jam 10 menit' : '60 menit',
          contentRating: '15+',
          genresList: ['Action', 'Thriller', 'Drama'],
          tagsList: ['Popular', 'Must Watch'],
        ));
      }
    }

    addToList(_filmKorea, 'Film Korea', true);
    addToList(_dramaKorea, 'Drama Korea', false);
    addToList(_dramaJepang, 'Drama Jepang', false);
    addToList(_filmJepang, 'Film Jepang', true);

    return generatedList;
  }

  static final ValueNotifier<List<Drama>> dramaListNotifier = ValueNotifier<List<Drama>>(_generateData());
}
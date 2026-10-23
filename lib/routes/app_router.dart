import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/actor.dart';
import '../models/drama.dart';
import '../services/api_service.dart';
import '../screens/splash_screen.dart';
import '../screens/welcome_login_page.dart';
import '../screens/complete_profile_page.dart';
import '../screens/main_navigation.dart';
import '../screens/settings_page.dart';
import '../screens/edit_profile_page.dart';
import '../screens/detail_page.dart';
import '../screens/actor_detail_page.dart';
import '../screens/search_page.dart';
import '../screens/release_schedule_page.dart';
import '../screens/friends_page.dart';
import '../screens/user_profile_detail_page.dart';
import '../screens/about_app_page.dart';
import '../screens/customer_service_page.dart';
import '../screens/see_all_page.dart';
import '../screens/genre_detail_page.dart';
import '../screens/decade_explore_page.dart';

export 'package:go_router/go_router.dart' hide GoRouterHelper;

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Definisi rute aplikasi menggunakan GoRouter
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      bool isLoggedIn = false;
      try {
        isLoggedIn = Supabase.instance.client.auth.currentSession != null;
      } catch (_) {
        isLoggedIn = false;
      }

      final location = state.matchedLocation;
      final isLoggingIn = location == '/login';
      final isSplash = location == '/';

      if (!isLoggedIn) {
        // Jika pengguna belum login (cek via Supabase Auth), arahkan ke /login.
        // Halaman splash (/) dan halaman login (/login) diizinkan diakses tanpa login.
        if (isSplash || isLoggingIn) {
          return null;
        }
        return '/login';
      }

      // Jika sudah login dan berada di / atau /login, arahkan ke /home.
      if (isSplash || isLoggingIn) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/splash',
        redirect: (_, _) => '/',
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const WelcomeLoginPage(),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfilePage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainNavigation(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
        routes: [
          GoRoute(
            path: 'edit-profile',
            builder: (context, state) => const EditProfilePage(),
          ),
        ],
      ),
      GoRoute(
        path: '/edit-profile',
        redirect: (_, _) => '/settings/edit-profile',
      ),
      GoRoute(
        path: '/movie/:id',
        builder: (context, state) {
          final idStr = state.pathParameters['id'] ?? '0';
          final parsedId = int.tryParse(idStr) ?? 0;

          Drama? drama;
          String? heroTag;
          String? posterUrl;
          ApiService? apiService;

          if (state.extra is Drama) {
            drama = state.extra as Drama;
          } else if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            drama = map['drama'] as Drama? ?? map['movie'] as Drama?;
            heroTag = map['heroTag'] as String?;
            posterUrl = map['posterUrl'] as String?;
            apiService = map['apiService'] as ApiService?;
          }

          final effectiveMovieId = parsedId > 0 ? parsedId : (drama?.id ?? 0);

          return DetailPage(
            movieId: effectiveMovieId > 0 ? effectiveMovieId : (drama == null ? 0 : null),
            drama: drama,
            heroTag: heroTag,
            posterUrl: posterUrl,
            apiService: apiService,
          );
        },
      ),
      GoRoute(
        path: '/actor/:id',
        builder: (context, state) {
          final idStr = state.pathParameters['id'] ?? '0';
          final parsedId = int.tryParse(idStr) ?? 0;

          Actor? actor;
          String? heroTag;
          String? imageUrl;
          ApiService? apiService;

          if (state.extra is Actor) {
            actor = state.extra as Actor;
          } else if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            actor = map['actor'] as Actor?;
            heroTag = map['heroTag'] as String?;
            imageUrl = map['imageUrl'] as String?;
            apiService = map['apiService'] as ApiService?;
          }

          actor ??= Actor(id: parsedId, name: '');

          return ActorDetailPage(
            actor,
            heroTag: heroTag,
            imageUrl: imageUrl,
            apiService: apiService,
          );
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchPage(),
      ),
      GoRoute(
        path: '/schedule',
        builder: (context, state) => const ReleaseSchedulePage(),
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendsPage(),
      ),
      GoRoute(
        path: '/user/:id',
        builder: (context, state) {
          final userId = state.pathParameters['id'] ?? '';
          final initialProfile = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null;
          return UserProfileDetailPage(
            userId: userId,
            initialProfile: initialProfile,
          );
        },
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutAppPage(),
      ),
      GoRoute(
        path: '/customer-service',
        builder: (context, state) => const CustomerServicePage(),
      ),
      GoRoute(
        path: '/see-all',
        builder: (context, state) {
          String title = state.uri.queryParameters['title'] ?? 'Semua Film';
          List<Drama> dramaList = const [];

          if (state.extra is List<Drama>) {
            dramaList = state.extra as List<Drama>;
          } else if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            title = map['title'] as String? ?? title;
            dramaList = (map['dramaList'] as List<Drama>?) ?? const [];
          }

          return SeeAllPage(
            title: title,
            dramaList: dramaList,
          );
        },
      ),
      GoRoute(
        path: '/credits',
        builder: (context, state) {
          String title = state.uri.queryParameters['title'] ?? 'Kredit Lengkap';
          List<dynamic>? cast;
          List<dynamic>? crew;
          List<dynamic>? items;
          ApiService? apiService;

          if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            title = map['title'] as String? ?? title;
            cast = map['cast'] as List<dynamic>?;
            crew = map['crew'] as List<dynamic>?;
            items = map['items'] as List<dynamic>?;
            apiService = map['apiService'] as ApiService?;
          }

          return FullCreditsPage(
            title: title,
            cast: cast,
            crew: crew,
            items: items,
            apiService: apiService,
          );
        },
      ),
      GoRoute(
        path: '/genre/:id',
        builder: (context, state) {
          final idStr = state.pathParameters['id'] ?? '0';
          final genreId = int.tryParse(idStr) ?? 0;
          String genreName = state.uri.queryParameters['name'] ?? '';
          ApiService? apiService;

          if (state.extra is String) {
            genreName = state.extra as String;
          } else if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            genreName = map['genreName'] as String? ?? genreName;
            apiService = map['apiService'] as ApiService?;
          }

          if (genreName.isEmpty) {
            genreName = 'Genre';
          }

          return GenreDetailPage(
            genreId: genreId,
            genreName: genreName,
            apiService: apiService,
          );
        },
      ),
      GoRoute(
        path: '/decade/:decade',
        builder: (context, state) {
          final decade = state.pathParameters['decade'] ?? '2026';
          String? startDate = state.uri.queryParameters['start_date'];
          String? endDate = state.uri.queryParameters['end_date'];
          int? year = int.tryParse(state.uri.queryParameters['year'] ?? '');
          ApiService? apiService;

          if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            startDate ??= map['startDate'] as String?;
            endDate ??= map['endDate'] as String?;
            year ??= map['year'] as int?;
            apiService = map['apiService'] as ApiService?;
          }

          year ??= int.tryParse(decade);

          return DecadeExplorePage(
            decade: decade,
            startDate: startDate,
            endDate: endDate,
            year: year,
            apiService: apiService,
          );
        },
      ),
      GoRoute(
        path: '/year/:year',
        builder: (context, state) {
          final yearStr = state.pathParameters['year'] ?? '2026';
          final year = int.tryParse(yearStr);
          ApiService? apiService;

          if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            apiService = map['apiService'] as ApiService?;
          }

          return DecadeExplorePage(
            decade: yearStr,
            year: year,
            apiService: apiService,
          );
        },
      ),
    ],
  );

  /// Helper untuk meresolusi widget berdasarkan path ketika diuji pada widget test tanpa GoRouter
  static Widget? buildWidgetForLocation(String location, Object? extra) {
    final uri = Uri.parse(location);
    final path = uri.path;

    if (path == '/' || path == '/splash') {
      return const SplashScreen();
    } else if (path == '/login') {
      return const WelcomeLoginPage();
    } else if (path == '/complete-profile') {
      return const CompleteProfilePage();
    } else if (path == '/home') {
      return const MainNavigation();
    } else if (path == '/settings') {
      return const SettingsPage();
    } else if (path == '/settings/edit-profile' || path == '/edit-profile') {
      return const EditProfilePage();
    } else if (path.startsWith('/movie/')) {
      final idStr = path.replaceFirst('/movie/', '');
      final parsedId = int.tryParse(idStr) ?? 0;
      Drama? drama;
      String? heroTag;
      String? posterUrl;
      ApiService? apiService;
      if (extra is Drama) {
        drama = extra;
      } else if (extra is Map<String, dynamic>) {
        drama = extra['drama'] as Drama? ?? extra['movie'] as Drama?;
        heroTag = extra['heroTag'] as String?;
        posterUrl = extra['posterUrl'] as String?;
        apiService = extra['apiService'] as ApiService?;
      }
      return DetailPage(
        movieId: parsedId > 0 ? parsedId : (drama?.id ?? 0),
        drama: drama,
        heroTag: heroTag,
        posterUrl: posterUrl,
        apiService: apiService,
      );
    } else if (path.startsWith('/actor/')) {
      final idStr = path.replaceFirst('/actor/', '');
      final parsedId = int.tryParse(idStr) ?? 0;
      Actor? actor;
      String? heroTag;
      String? imageUrl;
      ApiService? apiService;
      if (extra is Actor) {
        actor = extra;
      } else if (extra is Map<String, dynamic>) {
        actor = extra['actor'] as Actor?;
        heroTag = extra['heroTag'] as String?;
        imageUrl = extra['imageUrl'] as String?;
        apiService = extra['apiService'] as ApiService?;
      }
      actor ??= Actor(id: parsedId, name: '');
      return ActorDetailPage(
        actor,
        heroTag: heroTag,
        imageUrl: imageUrl,
        apiService: apiService,
      );
    } else if (path == '/search') {
      return const SearchPage();
    } else if (path == '/schedule') {
      return const ReleaseSchedulePage();
    } else if (path == '/friends') {
      return const FriendsPage();
    } else if (path.startsWith('/user/')) {
      final userId = path.replaceFirst('/user/', '');
      final initialProfile = extra is Map<String, dynamic> ? extra : null;
      return UserProfileDetailPage(
        userId: userId,
        initialProfile: initialProfile,
      );
    } else if (path == '/about') {
      return const AboutAppPage();
    } else if (path == '/customer-service') {
      return const CustomerServicePage();
    } else if (path == '/see-all') {
      String title = uri.queryParameters['title'] ?? 'Semua Film';
      List<Drama> dramaList = const [];
      if (extra is List<Drama>) {
        dramaList = extra;
      } else if (extra is Map<String, dynamic>) {
        title = extra['title'] as String? ?? title;
        dramaList = (extra['dramaList'] as List<Drama>?) ?? const [];
      }
      return SeeAllPage(title: title, dramaList: dramaList);
    } else if (path == '/credits') {
      String title = uri.queryParameters['title'] ?? 'Kredit Lengkap';
      List<dynamic>? cast;
      List<dynamic>? crew;
      List<dynamic>? items;
      ApiService? apiService;
      if (extra is Map<String, dynamic>) {
        title = extra['title'] as String? ?? title;
        cast = extra['cast'] as List<dynamic>?;
        crew = extra['crew'] as List<dynamic>?;
        items = extra['items'] as List<dynamic>?;
        apiService = extra['apiService'] as ApiService?;
      }
      return FullCreditsPage(
        title: title,
        cast: cast,
        crew: crew,
        items: items,
        apiService: apiService,
      );
    } else if (path.startsWith('/genre/')) {
      final idStr = path.replaceFirst('/genre/', '');
      final genreId = int.tryParse(idStr) ?? 0;
      String genreName = uri.queryParameters['name'] ?? '';
      if (extra is String) {
        genreName = extra;
      } else if (extra is Map<String, dynamic>) {
        genreName = extra['genreName'] as String? ?? genreName;
      }
      return GenreDetailPage(
        genreId: genreId,
        genreName: genreName.isNotEmpty ? genreName : 'Genre',
      );
    } else if (path.startsWith('/year/')) {
      final yearStr = path.replaceFirst('/year/', '');
      final year = int.tryParse(yearStr);
      ApiService? apiService;
      if (extra is Map<String, dynamic>) {
        apiService = extra['apiService'] as ApiService?;
      }
      return DecadeExplorePage(
        decade: yearStr,
        year: year,
        apiService: apiService,
      );
    } else if (path.startsWith('/decade/')) {
      final decade = path.replaceFirst('/decade/', '');
      final year = int.tryParse(decade);
      String? startDate = uri.queryParameters['start_date'];
      String? endDate = uri.queryParameters['end_date'];
      ApiService? apiService;
      if (extra is Map<String, dynamic>) {
        startDate ??= extra['startDate'] as String?;
        endDate ??= extra['endDate'] as String?;
        apiService = extra['apiService'] as ApiService?;
      }
      return DecadeExplorePage(
        decade: decade.isNotEmpty ? decade : '2026',
        startDate: startDate,
        endDate: endDate,
        year: year,
        apiService: apiService,
      );
    }

    return null;
  }
}

/// Instance GoRouter global untuk aplikasi
final GoRouter appRouter = AppRouter.router;

/// Ekstensi navigasi context yang menggabungkan GoRouter dengan graceful fallback untuk pengujian widget
extension AppRouterHelper on BuildContext {
  /// Menggantikan navigasi Navigator.pushReplacement atau router.go
  void go(String location, {Object? extra}) {
    final router = GoRouter.maybeOf(this);
    if (router != null) {
      router.go(location, extra: extra);
    } else {
      final widget = AppRouter.buildWidgetForLocation(location, extra);
      if (widget != null) {
        Navigator.of(this).pushReplacement(
          MaterialPageRoute(builder: (_) => widget),
        );
      }
    }
  }

  /// Menggantikan navigasi Navigator.push atau router.push
  Future<T?> push<T extends Object?>(String location, {Object? extra}) {
    final router = GoRouter.maybeOf(this);
    if (router != null) {
      return router.push<T>(location, extra: extra);
    } else {
      final widget = AppRouter.buildWidgetForLocation(location, extra);
      if (widget != null) {
        return Navigator.of(this).push<T>(
          MaterialPageRoute(builder: (_) => widget),
        );
      }
      return Future<T?>.value(null);
    }
  }

  /// Menggantikan Navigator.pop atau router.pop
  void pop<T extends Object?>([T? result]) {
    final router = GoRouter.maybeOf(this);
    if (router != null && router.canPop()) {
      router.pop<T>(result);
    } else {
      Navigator.of(this).pop<T>(result);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../routes/app_router.dart';
import '../data/shared_data.dart';
import 'complete_profile_page.dart';
import 'main_navigation.dart';

/// Halaman WelcomeLoginPage: menggabungkan estetika background poster grid cinematic
/// dengan form Login / Register modern berdesain curved bottom sheet.
class WelcomeLoginPage extends StatefulWidget {
  final SupabaseClient? supabaseClient;
  final Widget? nextScreen;

  const WelcomeLoginPage({
    super.key,
    this.supabaseClient,
    this.nextScreen,
  });

  @override
  State<WelcomeLoginPage> createState() => _WelcomeLoginPageState();
}

class _WelcomeLoginPageState extends State<WelcomeLoginPage> {
  // Mode autentikasi aktif: true = Login, false = Register
  bool _isLogin = true;
  bool get isLoginMode => _isLogin;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  SupabaseClient get _supabase =>
      widget.supabaseClient ?? Supabase.instance.client;

  // 3 Kolom poster film untuk latar belakang masonry grid
  static const List<String> _col1 = [
    'https://image.tmdb.org/t/p/w500/kyeqWdyUXW608qlYkRqosgbbJyK.jpg', // Avatar
    'https://image.tmdb.org/t/p/w500/74xTEgt7R36Fpooo50r9T25onhq.jpg', // The Batman
    'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg', // Interstellar
    'https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg', // The Dark Knight
  ];

  static const List<String> _col2 = [
    'https://image.tmdb.org/t/p/w500/edv5CZvWj09upOsy2Y6IwDhK8bt.jpg', // Inception
    'https://image.tmdb.org/t/p/w500/8Vt6mWEReuy4Of61Lnj5Xj704m8.jpg', // Spider-Man
    'https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg', // Oppenheimer
    'https://image.tmdb.org/t/p/w500/rCzpDGLbOoPwLjy3OAm5NUPOTrC.jpg', // Lord of the Rings
  ];

  static const List<String> _col3 = [
    'https://image.tmdb.org/t/p/w500/or06FN3Dka5tukK1e9sl16pB3iy.jpg', // Avengers Endgame
    'https://image.tmdb.org/t/p/w500/d5NXSklXo0qyIYkgV94XAgMIckC.jpg', // Dune
    'https://image.tmdb.org/t/p/w500/39wmItIWsg5sZMyRUHLkWBcuVCM.jpg', // Spirited Away
    'https://image.tmdb.org/t/p/w500/6oom5QYQ2yQTMJIbnvbkBL9cDK6.jpg', // The Matrix
  ];

  static const Color _primaryBlue = Color(0xFF008CFF);

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _emailFocusNode.addListener(_onFieldChanged);
    _passwordFocusNode.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _emailFocusNode.removeListener(_onFieldChanged);
    _passwordFocusNode.removeListener(_onFieldChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Logika autentikasi Supabase Auth
  Future<void> _handleAuth() async {
    if (_isLoading) return;

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan password tidak boleh kosong'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // Tab Login: signInWithPassword
        final AuthResponse response = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (response.user != null) {
          if (!mounted) return;
          final user = response.user!;
          final metadata = user.userMetadata ?? {};
          final fullName = (metadata['full_name'] as String? ?? '').trim();
          final username = (metadata['username'] as String? ?? '').trim();

          bool hasProfile = fullName.isNotEmpty && username.isNotEmpty;
          if (!hasProfile) {
            try {
              final profile = await _supabase
                  .from('profiles')
                  .select('full_name, username')
                  .eq('id', user.id)
                  .maybeSingle();
              if (profile != null) {
                final dbName = (profile['full_name'] as String? ?? '').trim();
                final dbUser = (profile['username'] as String? ?? '').trim();
                if (dbName.isNotEmpty && dbUser.isNotEmpty) {
                  hasProfile = true;
                }
              }
            } catch (_) {}
          }

          if (!mounted) return;

          if (hasProfile) {
            _navigateToNext(user.id);
          } else {
            if (widget.nextScreen != null) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => CompleteProfilePage(
                    supabaseClient: _supabase,
                    nextScreen: widget.nextScreen,
                  ),
                ),
              );
            } else {
              context.go('/complete-profile');
            }
          }
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Login gagal! Email belum terdaftar atau password salah. Silakan buat akun di menu Register.',
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Tab Register: signUp
        final AuthResponse response = await _supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (response.user != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Registrasi berhasil! Silakan lengkapi profil Anda.',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          if (widget.nextScreen != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => CompleteProfilePage(
                  supabaseClient: _supabase,
                  nextScreen: widget.nextScreen,
                ),
              ),
            );
          } else {
            context.go('/complete-profile');
          }
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      if (_isLogin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Login gagal! Email belum terdaftar atau password salah. Silakan buat akun di menu Register.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message.isNotEmpty
                  ? 'Registrasi gagal: ${e.message}'
                  : 'Registrasi gagal. Silakan coba lagi.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $error'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToNext([dynamic userId]) {
    // Muat data watchlist user yang aktif dari Supabase
    SharedData.fetchUserWatchlist(client: _supabase);
    // SharedData.fetchUserRiwayat(client: _supabase); // Riwayat dinonaktifkan
    globalNavIndex.value = 0;
    if (widget.nextScreen != null) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              widget.nextScreen!,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBg = Color(0xFF15171E);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color formSurfaceColor = Theme.of(context).colorScheme.surface;
    final Color inputFieldFillColor =
        isDark ? (Colors.grey[800] ?? const Color(0xFF2C2C2C)) : (Colors.grey[100] ?? const Color(0xFFF5F5F5));
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    const Color hintColor = Colors.grey;
    final Color borderColor = isDark ? (Colors.grey[700] ?? const Color(0xFF424242)) : Colors.grey.shade200;

    final bool isEmailActive =
        _emailFocusNode.hasFocus || _emailController.text.isNotEmpty;
    final Color emailIconColor = isEmailActive ? _primaryBlue : Colors.grey;

    final bool isPasswordActive =
        _passwordFocusNode.hasFocus || _passwordController.text.isNotEmpty;
    final Color passwordIconColor =
        isPasswordActive ? _primaryBlue : Colors.grey;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: formSurfaceColor,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: darkBg,
        body: Stack(
          children: [
            // ========================================================
            // 1. LATAR BELAKANG: MASONRY POSTER GRID (LAYER BAWAH)
            // ========================================================
            Positioned.fill(
              child: ClipRect(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildPosterColumn(_col1, offset: 0),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPosterColumn(_col2, offset: -50),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPosterColumn(_col3, offset: -15),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ========================================================
            // 2. GRADIENT OVERLAY GELAP (LAYER TENGAH)
            // ========================================================
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.35, 0.65, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.65),
                      darkBg.withValues(alpha: 0.90),
                      darkBg,
                    ],
                  ),
                ),
              ),
            ),

            // ========================================================
            // 3. KONTEN DEPAN: JUDUL DI TENGAH & BOTTOM SHEET FORM
            // ========================================================
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Teks Judul & Subtitle di bagian tengah layar
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Selamat Datang di MyWatchList',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                                fontFamily: 'Roboto',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'Jelajahi ribuan film dan buat daftar tontonan impianmu.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.80),
                                  fontSize: 14,
                                  height: 1.45,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ========================================================
                  // 4. FORM LOGIN (LAYER ATAS / DEPAN DI BAGIAN PALING BAWAH)
                  // ========================================================
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: formSurfaceColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32.0),
                          topRight: Radius.circular(32.0),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 20.0,
                            offset: Offset(0, -6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 28.0),
                      child: SafeArea(
                        top: false,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // a. Tombol Toggle (Login / Register) berbentuk pil
                              _buildPillToggle(isDark),
                              const SizedBox(height: 20),

                              // b. TextFormField untuk Email (dengan ikon surat dinamis)
                              TextFormField(
                                key: const Key('email_field'),
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.mail_outline_rounded,
                                    color: emailIconColor,
                                  ),
                                  hintText: 'Email',
                                  hintStyle: const TextStyle(
                                    color: hintColor,
                                    fontSize: 14,
                                  ),
                                  filled: true,
                                  fillColor: inputFieldFillColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: borderColor,
                                      width: 1.0,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: _primaryBlue,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // c. TextFormField untuk Password (ikon gembok & mata dinamis)
                              TextFormField(
                                key: const Key('password_field'),
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                obscureText: _obscurePassword,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    color: passwordIconColor,
                                  ),
                                  suffixIcon: IconButton(
                                    key: const Key('toggle_password_visibility'),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Theme.of(context).iconTheme.color ?? Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  hintText: 'Password',
                                  hintStyle: const TextStyle(
                                    color: hintColor,
                                    fontSize: 14,
                                  ),
                                  filled: true,
                                  fillColor: inputFieldFillColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: borderColor,
                                      width: 1.0,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: _primaryBlue,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // e. Tombol utama (ElevatedButton) warna biru gelap bertuliskan 'Login'
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  key: const Key('login_button'),
                                  onPressed: _isLoading ? null : _handleAuth,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          _isLogin ? 'Login' : 'Register',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun tombol toggle berbentuk pil untuk Login / Register
  Widget _buildPillToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          // Tab Login
          Expanded(
            child: GestureDetector(
              key: const Key('toggle_login'),
              onTap: () {
                if (_isLoading) return;
                if (!_isLogin) {
                  setState(() {
                    _isLogin = true;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isLogin ? _primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: _isLogin
                      ? [
                          BoxShadow(
                            color: _primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: _isLogin
                          ? Colors.white
                          : (isDark ? Colors.grey[400] : Colors.grey.shade600),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Tab Register
          Expanded(
            child: GestureDetector(
              key: const Key('toggle_register'),
              onTap: () {
                if (_isLoading) return;
                if (_isLogin) {
                  setState(() {
                    _isLogin = false;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isLogin ? _primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: !_isLogin
                      ? [
                          BoxShadow(
                            color: _primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Register',
                    style: TextStyle(
                      color: !_isLogin
                          ? Colors.white
                          : (isDark ? Colors.grey[400] : Colors.grey.shade600),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun satu kolom poster film
  Widget _buildPosterColumn(List<String> posters, {required double offset}) {
    return Transform.translate(
      offset: Offset(0, offset),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: posters.map((url) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF222634),
                      child: const Center(
                        child: Icon(
                          Icons.movie_outlined,
                          color: Colors.white24,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
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
  bool _isGoogleLoading = false;
  bool _isCheckingProfile = false;
  StreamSubscription<AuthState>? _authSubscription;

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

    // Dengarkan perubahan status autentikasi (termasuk callback Google Sign-In)
    try {
      _authSubscription = _supabase.auth.onAuthStateChange.listen((authState) {
        if (!mounted || _isLoading || _isCheckingProfile) return;
        if (authState.event == AuthChangeEvent.signedIn &&
            authState.session?.user != null) {
          _checkProfileAndRedirect(authState.session!.user, isOAuth: true);
        }
      });

      // Jika pengguna kembali dari redirect OAuth Google dengan sesi aktif di halaman ini,
      // periksa profil database dan arahkan sesuai status pendaftaran profilnya.
      final existingUser = _supabase.auth.currentUser;
      if (existingUser != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _checkProfileAndRedirect(existingUser, isOAuth: true);
          }
        });
      }
    } catch (_) {}
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
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

  // Logika autentikasi Supabase Auth (Email & Password)
  Future<void> _handleAuth() async {
    if (_isLoading || _isGoogleLoading) return;

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
          SharedData.markEmailAsManualAccount(email);
          if (!mounted) return;
          await _checkProfileAndRedirect(response.user!, isOAuth: false);
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
          SharedData.markEmailAsManualAccount(email);
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

      // Periksa apakah email tersebut terdaftar melalui Google Sign-In
      final bool isGoogleAccount = await SharedData.isGoogleAccountEmail(
        email,
        client: _supabase,
        authError: e,
      );
      if (!mounted) return;

      if (isGoogleAccount) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email ini sudah terdaftar melalui Google. Mengalihkan ke login Google...',
            ),
            backgroundColor: _primaryBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _handleGoogleSignIn();
        return;
      }

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

  /// Mengecek apakah record profil pengguna dengan id atau email sudah ada di tabel `profiles` Supabase.
  /// - Jika belum ada, arahkan ke halaman pengisian data diri (/complete-profile).
  /// - Jika sudah ada, arahkan langsung ke halaman utama (/home).
  Future<void> _checkProfileAndRedirect(
    User user, {
    bool isOAuth = false,
  }) async {
    if (_isCheckingProfile || !mounted) return;
    _isCheckingProfile = true;

    try {
      SharedData.recordAuthProviderFromUser(
        email: user.email,
        appMetadata: user.appMetadata,
        userMetadata: user.userMetadata,
      );
      final bool hasProfile = await SharedData.isUserProfileRegistered(
        client: _supabase,
        userId: user.id,
        email: user.email,
        userMetadata: user.userMetadata,
        allowMetadataFallback: !isOAuth,
      );

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
    } finally {
      _isCheckingProfile = false;
    }
  }

  /// Logika Autentikasi Google OAuth menggunakan Supabase
  Future<void> _handleGoogleSignIn() async {
    if (_isLoading || _isGoogleLoading) return;

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? Uri.base.origin : null,
      );

      // Jika sesi langsung tersedia (misal pada alur non-redirect / popup / pengujian),
      // cek apakah profil pengguna sudah terdaftar di tabel profiles Supabase.
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null && mounted) {
        await _checkProfileAndRedirect(currentUser, isOAuth: true);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message.isNotEmpty
                ? 'Gagal masuk dengan Google: ${e.message}'
                : 'Gagal masuk dengan Google. Silakan coba lagi.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghubungkan akun Google: $error'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  /// Dialog Lupa Kata Sandi (Forgot Password) menggunakan supabase.auth.resetPasswordForEmail()
  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    bool isSending = false;
    String? errorMessage;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF1E212B) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final Color subTextColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final Color fieldBg =
        isDark ? const Color(0xFF262A37) : Colors.grey.shade100;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: _primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lupa Kata Sandi?',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Masukkan alamat email yang terdaftar pada akun MyWatchList Anda. Kami akan mengirimkan tautan untuk mengatur ulang kata sandi.',
                      style: TextStyle(
                        fontSize: 13,
                        color: subTextColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('reset_password_email_field'),
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Alamat Email',
                        hintText: 'nama@email.com',
                        labelStyle: TextStyle(color: subTextColor),
                        hintStyle: TextStyle(
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade400,
                        ),
                        prefixIcon: const Icon(
                          Icons.mail_outline_rounded,
                          color: _primaryBlue,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: fieldBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: _primaryBlue,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Batal',
                    style: TextStyle(color: subTextColor),
                  ),
                ),
                ElevatedButton(
                  key: const Key('send_reset_password_button'),
                  onPressed: isSending
                      ? null
                      : () async {
                          final resetEmail =
                              resetEmailController.text.trim();
                          if (resetEmail.isEmpty) {
                            setDialogState(() {
                              errorMessage =
                                  'Masukkan alamat email Anda terlebih dahulu.';
                            });
                            return;
                          }
                          if (!resetEmail.contains('@')) {
                            setDialogState(() {
                              errorMessage =
                                  'Format alamat email tidak valid.';
                            });
                            return;
                          }

                          setDialogState(() {
                            isSending = true;
                            errorMessage = null;
                          });

                          try {
                            await _supabase.auth.resetPasswordForEmail(
                              resetEmail,
                              redirectTo: kIsWeb ? Uri.base.origin : null,
                            );

                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Tautan pemulihan kata sandi telah dikirim ke $resetEmail. Silakan periksa email Anda.',
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } on AuthException catch (e) {
                            setDialogState(() {
                              isSending = false;
                              errorMessage = e.message.isNotEmpty
                                  ? e.message
                                  : 'Gagal mengirim email pemulihan kata sandi.';
                            });
                          } catch (e) {
                            setDialogState(() {
                              isSending = false;
                              errorMessage =
                                  'Gagal mengirim email pemulihan: $e';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Kirim Tautan Reset'),
                ),
              ],
            );
          },
        );
      },
    );
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
    final Color inputFieldFillColor = isDark
        ? (Colors.grey[800] ?? const Color(0xFF2C2C2C))
        : (Colors.grey[100] ?? const Color(0xFFF5F5F5));
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    const Color hintColor = Colors.grey;
    final Color borderColor = isDark
        ? (Colors.grey[700] ?? const Color(0xFF424242))
        : Colors.grey.shade200;

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
                      padding:
                          const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 28.0),
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
                                    key: const Key(
                                        'toggle_password_visibility'),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color:
                                          Theme.of(context).iconTheme.color ??
                                              Colors.grey,
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

                              // d. Tautan Lupa Kata Sandi di dekat kolom password
                              if (_isLogin) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    key: const Key('forgot_password_button'),
                                    onPressed:
                                        (_isLoading || _isGoogleLoading)
                                            ? null
                                            : _showForgotPasswordDialog,
                                    style: TextButton.styleFrom(
                                      foregroundColor: _primaryBlue,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Lupa kata sandi?',
                                      style: TextStyle(
                                        color: _primaryBlue,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ] else
                                const SizedBox(height: 24),

                              // e. Tombol utama (ElevatedButton) warna biru bertuliskan 'Login' / 'Register'
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  key: const Key('login_button'),
                                  onPressed: (_isLoading || _isGoogleLoading)
                                      ? null
                                      : _handleAuth,
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

                              const SizedBox(height: 18),

                              // f. Pemisah "Atau lanjutkan dengan"
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: borderColor,
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(
                                      'Atau',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: borderColor,
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // g. Tombol Google Sign-In dengan ikon logo Google
                              SizedBox(
                                height: 50,
                                child: OutlinedButton(
                                  key: const Key('google_sign_in_button'),
                                  onPressed: (_isLoading || _isGoogleLoading)
                                      ? null
                                      : _handleGoogleSignIn,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? (Colors.grey[850] ??
                                            const Color(0xFF22252E))
                                        : Colors.white,
                                    foregroundColor: textColor,
                                    side: BorderSide(
                                      color: borderColor,
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isGoogleLoading
                                      ? SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.3,
                                            color: textColor,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const _GoogleLogoIcon(size: 20),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Lanjutkan dengan Google',
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ],
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
                if (_isLoading || _isGoogleLoading) return;
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
                if (_isLoading || _isGoogleLoading) return;
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

/// Widget ikon vektor logo Google resmi 4-warna (Biru, Merah, Kuning, Hijau)
class _GoogleLogoIcon extends StatelessWidget {
  final double size;

  const _GoogleLogoIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.width * 0.19;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // 1. Busur Merah (Atas)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      rect,
      -math.pi * 0.78,
      math.pi * 0.56,
      false,
      paint,
    );

    // 2. Busur Kuning (Kiri)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      rect,
      math.pi * 0.78,
      math.pi * 0.44,
      false,
      paint,
    );

    // 3. Busur Hijau (Bawah)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      rect,
      math.pi * 0.22,
      math.pi * 0.56,
      false,
      paint,
    );

    // 4. Busur Biru (Kanan Bawah) + Palang Horizontal Tengah "G"
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      rect,
      -math.pi * 0.04,
      math.pi * 0.28,
      false,
      paint,
    );

    final Paint barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - strokeWidth * 0.48,
        radius + strokeWidth * 0.45,
        strokeWidth * 0.96,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

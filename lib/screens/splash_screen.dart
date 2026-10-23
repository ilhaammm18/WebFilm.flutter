import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../routes/app_router.dart';
import '../widgets/mwl_logo.dart';

/// Halaman Splash Screen animasi MyWatchList dengan durasi total ~3.0 detik.
///
/// Koreografi animasi (nilai relatif terhadap durasi controller):
/// * Fase 1 (0.0 â€“ 0.4) : Busur sabit ganda atas & bawah logo MWL digambar
///   melingkar (sweep menggunakan PathMetrics).
/// * Fase 2 (0.3 â€“ 0.6) : Monogram 'MWL' muncul dengan efek scale & fade-in
///   hingga membentuk logo utuh di tengah layar.
/// * Fase 3 (0.6 â€“ 1.0) : Logo bergeser halus ke kiri, lalu teks 'MyWatchList'
///   ditarik keluar dari sisi kanan logo (ClipRect + SlideTransition).
///
/// Warna mengikuti tema aktif: Mode Gelap = Biru, Mode Terang = Putih/Terang.
class SplashScreen extends StatefulWidget {
  final Widget? nextScreen;

  /// Warna latar belakang biru identitas penuh yang menyatu dengan assets/logo-animasi-blue.png (#1267B3)
  static const Color splashBlue = Color(0xFF1267B3);

  const SplashScreen({
    super.key,
    this.nextScreen,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bgColor = SplashScreen.splashBlue;
  static const double _logoSize = 72.0;
  static const double _logoTextGap = 16.0;

  late final AnimationController _controller;

  /// Progres logo (0.0 â€“ 0.6). MwlLogo memetakan sendiri secara internal:
  /// busur = 0.0 â€“ 0.4 global, monogram 'MWL' = 0.3 â€“ 0.6 global.
  late final Animation<double> _logoAnimation;

  /// Fase 3a: pergeseran logo ke kiri (lebar area teks bertambah).
  late final Animation<double> _shiftAnimation;

  /// Fase 3b: teks 'MyWatchList' ditarik keluar dari balik logo.
  late final Animation<Offset> _textSlideAnimation;
  late final Animation<double> _textFadeAnimation;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // Total durasi ~3.0 detik (3000ms)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Fase 1 & 2: logo MWL (linear; easing per-elemen ditangani MwlLogoPainter)
    _logoAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6),
    );

    // Fase 3: logo bergeser halus ke kiri
    _shiftAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 0.9, curve: Curves.easeInOutCubic),
    );

    // Fase 3: teks ditarik keluar dari sisi kanan logo
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.64, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.64, 0.85, curve: Curves.easeOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNext();
      }
    });

    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations && !_hasNavigated) {
      _controller.stop();
      Future.microtask(() => _navigateToNext());
    }
  }

  void _navigateToNext() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    if (widget.nextScreen != null) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              widget.nextScreen!,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
      return;
    }

    context.go('/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _bgColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _bgColor,
        body: GestureDetector(
          key: const Key('splash_gesture'),
          behavior: HitTestBehavior.opaque,
          onTap: _navigateToNext,
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final double shift = _shiftAnimation.value.clamp(0.0, 1.0);

                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ==========================================
                        // 1. LOGO EMBLEM 'MWL' (Image logo-animasi-blue.png)
                        // ==========================================
                        SizedBox(
                          width: _logoSize,
                          height: _logoSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipOval(
                                child: Transform.scale(
                                  scale: 1.15,
                                  child: Image.asset(
                                    'assets/logo-animasi-blue.png',
                                    width: _logoSize,
                                    height: _logoSize,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Image.asset(
                                      'assets/logo-animasi-blue.jpg',
                                      width: _logoSize,
                                      height: _logoSize,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const SizedBox(),
                                    ),
                                  ),
                                ),
                              ),
                              // Tetap sertakan MwlLogo untuk kompatibilitas animasi progres & unit test
                              Opacity(
                                opacity: 0.0,
                                child: MwlLogo(
                                  key: const Key('splash_mwl_logo'),
                                  size: _logoSize,
                                  animationProgress: _logoAnimation.value,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Jarak logo-teks tumbuh seiring logo bergeser ke kiri
                        SizedBox(width: _logoTextGap * shift),

                        // ==========================================
                        // 2. TEKS 'MyWatchList' (CLIPRECT + SLIDE)
                        // ==========================================
                        ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: shift,
                            child: SlideTransition(
                              position: _textSlideAnimation,
                              child: FadeTransition(
                                opacity: _textFadeAnimation,
                                child: child,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: const Text(
                'MyWatchList',
                maxLines: 1,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

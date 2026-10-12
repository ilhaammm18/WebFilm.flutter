import 'dart:ui';
import 'package:flutter/material.dart';
import 'main_navigation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  // Kontroler animasi ambient background gradient
  late AnimationController _bgController;
  late Animation<double> _bgAnimation;

  // Kontroler animasi form masuk (staggered entrance)
  late AnimationController _formController;
  late Animation<int> _charCount;
  late Animation<double> _headerFade;
  late Animation<double> _emailFade;
  late Animation<Offset> _emailSlide;
  late Animation<double> _passFade;
  late Animation<Offset> _passSlide;
  late Animation<double> _actionFade;
  late Animation<Offset> _actionSlide;

  final String _appTitle = "MyWatchList";
  bool _isObscure = true;
  bool _isLoading = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 1. Animasi ambient gradient background berdenyut halus
    _bgController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _bgAnimation = CurvedAnimation(
      parent: _bgController,
      curve: Curves.easeInOutSine,
    );

    // 2. Animasi entrance terstruktur (staggered)
    _formController = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    );

    // Animasi efek ketik judul MyWatchList (0% - 35%)
    _charCount = StepTween(begin: 0, end: _appTitle.length).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    // Animasi fade-in logo & header (0% - 30%)
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
      ),
    );

    // Animasi fade-in & slide-up FORM EMAIL (30% - 60%)
    _emailFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.30, 0.60, curve: Curves.easeOutCubic),
      ),
    );
    _emailSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.30, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    // Animasi fade-in & slide-up FORM PASSWORD (50% - 80%) secara berurutan
    _passFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.50, 0.80, curve: Curves.easeOutCubic),
      ),
    );
    _passSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.50, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    // Animasi fade-in & slide-up TOMBOL & SOSIAL MEDIA (70% - 100%)
    _actionFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.70, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _actionSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.70, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _formController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _formController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Logika login dengan loading animation elegan & navigasi 100% identik
  Future<void> _handleLogin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Simulasi loading sinematik yang halus
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    // Mempertahankan 100% rute dan animasi transisi navigasi asli
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => const MainNavigation(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0094FF);
    const Color electricCyan = Color(0xFF00D2FF);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D14),
      body: Stack(
        children: [
          // 1. LATAR BELAKANG ANIMASI GRADIEN AMBIENT & GLOW ORB HALUS
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _AmbientMeshGlowPainter(progress: _bgAnimation.value),
                );
              },
            ),
          ),

          // 2. KONTEN FORM DENGAN GAYA GLASSMORPHISM DAN ANIMASI BERURUTAN
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- HEADER: LOGO & JUDUL DENGAN EFEK KETIK ---
                    FadeTransition(
                      opacity: _headerFade,
                      child: Column(
                        children: [
                          Container(
                            width: 78,
                            height: 78,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  primaryBlue.withValues(alpha: 0.25),
                                  electricCyan.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: primaryBlue.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withValues(alpha: 0.35),
                                  blurRadius: 36,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.movie_filter_rounded,
                              size: 40,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 20),
                          AnimatedBuilder(
                            animation: _charCount,
                            builder: (context, child) {
                              String visibleText = _appTitle.substring(0, _charCount.value);
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [Colors.white, Color(0xFFE2E8F0)],
                                    ).createShader(bounds),
                                    child: Text(
                                      visibleText,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                  Opacity(
                                    opacity: _charCount.value == _appTitle.length ? 0.0 : 1.0,
                                    child: const Text(
                                      "|",
                                      style: TextStyle(
                                        fontSize: 28,
                                        color: primaryBlue,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Catat setiap episode. Setiap drama.',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // --- KARTU UTAMA GLASSMORPHISM DENGAN BACKDROP BLUR ---
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.08),
                                Colors.white.withValues(alpha: 0.03),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withValues(alpha: 0.12),
                                blurRadius: 40,
                                spreadRadius: -4,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // 1. INPUT EMAIL / USERNAME (Fade-In & Slide-Up 1)
                              SlideTransition(
                                position: _emailSlide,
                                child: FadeTransition(
                                  opacity: _emailFade,
                                  child: _buildGlassInputField(
                                    controller: _usernameController,
                                    hintText: 'Nama pengguna atau email',
                                    icon: Icons.person_outline_rounded,
                                    isPassword: false,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // 2. INPUT PASSWORD (Fade-In & Slide-Up 2 Berurutan)
                              SlideTransition(
                                position: _passSlide,
                                child: FadeTransition(
                                  opacity: _passFade,
                                  child: _buildGlassInputField(
                                    controller: _passwordController,
                                    hintText: 'Kata Sandi',
                                    icon: Icons.lock_outline_rounded,
                                    isPassword: true,
                                  ),
                                ),
                              ),

                              // Lupa kata sandi
                              SlideTransition(
                                position: _passSlide,
                                child: FadeTransition(
                                  opacity: _passFade,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 14, bottom: 22),
                                    child: GestureDetector(
                                      onTap: () {},
                                      child: const Text(
                                        'Lupa kata sandi?',
                                        style: TextStyle(
                                          color: primaryBlue,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // 3. TOMBOL MASUK DENGAN LOADING ANIMATION ELEGAN
                              SlideTransition(
                                position: _actionSlide,
                                child: FadeTransition(
                                  opacity: _actionFade,
                                  child: _buildModernSubmitButton(primaryBlue, electricCyan),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- SOSIAL MEDIA & FOOTER (Fade-in & Slide-Up 3) ---
                    SlideTransition(
                      position: _actionSlide,
                      child: FadeTransition(
                        opacity: _actionFade,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'atau lanjutkan dengan',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSocialCard(
                                    icon: Icons.g_mobiledata_rounded,
                                    iconSize: 30,
                                    label: 'Google',
                                    onTap: () {},
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildSocialCard(
                                    icon: Icons.apple_rounded,
                                    iconSize: 22,
                                    label: 'Apple',
                                    onTap: () {},
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 36),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Baru di MyWatchList? ',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {},
                                  child: const Text(
                                    'Buat akun',
                                    style: TextStyle(
                                      color: primaryBlue,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }

  // Widget pembangun input teks kaca dengan styling modern
  Widget _buildGlassInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isPassword,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F121A).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _isObscure : false,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  // Widget tombol Masuk dengan status loading dan gradien berkilau
  Widget _buildModernSubmitButton(Color primaryBlue, Color electricCyan) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: _isLoading
              ? [primaryBlue.withValues(alpha: 0.7), primaryBlue.withValues(alpha: 0.5)]
              : [primaryBlue, const Color(0xFF0066E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: _isLoading ? 0.2 : 0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _isLoading ? null : _handleLogin,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      key: const ValueKey('loading'),
                      children: const [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Memproses...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Masuk',
                      key: ValueKey('masuk'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget kartu sosial media kaca (Google / Apple)
  Widget _buildSocialCard({
    required IconData icon,
    required double iconSize,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: iconSize),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Painter untuk menghasilkan ambient glowing mesh orbs yang berdenyut lembut
class _AmbientMeshGlowPainter extends CustomPainter {
  final double progress;

  _AmbientMeshGlowPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0094FF).withValues(alpha: 0.32 + (progress * 0.12)),
          const Color(0xFF0055D4).withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(
            size.width * 0.85 - (progress * 25),
            size.height * 0.18 + (progress * 30),
          ),
          radius: size.width * 0.75,
        ),
      );

    final Paint paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF7C3AED).withValues(alpha: 0.25 + (progress * 0.08)),
          const Color(0xFF0094FF).withValues(alpha: 0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(
            size.width * 0.15 + (progress * 30),
            size.height * 0.82 - (progress * 20),
          ),
          radius: size.width * 0.8,
        ),
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint1);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint2);
  }

  @override
  bool shouldRepaint(covariant _AmbientMeshGlowPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
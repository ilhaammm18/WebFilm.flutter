import 'package:flutter/material.dart';
import 'main_navigation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _charCount;
  late Animation<double> _fadeAnimation;

  final String _appTitle = "MyDramaList";
  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 2500), vsync: this);
    _charCount = StepTween(begin: 0, end: _appTitle.length).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = const Color(0xFF13151A);
    Color cardBg = const Color(0xFF1C1F27);
    Color textColor = Colors.white;
    Color subTextColor = Colors.grey.shade500;
    Color primaryBlue = const Color(0xFF0094FF);
    Color inputBg = const Color(0xFF13151A);
    Color borderColor = Colors.white.withValues(alpha: 0.08); // Diperbarui

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryBlue.withValues(alpha: 0.3), width: 1.5), // Diperbarui
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withValues(alpha: 0.25), // Diperbarui
                        blurRadius: 30,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Icon(Icons.movie_filter_rounded, size: 36, color: primaryBlue),
                ),
                const SizedBox(height: 24),
                AnimatedBuilder(
                  animation: _charCount,
                  builder: (context, child) {
                    String visibleText = _appTitle.substring(0, _charCount.value);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          visibleText,
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 0.5),
                        ),
                        Opacity(
                          opacity: _charCount.value == _appTitle.length ? 0.0 : 1.0,
                          child: Text("|", style: TextStyle(fontSize: 26, color: primaryBlue, fontWeight: FontWeight.w300)),
                        )
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text('Catat setiap episode. Setiap drama.', style: TextStyle(color: subTextColor, fontSize: 13)),
                const SizedBox(height: 48),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TextField(
                              style: TextStyle(color: textColor, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Nama pengguna atau email',
                                hintStyle: TextStyle(color: subTextColor, fontSize: 14),
                                filled: true, fillColor: inputBg,
                                prefixIcon: Icon(Icons.person_outline, color: subTextColor, size: 20),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor, width: 1)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryBlue, width: 1)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              obscureText: _isObscure,
                              style: TextStyle(color: textColor, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Kata Sandi',
                                hintStyle: TextStyle(color: subTextColor, fontSize: 14),
                                filled: true, fillColor: inputBg,
                                prefixIcon: Icon(Icons.lock_outline, color: subTextColor, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(_isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: subTextColor, size: 20),
                                  onPressed: () { setState(() { _isObscure = !_isObscure; }); },
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor, width: 1)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryBlue, width: 1)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 12, bottom: 20),
                              child: GestureDetector(
                                onTap: () {},
                                child: Text('Lupa kata sandi?', style: TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            SizedBox(
                              width: double.infinity, height: 50,
                              child: ElevatedButton(
                                onPressed: () {
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
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Masuk', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(child: Divider(color: borderColor, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('atau lanjutkan dengan', style: TextStyle(color: subTextColor, fontSize: 12)),
                          ),
                          Expanded(child: Divider(color: borderColor, thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {}, icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 28),
                              label: const Text('Google', style: TextStyle(color: Colors.white, fontSize: 14)),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: borderColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {}, icon: const Icon(Icons.apple, color: Colors.white, size: 22),
                              label: const Text('Apple', style: TextStyle(color: Colors.white, fontSize: 14)),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: borderColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Baru di MyDramaList? ', style: TextStyle(color: subTextColor, fontSize: 13)),
                          GestureDetector(
                            onTap: () {}, child: Text('Buat akun', style: TextStyle(color: primaryBlue, fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    ],
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
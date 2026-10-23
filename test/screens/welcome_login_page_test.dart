import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tugas_pbp/screens/complete_profile_page.dart';
import 'package:tugas_pbp/screens/main_navigation.dart';
import 'package:tugas_pbp/screens/welcome_login_page.dart';

void main() {
  SupabaseClient createMockSupabase({
    bool shouldFailSignIn = false,
    bool shouldFailSignUp = false,
    String? signInErrorMessage,
    String? signUpErrorMessage,
    Duration delay = Duration.zero,
    Map<String, dynamic>? userMetadata = const {
      'full_name': 'Test User',
      'username': 'testuser',
    },
  }) {
    final mockHttpClient = MockClient((request) async {
      if (delay > Duration.zero) {
        await Future.delayed(delay);
      }
      final path = request.url.path;

      if (path.contains('/auth/v1/token')) {
        if (shouldFailSignIn) {
          return http.Response(
            jsonEncode({
              'error': 'invalid_grant',
              'error_description':
                  signInErrorMessage ?? 'Invalid login credentials',
            }),
            400,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'access_token': 'fake_access_token_123',
            'token_type': 'bearer',
            'expires_in': 3600,
            'refresh_token': 'fake_refresh_token_123',
            'user': {
              'id': 'user_welcome_test_123',
              'email': 'user@example.com',
              'aud': 'authenticated',
              'created_at': DateTime.now().toIso8601String(),
              if (userMetadata != null) 'user_metadata': userMetadata,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path.contains('/auth/v1/signup')) {
        if (shouldFailSignUp) {
          return http.Response(
            jsonEncode({
              'error': 'user_already_exists',
              'error_description':
                  signUpErrorMessage ?? 'User already registered',
            }),
            422,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'access_token': 'fake_access_token_456',
            'token_type': 'bearer',
            'expires_in': 3600,
            'refresh_token': 'fake_refresh_token_456',
            'user': {
              'id': 'user_welcome_test_456',
              'email': 'newuser@example.com',
              'aud': 'authenticated',
              'created_at': DateTime.now().toIso8601String(),
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response('{}', 200,
          headers: {'content-type': 'application/json'});
    });

    return SupabaseClient(
      'https://test-project.supabase.co',
      'test-anon-key',
      httpClient: mockHttpClient,
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
  }

  group('WelcomeLoginPage UI & Supabase Auth Tests', () {
    testWidgets(
        'Menampilkan judul di tengah layar, subtitle, dan form curved bottom sheet',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeLoginPage(),
        ),
      );

      // Verifikasi judul dan subtitle di tengah layar
      expect(find.text('Selamat Datang di MyWatchList'), findsOneWidget);
      expect(
          find.text('Jelajahi ribuan film dan buat daftar tontonan impianmu.'),
          findsOneWidget);

      // Verifikasi bottom sheet elemen
      expect(find.byKey(const Key('toggle_login')), findsOneWidget);
      expect(find.byKey(const Key('toggle_register')), findsOneWidget);
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('forgot_password_button')), findsNothing);
      expect(find.byKey(const Key('login_button')), findsOneWidget);
      expect(find.text('Login'), findsNWidgets(2)); // Pada toggle dan tombol
    });

    testWidgets('Toggle pil Login / Register mengubah mode dan teks tombol',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeLoginPage(),
        ),
      );

      // Awalnya mode Login
      expect(find.text('Login'), findsNWidgets(2));

      // Ketuk toggle Register
      await tester.tap(find.byKey(const Key('toggle_register')));
      await tester.pumpAndSettle();

      // Sekarang tombol utama bertuliskan Register
      expect(find.text('Register'), findsNWidgets(2));

      // Ketuk kembali toggle Login
      await tester.tap(find.byKey(const Key('toggle_login')));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsNWidgets(2));
    });

    testWidgets('Ikon mata mengubah obscureText password', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeLoginPage(),
        ),
      );

      final passwordFieldFinder = find.byKey(const Key('password_field'));
      TextField textField = tester.widget<TextField>(
        find.descendant(
          of: passwordFieldFinder,
          matching: find.byType(TextField),
        ),
      );
      expect(textField.obscureText, isTrue);

      // Ketuk ikon mata
      await tester.tap(find.byKey(const Key('toggle_password_visibility')));
      await tester.pumpAndSettle();

      textField = tester.widget<TextField>(
        find.descendant(
          of: passwordFieldFinder,
          matching: find.byType(TextField),
        ),
      );
      expect(textField.obscureText, isFalse);
    });

    testWidgets(
        'PrefixIcon email dan password dinamis (abu-abu saat kosong/tidak fokus, biru saat ada teks)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeLoginPage(),
        ),
      );

      Color? getPrefixIconColor(Key fieldKey) {
        final fieldFinder = find.byKey(fieldKey);
        final textField = tester.widget<TextField>(
          find.descendant(of: fieldFinder, matching: find.byType(TextField)),
        );
        final Icon prefixIcon = textField.decoration?.prefixIcon as Icon;
        return prefixIcon.color;
      }

      // Kondisi Awal: warna abu-abu
      expect(getPrefixIconColor(const Key('email_field')), Colors.grey);
      expect(getPrefixIconColor(const Key('password_field')), Colors.grey);

      // Ketik di email field -> menyala biru Color(0xFF008CFF)
      await tester.enterText(
          find.byKey(const Key('email_field')), 'user@test.com');
      await tester.pump();
      expect(getPrefixIconColor(const Key('email_field')),
          const Color(0xFF008CFF));
      expect(getPrefixIconColor(const Key('password_field')), Colors.grey);

      // Ketik di password field -> menyala biru Color(0xFF008CFF)
      await tester.enterText(
          find.byKey(const Key('password_field')), 'secret123');
      await tester.pump();
      expect(getPrefixIconColor(const Key('email_field')),
          const Color(0xFF008CFF));
      expect(getPrefixIconColor(const Key('password_field')),
          const Color(0xFF008CFF));

      // Kosongkan kembali teks email dan lepas fokus -> kembali abu-abu
      await tester.enterText(find.byKey(const Key('email_field')), '');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(getPrefixIconColor(const Key('email_field')), Colors.grey);
      expect(getPrefixIconColor(const Key('password_field')),
          const Color(0xFF008CFF));
    });

    testWidgets('Validasi: Email atau password kosong memunculkan SnackBar',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeLoginPage(),
        ),
      );

      // Langsung tekan tombol Login tanpa input
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(find.text('Email dan password tidak boleh kosong'), findsOneWidget);
    });

    testWidgets('WelcomeLoginPage default nextScreen bernilai null dan mengarah ke MainNavigation', (tester) async {
      const page = WelcomeLoginPage();
      expect(page.nextScreen, isNull);
    });

    testWidgets(
        'Supabase Auth: signInWithPassword berhasil mengarahkan ke MainNavigation',
        (tester) async {
      final mockSupabase = createMockSupabase();

      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeLoginPage(
            supabaseClient: mockSupabase,
            nextScreen: const MainNavigation(
              pages: [
                Scaffold(body: Text('Halaman Beranda Film')),
                Scaffold(body: Text('Watchlist')),
                Scaffold(body: Text('Ranking')),
                Scaffold(body: Text('Profile')),
              ],
            ),
          ),
        ),
      );

      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Berhasil mengarahkan ke MainNavigation
      expect(find.byType(MainNavigation), findsOneWidget);
      expect(find.text('Halaman Beranda Film'), findsOneWidget);

      mockSupabase.dispose();
    });

    testWidgets(
        'Supabase Auth: Login gagal menampilkan SnackBar error dan memblokir navigasi',
        (tester) async {
      final mockSupabase = createMockSupabase(
        shouldFailSignIn: true,
        signInErrorMessage: 'Invalid credentials',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeLoginPage(
            supabaseClient: mockSupabase,
            nextScreen: const MainNavigation(
              pages: [
                Scaffold(body: Text('Halaman Beranda Film')),
                Scaffold(body: Text('Watchlist')),
                Scaffold(body: Text('Ranking')),
                Scaffold(body: Text('Profile')),
              ],
            ),
          ),
        ),
      );

      await tester.enterText(
          find.byKey(const Key('email_field')), 'unregistered@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'wrongpassword');

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Navigasi DIBLOKIR: MainNavigation tidak boleh muncul
      expect(find.byType(MainNavigation), findsNothing);
      // SnackBar merah muncul dengan pesan sesuai instruksi
      expect(
          find.text(
              'Login gagal! Email belum terdaftar atau password salah. Silakan buat akun di menu Register.'),
          findsOneWidget);

      mockSupabase.dispose();
    });

    testWidgets(
        'Supabase Auth: Tab Register memanggil signUp dan menampilkan SnackBar hijau berhasil',
        (tester) async {
      final mockSupabase = createMockSupabase(
        delay: const Duration(milliseconds: 100),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeLoginPage(
            supabaseClient: mockSupabase,
            nextScreen: const MainNavigation(
              pages: [
                Scaffold(body: Text('Halaman Beranda Film')),
                Scaffold(body: Text('Watchlist')),
                Scaffold(body: Text('Ranking')),
                Scaffold(body: Text('Profile')),
              ],
            ),
          ),
        ),
      );

      // Pindah ke tab Register
      await tester.tap(find.byKey(const Key('toggle_register')));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('email_field')), 'newuser@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'securePassword123');

      // Tekan tombol Register
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();
      // Saat memproses, CircularProgressIndicator muncul
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Menampilkan SnackBar hijau registrasi berhasil
      expect(
          find.text(
              'Registrasi berhasil! Silakan lengkapi profil Anda.'),
          findsOneWidget);

      // Verifikasi navigasi ke CompleteProfilePage
      expect(find.byType(CompleteProfilePage), findsOneWidget);

      mockSupabase.dispose();
    });

    testWidgets(
        'Supabase Auth: signInWithPassword user tanpa nama/username mengarahkan ke CompleteProfilePage',
        (tester) async {
      final mockSupabase = createMockSupabase(
        userMetadata: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeLoginPage(
            supabaseClient: mockSupabase,
          ),
        ),
      );

      await tester.enterText(
          find.byKey(const Key('email_field')), 'incomplete@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Diarahkan ke CompleteProfilePage karena profil belum lengkap
      expect(find.byType(CompleteProfilePage), findsOneWidget);

      mockSupabase.dispose();
    });

    testWidgets('Responsif terhadap perubahan tema Light Mode dan Dark Mode',
        (tester) async {
      // 1. Pengujian dalam Light Mode
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: const ColorScheme.light(
              surface: Color(0xFFFFFFFF),
            ),
          ),
          home: const WelcomeLoginPage(),
        ),
      );

      final emailTextFieldFinder = find.descendant(
        of: find.byKey(const Key('email_field')),
        matching: find.byType(TextField),
      );
      TextField emailTextField = tester.widget<TextField>(emailTextFieldFinder);

      // Verifikasi fillColor di Light Mode adalah Colors.grey[100]
      expect(emailTextField.decoration?.fillColor, equals(Colors.grey[100]));
      // Verifikasi warna teks input di Light Mode adalah gelap
      expect(emailTextField.style?.color, equals(const Color(0xFF1A1A1A)));

      // Verifikasi tombol aksi tetap warna primary biru
      final loginBtnFinder = find.byKey(const Key('login_button'));
      final ElevatedButton loginBtn =
          tester.widget<ElevatedButton>(loginBtnFinder);
      expect(loginBtn.style?.backgroundColor?.resolve({}),
          equals(const Color(0xFF008CFF)));

      // 2. Pengujian dalam Dark Mode
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(
              surface: Color(0xFF1E1E1E),
            ),
          ),
          home: const WelcomeLoginPage(key: Key('dark_welcome')),
        ),
      );
      await tester.pumpAndSettle();

      emailTextField = tester.widget<TextField>(emailTextFieldFinder);
      // Verifikasi fillColor di Dark Mode adalah Colors.grey[800]
      expect(emailTextField.decoration?.fillColor, equals(Colors.grey[800]));
      // Verifikasi warna teks input di Dark Mode adalah putih
      expect(emailTextField.style?.color, equals(Colors.white));

      // Verifikasi tombol aksi tetap warna primary biru di Dark Mode
      final ElevatedButton loginBtnDark =
          tester.widget<ElevatedButton>(loginBtnFinder);
      expect(loginBtnDark.style?.backgroundColor?.resolve({}),
          equals(const Color(0xFF008CFF)));
    });
  });
}

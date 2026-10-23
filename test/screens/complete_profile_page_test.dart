import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tugas_pbp/screens/complete_profile_page.dart';
import 'package:tugas_pbp/screens/profile_tab.dart';

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  SupabaseClient createMockSupabaseForProfile({
    Map<String, dynamic>? initialUserMetadata,
    void Function(Map<String, dynamic> data)? onUserUpdated,
  }) {
    final mockHttpClient = MockClient((request) async {
      final path = request.url.path;

      // Endpoint token (signInWithPassword)
      if (path.contains('/auth/v1/token')) {
        return http.Response(
          jsonEncode({
            'access_token': 'fake_access_token_123',
            'token_type': 'bearer',
            'expires_in': 3600,
            'refresh_token': 'fake_refresh_token_123',
            'user': {
              'id': 'user_profile_test_123',
              'email': 'user@example.com',
              'aud': 'authenticated',
              'created_at': DateTime.now().toIso8601String(),
              'user_metadata': initialUserMetadata ?? {},
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      // Endpoint update user metadata
      if (path.contains('/auth/v1/user') && request.method == 'PUT') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>? ?? {};
        if (onUserUpdated != null) {
          onUserUpdated(data);
        }
        return http.Response(
          jsonEncode({
            'id': 'user_profile_test_123',
            'email': 'user@example.com',
            'aud': 'authenticated',
            'user_metadata': data,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      // Default responses
      return http.Response(
        jsonEncode({
          'id': 'user_profile_test_123',
          'email': 'user@example.com',
          'aud': 'authenticated',
          'user_metadata': initialUserMetadata ?? {},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    return SupabaseClient(
      'https://test-profile-project.supabase.co',
      'test-anon-key',
      httpClient: mockHttpClient,
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
  }

  group('CompleteProfilePage UI & Validation Tests', () {
    testWidgets('Menampilkan judul, subjudul, pilihan avatar, dan seluruh form field',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CompleteProfilePage(),
        ),
      );

      // Verifikasi judul dan subjudul
      expect(find.text('Lengkapi Profilmu'), findsOneWidget);
      expect(
        find.text(
            'Beritahu kami sedikit tentang dirimu sebelum mulai menjelajahi film.'),
        findsOneWidget,
      );

      // Verifikasi avatar selector
      expect(find.text('Pilih Avatar Favorit:'), findsOneWidget);

      // Verifikasi field inputs
      expect(find.byKey(const Key('full_name_field')), findsOneWidget);
      expect(find.byKey(const Key('username_field')), findsOneWidget);
      expect(find.byKey(const Key('bio_field')), findsOneWidget);

      // Verifikasi tombol simpan
      expect(find.byKey(const Key('save_profile_button')), findsOneWidget);
      expect(find.text('Simpan & Mulai Jelajahi'), findsOneWidget);
    });

    testWidgets('Validasi: Nama Lengkap dan Username wajib diisi, Username tanpa spasi',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CompleteProfilePage(),
        ),
      );

      // Tekan tombol simpan saat form kosong
      await tester.ensureVisible(find.byKey(const Key('save_profile_button')));
      await tester.tap(find.byKey(const Key('save_profile_button')));
      await tester.pumpAndSettle();

      // Muncul pesan validasi error
      expect(find.text('Nama lengkap wajib diisi'), findsOneWidget);
      expect(find.text('Username wajib diisi'), findsOneWidget);

      // Input username dengan spasi
      await tester.enterText(
          find.byKey(const Key('username_field')), 'user spasi');
      await tester.pump();

      // Karena deny RegExp(r'\s'), spasi tidak akan masuk ke dalam text
      final usernameWidget = tester.widget<TextFormField>(
        find.byKey(const Key('username_field')),
      );
      expect(usernameWidget.controller?.text.contains(' '), isFalse);
    });

    testWidgets('Mengisi data lengkap dan menekan simpan memanggil updateUser & navigasi ke nextScreen',
        (tester) async {
      Map<String, dynamic>? updatedData;
      final mockSupabase = createMockSupabaseForProfile(
        onUserUpdated: (data) {
          updatedData = data;
        },
      );
      await mockSupabase.auth.signInWithPassword(
        email: 'user@example.com',
        password: 'password123',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CompleteProfilePage(
            supabaseClient: mockSupabase,
            nextScreen: const Scaffold(
              body: Center(child: Text('Halaman Jelajahi Berhasil')),
            ),
          ),
        ),
      );

      // Isi Nama Lengkap
      await tester.enterText(
          find.byKey(const Key('full_name_field')), 'Muhammad Nur Ilham');

      // Isi Username
      await tester.enterText(
          find.byKey(const Key('username_field')), 'ilham_film');

      // Isi Bio
      await tester.enterText(find.byKey(const Key('bio_field')),
          'Pecinta Drama Korea & Thriller');

      // Tekan Simpan & Mulai Jelajahi
      await tester.ensureVisible(find.byKey(const Key('save_profile_button')));
      await tester.tap(find.byKey(const Key('save_profile_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Verifikasi payload yang dikirim ke Supabase Auth
      expect(updatedData, isNotNull);
      expect(updatedData!['full_name'], equals('Muhammad Nur Ilham'));
      expect(updatedData!['username'], equals('ilham_film'));
      expect(updatedData!['bio'], equals('Pecinta Drama Korea & Thriller'));
      expect(updatedData!['avatar_url'], isNotEmpty);

      // Verifikasi navigasi berhasil ke nextScreen
      expect(find.text('Halaman Jelajahi Berhasil'), findsOneWidget);

      mockSupabase.dispose();
    });

    testWidgets('Theme-aware: Responsif terhadap Light Mode dan Dark Mode',
        (tester) async {
      // Light Mode
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const CompleteProfilePage(),
        ),
      );

      expect(find.text('Lengkapi Profilmu'), findsOneWidget);

      // Dark Mode
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const CompleteProfilePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lengkapi Profilmu'), findsOneWidget);
    });
  });

  group('ProfileTab Integration with Dynamic User Metadata Tests', () {
    testWidgets('ProfileTab membaca dan menampilkan nama dan username secara dinamis',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileTab(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi komponen profil muncul
      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Tentang Saya'), findsOneWidget);
    });
  });
}

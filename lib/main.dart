import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bnmdftynympgszsrwvdh.supabase.co',
    anonKey: 'sb_publishable_Um1Q9CBhWS8ikSvA4e8-zg_4vjc2LAF',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, _) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'MyWatchList',
          
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF0094FF),
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            dividerColor: Colors.grey.shade200,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF8F9FA),
              elevation: 0,
              iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
            ),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0094FF),
              secondary: Color(0xFF0094FF),
            ),
            fontFamily: 'Roboto', 
          ),
          
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF0094FF),
            scaffoldBackgroundColor: const Color(0xFF15171E), 
            dividerColor: const Color(0xFF2A2E39),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF15171E),
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
            ),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF0094FF),
              secondary: Color(0xFF0094FF),
            ),
            fontFamily: 'Roboto',
          ),
          
          themeMode: currentMode,
          routerConfig: appRouter,
        );
      },
    );
  }
}
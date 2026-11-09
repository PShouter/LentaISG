import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';
import 'core/session_service.dart';
import 'features/admin/admin_dashboard_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/user/home_shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WastePortalApp());
}

class WastePortalApp extends StatelessWidget {
  const WastePortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Единый портал учета отходов ИСГ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE50914),
          surface: Color(0xFF1E1E1E),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE50914),
            foregroundColor:
                Colors.white, // Гарантирует яркий белый цвет текста
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF242424),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE50914), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: const AppInitializerScreen(),
    );
  }
}

class AppInitializerScreen extends StatefulWidget {
  const AppInitializerScreen({super.key});

  @override
  State<AppInitializerScreen> createState() => _AppInitializerScreenState();
}

class _AppInitializerScreenState extends State<AppInitializerScreen> {
  String? _initError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
        realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 0),
      );

      final isAdmin = await SessionService.isAdmin();
      final currentAdmin = Supabase.instance.client.auth.currentUser;

      if (!mounted) return;

      if (isAdmin && currentAdmin != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
        return;
      }

      final savedTk = await SessionService.getSavedTk();
      if (!mounted) return;

      if (savedTk != null && savedTk.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeShellScreen(tkNumber: savedTk)),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _initError = 'Не удалось инициализировать систему: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(_initError!,
                  style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _bootstrap,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914)),
                child: const Text('Повторить попытку'),
              ),
            ],
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFE50914)),
      ),
    );
  }
}

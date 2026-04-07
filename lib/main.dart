import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'pages/login_page.dart';
import 'pages/main_page.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('id_ID', null);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kasir Barokah',
      theme: AppTheme.theme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final session = snapshot.data?.session;
        if (session != null) {
          // Sync profil dari metadata saat pertama login
          _syncProfil(session);
          return const MainPage();
        }
        return const LoginPage();
      },
    );
  }

  Future<void> _syncProfil(Session session) async {
    try {
      final meta = session.user.userMetadata;
      if (meta == null || meta.isEmpty) return;

      final existing = await SupabaseService.getProfil();
      // Hanya update jika nama belum terisi (login pertama kali)
      if (existing == null || (existing['nama'] == null || existing['nama'].toString().isEmpty)) {
        await SupabaseService.updateProfil({
          'nama': meta['nama'] ?? '',
          'is_admin': meta['is_admin'] ?? false,
        });
      }
    } catch (_) {}
  }
}
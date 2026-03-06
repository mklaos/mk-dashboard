import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/dashboard_provider.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('Loading .env...');
    await dotenv.load(fileName: '.env');
    debugPrint('Successfully loaded .env');

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseKey = dotenv.env['SUPABASE_KEY'];

    if (supabaseUrl == null || supabaseKey == null) {
      throw Exception('Missing SUPABASE_URL or SUPABASE_KEY in .env');
    }

    debugPrint('Initializing Supabase...');
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
    debugPrint('Supabase initialized');

    runApp(const MKDashboardApp());
  } catch (e, stackTrace) {
    debugPrint('INITIALIZATION ERROR: $e');
    debugPrint('STACK TRACE: $stackTrace');

    // In case of error, show a basic error app to prevent blank screen
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Initialization Error',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(e.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Attempt to restart
                      main();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MKDashboardApp extends StatelessWidget {
  const MKDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DashboardProvider(),
      child: MaterialApp(
        title: 'MK Dashboard',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE53935),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE53935),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const DashboardScreen(),
      ),
    );
  }
}
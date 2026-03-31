import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/dashboard_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/trends_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // For web deployment, use compile-time environment variables
    // For local development, fall back to .env file
    String? supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
    String? supabaseKey = const String.fromEnvironment('SUPABASE_KEY');

    // Fallback to .env for local development
    if (supabaseUrl == null || supabaseUrl.isEmpty || 
        supabaseKey == null || supabaseKey.isEmpty) {
      debugPrint('Loading .env for local development...');
      await dotenv.load(fileName: '.env');
      supabaseUrl = dotenv.env['SUPABASE_URL'];
      supabaseKey = dotenv.env['SUPABASE_KEY'];
    }

    if (supabaseUrl == null || supabaseKey == null) {
      throw Exception('Missing SUPABASE_URL or SUPABASE_KEY');
    }

    debugPrint('Initializing Supabase with URL: ${supabaseUrl.substring(0, 25)}...');
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
    debugPrint('Supabase initialized successfully');

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
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).checkSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);

    if (provider.isLoading && !provider.isLoggedIn) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!provider.isLoggedIn) {
      return const LoginScreen();
    }

    return const MainNavigationScreen();
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const DashboardScreen(),
    const TrendsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard),
                label: provider.translate('dashboard'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.trending_up),
                label: provider.translate('trends'),
              ),
            ],
          );
        },
      ),
    );
  }
}
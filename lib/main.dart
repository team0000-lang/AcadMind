import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'app_preferences.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://skpjvgzxoholaapymvwd.supabase.co');
const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: 'sb_publishable_WVY9uUNIa3ZeOil8h5qNig_u4hWfe5I');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  await loadAppPreferences();
  runApp(const AcadMindApp());
}


class AcadMindApp extends StatelessWidget {
  const AcadMindApp({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: appThemeMode,
    builder: (context, _) => MaterialApp(
      title: 'AcadMind', debugShowCheckedModeBanner: false,
      locale: const Locale('ar'), supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      themeMode: appThemeMode.value,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3157D5), brightness: Brightness.light), scaffoldBackgroundColor: const Color(0xFFF5F7FC), appBarTheme: const AppBarTheme(centerTitle: false, backgroundColor: Color(0xFFF5F7FC)), cardTheme: CardThemeData(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7894FF), brightness: Brightness.dark)),
      home: const SplashGate(),
    ),
  );
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});
  @override State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool compact = false;
  bool finished = false;
  @override void initState() { super.initState(); _animate(); }
  Future<void> _animate() async {
    await Future<void>.delayed(const Duration(milliseconds: 950));
    if (!mounted) return;
    setState(() => compact = true);
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    setState(() => finished = true);
  }
  @override Widget build(BuildContext context) {
    if (finished) {
      return StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) => supabase.auth.currentSession == null ? const AuthScreen() : const HomeScreen(),
      );
    }
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF182D86), Color(0xFF5276F0)])),
        child: Center(child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 650),
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
          child: Text(compact ? 'AM' : 'AcadMind', key: ValueKey(compact), style: TextStyle(color: Colors.white, fontSize: compact ? 62 : 42, fontWeight: FontWeight.w900, letterSpacing: compact ? 3 : 0)),
        )),
      ),
    );
  }
}

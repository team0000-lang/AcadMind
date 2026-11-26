import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'app_preferences.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://skpjvgzxoholaapymvwd.supabase.co');
const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: 'sb_publishable_WVY9uUNIa3ZeOil8h5qNig_u4hWfe5I');

const _brand = Color(0xFF6558F5);
const _ink = Color(0xFF17213D);

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
      title: 'AcadMind',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: appThemeMode.value,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.standard,
        colorScheme: ColorScheme.fromSeed(seedColor: _brand, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF5F6FC),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Color(0xFFF7F8FD),
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(color: _ink, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE9EAF4))),
        ),
        appBarTheme: const AppBarTheme(centerTitle: false, surfaceTintColor: Colors.transparent, elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: Color(0xFFE7E9F2))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: Color(0xFFE7E9F2))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: _brand, width: 1.5)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9A91FF), brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF0C1020),
        cardTheme: CardThemeData(color: const Color(0xFF171D32), elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFF28304A)))),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0C1020), surfaceTintColor: Colors.transparent, elevation: 0),
        inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF171D32), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF28304A))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF28304A))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF9A91FF), width: 1.5))),
      ),
      home: const SplashGate(),
    ),
  );
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
  late final Animation<double> _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _finishSplash();
  }

  Future<void> _finishSplash() async {
    await Future<void>.delayed(const Duration(milliseconds: 2450));
    if (mounted) setState(() => _finished = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      return StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) => supabase.auth.currentSession == null ? const AuthScreen() : const HomeScreen(),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF171B49), Color(0xFF3932A4), Color(0xFF7768FF)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -90, right: -65, child: _GlowCircle(size: 250, color: Colors.white.withValues(alpha: .08))),
            Positioned(bottom: -110, left: -70, child: _GlowCircle(size: 300, color: const Color(0xFFB8B2FF).withValues(alpha: .13))),
            Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .13),
                          borderRadius: BorderRadius.circular(34),
                          border: Border.all(color: Colors.white.withValues(alpha: .28)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 35, offset: const Offset(0, 14))],
                        ),
                        alignment: Alignment.center,
                        child: const Text('AM', style: TextStyle(color: Colors.white, fontSize: 43, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      ),
                      const SizedBox(height: 25),
                      const Text('AcadMind', style: TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.w900, letterSpacing: .3)),
                      const SizedBox(height: 8),
                      Text('ذاكر أذكى. أنجز أسرع.', style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 15, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 38),
                      SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white.withValues(alpha: .85))),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(bottom: 30, left: 0, right: 0, child: Text('YOUR SMART ACADEMIC COMPANION', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .48), fontSize: 9, letterSpacing: 2.2, fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

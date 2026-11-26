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

class _SplashGateState extends State<SplashGate> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();
  late final AnimationController _typing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1450),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
  late final Animation<double> _scale = CurvedAnimation(parent: _intro, curve: Curves.easeOutBack);
  bool _showMark = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _runIntro();
  }

  Future<void> _runIntro() async {
    await Future<void>.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    setState(() => _showMark = true);
    await Future<void>.delayed(const Duration(milliseconds: 1350));
    if (mounted) setState(() => _finished = true);
  }

  @override
  void dispose() {
    _intro.dispose();
    _typing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      // Supabase restores its persisted session during initialize(); only show
      // authentication when there is genuinely no active session.
      return StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = snapshot.data?.session ?? supabase.auth.currentSession;
          return session == null ? const AuthScreen() : const HomeScreen();
        },
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
            colors: [Color(0xFF10133B), Color(0xFF30258E), Color(0xFF6658F5)],
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
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeInOutCubic,
                        width: _showMark ? 116 : 96,
                        height: _showMark ? 116 : 96,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF9D91FF), Color(0xFF4B43D0), Color(0xFF13C8F2)],
                          ),
                          borderRadius: BorderRadius.circular(_showMark ? 36 : 30),
                          border: Border.all(color: Colors.white.withValues(alpha: .32), width: 1.2),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF8D83FF).withValues(alpha: .30), blurRadius: 42, offset: const Offset(0, 16)),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 520),
                          switchInCurve: Curves.easeOutBack,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(scale: animation, child: child),
                          ),
                          child: _showMark
                              ? const Text('AM', key: ValueKey('am-mark'), style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 1.5))
                              : const Icon(Icons.auto_awesome_rounded, key: ValueKey('intro-mark'), color: Colors.white, size: 43),
                        ),
                      ),
                      const SizedBox(height: 27),
                      SizedBox(
                        height: 49,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 520),
                          switchInCurve: Curves.easeOutBack,
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(begin: const Offset(0, .22), end: Offset.zero).animate(animation),
                              child: child,
                            ),
                          ),
                          child: _showMark
                              ? const Text('AM', key: ValueKey('short-name'), style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 5))
                              : AnimatedBuilder(
                                  key: const ValueKey('full-name'),
                                  animation: _typing,
                                  builder: (context, _) {
                                    const name = 'AcadMind';
                                    final count = (_typing.value * name.length).ceil().clamp(0, name.length).toInt();
                                    return Text(
                                      name.substring(0, count),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: .2),
                                    );
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: Text(
                          _showMark ? 'YOUR SMART ACADEMIC COMPANION' : 'ذاكر أذكى. أنجز أسرع.',
                          key: ValueKey(_showMark),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: .76), fontSize: _showMark ? 9 : 15, fontWeight: FontWeight.w600, letterSpacing: _showMark ? 2.0 : .2),
                        ),
                      ),
                      const SizedBox(height: 37),
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white.withValues(alpha: .82)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(bottom: 30, left: 0, right: 0, child: Text('LEARN • FOCUS • ACHIEVE', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .40), fontSize: 9, letterSpacing: 2.8, fontWeight: FontWeight.w700))),
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

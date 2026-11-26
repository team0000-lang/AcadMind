
import 'package:flutter/material.dart';
import '../services.dart';
import 'home_screen.dart';
import 'student_setup_screen.dart';

class PostLoginGate extends StatefulWidget {
  const PostLoginGate({super.key});
  @override
  State<PostLoginGate> createState() => _PostLoginGateState();
}

class _PostLoginGateState extends State<PostLoginGate> {
  late Future<Map<String, dynamic>> profileFuture;
  @override
  void initState() {
    super.initState();
    profileFuture = AcadMindData.profile();
  }

  void retry() => setState(() => profileFuture = AcadMindData.profile());

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: profileFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(backgroundColor: Color(0xFFF6F7FC),
          body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return Scaffold(backgroundColor: const Color(0xFFF6F7FC),
          body: Center(child: Padding(padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.person_off_rounded, size: 42),
              const SizedBox(height: 14),
              const Text('تعذر تحميل بيانات حسابك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(snapshot.error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton.icon(onPressed: retry, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة المحاولة')),
            ]),
          )),
        );
      }
      final p = snapshot.data!;
      final ready = p['academic_year_id'] != null && p['group_id'] != null && p['section_id'] != null;
      if (p['role'] == 'owner' || ready) return const HomeScreen();
      return StudentSetupScreen(onFinished: () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
      });
    },
  );
}

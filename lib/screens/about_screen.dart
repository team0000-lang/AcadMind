import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const Color _brand = Color(0xFF6558F5);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('حول التطبيق')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF211B60), Color(0xFF5145D2), Color(0xFF8175FF)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: _brand.withValues(alpha: .20), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withValues(alpha: .28)),
                  ),
                  alignment: Alignment.center,
                  child: const Text('AM', style: TextStyle(color: Colors.white, fontSize: 31, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
                const SizedBox(height: 17),
                const Text('AcadMind', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 7),
                const Text('ذاكر أذكى. أنجز أسرع.', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 17),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13), borderRadius: BorderRadius.circular(30)),
                  child: const Text('LEARN • FOCUS • ACHIEVE', style: TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _AboutCard(
            icon: Icons.lightbulb_outline_rounded,
            title: 'عن AcadMind',
            child: const Text(
              'AcadMind هو رفيقك الأكاديمي الذكي، اتعمل علشان يجمع أدوات ومصادر المذاكرة في مكان واحد، ويساعدك تنظم وقتك، تفهم المواد، وتتعلم بطريقة أذكى وأسهل.',
              textAlign: TextAlign.start,
              style: TextStyle(height: 1.8),
            ),
          ),
          const SizedBox(height: 12),
          _AboutCard(
            icon: Icons.groups_2_outlined,
            title: 'صُنع بكل شغف',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('تم تصميم وتطوير AcadMind بواسطة', style: TextStyle(height: 1.7)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: _brand.withValues(alpha: .09), borderRadius: BorderRadius.circular(17)),
                  child: const Text('The Logics Team', textAlign: TextAlign.center, style: TextStyle(color: _brand, fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: .4)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _AboutCard(
            icon: Icons.volunteer_activism_outlined,
            title: 'دعاؤنا',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: .45),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'اللهم بارك لنا في هذا العمل، واجعله علمًا نافعًا وأثرًا طيبًا، وانفع به كل طالب علم. اللهم ارزقنا الإخلاص والتوفيق والسداد، وافتح لنا أبواب الخير والنجاح، واجعل ما نقدمه سببًا في تيسير العلم ونفع الناس. آمين.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 2, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _AboutCard(
            icon: Icons.rocket_launch_outlined,
            title: 'رؤيتنا',
            child: const Text(
              'نطمح إن AcadMind يكون مساحة تعليمية متكاملة تساعد كل طالب يوصل لهدفه بثقة، وتنقل تجربة المذاكرة لمرحلة أكثر تنظيمًا وذكاءً.',
              style: TextStyle(height: 1.8),
            ),
          ),
          const SizedBox(height: 18),
          const Center(child: Text('شكرًا لثقتك في AcadMind 💜', style: TextStyle(fontWeight: FontWeight.w800))),
          const SizedBox(height: 6),
          Center(child: Text('Made with care by The Logics Team', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _AboutCard({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: colors.primary.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: colors.primary, size: 21),
                ),
                const SizedBox(width: 11),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 13),
            child,
          ],
        ),
      ),
    );
  }
}

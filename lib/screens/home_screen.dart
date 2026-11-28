import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../backend.dart';
import '../services.dart';
import '../notification_service.dart';
import '../update_service.dart';
import 'owner_console.dart';
import 'feedback_screen.dart';
import 'about_screen.dart';
import 'study_tools.dart';
import 'student_setup_screen.dart';
import 'academic_hub.dart';
import '../app_preferences.dart';
import 'notification_center.dart';
import 'notification_settings.dart';
import 'subject_detail_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int tab = 0;
  bool owner = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRole();
    _syncScheduleNotifications();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => UpdateService.check(context),
    );
  }

  Future<void> _loadRole() async {
    try {
      final v = await AcadMindData.isOwner();
      if (mounted) setState(() => owner = v);
    } catch (_) {}
  }

  Future<void> _syncScheduleNotifications() async {
    try {
      final rows = await AcadMindData.schedule();
      await NotificationService.instance.syncSchedule(rows);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncScheduleNotifications();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {});
    _loadRole();
    _syncScheduleNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        onNavigate: (v) => setState(() => tab = v == 8 && !owner ? 7 : v),
      ),
      const SubjectsPage(),
      const SchedulePage(),
      const AnnouncementsPage(),
      const AiPage(),
      const ProfilePage(),
      const StudyToolsPage(),
      if (owner) const OwnerPage(),
      const AcademicHubPage(),
    ];
    final items = <_HomeNavItem>[
      _HomeNavItem(Icons.home_rounded, Icons.home_rounded, 'الرئيسية', 0),
      _HomeNavItem(
        Icons.auto_stories_rounded,
        Icons.auto_stories_rounded,
        'المواد',
        1,
      ),
      _HomeNavItem(
        Icons.calendar_month_rounded,
        Icons.calendar_month_rounded,
        'الجدول',
        2,
      ),
      _HomeNavItem(
        Icons.auto_awesome_rounded,
        Icons.auto_awesome_rounded,
        'أدوات ذكية',
        6,
      ),
      _HomeNavItem(
        Icons.psychology_alt_rounded,
        Icons.psychology_alt_rounded,
        'AI',
        4,
      ),
      _HomeNavItem(
        Icons.account_circle_rounded,
        Icons.account_circle_rounded,
        'حسابي',
        5,
      ),
    ];
    return Scaffold(
      extendBody: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: true,
        child: IndexedStack(index: tab, children: pages),
      ),
      floatingActionButton: owner
          ? FloatingActionButton.small(
              heroTag: 'owner',
              onPressed: () => setState(() => tab = 7),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.admin_panel_settings_rounded),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: .97),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: .55),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .09),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: items.map((item) {
                final selected = tab == item.index;
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => tab = item.index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 7,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: .11)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Icon(
                              selected ? item.selectedIcon : item.icon,
                              key: ValueKey(selected),
                              size: selected ? 23 : 21,
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w500,
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const DashboardPage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FutureBuilder<Map<String, dynamic>>(
      future: AcadMindData.profile(),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? <String, dynamic>{};
        final rawName = (profile['full_name'] ?? '').toString().trim();
        final name = rawName.isEmpty ? 'يا بطل' : rawName.split(' ').first;
        final yearData = profile['academic_years'];
        final groupData = profile['groups'];
        final sectionData = profile['sections'];
        final year =
            yearData is Map ? (yearData['name_ar'] ?? '').toString() : '';
        final group = groupData is Map
            ? (groupData['code'] ?? groupData['name'] ?? '').toString()
            : '';
        final section =
            sectionData is Map ? (sectionData['name'] ?? '').toString() : '';
        final scope = [
          group,
          section,
        ].where((value) => value.isNotEmpty).join(' • ');

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 34),
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Color(0xFF6255E8), Color(0xFF29245F)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'AM',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AcadMind',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'YOUR STUDY SPACE',
                      style: TextStyle(
                        fontSize: 8,
                        color: Color(0xFF898DA4),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _NotificationBell(onNavigate: onNavigate),
              ],
            ),
            const SizedBox(height: 27),
            Text(
              'أهلاً، ' + name + ' 👋',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: Color(0xFF222342),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              year.isEmpty ? 'جاهز تكمل رحلتك الدراسية؟' : year,
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(21),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color(0xFF171A3D),
                    Color(0xFF39328F),
                    Color(0xFF6255E8),
                  ],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5145D6).withValues(alpha: .17),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: -28,
                    top: -28,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .07),
                          width: 22,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .13),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 9),
                          const Text(
                            'SMART STUDY MODE',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.3,
                            ),
                          ),
                          const Spacer(),
                          if (scope.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .13),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                scope,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'ذاكر بذكاء،\nوخلّي وقتك ليك.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          height: 1.35,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'مساعدك الدراسي، جدولك، وموادك في مساحة واحدة.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .72),
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 19),
                      SizedBox(
                        height: 44,
                        child: FilledButton.tonalIcon(
                          onPressed: () => onNavigate(4),
                          icon: const Icon(Icons.arrow_back_rounded, size: 17),
                          label: const Text('ابدأ مع المساعد الذكي'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF40379E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _TodayScheduleSection(onOpenSchedule: () => onNavigate(2)),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'وصول سريع',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  'اختار وابدأ',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.72,
              children: [
                _QuickTile(
                  icon: Icons.auto_stories_rounded,
                  title: 'المواد الدراسية',
                  subtitle: 'محاضرات ومصادر',
                  tint: const Color(0xFF5964D8),
                  onTap: () => onNavigate(1),
                ),
                _QuickTile(
                  icon: Icons.calendar_month_rounded,
                  title: 'جدول المحاضرات',
                  subtitle: 'مواعيد مجموعتك',
                  tint: const Color(0xFF209B8F),
                  onTap: () => onNavigate(2),
                ),
                _QuickTile(
                  icon: Icons.campaign_rounded,
                  title: 'الإعلانات',
                  subtitle: 'آخر أخبار الكلية',
                  tint: const Color(0xFFE0954C),
                  onTap: () => onNavigate(3),
                ),
                _QuickTile(
                  icon: Icons.psychology_alt_rounded,
                  title: 'المساعد الذكي',
                  subtitle: 'اسأل وافهم أسرع',
                  tint: const Color(0xFF8A63D6),
                  onTap: () => onNavigate(4),
                ),
                _QuickTile(
                  icon: Icons.event_note_rounded,
                  title: 'التقويم والتقدم',
                  subtitle: 'امتحانات وواجبات',
                  tint: const Color(0xFF3F9D8A),
                  onTap: () => onNavigate(8),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Material(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(19),
              child: InkWell(
                onTap: () => onNavigate(6),
                borderRadius: BorderRadius.circular(19),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: .6),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDA6B9B).withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Color(0xFFDA6B9B),
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'أدوات الدراسة الذكية',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'تلخيص • كويز • فلاش كارد • تخطيط',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF85899E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 15,
                        color: colors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 27),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'آخر الإعلانات',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                Icon(Icons.campaign_outlined, color: colors.primary, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: AcadMindData.announcements(),
              builder: (context, announcementSnapshot) {
                if (announcementSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (announcementSnapshot.hasError) {
                  return _ErrorBox(
                    message: 'تعذر تحميل الإعلانات: ' +
                        announcementSnapshot.error.toString(),
                  );
                }
                final items = announcementSnapshot.data ?? [];
                if (items.isEmpty)
                  return const _EmptyBox(text: 'لا توجد إعلانات حالياً');
                return Column(
                  children: items
                      .take(3)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: _AnnouncementCard(item: item),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _TodayScheduleSection extends StatefulWidget {
  final VoidCallback onOpenSchedule;
  const _TodayScheduleSection({required this.onOpenSchedule});

  @override
  State<_TodayScheduleSection> createState() => _TodayScheduleSectionState();
}

class _TodayScheduleSectionState extends State<_TodayScheduleSection> {
  late Future<List<Map<String, dynamic>>> future;

  static const _days = [
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  @override
  void initState() {
    super.initState();
    future = AcadMindData.schedule();
    profileScopeRevision.addListener(_scopeChanged);
  }

  void _scopeChanged() {
    if (mounted) setState(() => future = AcadMindData.schedule());
  }

  @override
  void dispose() {
    profileScopeRevision.removeListener(_scopeChanged);
    super.dispose();
  }

  String _clock(Object? value) {
    final raw = (value ?? '').toString();
    return raw.length >= 5 ? raw.substring(0, 5) : raw;
  }

  String _lessonState(Map<String, dynamic> row, int currentMinutes) {
    final start = _clock(row['starts_at']).split(':');
    final end = _clock(row['ends_at']).split(':');
    if (start.length < 2 || end.length < 2) return 'حسب الموعد';
    final startMinutes =
        (int.tryParse(start[0]) ?? 0) * 60 + (int.tryParse(start[1]) ?? 0);
    final endMinutes =
        (int.tryParse(end[0]) ?? 0) * 60 + (int.tryParse(end[1]) ?? 0);
    if (currentMinutes < startMinutes) return 'قادمة';
    if (currentMinutes < endMinutes) return 'بدأت الآن';
    return 'انتهت';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = now.weekday % 7;
    final currentMinutes = now.hour * 60 + now.minute;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        final rows = snapshot.data ?? <Map<String, dynamic>>[];
        final lessons = rows
            .where((row) => row['day_of_week'] == today)
            .toList()
          ..sort(
            (a, b) => _clock(a['starts_at']).compareTo(_clock(b['starts_at'])),
          );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'جدول محاضرات النهارده',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_days[today]} • ${now.day}/${now.month}/${now.year}',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.onOpenSchedule,
                  icon: const Icon(Icons.arrow_back_rounded, size: 15),
                  label: const Text('الجدول الكامل'),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA726).withValues(alpha: .11),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: const Color(0xFFFFA726).withValues(alpha: .25),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFFB87919),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'المواعيد الحالية تقريبية وتحتاج تأكيد الإدارة.',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF986318),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (snapshot.hasError)
              _ErrorBox(message: 'تعذر تحميل محاضرات اليوم: ${snapshot.error}')
            else if (lessons.isEmpty)
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: .6),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      color: colors.primary,
                      size: 25,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'مفيش محاضرات أو سكاشن مسجلة ليك النهارده.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...lessons.map((lesson) {
                final subjectData = lesson['subjects'];
                final subjectName = subjectData is Map
                    ? (subjectData['name_en'] ?? 'Lecture').toString()
                    : 'محاضرة';
                final groupData = lesson['groups'];
                final sectionData = lesson['sections'];
                final group = groupData is Map
                    ? (groupData['code'] ?? '').toString()
                    : '';
                final section = sectionData is Map
                    ? (sectionData['name'] ?? '').toString()
                    : '';
                final scope = [
                  group,
                  section,
                ].where((v) => v.isNotEmpty).join(' • ');
                final location =
                    (lesson['location'] ?? 'المكان غير محدد').toString();
                final instructor =
                    (lesson['instructor'] ?? 'المحاضر غير محدد').toString();
                final state = _lessonState(lesson, currentMinutes);
                final active = state == 'بدأت الآن';
                final typeLabel =
                    lesson['class_type'] == 'lecture' ? 'محاضرة' : 'سكشن';
                return Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: active
                          ? colors.primary.withValues(alpha: .55)
                          : colors.outlineVariant.withValues(alpha: .55),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 66,
                        padding: const EdgeInsets.symmetric(
                          vertical: 9,
                          horizontal: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: .09),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _clock(lesson['starts_at']),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _clock(lesson['ends_at']),
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    subjectName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? colors.primary.withValues(alpha: .12)
                                        : colors.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    state,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: active
                                          ? colors.primary
                                          : colors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 7,
                              runSpacing: 3,
                              children: [
                                Text(
                                  typeLabel,
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (scope.isNotEmpty)
                                  Text(
                                    scope,
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '$location • $instructor',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color tint;
  final VoidCallback onTap;
  const _QuickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: .6),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: tint, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData subjectIcon(String? key) => switch (key) {
      'business' => Icons.business_center_rounded,
      'language' => Icons.translate_rounded,
      'computer' => Icons.computer_rounded,
      'code' => Icons.code_rounded,
      'science' => Icons.science_rounded,
      'calculate' => Icons.functions_rounded,
      _ => Icons.menu_book_rounded,
    };
Color subjectColor(String? key) => switch (key) {
      'business' => const Color(0xFFDA9146),
      'language' => const Color(0xFF4288C7),
      'computer' => const Color(0xFF5D69D8),
      'code' => const Color(0xFF269B8C),
      'science' => const Color(0xFF45A36C),
      'calculate' => const Color(0xFF9A68C8),
      _ => const Color(0xFF6558F5),
    };

class SubjectsPage extends StatelessWidget {
  const SubjectsPage({super.key});
  @override
  Widget build(BuildContext c) => _AsyncList<Map<String, dynamic>>(
        future: AcadMindData.subjects(),
        empty: 'لا توجد مواد مضافة لحسابك بعد',
        builder: (item) {
          final tint = subjectColor(item['icon_path']?.toString());
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                subjectIcon(item['icon_path']?.toString()),
                color: tint,
                size: 25,
              ),
            ),
            title: Text(
              (item['name_en'] ?? 'Subject') as String,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              (item['description'] ?? item['code'] ?? '') as String,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.push(
              c,
              MaterialPageRoute(
                  builder: (_) => SubjectDetailPage(subject: item)),
            ),
          );
        },
      );
}

class SubjectDetailPage extends StatelessWidget {
  final Map<String,dynamic> subject;
  const SubjectDetailPage({super.key,required this.subject});
  @override Widget build(BuildContext context) => RedesignedSubjectDetailPage(subject: subject);
}


class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});
  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  static const days = [
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];
  late Future<List<Map<String, dynamic>>> future;
  int selectedDay = -1;

  @override
  void initState() {
    super.initState();
    future = loadSchedule();
    profileScopeRevision.addListener(scopeChanged);
  }

  Future<List<Map<String, dynamic>>> loadSchedule() async {
    final rows = await AcadMindData.schedule();
    await NotificationService.instance.syncSchedule(rows);
    return rows;
  }

  void reload() {
    setState(() => future = loadSchedule());
  }

  void scopeChanged() {
    if (mounted) reload();
  }

  @override
  void dispose() {
    profileScopeRevision.removeListener(scopeChanged);
    super.dispose();
  }

  String clock(Object? value) {
    final raw = (value ?? '').toString();
    return raw.length >= 5 ? raw.substring(0, 5) : raw;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 42),
                  const SizedBox(height: 12),
                  const Text('تعذر تحميل الجدول'),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: reload,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
        }

        final rows = snapshot.data ?? <Map<String, dynamic>>[];
        final filtered = selectedDay == -1
            ? rows
            : rows.where((row) => row['day_of_week'] == selectedDay).toList();
        final groupedDays = selectedDay == -1
            ? days
                .asMap()
                .entries
                .where(
                  (entry) => rows.any((row) => row['day_of_week'] == entry.key),
                )
                .toList()
            : [MapEntry(selectedDay, days[selectedDay])];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 15, 18, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'جدولي الدراسي',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'تابع محاضراتك وسكاشنك خلال الأسبوع',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: reload,
                    tooltip: 'تحديث الجدول',
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 7),
                    child: ChoiceChip(
                      label: const Text('الأسبوع'),
                      selected: selectedDay == -1,
                      onSelected: (_) => setState(() => selectedDay = -1),
                      selectedColor: colors.primaryContainer,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: selectedDay == -1
                            ? colors.onPrimaryContainer
                            : colors.onSurfaceVariant,
                      ),
                      showCheckmark: false,
                    ),
                  ),
                  ...days.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsetsDirectional.only(end: 7),
                          child: ChoiceChip(
                            label: Text(entry.value),
                            selected: selectedDay == entry.key,
                            onSelected: (_) =>
                                setState(() => selectedDay = entry.key),
                            selectedColor: colors.primaryContainer,
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: selectedDay == entry.key
                                  ? colors.onPrimaryContainer
                                  : colors.onSurfaceVariant,
                            ),
                            showCheckmark: false,
                          ),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726).withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: const Color(0xFFFFA726).withValues(alpha: .25),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFB87919),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'الجدول مضاف كتوقيت مبدئي؛ راجع الإدارة قبل الاعتماد النهائي.',
                        style: TextStyle(
                          color: Color(0xFF986318),
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: rows.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(23),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: colors.outlineVariant.withValues(
                                alpha: .6,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: .10),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Icon(
                                  Icons.calendar_month_rounded,
                                  color: colors.primary,
                                  size: 35,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'جدولك لسه ما اتضافش',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'اختيارك للمجموعة والسكشن اتحفظ. أول ما الإدارة تضيف المواعيد هتظهر هنا تلقائيًا.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 12,
                                  height: 1.7,
                                ),
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: reload,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('تحديث الجدول'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(26),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.event_available_rounded,
                                  size: 40,
                                  color: colors.onSurfaceVariant,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'مفيش محاضرات يوم ' + days[selectedDay],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 9, 16, 28),
                          children: [
                            ...groupedDays.map((entry) {
                              final dayRows = rows
                                  .where(
                                    (row) => row['day_of_week'] == entry.key,
                                  )
                                  .toList()
                                ..sort(
                                  (a, b) => clock(a['starts_at'])
                                      .compareTo(clock(b['starts_at'])),
                                );
                              if (dayRows.isEmpty)
                                return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 23,
                                          decoration: BoxDecoration(
                                            color: colors.primary,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        const SizedBox(width: 9),
                                        Text(
                                          entry.value,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          dayRows.length.toString() + ' محاضرة',
                                          style: TextStyle(
                                            color: colors.onSurfaceVariant,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ...dayRows.map(
                                      (item) => _ScheduleLessonCard(
                                        item: item,
                                        time: clock(item['starts_at']) +
                                            ' – ' +
                                            clock(item['ends_at']),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
            ),
          ],
        );
      },
    );
  }
}

class _NotificationBell extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  const _NotificationBell({required this.onNavigate});

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  Future<int> _unreadCount() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return 0;
    final rows = await supabase
        .from('user_notifications')
        .select('id,type')
        .eq('user_id', uid)
        .eq('is_read', false)
        .limit(100);
    var count = 0;
    for (final row in rows) {
      if (await NotificationService.instance
          .isNotificationTypeEnabled((row['type'] ?? 'general').toString())) {
        count++;
      }
    }
    return count;
  }

  void _open() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationCenterPage(onNavigate: widget.onNavigate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FutureBuilder<int>(
      future: _unreadCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Material(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _open,
            child: Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: .65),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Icon(
                      count > 0
                          ? Icons.notifications_rounded
                          : Icons.notifications_none_rounded,
                      color: colors.onSurface,
                      size: 21,
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: -3,
                      top: -5,
                      child: Container(
                        constraints:
                            const BoxConstraints(minWidth: 17, minHeight: 17),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: colors.error,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScheduleLessonCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String time;
  const _ScheduleLessonCard({required this.item, required this.time});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final subject = item['subjects'] is Map
        ? (item['subjects']['name_en'] ?? 'Lecture').toString()
        : 'محاضرة';
    final location = (item['location'] ?? 'المكان غير محدد').toString();
    final instructor = (item['instructor'] ?? 'المحاضر غير محدد').toString();
    final isLecture = item['class_type'] == 'lecture';
    final tint = isLecture ? const Color(0xFF5964D8) : const Color(0xFF21978D);
    final group = item['groups'] is Map
        ? (item['groups']['code'] ?? item['groups']['name'] ?? '').toString()
        : '';
    final section = item['sections'] is Map
        ? (item['sections']['name'] ?? '').toString()
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 49,
            height: 55,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isLecture ? Icons.menu_book_rounded : Icons.groups_rounded,
              color: tint,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      time,
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (group.isNotEmpty || section.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          [
                            group,
                            section,
                          ].where((v) => v.isNotEmpty).join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 12,
                  runSpacing: 5,
                  children: [
                    _ScheduleMeta(
                      icon: Icons.location_on_outlined,
                      value: location,
                    ),
                    _ScheduleMeta(
                      icon: Icons.person_outline_rounded,
                      value: instructor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleMeta extends StatelessWidget {
  final IconData icon;
  final String value;
  const _ScheduleMeta({required this.icon, required this.value});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 185),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
}

class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({super.key});
  @override
  Widget build(BuildContext c) => _AsyncList<Map<String, dynamic>>(
        future: AcadMindData.announcements(),
        empty: 'لا توجد إعلانات حالياً',
        builder: (e) => _AnnouncementCard(item: e),
      );
}

class _AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _AnnouncementCard({required this.item});
  @override
  Widget build(BuildContext c) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign, color: Color(0xFF3157D5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (item['title'] ?? 'إعلان') as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    '${item['priority'] ?? 0}/5',
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text((item['content'] ?? '') as String),
              const SizedBox(height: 5),
              Text(
                (item['published_at'] ?? '') as String,
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        ),
      );
}

class AiPage extends StatefulWidget {
  const AiPage({super.key});
  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final input = TextEditingController();
  final scroll = ScrollController();
  final messages = <Map<String, dynamic>>[];
  bool busy = false;
  String? subjectId;
  String? conversationId;
  late Future<List<Map<String, dynamic>>> subjectFuture;

  @override
  void initState() {
    super.initState();
    subjectFuture = supabase
        .from('subjects')
        .select('id,name_en')
        .eq('is_active', true)
        .isFilter('deleted_at', null)
        .order('name_en')
        .then((v) => List<Map<String, dynamic>>.from(v));
  }

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients)
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
    });
  }

  void _newChat() {
    if (busy) return;
    setState(() {
      messages.clear();
      conversationId = null;
    });
  }

  Future<void> _sendPrompt(String prompt) async {
    input.text = prompt;
    await send();
  }

  Future<void> _openHistory() async {
    if (busy) return;
    try {
      final rows = await supabase
          .from('ai_conversations')
          .select('id,title,subject_id,updated_at')
          .isFilter('deleted_at', null)
          .order('updated_at', ascending: false)
          .limit(40);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * .72,
            child: rows.isEmpty
                ? const Center(child: Text('لا توجد محادثات محفوظة بعد'))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'سجل المحادثات',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      ...rows.map((raw) {
                        final row = Map<String, dynamic>.from(raw);
                        final id = row['id'].toString();
                        final title =
                            (row['title'] ?? 'محادثة جديدة').toString();
                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.chat_bubble_outline_rounded),
                            ),
                            title: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              (row['updated_at'] ?? '').toString(),
                            ),
                            onTap: () async {
                              Navigator.pop(sheetContext);
                              await _restoreConversation(row);
                            },
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) async {
                                if (action == 'rename')
                                  await _renameConversation(id, title);
                                if (action == 'delete')
                                  await _deleteConversation(id);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'rename',
                                  child: Text('إعادة تسمية'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('حذف'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ),
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر تحميل سجل المحادثات. حاول مرة أخرى.'),
          ),
        );
    }
  }

  Future<void> _restoreConversation(Map<String, dynamic> conversation) async {
    try {
      final id = conversation['id'].toString();
      final rows = await supabase
          .from('ai_messages')
          .select('role,content,sources,created_at')
          .eq('conversation_id', id)
          .order('created_at');
      if (!mounted) return;
      setState(() {
        conversationId = id;
        subjectId = conversation['subject_id']?.toString();
        messages
          ..clear()
          ..addAll(
            rows.map((raw) {
              final row = Map<String, dynamic>.from(raw);
              final sources = row['sources'];
              return <String, dynamic>{
                'role': row['role'],
                'content': row['content'],
                'sources': sources is List
                    ? sources
                        .whereType<Map>()
                        .map((source) => Map<String, dynamic>.from(source))
                        .toList()
                    : <Map<String, dynamic>>[],
              };
            }),
          );
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر استعادة المحادثة.')));
    }
  }

  Future<void> _renameConversation(String id, String currentTitle) async {
    final controller = TextEditingController(text: currentTitle);
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إعادة تسمية المحادثة'),
        content: TextField(
          controller: controller,
          maxLength: 90,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'اسم المحادثة'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty) return;
    try {
      await supabase
          .from('ai_conversations')
          .update({'title': title}).eq('id', id);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تحديث اسم المحادثة')));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحديث اسم المحادثة')),
        );
    }
  }

  Future<void> _deleteConversation(String id) async {
    try {
      await supabase
          .from('ai_conversations')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()}).eq(
              'id', id);
      if (conversationId == id && mounted) _newChat();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المحادثة من السجل')),
        );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذر حذف المحادثة')));
    }
  }

  Future<void> send() async {
    final question = input.text.trim();
    if (question.isEmpty || busy) return;
    final session = supabase.auth.currentSession;
    if (session == null) {
      setState(() {
        messages.add({'role': 'user', 'content': question});
        messages.add({
          'role': 'assistant',
          'content':
              'جلسة الدخول غير موجودة. سجّل الدخول مرة أخرى علشان تقدر تستخدم المساعد.',
          'sources': [],
        });
      });
      input.clear();
      _scrollToBottom();
      return;
    }
    setState(() {
      messages.add({'role': 'user', 'content': question});
      busy = true;
    });
    input.clear();
    _scrollToBottom();
    try {
      final response = await supabase.functions.invoke(
        'ai-chat',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
        body: {
          'question': question,
          'subjectId': subjectId,
          'conversationId': conversationId,
          'retrieve': subjectId != null,
        },
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final answer = (data['answer'] ??
              data['message'] ??
              data['error'] ??
              'لم يصل رد من المساعد.')
          .toString();
      final sources = List<Map<String, dynamic>>.from(
        (data['sources'] as List? ?? const []).whereType<Map>().map(
              (e) => Map<String, dynamic>.from(e),
            ),
      );
      if (mounted) {
        setState(() {
          conversationId = data['conversationId']?.toString() ?? conversationId;
          messages.add({
            'role': 'assistant',
            'content': answer,
            'sources': sources,
          });
        });
        _scrollToBottom();
      }
    } on FunctionException catch (e) {
      if (mounted) {
        final detail = e.details;
        final detailText = detail is Map
            ? (detail['error'] ?? detail['message'] ?? '').toString()
            : (detail?.toString() ?? '');
        final readable = e.status == 401
            ? 'جلسة الدخول غير موجودة أو انتهت. سجّل الخروج ثم ادخل إلى حسابك مرة أخرى.'
            : (e.status == 504
                ? 'خدمة Gemini اتأخرت في الرد. جرّب سؤالًا أقصر بعد لحظات.'
                : ((e.status == 502 || e.status == 503)
                    ? 'المساعد مضغوط مؤقتًا ولم ينجح الاتصال بالنموذج الاحتياطي. جرّب مرة أخرى بعد لحظات.'
                : (detailText.contains('GEMINI_API_KEY') ||
                        detailText.toLowerCase().contains('not configured')
                    ? 'خدمة الذكاء الاصطناعي غير مهيأة على الخادم بعد. راجع إعداد GEMINI_API_KEY في Supabase Secrets.'
                    : (detailText.isEmpty
                        ? (e.reasonPhrase ?? 'حاول مرة أخرى.')
                        : detailText))));
        setState(
          () => messages.add({
            'role': 'assistant',
            'content': 'تعذر تشغيل المساعد: ' + readable,
            'sources': [],
          }),
        );
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => messages.add({
            'role': 'assistant',
            'content': 'حدث خطأ أثناء الاتصال بالمساعد. حاول مرة أخرى.',
            'sources': [],
          }),
        );
        _scrollToBottom();
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(15, 13, 8, 13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [colors.primary, colors.primary.withValues(alpha: .78)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: .16),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AcadMind AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'مساعدك الدراسي الذكي',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _openHistory,
                  tooltip: 'سجل المحادثات',
                  icon: const Icon(Icons.history_rounded, color: Colors.white),
                ),
                IconButton(
                  onPressed: _newChat,
                  tooltip: 'محادثة جديدة',
                  icon: const Icon(
                    Icons.add_comment_outlined,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: subjectFuture,
            builder: (context, snapshot) => DropdownButtonFormField<String>(
              value: subjectId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'المادة الدراسية',
                prefixIcon: Icon(Icons.menu_book_rounded),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('سؤال عام — كل المواد'),
                ),
                ...(snapshot.data ?? []).map(
                  (item) => DropdownMenuItem<String>(
                    value: '${item['id']}',
                    child: Text('${item['name_en']}'),
                  ),
                ),
              ],
              onChanged: busy
                  ? null
                  : (value) {
                      setState(() {
                        subjectId = value;
                        conversationId = null;
                        messages.clear();
                      });
                    },
            ),
          ),
        ),
        Expanded(
          child: messages.isEmpty
              ? _ChatWelcome(onPrompt: _sendPrompt)
              : ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                  itemCount: messages.length + (busy ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length)
                      return const _TypingIndicator();
                    return _ChatBubble(message: messages[index], index: index);
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 7, 7, 7),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: .65),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .035),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => send(),
                      decoration: const InputDecoration(
                        hintText: 'اسأل عن محاضرة أو مفهوم...',
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 46,
                    height: 46,
                    child: IconButton.filled(
                      onPressed: busy ? null : send,
                      tooltip: 'إرسال',
                      icon: const Icon(Icons.arrow_upward_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatWelcome extends StatelessWidget {
  final ValueChanged<String> onPrompt;
  const _ChatWelcome({required this.onPrompt});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final suggestions = [
      ('اشرحلي موضوع صعب', Icons.lightbulb_outline_rounded),
      ('لخصلي المحاضرة', Icons.summarize_rounded),
      ('اعمللي أسئلة للمراجعة', Icons.quiz_outlined),
      ('نظملي خطة مذاكرة', Icons.event_note_rounded),
    ];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .75, end: 1),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutBack,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.primary, colors.tertiary],
                  ),
                  borderRadius: BorderRadius.circular(27),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: .20),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 39,
                ),
              ),
            ),
            const SizedBox(height: 21),
            const Text(
              'ابدأ سؤالك مع AcadMind',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'اسأل، افهم، ولخّص. اختار مادة علشان المساعد يقدر يرجع لمصادرها ومحاضراتها.',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.6,
                color: colors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 23),
            ...suggestions.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Material(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onPrompt(item.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: .65),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(item.$2, color: colors.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.$1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 14,
                            color: colors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'قد يخطئ الذكاء الاصطناعي؛ راجع المعلومات المهمة من مصادرها.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final int index;
  const _ChatBubble({required this.message, required this.index});

  @override
  Widget build(BuildContext context) {
    final isUser = message['role'] == 'user';
    final colors = Theme.of(context).colorScheme;
    final sources = (message['sources'] as List? ?? const []);
    return TweenAnimationBuilder<double>(
      key: ValueKey('chat-$index'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: Align(
        alignment: isUser
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * .86,
          ),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
          decoration: BoxDecoration(
            color: isUser ? colors.primary : Theme.of(context).cardColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(19),
              topRight: const Radius.circular(19),
              bottomLeft: Radius.circular(isUser ? 19 : 5),
              bottomRight: Radius.circular(isUser ? 5 : 19),
            ),
            border: isUser
                ? null
                : Border.all(
                    color: colors.outlineVariant.withValues(alpha: .55),
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .025),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 15,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'إجابة AcadMind',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 30,
                          height: 30,
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: 'نسخ الإجابة',
                        icon: Icon(
                          Icons.copy_rounded,
                          size: 15,
                          color: colors.onSurfaceVariant,
                        ),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: message['content'].toString()),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم نسخ الإجابة')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              if (isUser)
                Text(
                  message['content'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.55,
                    fontSize: 14,
                  ),
                )
              else
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: MarkdownBody(
                    data: message['content'] as String,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                        .copyWith(
                      p: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.75, fontSize: 14),
                      h1: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.45,
                          ),
                      h2: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.45,
                          ),
                      h3: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.4,
                          ),
                      listBullet: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                      code: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: colors.primary,
                        backgroundColor: colors.surfaceContainerHighest,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(
                            alpha: .7,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (sources.isNotEmpty) ...[
                const SizedBox(height: 9),
                Divider(height: 1, color: colors.outlineVariant),
                const SizedBox(height: 8),
                Text(
                  'المصادر المستخدمة',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                ...sources.map(
                  (source) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '• ${source['documentName'] ?? 'ملف المادة'}${source['page'] == null ? '' : ' — صفحة ${source['page']}'}',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'AcadMind بيجهز الإجابة...',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = AcadMindData.profile();
  }

  void reload() {
    if (mounted) setState(() => future = AcadMindData.profile());
  }

  String related(Map<String, dynamic> profile, String key) {
    final item = profile[key];
    if (item is! Map) return '';
    return (item['name_ar'] ?? item['code'] ?? item['name'] ?? '').toString();
  }

  Future<void> editProfile(Map<String, dynamic> profile) async {
    final name = TextEditingController(
      text: (profile['full_name'] ?? '').toString(),
    );
    final phone = TextEditingController(
      text: (profile['phone'] ?? '').toString(),
    );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل بيانات الحساب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'الاسم بالكامل'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم الهاتف'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('اكتب الاسم الأول')),
                );
                return;
              }
              try {
                await supabase.from('profiles').update({
                  'full_name': name.text.trim(),
                  'phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
                }).eq('id', supabase.auth.currentUser!.id);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                reload();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث بيانات الحساب')),
                );
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('تعذر حفظ البيانات: ' + e.toString()),
                    ),
                  );
                }
              }
            },
            child: const Text('حفظ التغييرات'),
          ),
        ],
      ),
    );
    name.dispose();
    phone.dispose();
  }

  bool get _isAnonymousSession {
    final token = supabase.auth.currentSession?.accessToken;
    if (token == null) return false;
    final parts = token.split('.');
    if (parts.length != 3) return false;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return payload is Map && payload['is_anonymous'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> upgradeGuestAccount() async {
    final name = TextEditingController();
    final emailInput = TextEditingController();
    final otp = TextEditingController();
    final password = TextEditingController();
    final confirm = TextEditingController();
    final userId = supabase.auth.currentUser?.id;
    var phase = 0;
    var busy = false;

    if (userId == null || !_isAnonymousSession) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            phase == 0 ? 'حفظ حساب الضيف' : 'تأكيد البريد وإنشاء كلمة المرور',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: phase == 0
                  ? [
                      const Text(
                        'هنحوّل حساب الضيف الحالي إلى حساب دائم مع الاحتفاظ بنفس الجدول والمجموعة والسكشن.',
                        style: TextStyle(fontSize: 12, height: 1.6),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: name,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'الاسم بالكامل',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emailInput,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'هنرسل لك رمز تأكيد من 6 أرقام. لازم تأكد البريد قبل إنشاء كلمة المرور.',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),
                    ]
                  : [
                      const Text(
                        'اكتب رمز التأكيد المرسل إلى بريدك، وبعدها اختار كلمة مرور لتسجيل الدخول مستقبلاً.',
                        style: TextStyle(fontSize: 12, height: 1.6),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: otp,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'رمز التأكيد (6 أرقام)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'كلمة المرور الجديدة',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: confirm,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'تأكيد كلمة المرور',
                        ),
                      ),
                    ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (phase == 0) {
                        final emailValue = emailInput.text.trim();
                        if (name.text.trim().isEmpty ||
                            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(emailValue)) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'اكتب اسمك وبريدًا إلكترونيًا صحيحًا.',
                              ),
                            ),
                          );
                          return;
                        }
                      } else if (otp.text.trim().length < 6 ||
                          password.text.length < 8 ||
                          password.text != confirm.text) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تأكد من رمز التأكيد، وأن كلمة المرور 8 أحرف على الأقل ومتطابقة.',
                            ),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => busy = true);
                      try {
                        if (phase == 0) {
                          await supabase.auth.updateUser(
                            UserAttributes(
                              email: emailInput.text.trim(),
                              data: {'full_name': name.text.trim()},
                            ),
                          );
                          if (!dialogContext.mounted) return;
                          setDialogState(() => phase = 1);
                        } else {
                          final verification = await supabase.auth.verifyOTP(
                            type: OtpType.emailChange,
                            email: emailInput.text.trim(),
                            token: otp.text.trim(),
                          );
                          final verifiedUser =
                              verification.user ?? supabase.auth.currentUser;
                          if (verifiedUser == null ||
                              verifiedUser.id != userId) {
                            throw Exception(
                              'تعذر تأكيد نفس حساب الضيف. لم يتم تغيير الحساب.',
                            );
                          }

                          await supabase.auth.updateUser(
                            UserAttributes(
                              password: password.text,
                              data: {'full_name': name.text.trim()},
                            ),
                          );

                          await supabase.from('profiles').update({
                            'full_name': name.text.trim(),
                            'email': emailInput.text.trim(),
                            'updated_at':
                                DateTime.now().toUtc().toIso8601String(),
                          }).eq('id', userId);

                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          reload();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'تم تأمين حسابك بنجاح، وبياناتك الدراسية محفوظة كما هي.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      } on AuthException catch (e) {
                        final detail = e.message
                                .toLowerCase()
                                .contains('manual linking')
                            ? 'فعّل Manual Linking من إعدادات Authentication في Supabase، ثم حاول مرة أخرى.'
                            : e.message;
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text('تعذر إكمال العملية: $detail'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text('تعذر إكمال العملية: $e')),
                          );
                        }
                      } finally {
                        if (dialogContext.mounted)
                          setDialogState(() => busy = false);
                      }
                    },
              child: busy
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      phase == 0 ? 'إرسال رمز التأكيد' : 'تأكيد وإنشاء الحساب',
                    ),
            ),
          ],
        ),
      ),
    );

    name.dispose();
    emailInput.dispose();
    otp.dispose();
    password.dispose();
    confirm.dispose();
  }

  Future<void> changePassword() async {
    final password = TextEditingController();
    final confirm = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الجديدة',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              if (password.text.length < 8 || password.text != confirm.text) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'تأكد من تطابق كلمتي المرور وأن تكون 8 أحرف على الأقل',
                    ),
                  ),
                );
                return;
              }
              try {
                await supabase.auth.updateUser(
                  UserAttributes(password: password.text),
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')),
                );
              } on AuthException catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(SnackBar(content: Text(e.message)));
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('تعذر تغيير كلمة المرور: ' + e.toString()),
                    ),
                  );
                }
              }
            },
            child: const Text('تحديث كلمة المرور'),
          ),
        ],
      ),
    );
    password.dispose();
    confirm.dispose();
  }

  Future<void> openAcademicSetup() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const StudentSetupScreen(forceEdit: true),
      ),
    );
    if (changed == true) reload();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off_rounded, size: 42),
                  const SizedBox(height: 12),
                  const Text('مش قادرين نحمّل بيانات الحساب'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: reload,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
        }

        final p = snapshot.data!;
        final isGuest = _isAnonymousSession;
        final authUser = supabase.auth.currentUser;
        final fullName = (p['full_name'] ?? '').toString().trim();
        final displayName = fullName.isEmpty ? 'طالب AcadMind' : fullName;
        final email = (authUser?.email ??
                p['email'] ??
                (isGuest ? 'حساب ضيف' : 'غير متاح'))
            .toString();
        final year = related(p, 'academic_years');
        final group = related(p, 'groups');
        final section = related(p, 'sections');
        final scope = [
          group,
          section,
        ].where((value) => value.isNotEmpty).join(' • ');
        final isOwner = p['role'] == 'owner';
        final initial = displayName.isEmpty ? 'A' : displayName.substring(0, 1);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 34),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'حسابي',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: reload,
                    tooltip: 'تحديث البيانات',
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color(0xFF171A3D),
                      Color(0xFF39328F),
                      Color(0xFF6255E8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5145D6).withValues(alpha: .15),
                      blurRadius: 22,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 31,
                      backgroundColor: Colors.white.withValues(alpha: .16),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isOwner
                                  ? 'مالك النظام'
                                  : (isGuest ? 'حساب ضيف' : 'حساب طالب'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              const _AccountHeading(
                title: 'البيانات الشخصية',
                subtitle: 'معلومات حسابك في AcadMind',
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    _AccountInfoTile(
                      icon: Icons.alternate_email_rounded,
                      title: 'البريد الإلكتروني',
                      value: email,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _AccountInfoTile(
                      icon: Icons.phone_rounded,
                      title: 'رقم الهاتف',
                      value: (p['phone'] ?? '').toString().isEmpty
                          ? 'غير مضاف'
                          : p['phone'].toString(),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _AccountInfoTile(
                      icon: Icons.school_rounded,
                      title: 'السنة الدراسية',
                      value: year.isEmpty ? 'لم يتم التحديد' : year,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _AccountInfoTile(
                      icon: Icons.verified_user_outlined,
                      title: 'حالة الحساب',
                      value: (p['status'] ?? 'غير معروف').toString() +
                          ' • ' +
                          (p['role'] ?? 'student').toString(),
                    ),
                  ],
                ),
              ),
              if (isGuest) ...[
                const SizedBox(height: 18),
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFECEBFF),
                      child: Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF5145D6),
                      ),
                    ),
                    title: const Text(
                      'احفظ حسابك ولا تفقد بياناتك',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: const Text(
                      'اربط بريدك الإلكتروني بحساب الضيف واحتفظ بجدولك ومجموعتك والسكشن.',
                      style: TextStyle(fontSize: 10, height: 1.5),
                    ),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: upgradeGuestAccount,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              const _AccountHeading(
                title: 'بياناتك الأكاديمية',
                subtitle: 'المجموعة والسكشن المستخدمان في عرض الجدول',
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6255E8)
                                  .withValues(alpha: .11),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.groups_rounded,
                              color: Color(0xFF6255E8),
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'المجموعة والسكشن',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  scope.isEmpty ? 'لم يتم تحديدهما بعد' : scope,
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!isOwner) ...[
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: openAcademicSetup,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('تغيير المجموعة والسكشن'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const _AccountHeading(
                title: 'إعدادات التطبيق',
                subtitle: 'خصص تجربة الاستخدام',
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 39,
                        height: 39,
                        decoration: BoxDecoration(
                          color: const Color(0xFF299B91).withValues(alpha: .11),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.dark_mode_outlined,
                          color: Color(0xFF299B91),
                        ),
                      ),
                      const SizedBox(width: 11),
                      const Expanded(
                        child: Text(
                          'مظهر التطبيق',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DropdownButton<ThemeMode>(
                        value: appThemeMode.value,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('تلقائي'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('فاتح'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('داكن'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) saveThemeMode(value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text(
                    'إعدادات الإشعارات',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'وقت تذكير المحاضرات وإشعارات المحتوى والتحديثات',
                  ),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationSettingsPage(),
                    ),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text(
                    'حول التطبيق',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('فريق التطوير ومعلومات الإصدار'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: const Text(
                    'اقتراح أو الإبلاغ عن مشكلة',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('ساعدنا نطوّر AcadMind'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => editProfile(p),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('تعديل بياناتي'),
                ),
              ),
              const SizedBox(height: 9),
              if (!isGuest && email.isNotEmpty && email != 'غير متاح')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: changePassword,
                    icon: const Icon(Icons.lock_reset_rounded),
                    label: const Text('تغيير كلمة المرور'),
                  ),
                ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await supabase.auth.signOut();
                      if (!mounted) return;
                      // The app may have been opened from a pushed login route.
                      // Remove that protected route so the signed-out root gate is visible.
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).popUntil((route) => route.isFirst);
                    } on AuthException catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تعذر تسجيل الخروج: ${error.message}',
                            ),
                          ),
                        );
                      }
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تعذر تسجيل الخروج: $error')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('تسجيل الخروج'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                    side: BorderSide(
                      color: colors.error.withValues(alpha: .35),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'AcadMind • YOUR SMART ACADEMIC COMPANION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant.withValues(alpha: .7),
                    fontSize: 9,
                    letterSpacing: .7,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AccountHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  const _AccountHeading({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
}

class _AccountInfoTile extends StatelessWidget {
  final IconData icon;
  final String title, value;
  const _AccountInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        dense: true,
      );
}

class OwnerPage extends StatelessWidget {
  const OwnerPage({super.key});
  @override
  Widget build(BuildContext context) => const OwnerConsole();
}

class _AsyncList<T> extends StatelessWidget {
  final Future<List<T>> future;
  final String empty;
  final Widget Function(T) builder;
  const _AsyncList({
    required this.future,
    required this.empty,
    required this.builder,
  });
  @override
  Widget build(BuildContext c) => FutureBuilder<List<T>>(
        future: future,
        builder: (c, s) {
          if (s.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (s.hasError)
            return _ErrorBox(message: 'تعذر تحميل البيانات: ${s.error}');
          final list = s.data ?? [];
          if (list.isEmpty) return _EmptyBox(text: empty);
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (c, i) => Card(child: builder(list[i])),
          );
        },
      );
}

class _EmptyBox extends StatelessWidget {
  final String text;
  const _EmptyBox({required this.text});
  @override
  Widget build(BuildContext c) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      );
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});
  @override
  Widget build(BuildContext c) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(c).colorScheme.error),
          ),
        ),
      );
}

class _HomeNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int index;
  const _HomeNavItem(this.icon, this.selectedIcon, this.label, this.index);
}

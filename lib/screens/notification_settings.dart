import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../notification_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool before = true;
  bool start = true;
  bool academic = true;
  bool announcements = true;
  bool materials = true;
  bool lectures = true;
  bool videos = true;
  bool updates = true;
  int minutes = 10;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      before = p.getBool('notification_lecture_before_enabled') ?? true;
      start = p.getBool('notification_class_start_enabled') ?? true;
      academic = p.getBool('notification_academic_events_enabled') ?? true;
      announcements = p.getBool('notification_announcements_enabled') ?? true;
      materials = p.getBool('notification_materials_enabled') ?? true;
      lectures = p.getBool('notification_lectures_enabled') ?? true;
      videos = p.getBool('notification_videos_enabled') ?? true;
      updates = p.getBool('notification_updates_enabled') ?? true;
      minutes = p.getInt('notification_reminder_minutes') ?? 10;
    });
  }

  Future<void> _save() async {
    setState(() => saving = true);
    final p = await SharedPreferences.getInstance();
    await p.setBool('notification_lecture_before_enabled', before);
    await p.setBool('notification_class_start_enabled', start);
    await p.setBool('notification_academic_events_enabled', academic);
    await p.setBool('notification_announcements_enabled', announcements);
    await p.setBool('notification_materials_enabled', materials);
    await p.setBool('notification_lectures_enabled', lectures);
    await p.setBool('notification_videos_enabled', videos);
    await p.setBool('notification_updates_enabled', updates);
    await p.setInt('notification_reminder_minutes', minutes);

    try {
      await NotificationService.instance.initialize();
    } catch (_) {}

    if (!mounted) return;
    setState(() => saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ إعدادات الإشعارات')),
    );
  }

  Widget _section(String title, String subtitle) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );

  Widget _toggle(String title, String subtitle, bool value,
      ValueChanged<bool> onChanged, IconData icon) {
    return Card(
      child: SwitchListTile.adaptive(
        secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 10)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'حفظ',
            onPressed: saving ? null : _save,
            icon: saving
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator())
                : const Icon(Icons.save_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
        children: [
          _section('Class Reminders', 'تحكم في تنبيهات المحاضرات والسكاشن'),
          _toggle('Reminder before class', 'تنبيه قبل بداية الحصة', before,
              (v) => setState(() => before = v), Icons.alarm_rounded),
          if (before)
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Reminder time',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    DropdownButton<int>(
                      value: [5, 10, 15, 30].contains(minutes) ? minutes : 10,
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5 min')),
                        DropdownMenuItem(value: 10, child: Text('10 min')),
                        DropdownMenuItem(value: 15, child: Text('15 min')),
                        DropdownMenuItem(value: 30, child: Text('30 min')),
                      ],
                      onChanged: (v) => setState(() => minutes = v ?? 10),
                    ),
                  ],
                ),
              ),
            ),
          _toggle('Class starts now', 'إشعار عند بداية Lecture / Section / Practical',
              start, (v) => setState(() => start = v), Icons.play_arrow_rounded),
          _section('Academic Events', 'الامتحانات والواجبات والاختبارات'),
          _toggle('Academic reminders', 'تفعيل تذكيرات الأحداث الأكاديمية',
              academic, (v) => setState(() => academic = v), Icons.school_rounded),
          _section('AcadMind Updates', 'التحديثات والمحتوى الجديد'),
          _toggle('Announcements', 'إشعارات إعلانات الإدارة', announcements,
              (v) => setState(() => announcements = v), Icons.campaign_rounded),
          _toggle('New materials', 'إشعار عند إضافة مادة جديدة', materials,
              (v) => setState(() => materials = v), Icons.folder_open_rounded),
          _toggle('New lectures', 'إشعار عند إضافة Lecture جديدة', lectures,
              (v) => setState(() => lectures = v), Icons.menu_book_rounded),
          _toggle('New YouTube explanations', 'إشعار عند إضافة شرح جديد',
              videos, (v) => setState(() => videos = v), Icons.play_circle_rounded),
          _toggle('App updates', 'إشعار عند توفر إصدار جديد', updates,
              (v) => setState(() => updates = v), Icons.system_update_rounded),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: saving ? null : _save,
            icon: const Icon(Icons.save_rounded),
            label: const Text('حفظ الإعدادات'),
          ),
        ],
      ),
    );
  }
}

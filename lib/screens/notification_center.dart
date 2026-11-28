import 'package:flutter/material.dart';
import '../backend.dart';

class NotificationCenterPage extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const NotificationCenterPage({super.key, this.onNavigate});

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await supabase
        .from('user_notifications')
        .select('id,type,title,body,route,data,is_read,created_at')
        .order('created_at', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _markAll() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    await supabase
        .from('user_notifications')
        .update({'is_read': true})
        .eq('user_id', uid);
    if (mounted) setState(() => future = _load());
  }

  Future<void> _open(Map<String, dynamic> item) async {
    try {
      await supabase
          .from('user_notifications')
          .update({'is_read': true})
          .eq('id', item['id']);
    } catch (_) {}

    if (!mounted) return;
    final route = (item['route'] ?? '').toString();
    final target = switch (route) {
      '/subjects' || '/subject' || '/material' => 1,
      '/schedule' || '/lecture' => 2,
      '/announcements' || '/announcement' => 3,
      '/ai' || '/ai/result' => 4,
      '/study-tools' || '/tools' => 6,
      _ => -1,
    };

    if (target >= 0 && widget.onNavigate != null) {
      Navigator.pop(context);
      widget.onNavigate!(target);
      return;
    }

    setState(() => future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          TextButton(
            onPressed: _markAll,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (c, s) {
          if (s.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.hasError) {
            return Center(
              child: Text('Unable to load notifications',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            );
          }

          final rows = s.data ?? [];
          if (rows.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 52),
                  SizedBox(height: 12),
                  Text('No notifications yet',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 9),
            itemBuilder: (c, i) {
              final x = rows[i];
              final unread = x['is_read'] != true;
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _open(x),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: unread
                        ? cs.primaryContainer.withValues(alpha: .34)
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: unread
                          ? cs.primary.withValues(alpha: .2)
                          : cs.outlineVariant.withValues(alpha: .5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(_iconFor(x['type'].toString()),
                            color: cs.primary),
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
                                    x['title'].toString(),
                                    style: TextStyle(
                                      fontWeight: unread
                                          ? FontWeight.w900
                                          : FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (unread)
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: cs.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              x['body'].toString(),
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _date(x['created_at'].toString()),
                              style: TextStyle(
                                fontSize: 9,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) => switch (type) {
        'lecture' => Icons.schedule_rounded,
        'material' => Icons.folder_open_rounded,
        'video' => Icons.play_circle_outline_rounded,
        'ai' => Icons.auto_awesome_rounded,
        'announcement' => Icons.campaign_rounded,
        'update' => Icons.system_update_rounded,
        'exam' => Icons.school_rounded,
        'assignment' || 'deadline' => Icons.assignment_rounded,
        'quiz' => Icons.quiz_rounded,
        _ => Icons.notifications_rounded,
      };

  String _date(String value) {
    final d = DateTime.tryParse(value)?.toLocal();
    if (d == null) return '';
    final now = DateTime.now();
    final difference = now.difference(d);
    if (difference.inMinutes < 1) return 'الآن';
    if (difference.inMinutes < 60) return 'منذ ${difference.inMinutes} دقيقة';
    if (difference.inHours < 24) return 'منذ ${difference.inHours} ساعة';
    if (difference.inDays < 7) return 'منذ ${difference.inDays} يوم';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _scheduleIdsKey = 'acadmind_schedule_notification_ids';
  static const _eventIdsKey = 'acadmind_academic_notification_ids';

  Future<void> initialize() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  int _stableId(String value) => value.codeUnits.fold<int>(
        0,
        (sum, unit) => (sum * 31 + unit) & 0x7fffffff,
      );

  Future<bool> _enabled(String key, bool fallback) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? fallback;
  }

  Future<int> _reminderMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('notification_reminder_minutes') ?? 10;
  }

  Future<bool> isNotificationTypeEnabled(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = switch (type) {
      'announcement' => 'notification_announcements_enabled',
      'material' => 'notification_materials_enabled',
      'lecture' => 'notification_lectures_enabled',
      'video' => 'notification_videos_enabled',
      'update' => 'notification_updates_enabled',
      'exam' || 'assignment' || 'deadline' || 'quiz' =>
        'notification_academic_events_enabled',
      _ => null,
    };
    return key == null ? true : (prefs.getBool(key) ?? true);
  }

  Future<void> _cancelStoredIds(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(key) ?? const <String>[];
    for (final raw in ids) {
      final id = int.tryParse(raw);
      if (id != null) await _plugin.cancel(id);
    }
    await prefs.remove(key);
  }

  Future<void> _saveIds(String key, List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      key,
      ids.map((id) => id.toString()).toList(),
    );
  }

  Future<void> syncSchedule(List<Map<String, dynamic>> rows) async {
    await initialize();

    // Never use cancelAll() here: it would erase AI, announcement and
    // academic-event notifications. Cancel only the IDs owned by Schedule.
    await _cancelStoredIds(_scheduleIdsKey);

    final prefs = await SharedPreferences.getInstance();
    final beforeEnabled =
        prefs.getBool('notification_lecture_before_enabled') ?? true;
    final startEnabled =
        prefs.getBool('notification_class_start_enabled') ?? true;
    final reminderMinutes =
        prefs.getInt('notification_reminder_minutes') ?? 10;

    const beforeDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'acadmind_lecture_before',
        'تذكير قبل المحاضرة',
        channelDescription: 'تنبيه قبل المحاضرة أو السكشن قبل الموعد المحدد',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    const startDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'acadmind_lecture_start',
        'بداية المحاضرة',
        channelDescription: 'تنبيه عند موعد بداية المحاضرة أو السكشن',
        importance: Importance.max,
        priority: Priority.max,
      ),
      iOS: DarwinNotificationDetails(),
    );

    if (!beforeEnabled && !startEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    final scheduledIds = <int>[];

    for (final row in rows) {
      if (row['is_active'] == false || row['deleted_at'] != null) continue;

      final day = (row['day_of_week'] as num?)?.toInt();
      final startsAt = row['starts_at']?.toString() ?? '';
      final timeParts = startsAt.split(':');
      if (day == null || timeParts.length < 2) continue;

      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      if (hour == null || minute == null || day < 0 || day > 6) continue;

      final todayIndex = now.weekday % 7; // Sunday = 0
      final daysAhead = (day - todayIndex + 7) % 7;
      var lecture = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + daysAhead,
        hour,
        minute,
      );

      if (!lecture.isAfter(now)) {
        lecture = lecture.add(const Duration(days: 7));
      }

      final reminder = lecture.subtract(Duration(minutes: reminderMinutes));
      final subjectData = row['subjects'];
      final subject = subjectData is Map
          ? (subjectData['name_en'] ?? 'Your class').toString()
          : 'Your class';
      final location = (row['location'] ?? '').toString();
      final where = location.isEmpty ? '' : ' — $location';
      final classType = (row['class_type'] ?? 'lecture').toString();
      final typeLabel = switch (classType.toLowerCase()) {
        'section' => 'Section',
        'practical' => 'Practical',
        'lab' => 'Lab',
        'tutorial' => 'Tutorial',
        _ => 'Lecture',
      };
      final rowId = (row['id'] ?? '$day-$hour-$minute').toString();

      if (beforeEnabled && reminder.isAfter(now)) {
        final id = _stableId('$rowId-before');
        await _plugin.zonedSchedule(
          id,
          'استعد للـ $typeLabel',
          'فاضل $reminderMinutes دقيقة على $subject$where',
          reminder,
          beforeDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        scheduledIds.add(id);
      }

      if (startEnabled) {
        final id = _stableId('$rowId-start');
        await _plugin.zonedSchedule(
          id,
          'بدأ الـ $typeLabel',
          '$subject يبدأ الآن$where',
          lecture,
          startDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        scheduledIds.add(id);
      }
    }

    await _saveIds(_scheduleIdsKey, scheduledIds);
  }

  Future<void> syncAcademicEvents(List<Map<String, dynamic>> events) async {
    await initialize();
    final enabled = await _enabled('notification_academic_events_enabled', true);
    await _cancelStoredIds(_eventIdsKey);
    if (!enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'acadmind_academic_events',
        'تذكيرات أكاديمية',
        channelDescription:
            'تذكيرات الامتحانات والواجبات والفعاليات الأكاديمية',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final scheduledIds = <int>[];
    for (final event in events) {
      final minutes = (event['reminder_minutes'] as num?)?.toInt() ?? 0;
      if (minutes <= 0 || event['is_active'] == false) continue;
      final startsAt =
          DateTime.tryParse((event['starts_at'] ?? '').toString());
      if (startsAt == null) continue;

      final reminder = tz.TZDateTime.from(startsAt, tz.local)
          .subtract(Duration(minutes: minutes));
      if (!reminder.isAfter(now)) continue;

      final rawId =
          (event['id'] ?? event['title'] ?? startsAt.toIso8601String())
              .toString();
      final id = _stableId('academic-$rawId');
      final subjectData = event['subjects'];
      final subject =
          subjectData is Map ? (subjectData['name_en'] ?? '').toString() : '';
      final type = switch (event['event_type']) {
        'exam' => 'امتحان قادم',
        'assignment' || 'deadline' => 'موعد تسليم قادم',
        'quiz' => 'اختبار قصير قادم',
        _ => 'تذكير أكاديمي',
      };
      final title = (event['title'] ?? 'حدث أكاديمي').toString();

      await _plugin.zonedSchedule(
        id,
        type,
        subject.isEmpty ? title : '$title — $subject',
        reminder,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      scheduledIds.add(id);
    }

    await _saveIds(_eventIdsKey, scheduledIds);
  }
}

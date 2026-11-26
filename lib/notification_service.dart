import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    _ready = true;
  }

  int _stableId(String value) => value.codeUnits.fold<int>(0, (sum, unit) => (sum * 31 + unit) & 0x7fffffff);

  Future<void> syncSchedule(List<Map<String, dynamic>> rows) async {
    await initialize();
    await _plugin.cancelAll();
    const beforeDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'acadmind_lecture_before', 'تذكير قبل المحاضرة',
        channelDescription: 'تنبيه قبل المحاضرة أو السكشن بعشر دقائق',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    const startDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'acadmind_lecture_start', 'بداية المحاضرة',
        channelDescription: 'تنبيه عند موعد بداية المحاضرة أو السكشن',
        importance: Importance.max,
        priority: Priority.max,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final now = tz.TZDateTime.now(tz.local);
    for (final row in rows) {
      if (row['is_active'] == false || row['deleted_at'] != null) continue;

      final day = (row['day_of_week'] as num).toInt();
      final timeParts = (row['starts_at'] as String).split(':');
      if (timeParts.length < 2) continue;

      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      if (hour == null || minute == null || day < 0 || day > 6) continue;

      final todayIndex = now.weekday % 7; // Sunday = 0
      final daysAhead = (day - todayIndex + 7) % 7;
      var lecture = tz.TZDateTime(tz.local, now.year, now.month, now.day + daysAhead, hour, minute);
      // If today's lesson has already started, target the next weekly occurrence.
      if (!lecture.isAfter(now)) {
        lecture = lecture.add(const Duration(days: 7));
      }

      var reminder = lecture.subtract(const Duration(minutes: 10));
      // If the student opens the app less than 10 minutes before a lesson,
      // keep the start alert for today and move only the early warning to next week.
      if (!reminder.isAfter(now)) {
        reminder = reminder.add(const Duration(days: 7));
      }

      final subjectData = row['subjects'];
      final subject = subjectData is Map
          ? (subjectData['name_en'] ?? 'your class').toString()
          : 'محاضرتك';
      final location = (row['location'] ?? '').toString();
      final where = location.isEmpty ? '' : ' — $location';
      final rowId = (row['id'] ?? '$day-$hour-$minute').toString();

      await _plugin.zonedSchedule(
        _stableId('$rowId-before'),
        'استعد للمحاضرة',
        'فاضل 10 دقائق على $subject$where',
        reminder,
        beforeDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      await _plugin.zonedSchedule(
        _stableId('$rowId-start'),
        'بدأ موعد المحاضرة',
        '$subject تبدأ الآن$where',
        lecture,
        startDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }
}

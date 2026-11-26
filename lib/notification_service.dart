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
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'acadmind_lecture_reminders', 'تذكير المحاضرات',
        channelDescription: 'تنبيه قبل بداية المحاضرة بعشر دقائق',
        importance: Importance.high,
        priority: Priority.high,
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
      var daysAhead = (day - todayIndex + 7) % 7;
      var lecture = tz.TZDateTime(tz.local, now.year, now.month, now.day + daysAhead, hour, minute);
      var reminder = lecture.subtract(const Duration(minutes: 10));
      if (!reminder.isAfter(now)) {
        daysAhead += 7;
        lecture = tz.TZDateTime(tz.local, now.year, now.month, now.day + daysAhead, hour, minute);
        reminder = lecture.subtract(const Duration(minutes: 10));
      }
      final subject = (row['subjects'] is Map) ? ((row['subjects'] as Map)['name_ar'] ?? 'محاضرتك').toString() : 'محاضرتك';
      await _plugin.zonedSchedule(
        _stableId((row['id'] ?? '$day-$hour-$minute').toString()),
        'محاضرتك قربت تبدأ',
        'فاضل 10 دقائق على $subject',
        reminder,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }
}

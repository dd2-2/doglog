import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 일정(예방접종/구충/미용 등) 마감일 아침 9시 로컬 알림.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    // tz.local을 설정하지 않으면 zonedSchedule 호출 시 예외가 발생해 일정 저장 자체가
    // 항상 실패하는 버그가 있었음. 이 앱은 한국어 전용이라 서울 기준으로 고정.
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> scheduleForItem({
    required int scheduleId,
    required String dogName,
    required String title,
    required DateTime dueDate,
  }) async {
    await cancel(scheduleId);

    final scheduledDate = tz.TZDateTime.from(
      DateTime(dueDate.year, dueDate.month, dueDate.day, 9),
      tz.local,
    );
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      scheduleId,
      '$dogName · $title',
      '오늘은 $title 예정일이에요',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'doglog_schedule',
          '일정 알림',
          channelDescription: '반려동물 일정(예방접종/구충/목욕/미용 등) 리마인더',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(int scheduleId) => _plugin.cancel(scheduleId);
}

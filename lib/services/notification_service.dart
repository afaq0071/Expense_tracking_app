import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Singleton service for managing local notifications.
///
/// Handles initialization, permission requests, scheduling, and cancellation
/// of notifications for budgets, recurring transactions, and savings goals.
class NotificationService {
  // ── Singleton ──────────────────────────────────────────────────────

  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // ── Plugin instance ────────────────────────────────────────────────

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Notification channel IDs ───────────────────────────────────────

  static const String _channelId = 'expense_tracker_notifications';
  static const String _channelName = 'Expense Tracker Notifications';
  static const String _channelDesc =
      'Notifications for budgets, recurring transactions, and savings goals';

  // ── Initialization ─────────────────────────────────────────────────

  /// Initializes the notification plugin and timezone data.
  /// Safe to call multiple times (idempotent).
  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS/macOS initialization settings
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);

    // Create the notification channel (Android 8+)
    await _createNotificationChannel();

    _initialized = true;
  }

  /// Creates the Android notification channel.
  Future<void> _createNotificationChannel() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
        enableVibration: true,
      );
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  // ── Permission handling ────────────────────────────────────────────

  /// Requests notification permission (Android 13+, iOS).
  /// Returns true if permission is granted or already granted.
  Future<bool> requestPermission() async {
    // Android 13+ runtime permission
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS permission
    final iosPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true; // Other platforms: assume granted
  }

  /// Checks if notification permission is currently granted.
  Future<bool> isPermissionGranted() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.areNotificationsEnabled();
      return granted ?? false;
    }

    return true;
  }

  // ── Show immediate notification ────────────────────────────────────

  /// Shows an immediate notification (no scheduling).
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  // ── Schedule one-shot notification ─────────────────────────────────

  /// Schedules a one-shot notification at [scheduledTime].
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!_initialized) await init();

    final tzScheduled = tz.TZDateTime.from(scheduledTime, tz.local);

    // Don't schedule in the past
    if (tzScheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // ── Schedule repeating notification ────────────────────────────────

  /// Schedules a daily repeating notification at [timeOfDay].
  /// [timeOfDay] should be "HH:mm" format (e.g., "09:00").
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required String timeOfDay,
    String? payload,
  }) async {
    if (!_initialized) await init();

    final parts = timeOfDay.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // If the time has already passed today, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  // ── Schedule weekly notification ───────────────────────────────────

  /// Schedules a weekly repeating notification on [dayOfWeek] at [timeOfDay].
  /// [dayOfWeek]: 1 = Monday … 7 = Sunday.
  Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek,
    required String timeOfDay,
    String? payload,
  }) async {
    if (!_initialized) await init();

    final parts = timeOfDay.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Adjust to the target day of week
    while (scheduled.weekday != dayOfWeek || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  // ── Cancel notifications ───────────────────────────────────────────

  /// Cancels a single notification by [id].
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancels all notifications for a given base + range.
  /// e.g., cancelRange(1000, 50) cancels IDs 1000–1049.
  Future<void> cancelRange(int base, int count) async {
    for (var i = 0; i < count; i++) {
      await _plugin.cancel(base + i);
    }
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Cancels all scheduled notifications whose payload starts with [prefix].
  /// Useful for cancelling all notifications belonging to a category
  /// (e.g., all recurring reminders when the type is disabled).
  Future<void> cancelByPayloadPrefix(String prefix) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.payload != null && request.payload!.startsWith(prefix)) {
        await _plugin.cancel(request.id);
      }
    }
  }

  // ── Pending notifications ──────────────────────────────────────────

  /// Returns a list of all currently pending notification requests.
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }

  // ── Notification ID generators ─────────────────────────────────────
  //
  // Each type occupies a distinct 536,870,912-wide range within the
  // non-negative 31-bit space (0 – 2,147,483,647).  The formula is:
  //
  //   (type << 29) + (stableId.hashCode & 0x7FFFFFFF)
  //
  // where type is 0, 1, 2, or 3.  No modulo is used.

  /// Budget warning IDs: 0 – 536,870,911.
  static int budgetWarningId(String budgetId) =>
      (0 << 29) + (budgetId.hashCode & 0x7FFFFFFF);

  /// Budget exceeded IDs: 536,870,912 – 1,073,741,823.
  static int budgetExceededId(String budgetId) =>
      (1 << 29) + (budgetId.hashCode & 0x7FFFFFFF);

  /// Recurring reminder IDs: 1,073,741,824 – 1,610,612,735.
  static int recurringReminderId(String templateId) =>
      (2 << 29) + (templateId.hashCode & 0x7FFFFFFF);

  /// Savings goal reminder IDs: 1,610,612,736 – 2,147,483,647.
  static int savingsGoalReminderId(String goalId) =>
      (3 << 29) + (goalId.hashCode & 0x7FFFFFFF);
}

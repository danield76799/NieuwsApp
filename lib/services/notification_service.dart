import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/article.dart';

/// Service voor push notificaties
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize notificaties
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Timezone data laden
    tz_data.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
  }

  /// Check of artikel breaking news is. Only very strong signals should
  /// interrupt the user with a push notification.
  bool isBreakingNews(Article article) {
    final breakingKeywords = [
      'breaking', 'urgent', 'spoed', 'alarm', 'alert', 'liveblog',
      'schokkend', 'ramp', 'aanslag', 'evacuatie',
    ];
    
    final text = '${article.title} ${article.description}'.toLowerCase();
    return breakingKeywords.any((keyword) => text.contains(keyword));
  }

  /// Toon breaking news notificatie
  Future<void> showBreakingNews(Article article) async {
    const androidDetails = AndroidNotificationDetails(
      'breaking_news',
      'Breaking News',
      channelDescription: 'Belangrijk nieuws meldingen',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      article.id.hashCode,
      'Breaking: ${article.source}',
      article.title,
      details,
      payload: jsonEncode(article.toJson()),
    );
  }

  /// Toon dagelijkse nieuws samenvatting
  Future<void> showDailySummary(List<Article> articles) async {
    if (articles.isEmpty) return;

    const androidDetails = AndroidNotificationDetails(
      'daily_summary',
      'Dagelijkse Samenvatting',
      channelDescription: 'Dagelijkse nieuws samenvatting',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final topArticles = articles.take(3).map((a) => '• ${a.title}').join('\n');

    await _notifications.show(
      9999,
      'Nieuws Samenvatting',
      '${articles.length} nieuwe artikelen vandaag\n$topArticles',
      details,
    );
  }

  /// Schedule dagelijkse notificatie
  Future<void> scheduleDailyNotification({required int hour, required int minute}) async {
    await _notifications.zonedSchedule(
      8888,
      'Nieuws Update',
      'Bekijk het laatste nieuws van vandaag!',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_update',
          'Dagelijkse Update',
          channelDescription: 'Dagelijkse nieuws update',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancel alle notificaties
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Helper: volgende instantie van tijd
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  /// Handle notificatie tap
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final article = Article.fromJson(jsonDecode(response.payload!));
        // TODO: Navigate to article detail
        print('Tapped on article: ${article.title}');
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  /// Request permissions (iOS)
  Future<bool> requestPermissions() async {
    final result = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    return result ?? true;
  }
}

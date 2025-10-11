import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // تهيئة الإشعارات
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings);

    // إنشاء قنوات الإشعارات للأندرويد
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      const AndroidNotificationChannel paymentChannel =
          AndroidNotificationChannel(
        'payment_channel',
        'إشعارات الدفع',
        description: 'إشعارات تذكير بدفع فواتير المياه وتأكيدات الدفع',
        importance: Importance.high,
      );
      const AndroidNotificationChannel readingsChannel =
          AndroidNotificationChannel(
        'readings_channel',
        'قراءات جديدة',
        description: 'إشعارات قراءات العدادات',
        importance: Importance.defaultImportance,
      );
      const AndroidNotificationChannel alertsChannel =
          AndroidNotificationChannel(
        'alerts_channel',
        'تنبيهات مهمة',
        description: 'إشعارات التنبيهات المهمة',
        importance: Importance.max,
      );
      await androidPlugin.createNotificationChannel(paymentChannel);
      await androidPlugin.createNotificationChannel(readingsChannel);
      await androidPlugin.createNotificationChannel(alertsChannel);
    }
  }

  // إشعار تذكير بالدفع
  static Future<void> showPaymentReminder(
    String customerName,
    double amount,
    DateTime dueDate,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'payment_channel',
      'إشعارات الدفع',
      channelDescription: 'إشعارات تذكير بدفع فواتير المياه وتأكيدات الدفع',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'تذكير بدفع الفاتورة',
      'عزيزي $customerName، لديك فاتورة مستحقة بقيمة $amount ريال حتى ${dueDate.day}/${dueDate.month}/${dueDate.year}',
      details,
    );
  }

  // إشعار تأكيد الدفع
  static Future<void> showPaymentConfirmation(
    String customerName,
    double amount,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'payment_channel',
      'إشعارات الدفع',
      channelDescription: 'إشعارات تذكير بدفع فواتير المياه وتأكيدات الدفع',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'تم الدفع بنجاح',
      'عزيزي $customerName، تم دفع مبلغ $amount ريال بنجاح',
      details,
    );
  }

  // إشعار قراءة جديدة
  static Future<void> showNewReadingNotification(
    String customerName,
    double consumption,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'readings_channel',
      'قراءات جديدة',
      channelDescription: 'إشعارات قراءات العدادات',
      importance: Importance.defaultImportance,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'قراءة جديدة',
      'تم تسجيل قراءة جديدة للعميل $customerName - الاستهلاك: $consumption وحدة',
      details,
    );
  }

  // إشعار فاتورة متأخرة
  static Future<void> showOverdueInvoiceAlert(
    String customerName,
    double amount,
    int daysOverdue,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'alerts_channel',
      'تنبيهات مهمة',
      channelDescription: 'إشعارات التنبيهات المهمة',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'فاتورة متأخرة',
      'عزيزي $customerName، فاتورة بقيمة $amount ريال متأخرة $daysOverdue أيام',
      details,
    );
  }
}

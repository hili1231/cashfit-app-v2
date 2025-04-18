import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import '../providers/user_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger();

  Function(String type, Map<String, dynamic> data)? onNotificationTap;

  /// Initialize the notification service with FCM and local notifications.
  Future<void> initialize({
    required UserProvider
    userProvider, // Pass UserProvider instead of BuildContext
    required Function(String type, Map<String, dynamic> data) onTap,
  }) async {
    try {
      onNotificationTap = onTap;

      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _logger.i("User granted permission for notifications");
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        _logger.i("User granted provisional permission for notifications");
      } else {
        _logger.w("User denied permission for notifications");
        throw Exception("Notification permissions denied by user.");
      }

      // Initialize local notifications for both Android and iOS
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );
      const InitializationSettings initializationSettings =
          InitializationSettings(android: androidSettings, iOS: iosSettings);
      await _localNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) {
            try {
              final Map<String, dynamic> payloadData = jsonDecode(
                response.payload!,
              );
              final type = payloadData['type'] ?? '';
              onNotificationTap?.call(type, payloadData);
            } catch (e) {
              _logger.e("Error parsing notification payload: $e");
            }
          }
        },
      );

      // Configure Android notification channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'cashfit_channel',
        'CashFit Notifications',
        description: 'Notifications for CashFit app updates and reminders',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });

      // Handle notification taps when the app is in the background or terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
      });

      // Handle initial message when the app is opened from a terminated state
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Get and save the FCM token for the device
      String? token = await _messaging.getToken();
      if (token != null) {
        _logger.i("FCM Token: $token");
        // Save the token to the user's Firestore document
        if (userProvider.isLoggedIn && userProvider.currentUser != null) {
          await userProvider.updateUserFields({'fcmToken': token});
        }
      } else {
        _logger.e("Failed to retrieve FCM token");
        throw Exception("Failed to retrieve FCM token.");
      }
    } catch (e) {
      _logger.e("Failed to initialize NotificationService: $e");
      throw Exception("Failed to initialize NotificationService: $e");
    }
  }

  /// Show a local notification for a foreground message.
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'cashfit_channel',
          'CashFit Notifications',
          importance: Importance.max,
          priority: Priority.high,
          channelDescription:
              'Notifications for CashFit app updates and reminders',
          playSound: true,
          enableVibration: true,
        );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payloadData = {
      'type': message.data['type'] ?? '',
      'postId': message.data['postId'] ?? '',
      'userId': message.data['userId'] ?? '',
      'challengeId': message.data['challengeId'] ?? '',
    };
    final payload = jsonEncode(payloadData);

    await _localNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'CashFit',
      message.notification?.body ?? 'You have a new notification',
      platformDetails,
      payload: payload,
    );
  }

  /// Handle a notification tap by invoking the callback.
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] ?? '';
    onNotificationTap?.call(type, data);
  }
}

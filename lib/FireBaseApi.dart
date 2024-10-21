import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class FireBaseApi {
  static final FireBaseApi _instance = FireBaseApi._internal();
  factory FireBaseApi() => _instance;
  FireBaseApi._internal();

  final _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channelsssssssssssssss',
    'High Importance Notifications',
    importance: Importance.max,
    playSound: true,
    showBadge: true,
  );

  Future<void> initNotifications() async {
    await Firebase.initializeApp();
    await requestNotificationPermission();

    final fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fcmToken');

    await _initLocalNotifications();
    await _initPushNotifications();
  }

  Future<void> requestNotificationPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.createNotificationChannel(_channel);
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null) {
          final data = Map<String, dynamic>.from(ScreenPayload.fromJson(payload).data);
          handleNotificationTap(data);
        }
      },
    );
  }

  Future<void> _initPushNotifications() async {
    // Handle terminated state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      handleNotificationTap(initialMessage.data);
    }

    // Handle background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotificationTap(message.data);
    });

    // Handle foreground state
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showNotification(message);
    });
  }

  static void showNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            importance: _channel.importance,
            priority: Priority.max,
            icon: android.smallIcon,
          ),
        ),
        payload: ScreenPayload(data: message.data).toJson(),
      );
    }
  }

  static void handleNotificationTap(Map<String, dynamic> data) {
    final screen = data['screen'];
    switch (screen) {
      case 'profile':
        navigatorKey.currentState?.pushNamed('/profile');
        break;
      case 'settings':
        navigatorKey.currentState?.pushNamed('/settings');
        break;
      default:
        navigatorKey.currentState?.pushNamed('/');
    }
  }


}

class ScreenPayload {
  final Map<String, dynamic> data;
  ScreenPayload({required this.data});
  String toJson() => '{"data": ${jsonEncode(data)}}';
  static ScreenPayload fromJson(String json) {
    final map = jsonDecode(json);
    return ScreenPayload(data: map['data']);
  }
}



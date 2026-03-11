import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as dev;

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. Request Permissions (iOS/Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      dev.log('User granted notification permission');
    }

    // 2. Setup Local Notifications for Foreground
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    // 3. Listen for Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // 4. Update Token in Firestore
    _setupTokenListener();
  }

  static Future<void> _setupTokenListener() async {
    _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken);
    });

    String? token = await _messaging.getToken();
    if (token != null) {
      _saveTokenToFirestore(token);
    }
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      dev.log('FCM Token updated for user ${user.uid}');
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'dentcare_main_channel',
      'Clinical Alerts',
      channelDescription: 'Important clinical and appointment updates',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'New Clinical Alert',
      body: message.notification?.body ?? 'Open DentCare for details',
      notificationDetails: details,
    );
  }

  // Helper to send a notification (usually done via Cloud Functions/Backend, but here for reference)
  static Future<void> subscribeToClinic(String clinicId) async {
    await _messaging.subscribeToTopic('clinic_$clinicId');
    dev.log('Subscribed to topic: clinic_$clinicId');
  }
}

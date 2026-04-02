import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Meminta izin notifikasi
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      // Sync token jika sudah login
      await syncToken();
    }

    // Handle pesan saat aplikasi di foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foregound Message received: ${message.notification?.title}");
    });

    // Handle saat notifikasi di klik dan aplikasi terbuka dari background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification clicked! Data: ${message.data}");
    });
  }

  static Future<void> syncToken() async {
    try {
      final token = await _fcm.getToken();
      final sessionToken = await SessionStorage.getToken();
      
      if (token != null && sessionToken != null) {
        print("Syncing FCM Token: $token");
        await ApiClient.put('/api/profile/fcm-token', {'fcm_token': token});
      }
    } catch (e) {
      print("Error syncing FCM token: $e");
    }
  }

  static Future<String?> getToken() async {
    return await _fcm.getToken();
  }
}

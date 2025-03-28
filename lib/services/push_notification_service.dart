import 'dart:convert';
import 'package:http/http.dart' as http;

class PushNotificationService {
  // ✅ Make sure this matches your deployed Firebase Function URL
  static const String functionUrl = 'https://sendpushnotification-ipsp2tle2q-uc.a.run.app';

  /// 🔔 Generic push notification
  static Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data, // Optional: Add custom data
  }) async {
    if (fcmToken.isEmpty) {
      print('❌ FCM token is missing!');
      return;
    }

    print('📦 Sending push notification...');
    print('🔑 FCM Token: $fcmToken');
    print('📝 Title: $title');
    print('📨 Body: $body');

    final payload = {
      'fcmToken': fcmToken,
      'title': title,
      'body': body,
      'data': {
        'sender_name': data?['sender_name'] ?? '',
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        ...?data,
      },
    };


    try {
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        print('✅ Push notification sent successfully!');
      } else {
        print('❌ Failed to send notification: ${response.body}');
      }
    } catch (e) {
      print('❌ Error calling Firebase Function: $e');
    }
  }

  /// ❤️ Soul Match Like
  static Future<void> sendLikeNotification({
    required String fcmToken,
    required String likerName,
  }) async {
    await sendPushNotification(
      fcmToken: fcmToken,
      title: '✨ You’ve been liked!',
      body: '$likerName thinks you’re a great match! Swipe to find your connection.',
    );
  }

  /// 👫 Friend Request
  static Future<void> sendFriendRequestNotification({
    required String fcmToken,
    required String senderName,
  }) async {
    await sendPushNotification(
      fcmToken: fcmToken,
      title: '👤 Friend Request',
      body: '$senderName sent you a friend request!',
    );
  }

  /// 🫂 Friend Accepted
  static Future<void> sendFriendAcceptedNotification({
    required String fcmToken,
    required String senderName,
  }) async {
    await sendPushNotification(
      fcmToken: fcmToken,
      title: '🎉 You’re now friends!',
      body: 'You and $senderName are now connected on Aurana.',
    );
  }

  /// 💬 New Message (Optional future)
  static Future<void> sendMessageNotification({
    required String fcmToken,
    required String senderName,
    required String message,
  }) async {
    await sendPushNotification(
      fcmToken: fcmToken,
      title: '📨 New Message from $senderName',
      body: message,
    );
  }
}

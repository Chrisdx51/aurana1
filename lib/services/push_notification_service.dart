import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/googleapis_auth.dart'; // ✅ This is important!
import 'package:flutter/services.dart' show rootBundle;

class PushNotificationService {
  static const String _serviceAccountPath = 'service_account.json'; // Your JSON file in root folder
  static const String _projectId = 'aurana-b3436'; // Change to your real Firebase project ID

  static Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
  }) async {
    try {
      // Load your service account credentials
      final credentialsJson = json.decode(await rootBundle.loadString(_serviceAccountPath));
      final accountCredentials = ServiceAccountCredentials.fromJson(credentialsJson);

      // Scopes for FCM
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      // ✅ This function is from googleapis_auth package
      final client = await clientViaServiceAccount(accountCredentials, scopes);

      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$_projectId/messages:send');

      final payload = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
        },
      };

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('✅ Push notification sent successfully!');
      } else {
        print('❌ Failed to send notification: ${response.body}');
      }

      client.close();
    } catch (e) {
      print('❌ Error sending push notification: $e');
    }
  }

  static clientViaServiceAccount(ServiceAccountCredentials accountCredentials, List<String> scopes) {}
}

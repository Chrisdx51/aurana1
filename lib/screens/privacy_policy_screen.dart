import 'package:flutter/material.dart';
import '../widgets/banner_ad_widget.dart'; // ✅ Banner Ad at the top!

class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy & Terms'),
        backgroundColor: Colors.teal.shade400,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          BannerAdWidget(), // ✅ Banner under the header!

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header('Privacy Policy & Terms of Use'),
                  SizedBox(height: 16),

                  _paragraph(
                      'Welcome to Aurana. Your privacy and trust are important to us. '
                          'By using this app, you agree to the following terms and conditions outlined below. '
                          'Please read them carefully.'
                  ),

                  SizedBox(height: 24),
                  _sectionTitle('1. Data Collection & Usage'),
                  _paragraph(
                      'Aurana collects limited personal data to provide and improve your experience. This includes:\n\n'
                          '• Email address\n'
                          '• Username\n'
                          '• Date of Birth (optional)\n'
                          '• Profile information (spiritual path, aura color, zodiac sign, avatar)\n'
                          '• Location (optional, for features like Soul Match)\n'
                          '• FCM Token for notifications\n\n'
                          'We use this data to personalize your experience, connect you with other users, '
                          'deliver features like Soul Match, AI Guidance, and send notifications.\n\n'
                          'We do NOT sell or share your personal data with third-party marketers. '
                          'Your data stays within Aurana, unless required by law.'
                  ),

                  SizedBox(height: 24),
                  _sectionTitle('2. Features & Their Privacy'),
                  _paragraph(
                      '• Aura Catcher: Captures your aura using device inputs and displays visual interpretations. '
                          'No personal health or biometric data is collected.\n\n'
                          '• Soul Match: Matches you with other users based on profile preferences. Uses profile data like spiritual path, aura, and zodiac sign. '
                          'Your matches are private to you.\n\n'
                          '• AI Spiritual Guidance: Generates personalized insights and guidance. Uses your profile data, but does not store conversations long-term.\n\n'
                          '• Messaging: Messages are encrypted in transit. We do not actively monitor chats, '
                          'but we reserve the right to provide encrypted messages to law enforcement if required under lawful request.\n\n'
                          '• Notifications: You can control notifications for friend requests, messages, daily affirmations, and more in Settings.'
                  ),

                  SizedBox(height: 24),
                  _sectionTitle('3. User Responsibilities & Code of Conduct'),
                  _paragraph(
                      'Aurana is a safe and respectful spiritual community. By using the app, you agree to:\n\n'
                          '• Treat others with kindness and respect.\n'
                          '• Not engage in harassment, hate speech, or inappropriate content.\n'
                          '• Report any misuse through the app\'s reporting features.\n\n'
                          'Aurana is not responsible for the actions of other users. You are responsible for your behavior and interactions.'
                  ),

                  SizedBox(height: 24),
                  _sectionTitle('4. Law Enforcement & Legal Requests'),
                  _paragraph(
                      'Aurana respects your privacy, but we will comply with legal obligations. '
                          'If requested by law enforcement under a valid legal process, '
                          'we will share relevant user data, including encrypted files and records, as required by law.\n\n'
                          'We do not voluntarily disclose information without proper legal process.'
                  ),

                  SizedBox(height: 24),
                  _sectionTitle('5. Ads & Third-Party Services'),
                  _paragraph(
                      'Aurana uses third-party ad services (Google AdMob) to provide non-intrusive ads. '
                          'These third-party services may collect data in accordance with their privacy policies.\n\n'
                          'Aurana is not responsible for any third-party content, ads, or services. '
                          'Engagement with third-party services is at your discretion and risk.'
                  ),

                  SizedBox(height: 24),
                  _sectionTitle('6. Security & Encryption'),
                  _paragraph(
                      'We use encryption to protect your messages in transit. '
                          'However, no system is completely secure. Aurana cannot guarantee the absolute security of your data.\n\n'
                          'You are responsible for keeping your account credentials secure. '
                          'If you suspect any unauthorized use, please notify us immediately.'
                  ),

                  SizedBox(height: 24),
                  _sectionTitle('7. Limitation of Liability'),
                  _paragraph(
                      'Aurana is provided "as is". We do not guarantee uninterrupted or error-free service. '
                          'We are not liable for any loss, damage, or harm resulting from the use of the app.\n\n'
                          'Spiritual insights, readings, and guidance are for entertainment and personal reflection purposes only. '
                          'They are not medical, legal, or professional advice.'
                  ),

                  SizedBox(height: 24),
                  _sectionTitle('8. Account Deletion & Data Removal'),
                  _paragraph(
                      'You may delete your account at any time through the app\'s Settings. '
                          'Upon deletion, your profile data is permanently removed from our systems, '
                          'except where we are legally required to retain information.'
                  ),

                  SizedBox(height: 24),
                  _sectionTitle('9. Updates to This Policy'),
                  _paragraph(
                      'We may update this Privacy Policy and Terms of Use to reflect changes in our practices or services. '
                          'You will be notified of significant changes through the app. Continued use of Aurana after updates constitutes acceptance of the new terms.'
                  ),

                  SizedBox(height: 24),
                  Divider(color: Colors.white24),

                  SizedBox(height: 16),
                  _paragraph(
                      'If you have questions or concerns about this policy, contact us directly via the Aurana app or email support@aurana.app.'
                  ),

                  SizedBox(height: 32),
                  Center(
                    child: Text(
                      'Aurana © 2025',
                      style: TextStyle(color: Colors.white24, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.tealAccent),
    );
  }

  Widget _paragraph(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
    );
  }
}

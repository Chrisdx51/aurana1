import 'package:flutter/material.dart';
import '../widgets/banner_ad_widget.dart'; // ✅ Ad at the top!

class HelpAndFeaturesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Aurana Help & Features'),
        backgroundColor: Colors.teal.shade400,
      ),
      body: Column(
        children: [
          BannerAdWidget(), // ✅ Ad banner below header!

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header('Welcome to Aurana 🌌'),

                  _paragraph(
                      'Aurana is your spiritual companion. Here is a simple guide to help you understand and use the features of this sacred space. '
                          'Take your time, explore at your own pace, and remember—your journey is unique.'
                  ),

                  SizedBox(height: 24),

                  _sectionTitle('✨ Daily Practices'),

                  _subSection('🌞 Daily Affirmations',
                      'Receive a daily message to uplift and inspire you. These affirmations help align your energy and start your day with positivity. '
                          'Each morning, check the Affirmations section to receive your message of light.'),

                  _subSection('🔮 Daily Horoscope',
                      'Get personalized insights based on your zodiac sign. The horoscope gives gentle guidance and awareness about the energies influencing your day.'),

                  _subSection('🧘 Spiritual Guidance',
                      'Receive weekly spiritual reflections. These gentle nudges help you reconnect with your path and remind you of the deeper journey you are on.'),

                  SizedBox(height: 24),

                  _sectionTitle('🖼️ Aura Capture'),

                  _subSection('What is Aura Capture?',
                      'The Aura Capture allows you to visually experience the energy surrounding you. '
                          'Take a moment to capture your aura and reflect on the colors and feelings that emerge.'),

                  _subSection('How to Use Aura Capture',
                      '1. Go to the Aura Capture page.\n'
                          '2. Relax, take a deep breath, and tap the capture button.\n'
                          '3. View your aura and its unique colors.\n\n'
                          'Each color represents different energies and emotions. Use this as a moment of self-reflection.'),

                  SizedBox(height: 24),

                  _sectionTitle('🤝 Soul Match & Friend Connections'),

                  _subSection('Soul Match',
                      'Find and connect with other like-minded souls. Soul Match helps you discover spiritual connections based on shared paths and interests.\n\n'
                          'Swipe through profiles, send a connection request, and see who you resonate with.'),

                  _subSection('Friend Requests',
                      'You can send and receive friend requests. Once accepted, you can chat, share, and walk your journey together inside Aurana.'),

                  _subSection('Messaging',
                      'Communicate with your spiritual friends through private messages. Share thoughts, insights, and love, all within the sacred space of Aurana. '
                          'Messages are private and secure.'),

                  SizedBox(height: 24),

                  _sectionTitle('📜 Soul Journey & Milestones'),

                  _subSection('Soul Journey Posts',
                      'Share your personal insights, experiences, or spiritual moments on your Soul Journey wall. '
                          'These posts are for your reflections and sharing with your soul tribe.'),

                  _subSection('Milestones',
                      'Record and celebrate key moments in your spiritual awakening. Milestones can include breakthroughs, lessons, or sacred experiences. '
                          'You can even receive comments and encouragement from your friends.'),

                  SizedBox(height: 24),

                  _sectionTitle('🏆 Achievements & Badges'),

                  _subSection('Achievements',
                      'As you explore Aurana and engage with its features, you’ll unlock spiritual achievements. '
                          'These serve as reminders of your growth and dedication on your path.'),

                  _subSection('Badges',
                      'Badges are awarded for completing spiritual challenges and milestones. They represent your commitment and progress.'),

                  SizedBox(height: 24),

                  _sectionTitle('🌟 Personal Profile & Settings'),

                  _subSection('Customize Your Profile',
                      'Add your photo, spiritual path, element, aura color, and more. This helps others find you and feel your energy.'),

                  _subSection('Privacy Settings',
                      'Control who sees your profile, posts, and activity. Choose between public, friends only, or private.'),

                  _subSection('Notifications',
                      'Stay in control of what messages and reminders you receive. Customize your settings to suit your journey.'),

                  SizedBox(height: 24),

                  _sectionTitle('📍 Discovery & Connection'),

                  _subSection('User Discovery',
                      'Browse other spiritual profiles and discover people who share your interests. '
                          'You can filter by spiritual path, zodiac, or simply explore the community.'),

                  SizedBox(height: 24),

                  _sectionTitle('🛠️ Ads & Free Use'),

                  _subSection('Why You See Ads',
                      'Aurana is free for everyone. We show gentle ads to help us keep this space open and supported. '
                          'Thank you for understanding and supporting this sacred mission.'),

                  SizedBox(height: 24),

                  Divider(color: Colors.white24),

                  SizedBox(height: 16),

                  _paragraph(
                      'Aurana is always growing. We are working on new features, including:\n\n'
                          '✨ Group meditations\n'
                          '✨ Energy sharing circles\n'
                          '✨ Live spiritual events\n\n'
                          'Stay connected and join us on this ever-expanding journey!'
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

  // Widget Builders
  Widget _header(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: Colors.tealAccent,
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.purpleAccent,
      ),
    );
  }

  Widget _subSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.lightBlueAccent,
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paragraph(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        color: Colors.white70,
        height: 1.6,
      ),
    );
  }
}

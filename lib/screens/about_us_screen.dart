import 'package:flutter/material.dart';
import '../widgets/banner_ad_widget.dart'; // ✅ Banner Ad at the top!

class AboutUsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('About Aurana 🌌'),
        backgroundColor: Colors.teal.shade400,
      ),
      body: Column(
        children: [
          BannerAdWidget(), // ✅ Ad banner under the header

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header('Welcome to Aurana 🌿'),

                  SizedBox(height: 16),

                  _paragraph(
                      'Aurana is not just an app. It’s a sacred space born from the hearts of spiritual guides, healers, and energy workers. '
                          'We are not a company. We are not an organization. We are simply people—quiet souls who walk between the worlds—'
                          'bringing a tool for others on their journey of awakening and self-discovery.'
                  ),

                  SizedBox(height: 16),

                  _paragraph(
                      'Our mission is simple: to support and guide you as you step deeper into your truth. '
                          'Whether you’re just beginning your path or have been walking it for lifetimes, '
                          'Aurana is here to help you connect, grow, and share your light with the world.'
                  ),

                  SizedBox(height: 16),

                  _sectionTitle('A Spiritual Community, Not Just an App'),

                  SizedBox(height: 8),

                  _paragraph(
                      'We created Aurana as a safe haven—a place for spiritual beings from all walks of life to connect. '
                          'Here, you can:\n\n'
                          '🌸 Find soul connections and friendships\n'
                          '🌸 Receive daily affirmations to align your spirit\n'
                          '🌸 Explore AI-driven spiritual guidance and insights\n'
                          '🌸 Capture your aura and understand your energy field\n'
                          '🌸 Discover services from psychics, healers, and guides\n\n'
                          'Whether you seek companionship, wisdom, or healing, Aurana is here for you.'
                  ),

                  SizedBox(height: 16),

                  _sectionTitle('Why We Stay Discreet'),

                  SizedBox(height: 8),

                  _paragraph(
                      'We are not "tech experts" or "corporate people". We are energy workers, intuitives, and spiritual guides '
                          'who prefer to remain in the background—just as many healers do. '
                          'Our role is to hold space, offer guidance, and provide a safe platform for you to explore your soul’s journey. '
                          'You won’t see our faces, but you’ll feel our presence in every corner of this app.'
                  ),

                  SizedBox(height: 16),

                  _sectionTitle('Safety, Privacy, and Respect'),

                  SizedBox(height: 8),

                  _paragraph(
                      'Your privacy and safety are sacred to us.\n\n'
                          '✅ We do not sell or share your personal data.\n'
                          '✅ Messages are encrypted for your protection.\n'
                          '✅ You are always in control of your privacy settings.\n\n'
                          'We have created Aurana to be a sanctuary—free from judgment and full of respect for all spiritual paths.'
                  ),

                  SizedBox(height: 16),

                  _sectionTitle('This Is Just the Beginning...'),

                  SizedBox(height: 8),

                  _paragraph(
                      'Aurana is still in its early days. We are a growing community, and there is so much more to come.\n\n'
                          '✨ New features\n'
                          '✨ Deeper AI insights\n'
                          '✨ Expanded spiritual services\n'
                          '✨ Workshops, group meditations, and more\n\n'
                          'As more souls gather here, our light will grow brighter together.'
                  ),

                  SizedBox(height: 16),

                  _sectionTitle('Thank You for Being Here'),

                  SizedBox(height: 8),

                  _paragraph(
                      'Thank you for trusting Aurana as part of your sacred journey. Whether you are here to learn, heal, share, or simply be—you are welcome here.\n\n'
                          'May your path be blessed. 🌕✨'
                  ),

                  SizedBox(height: 24),

                  Divider(color: Colors.white24),

                  SizedBox(height: 16),

                  _paragraph(
                      'If you have questions, feedback, or wish to connect, please reach out to us directly through the app. '
                          'We are always listening, even if we remain unseen.'
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

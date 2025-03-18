import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../screens/about_us_screen.dart';
import '../screens/privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Toggle states
  bool friendRequestNotif = true;
  bool friendAcceptNotif = true;
  bool messageNotif = true;
  bool dailyAffirmationNotif = true;
  bool dailyHoroscopeNotif = true;
  bool moonCycleNotif = true;
  bool spiritualGuidanceNotif = true;
  bool auraCaptureReminderNotif = true;
  bool adsPageUpdates = true;

  bool showProfilePublic = true;
  bool allowFriendRequests = true;

  // Banner Ad
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettingsFromSupabase();
    _initBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _initBannerAd() async {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Ad Unit
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() => _isAdLoaded = true);
          print('✅ Banner Ad Loaded');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('❌ Failed to load banner ad: $error');
        },
      ),
    );

    await _bannerAd!.load();
  }

  Future<void> _loadSettingsFromSupabase() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final data = await Supabase.instance.client
          .from('profiles')
          .select('''
            friend_request_notif,
            friend_accept_notif,
            message_notif,
            daily_affirmation_notif,
            daily_horoscope_notif,
            moon_cycle_notif,
            spiritual_guidance_notif,
            aura_capture_reminder_notif,
            ads_page_updates,
            show_profile_public,
            allow_friend_requests
          ''')
          .eq('id', userId)
          .single();

      setState(() {
        friendRequestNotif = data['friend_request_notif'] ?? true;
        friendAcceptNotif = data['friend_accept_notif'] ?? true;
        messageNotif = data['message_notif'] ?? true;
        dailyAffirmationNotif = data['daily_affirmation_notif'] ?? true;
        dailyHoroscopeNotif = data['daily_horoscope_notif'] ?? true;
        moonCycleNotif = data['moon_cycle_notif'] ?? true;
        spiritualGuidanceNotif = data['spiritual_guidance_notif'] ?? true;
        auraCaptureReminderNotif = data['aura_capture_reminder_notif'] ?? true;
        adsPageUpdates = data['ads_page_updates'] ?? true;
        showProfilePublic = data['show_profile_public'] ?? true;
        allowFriendRequests = data['allow_friend_requests'] ?? true;
      });

      print('✅ Settings loaded successfully!');
    } catch (e) {
      print('❌ Error loading settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error loading settings!')),
      );
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      print('❌ User ID is null!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ User not found. Please log in again.')),
      );
      setState(() => _isSaving = false);
      return;
    }

    print('✅ Saving settings for user: $userId');

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .update({
        'friend_request_notif': friendRequestNotif,
        'friend_accept_notif': friendAcceptNotif,
        'message_notif': messageNotif,
        'daily_affirmation_notif': dailyAffirmationNotif,
        'daily_horoscope_notif': dailyHoroscopeNotif,
        'moon_cycle_notif': moonCycleNotif,
        'spiritual_guidance_notif': spiritualGuidanceNotif,
        'aura_capture_reminder_notif': auraCaptureReminderNotif,
        'ads_page_updates': adsPageUpdates,
        'show_profile_public': showProfilePublic,
        'allow_friend_requests': allowFriendRequests,
      })
          .eq('id', userId)
          .select('id') // confirm update
          .single();

      print('✅ Settings updated successfully: $response');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Settings saved!')),
      );
    } catch (e) {
      print('❌ Failed to save settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to save settings. Try again!')),
      );
    }

    setState(() => _isSaving = false);
  }

  void _logout() async {
    await Supabase.instance.client.auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _deleteAccount() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client.from('profiles').delete().eq('id', userId);
    await Supabase.instance.client.auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade700, Colors.black, Colors.red.shade700],
            ),
          ),
        ),
        title: Text('Settings ⚙️', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_isAdLoaded)
            Container(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          if (_isSaving)
            LinearProgressIndicator(
              color: Colors.tealAccent,
              backgroundColor: Colors.grey.shade800,
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('🔔 Notifications'),
                  _buildToggle('Friend Requests', friendRequestNotif, (val) => setState(() => friendRequestNotif = val)),
                  _buildToggle('Friend Accepted', friendAcceptNotif, (val) => setState(() => friendAcceptNotif = val)),
                  _buildToggle('Messages', messageNotif, (val) => setState(() => messageNotif = val)),
                  _buildToggle('Daily Affirmation', dailyAffirmationNotif, (val) => setState(() => dailyAffirmationNotif = val)),
                  _buildToggle('Daily Horoscope', dailyHoroscopeNotif, (val) => setState(() => dailyHoroscopeNotif = val)),
                  _buildToggle('Moon Cycle Reminder', moonCycleNotif, (val) => setState(() => moonCycleNotif = val)),
                  _buildToggle('Spiritual Guidance Reminder', spiritualGuidanceNotif, (val) => setState(() => spiritualGuidanceNotif = val)),
                  _buildToggle('Aura Capture Reminder', auraCaptureReminderNotif, (val) => setState(() => auraCaptureReminderNotif = val)),
                  _buildToggle('Ads Page Updates', adsPageUpdates, (val) => setState(() => adsPageUpdates = val)),

                  SizedBox(height: 10),
                  _notificationDisclaimer(),
                  SizedBox(height: 30),

                  _sectionHeader('🔒 Privacy'),
                  _buildToggle('Show Profile Publicly', showProfilePublic, (val) => setState(() => showProfilePublic = val)),
                  _buildToggle('Allow Friend Requests', allowFriendRequests, (val) => setState(() => allowFriendRequests = val)),

                  SizedBox(height: 30),

                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveSettings,
                      icon: Icon(Icons.save_alt_rounded, color: Colors.white),
                      label: Text('Save Settings', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: Icon(Icons.logout_rounded, color: Colors.white),
                      label: Text('Logout', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade600,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),

                  SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _bottomNavButton(context, 'About Us', Icons.info_outline, AboutUsScreen()),
                      _bottomNavButton(context, 'Privacy Policy', Icons.privacy_tip_outlined, PrivacyPolicyScreen()),
                    ],
                  ),

                  SizedBox(height: 40),

                  Center(
                    child: TextButton.icon(
                      onPressed: _deleteAccount,
                      icon: Icon(Icons.delete_forever, color: Colors.redAccent),
                      label: Text('Delete My Account', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: Colors.white, fontSize: 16),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              maxLines: 1,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.tealAccent,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _bottomNavButton(BuildContext context, String label, IconData icon, Widget page) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              SizedBox(height: 8),
              Text(label, style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notificationDisclaimer() {
    return Text(
      '⚠️ Some essential notifications may still be delivered as part of Aurana\'s service.',
      style: TextStyle(color: Colors.white60, fontSize: 12),
    );
  }
}

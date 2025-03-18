import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart'; // ✅ Voice readout!
import '../widgets/banner_ad_widget.dart'; // ✅ Ad Widget

class HoroscopeScreen extends StatefulWidget {
  const HoroscopeScreen({Key? key}) : super(key: key);

  @override
  _HoroscopeScreenState createState() => _HoroscopeScreenState();
}

class _HoroscopeScreenState extends State<HoroscopeScreen> with TickerProviderStateMixin {
  String userZodiacSign = 'aquarius';
  String horoscopeText = '';
  bool isLoading = true;

  late FlutterTts flutterTts;
  late AnimationController _starsController;

  @override
  void initState() {
    super.initState();
    _initVoice();
    _starsController = AnimationController(vsync: this, duration: Duration(seconds: 3))..repeat(reverse: true);
    _loadZodiacAndHoroscope();
  }

  @override
  void dispose() {
    flutterTts.stop();
    _starsController.dispose();
    super.dispose();
  }

  void _initVoice() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1);
    flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speakHoroscope() async {
    await flutterTts.speak(horoscopeText);
  }

  Future<void> _loadZodiacAndHoroscope() async {
    await fetchUserZodiacSign();
    await fetchHoroscopeForToday();
  }

  Future<void> fetchUserZodiacSign() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      print("❌ User not logged in!");
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('zodiac_sign, dob')
          .eq('id', userId)
          .single();

      if (response['zodiac_sign'] != null && response['zodiac_sign'].toString().isNotEmpty) {
        setState(() {
          userZodiacSign = response['zodiac_sign'].toLowerCase();
        });
      } else if (response['dob'] != null) {
        DateTime dob = DateTime.parse(response['dob']);
        setState(() {
          userZodiacSign = getZodiacSign(dob).toLowerCase();
        });
      }

      print("✅ User zodiac sign loaded: $userZodiacSign");
    } catch (e) {
      print("❌ Error fetching user zodiac sign: $e");
    }
  }

  Future<void> fetchHoroscopeForToday() async {
    setState(() => isLoading = true);

    final String apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      print('❌ OpenRouter API key not found.');
      setState(() => isLoading = false);
      return;
    }

    try {
      String today = DateTime.now().toIso8601String().substring(0, 10);

      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "mistralai/mistral-7b-instruct",
          "messages": [
            {
              "role": "user",
              "content":
              "Generate a unique, positive, spiritual, inspiring daily horoscope for \"$userZodiacSign\" on \"$today\". Short, hopeful, mobile-friendly."
            }
          ],
          "max_tokens": 300
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        setState(() {
          horoscopeText = content;
        });

        _speakHoroscope(); // ✅ Speak the horoscope automatically
      } else {
        setState(() {
          horoscopeText = 'No horoscope available.';
        });
      }
    } catch (e) {
      setState(() {
        horoscopeText = 'Error getting horoscope.';
      });
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Daily Horoscope'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueGrey.shade900, Colors.black87],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _twinklingStarsBackground(),

          Column(
            children: [
              const BannerAdWidget(),

              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: Colors.white))
                    : _buildHoroscopeCard(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _twinklingStarsBackground() {
    return AnimatedBuilder(
      animation: _starsController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.4 + (_starsController.value * 0.6),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg8.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHoroscopeCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: Colors.black.withOpacity(0.7),
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // ✅ Icon Centered
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/zodiac/$userZodiacSign.png'),
                    ),
                    SizedBox(height: 12),
                    Text(
                      userZodiacSign.toUpperCase(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.share, color: Colors.white),
                      onPressed: () {
                        _shareHoroscope(userZodiacSign, horoscopeText);
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // ✅ Horoscope Text Box
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: Text(
                        horoscopeText,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10),

              // ✅ Read Out Button (Optional)
              ElevatedButton.icon(
                onPressed: _speakHoroscope,
                icon: Icon(Icons.volume_up, color: Colors.white),
                label: Text("Listen", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareHoroscope(String sign, String description) {
    final text = 'Your daily $sign horoscope:\n\n$description';
    Share.share(text);
  }

  String getZodiacSign(DateTime dob) {
    int day = dob.day;
    int month = dob.month;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return "aries";
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return "taurus";
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return "gemini";
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return "cancer";
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return "leo";
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return "virgo";
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return "libra";
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return "scorpio";
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return "sagittarius";
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return "capricorn";
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return "aquarius";
    return "pisces";
  }
}

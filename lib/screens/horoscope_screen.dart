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
    _starsController =
    AnimationController(vsync: this, duration: Duration(seconds: 3))
      ..repeat(reverse: true);
    _loadZodiacAndHoroscope();
  }

  @override
  void dispose() {
    flutterTts.stop();
    _starsController.dispose();
    super.dispose();
  }

  void _initVoice() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("en-GB");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.40);

    // 🌟 Find the best-sounding voice on the device
    List<dynamic> voices = await flutterTts.getVoices;
    for (var voice in voices) {
      if (voice.toString().toLowerCase().contains('neural') ||
          voice.toString().toLowerCase().contains('natural') ||
          voice.toString().toLowerCase().contains('female')) {
        print("🎤 Using voice: $voice");
        await flutterTts.setVoice(voice);
        break;
      }
    }
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

      if (response['zodiac_sign'] != null && response['zodiac_sign']
          .toString()
          .isNotEmpty) {
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

        final cleanedText = content.replaceAll(RegExp(r'#\w+'), '').trim();

        setState(() {
          horoscopeText = cleanedText;
        });

        // ✅ Insert Notification for Horoscope
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await Supabase.instance.client.from('notifications').insert({
            'user_id': userId,
            'title': 'Your Daily Horoscope 🌠',
            'body': 'A new message from the stars is here.',
            'type': 'horoscope',
            'read': false,
            'created_at': DateTime.now().toIso8601String(),
          });
          print('✅ Horoscope notification added!');
        }

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
                    ? Center(
                    child: CircularProgressIndicator(color: Colors.white))
                    : _buildHoroscopeCard(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendHoroscopePicker() {
    DateTime? _selectedDate;
    String _friendZodiac = '';
    String _friendHoroscope = '';
    bool _isFriendLoading = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(
              "✨ Want to check a friend's horoscope?",
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              icon: Icon(Icons.cake, color: Colors.white),
              label: Text(
                  "Pick a Birthday", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent),
            ),
            SizedBox(height: 8),
            if (_selectedDate != null)
              ElevatedButton(
                onPressed: () async {
                  setState(() => _isFriendLoading = true);
                  _friendZodiac = getZodiacSign(_selectedDate!).toLowerCase();

                  final response = await http.post(
                    Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
                    headers: {
                      'Authorization': 'Bearer ${dotenv
                          .env['OPENROUTER_API_KEY'] ?? ''}',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({
                      "model": "mistralai/mistral-7b-instruct",
                      "messages": [
                        {
                          "role": "user",
                          "content": "Generate a unique spiritual horoscope for $_friendZodiac today."
                        }
                      ],
                      "max_tokens": 300
                    }),
                  );

                  if (response.statusCode == 200) {
                    final data = jsonDecode(response.body);
                    final content = data['choices'][0]['message']['content'];
                    final cleaned = content
                        .replaceAll(RegExp(r'#\w+'), '')
                        .trim();
                    setState(() => _friendHoroscope = cleaned);
                  } else {
                    setState(() =>
                    _friendHoroscope = 'Unable to load horoscope.');
                  }
                  setState(() => _isFriendLoading = false);
                },
                child: Text("🔮 See Their Horoscope"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
            if (_isFriendLoading) CircularProgressIndicator(),
            if (_friendHoroscope.isNotEmpty)
              Container(
                margin: EdgeInsets.only(top: 16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _friendHoroscope,
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ),
          ],
        );
      },
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
                image: AssetImage('assets/images/profile.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHoroscopeCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            color: Colors.black.withOpacity(0.7),
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // 🔮 Zodiac Avatar + Share
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage('assets/zodiac/$userZodiacSign.png'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          userZodiacSign.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.white),
                          onPressed: () {
                            _shareHoroscope(userZodiacSign, horoscopeText);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 📜 Horoscope Text Box
                  Container(
                    height: 300, // Make this taller if needed
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: Text(
                          horoscopeText,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🔊 Listen Button
                  ElevatedButton.icon(
                    onPressed: _speakHoroscope,
                    icon: const Icon(Icons.volume_up, color: Colors.white),
                    label: const Text("Listen", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 🎂 Friend Horoscope Section (separate from the card)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "✨ Want to check a friend's horoscope?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _pickFriendBirthday,
                  icon: const Icon(Icons.cake, color: Colors.white),
                  label: const Text("Pick a Birthday", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _pickFriendBirthday() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.deepPurpleAccent,
              onPrimary: Colors.white,
              surface: Colors.black,
              onSurface: Colors.white70,
            ),
            dialogBackgroundColor: Colors.black87,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.purpleAccent,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      String zodiac = getZodiacSign(pickedDate);
      setState(() {
        userZodiacSign = zodiac;
      });
      await fetchHoroscopeForToday();
    }
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

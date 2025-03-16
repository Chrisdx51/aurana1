import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ For API key

class HoroscopeScreen extends StatefulWidget {
  final String? zodiacSign;

  const HoroscopeScreen({Key? key, this.zodiacSign}) : super(key: key);

  @override
  _HoroscopeScreenState createState() => _HoroscopeScreenState();
}

class _HoroscopeScreenState extends State<HoroscopeScreen> {
  Map<String, String> horoscopes = {}; // Holds horoscope results
  bool isLoading = true;

  final List<String> zodiacSigns = [
    'aries', 'taurus', 'gemini', 'cancer', 'leo', 'virgo',
    'libra', 'scorpio', 'sagittarius', 'capricorn', 'aquarius', 'pisces'
  ];

  String userZodiacSign = 'aquarius'; // Default until fetched

  @override
  void initState() {
    super.initState();
    fetchUserZodiacSign().then((_) {
      fetchHoroscopes(); // Once zodiac loaded, fetch horoscope!
    });
  }

  /// ✅ Fetch user's zodiac sign from Supabase
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

      if (response['zodiac_sign'] != null) {
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

  /// ✅ Fetch horoscope from Gemini AI
  Future<void> fetchHoroscopes() async {
    setState(() => isLoading = true);
    Map<String, String> results = {};

    final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      print('❌ Gemini API key not found.');
      setState(() => isLoading = false);
      return;
    }

    try {
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Write a positive, inspiring daily horoscope for the zodiac sign "$userZodiacSign". Keep it spiritual and hopeful.'}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'];

        print("✅ Horoscope fetched: $content");

        results[userZodiacSign] = content;
      } else {
        print('❌ Failed to fetch horoscope: ${response.body}');
        results[userZodiacSign] = 'No horoscope available.';
      }
    } catch (e) {
      print('❌ Error fetching horoscope: $e');
      results[userZodiacSign] = 'Error getting horoscope.';
    }

    setState(() {
      horoscopes = results;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> reorderedSigns = [
      userZodiacSign,
      ...zodiacSigns.where((sign) => sign != userZodiacSign),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Horoscopes'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple, Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg8.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: reorderedSigns.length,
          itemBuilder: (context, index) {
            final sign = reorderedSigns[index];
            final description = horoscopes[sign] ?? 'No data yet';
            return _buildHoroscopeCard(sign, description, index == 0);
          },
        ),
      ),
    );
  }

  Widget _buildHoroscopeCard(String sign, String description, bool isUserSign) {
    return Card(
      color: isUserSign ? Colors.amber.withOpacity(0.9) : Colors.white70,
      elevation: isUserSign ? 10 : 3,
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: AssetImage('assets/zodiac/$sign.png'),
        ),
        title: Text(
          sign.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isUserSign ? Colors.black : Colors.black87,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(color: Colors.black54),
        ),
        trailing: IconButton(
          icon: Icon(Icons.share, color: Colors.deepPurple),
          onPressed: () {
            _shareHoroscope(sign, description);
          },
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

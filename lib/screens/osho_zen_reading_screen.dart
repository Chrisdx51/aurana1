import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/banner_ad_widget.dart';

class OshoZenReadingScreen extends StatefulWidget {
  @override
  _OshoZenReadingScreenState createState() => _OshoZenReadingScreenState();
}

class _OshoZenReadingScreenState extends State<OshoZenReadingScreen> {
  final List<String> zenCards = [
    'ace-of-clouds-osho-zen',
    'ace-of-fire-wallpaper',
    'ace-of-rainbows-osho-zen',
    'ace-of-water-osho-zen',
    'beyond-illusion-osho-zen',
    'condition-osho-zen',
    'creativity-osho-zen-tarot',
    'eight-of-clouds-osho-zen',
    'eight-of-fire-osho-zen',
    'eight-of-rainbows-osho-zen',
    'eight-of-water-osho-zen',
    'existence-osho-zen-wallpaper',
    'five-of-clouds-osho-zen',
    'five-of-fire-osho-zen',
    'five-of-rainbows-osho-zen',
    'five-of-water-osho-zen',
    'four-of-clouds-osho-zen',
    'four-of-fire-osho-zen',
    'four-of-rainbows-osho-zen',
    'four-of-water-osho-zen',
    'inner-voice-osho-zen-tarot',
    'innocence-osho-zen',
    'integration-osho-zen',
    'king-of-clouds',
    'king-of-fire-osho-zen',
    'king-of-rainbows-osho-zen',
    'king-of-water-osho-zen',
    'knight-of-clouds-osho-zen',
    'knight-of-fire-osho-zen',
    'knight-of-rainbows-osho-zen',
    'knight-of-water-osho-zen',
    'new-vision-osho-zen',
    'nine-of-clouds-osho-zen',
    'nine-of-fire-osho-zen',
    'nine-of-rainbow-osho-zen',
    'nine-of-water-osho-zen',
    'no-thingness-osho-zen',
    'page-of-clouds-osho-zen',
    'page-of-fire-osho-zen',
    'page-of-rainbows-osho-zen',
    'page-of-water-osho-zen',
    'past-lives-osho-zen',
    'projections-osho-zen',
    'queen-of-clouds-osho-zen',
    'queen-of-fire-osho-zen',
    'queen-of-rainbows-osho-zen',
    'queen-of-water-osho-zen',
    'seven-of-clouds-osho-zen',
    'seven-of-fire-osho-zen',
    'seven-of-rainbows-osho-zen',
    'six-of-clouds-osho-zen',
    'six-of-fire-osho-zen',
    'six-of-rainbows-osho-zen',
    'six-of-water-osho-zen',
    'ten-of-clouds-osho-zen',
    'ten-of-fire-osho-zen',
    'ten-of-rainbows-osho-zen',
    'ten-of-water-osho-zen',
    'the-aloneness-osho-zen',
    'the-awareness-osho-zen',
    'the-breakthrough-osho-zen',
    'the-change-osho-zen',
    'the-completion-osho-zen',
    'the-courage-osho-zen',
    'the-fool-oshozentarot-wallpaper',
    'the-lovers-osho-zen',
    'the-master-osho-zen',
    'the-rebel-osho-zen-tarot',
    'the-silence-osho-zen',
    'three-of-clouds-osho-zen',
    'three-of-fire-osho-zen',
    'three-of-rainbows-osho-zen',
    'three-of-water-osho-zen',
    'thunderbolt-osho-zen',
    'transformation-osho-zen',
    'two-of-clouds-osho-zen',
    'two-of-fire-zen',
    'two-of-rainbow-osho-zen',
    'two-of-water-osho-zen',
  ];

  DateTime? lastZenReadingTime;
  int zenReadingCount = 0;
  Timer? zenCountdownTimer;
  Duration? zenRemainingTime;

  final List<String> selectedCards = [];
  final Map<String, String> interpretations = {};
  final TextEditingController _questionController = TextEditingController();

  String userQuestion = '';
  bool questionSubmitted = false;
  bool isSpeaking = false;
  bool hasSpoken = false;
  bool cancelSpeech = false;
  bool showReadingAnimation = false;
  bool isSpinning = false;

  late FlutterTts flutterTts;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _initTTS();
    _loadLastZenReadingTime();
    _audioPlayer = AudioPlayer();
  }

  void _initTTS() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage("en-GB");
    flutterTts.setSpeechRate(0.4);
    flutterTts.setPitch(1.0);
    flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _loadLastZenReadingTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTime = prefs.getString('last_zen_reading_time');
    final counter = prefs.getInt('zen_reading_count') ?? 0;

    if (lastTime != null) {
      lastZenReadingTime = DateTime.parse(lastTime);
      final now = DateTime.now();
      final difference = now.difference(lastZenReadingTime!);

      if (difference >= Duration(hours: 24)) {
        zenReadingCount = 0;
        await prefs.setInt('zen_reading_count', 0);
        await prefs.setString('last_zen_reading_time', now.toIso8601String());
      }
    }

    zenReadingCount = counter;
    _updateZenRemainingTime();
    _startZenCountdown();
  }

  Future<void> _saveZenReadingTime() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    zenReadingCount++;

    await prefs.setString('last_zen_reading_time', now.toIso8601String());
    await prefs.setInt('zen_reading_count', zenReadingCount);

    setState(() {
      lastZenReadingTime = now;
      _updateZenRemainingTime();
      _startZenCountdown();
    });
  }

  void _updateZenRemainingTime() {
    if (lastZenReadingTime != null) {
      final now = DateTime.now();
      final nextTime = lastZenReadingTime!.add(Duration(hours: 24));
      zenRemainingTime = nextTime.difference(now).isNegative
          ? Duration.zero
          : nextTime.difference(now);
    } else {
      zenRemainingTime = Duration.zero;
    }
  }

  void _startZenCountdown() {
    zenCountdownTimer?.cancel();
    zenCountdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _updateZenRemainingTime();
        if (zenRemainingTime == Duration.zero) {
          timer.cancel();
        }
      });
    });
  }

  bool _canStartZenReading() {
    return zenReadingCount < 2 || (zenRemainingTime == null || zenRemainingTime == Duration.zero);
  }


  Future<void> _speakInterpretations() async {
    if (isSpeaking || hasSpoken) return;

    isSpeaking = true;
    hasSpoken = true;

    for (final card in selectedCards) {
      if (cancelSpeech) break;

      // 🔮 Convert filename to nice title
      String cleanCardName = formatCardName(card);
      String cardMeaning = interpretations[card] ?? 'Zen message missing.';

      // 🗣️ Speak the card and its meaning
      await flutterTts.speak("The card is $cleanCardName. $cardMeaning");
      await flutterTts.awaitSpeakCompletion(true);

      if (!cancelSpeech) await Future.delayed(Duration(seconds: 1));
    }

    isSpeaking = false;
  }


  String formatCardName(String filename) {
    return filename
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+osho\s+zen|\s+osho|\s+zen|\s+tarot'), '')
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }




  Future<String> _getZenReadingAI(String selectedCard) async {
    try {
      final String? apiKey = dotenv.env['OPENROUTER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) return "Missing API key.";

      String readableCard = formatCardName(selectedCard); // ✅ FIXED: define this here

      String prompt = "You are a Zen oracle. Give a peaceful, insightful spiritual reading for the card '$readableCard' using Osho Zen teachings.";

      if (userQuestion.isNotEmpty) {
        prompt += " The user asks: '$userQuestion'. Provide a connected interpretation.";
      }

      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "openai/gpt-3.5-turbo",
          "messages": [
            {"role": "system", "content": "You are a Zen oracle."},
            {"role": "user", "content": prompt}
          ],
          "max_tokens": 120,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData["choices"] != null) {
        return responseData["choices"][0]["message"]["content"].trim();
      } else {
        print("❌ OpenRouter AI Error: ${responseData["error"]?["message"] ?? 'Unknown error'}");
        return "Unable to channel your Zen reading.";
      }
    } catch (e) {
      print("❌ AI Error: $e");
      return "Unable to channel your Zen reading.";
    }
  }


  void _selectCard() async {
    // ✅ Block reading if over limit
    if (!_canStartZenReading()) return;

    if (selectedCards.length >= 3) return;

    int randomIndex;
    do {
      randomIndex = Random().nextInt(zenCards.length);
    } while (selectedCards.contains(zenCards[randomIndex]));

    final selected = zenCards[randomIndex];
    final readableCard = formatCardName(selected); // ✅ Clean name
    await _audioPlayer.play(AssetSource('sounds/card_flip.mp3'));
    final aiReading = await _getZenReadingAI(selected);

    setState(() {
      selectedCards.add(selected);
      interpretations[selected] = aiReading;
    });

    if (selectedCards.length == 3) {
      await Future.delayed(Duration(milliseconds: 800));
      setState(() => showReadingAnimation = true);

      await _saveZenReadingTime(); // ✅ Save the timestamp so limit applies
      _speakInterpretations();     // ✅ Speak the readings
    }
  }



  void _resetReading() {
    setState(() {
      selectedCards.clear();
      interpretations.clear();
      hasSpoken = false;
      cancelSpeech = false;
      showReadingAnimation = false;
      questionSubmitted = false;
      userQuestion = '';
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    _audioPlayer.dispose();
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Osho Zen Reading", style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/misc2.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  BannerAdWidget(),
                  SizedBox(height: 10),
                  _buildZenInstructionBox(),
                  if (!questionSubmitted) _buildQuestionBox(),
                  if (questionSubmitted) ...[
                    Text("Tap to reveal your Zen path...",
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                    SizedBox(height: 10),
                    _buildCardRow(),
                    SizedBox(height: 10),
                    if (selectedCards.length < 3)
                      ElevatedButton(
                        onPressed: _selectCard,
                        child: Text("Pick a Zen Card"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    if (selectedCards.length == 3) ...[
                      _buildZenRevealText(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                        child: _buildReadingBox(),
                      ),
                    ],


                  ],
                  SizedBox(height: 40),

                  _buildZenExplainerBox(), // 👈 Add this line


                ],
              ),
            ),

          ),
        ],
      ),
    );
  }

  Widget _buildZenExplainerBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.purpleAccent.withOpacity(0.6),
              blurRadius: 20,
              spreadRadius: 6,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "🌸 What is Osho Zen?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 6,
                    color: Colors.white70,
                    offset: Offset(0, 0),
                  )
                ],
              ),
            ),
            SizedBox(height: 10),
            Text(
              "The Osho Zen Tarot is not your traditional tarot. It's a journey into the present moment, designed to reflect your inner awareness and spiritual path. It doesn’t predict the future — it shows your state of being, your energy, and the whispers of your soul.\n\nThese cards speak through Zen wisdom. Use them not for answers from outside, but insight from within. Trust your intuition, ask your question, and let the magic of stillness speak.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZenInstructionBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4A148C), // deep purple
              Color(0xFF6A1B9A), // royal violet
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurpleAccent.withOpacity(0.7),
              blurRadius: 20,
              spreadRadius: 5,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '🧘 Your Zen Reading',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.4,
                shadows: [
                  Shadow(
                    blurRadius: 6,
                    color: Colors.purpleAccent,
                    offset: Offset(1, 1),
                  )
                ],
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Before we begin, take a deep breath.\n\nAsk a spiritual question about your soul, journey, or energy. The Osho Zen cards will reveal guidance from within.\n\nPick three cards and allow the silence to speak truth.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildQuestionBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Column(
        children: [
          TextField(
            controller: _questionController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'What would you like to explore?',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.black45,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              if (_questionController.text.trim().isEmpty) return;

              setState(() {
                userQuestion = _questionController.text.trim();
                questionSubmitted = true;
                print("✅ Zen Question submitted: $userQuestion");
              });
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0), // ⬛ No rounded corners
              ),
              elevation: 6,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.deepPurple,
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purpleAccent, Colors.white],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(0), // Match outer button
              ),
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  'Submit Question',
                  style: TextStyle(
                    color: Colors.blue, // 🔷 Blue font
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildCardRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
            (index) => Container(
          margin: EdgeInsets.all(8),
          height: 150,
          width: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade800, Colors.purple.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.8),
                blurRadius: 20,
                spreadRadius: 3,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: selectedCards.length > index
                ? Image.asset(
              'assets/images/osho zen/${selectedCards[index]}.png',
              fit: BoxFit.cover,
            )
                : Container(
              color: Colors.black38,
              child: Center(
                child: Text(
                  "?",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.purpleAccent,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZenRevealText() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          'Tap to reveal your Zen path…',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.purpleAccent,
                blurRadius: 12,
                offset: Offset(0, 0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingBox() {
    return Animate(
      effects: showReadingAnimation ? [FadeEffect(), ScaleEffect()] : [],
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.purpleAccent.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Zen Reading:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            ...selectedCards.map((card) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(interpretations[card] ?? ''),
                ],
              ),
            )),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (!isSpeaking) _speakInterpretations();
                    },
                    icon: Icon(Icons.volume_up, color: Colors.white),
                    label: Text("Speak Again", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      cancelSpeech = true;
                      flutterTts.stop();
                      isSpeaking = false;
                    },
                    icon: Icon(Icons.stop_circle, color: Colors.white),
                    label: Text("Stop", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

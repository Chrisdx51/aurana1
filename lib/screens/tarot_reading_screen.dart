import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart'; // ✅ For animations
import '../widgets/banner_ad_widget.dart'; // ✅ Make sure this path matches yours!

class TarotReadingScreen extends StatefulWidget {
  @override
  _TarotReadingScreenState createState() => _TarotReadingScreenState();
}

class _TarotReadingScreenState extends State<TarotReadingScreen> {
  final List<String> tarotCards = [
    'The Fool', 'The Magician', 'The High Priestess', 'The Empress', 'The Emperor',
    'The Hierophant', 'The Lovers', 'The Chariot', 'Strength', 'The Hermit',
    'Wheel of Fortune', 'Justice', 'The Hanged Man', 'Death', 'Temperance',
    'The Devil', 'The Tower', 'The Star', 'The Moon', 'The Sun', 'Judgment', 'The World',
  ];

  final Map<String, String> tarotInterpretations = {};
  final List<String> selectedCards = [];

  DateTime? lastReadingTime;
  bool isSpinning = false;
  int cardsSelected = 0;
  Timer? countdownTimer;
  Duration? remainingTime;
  late AudioPlayer _audioPlayer;
  final TextEditingController _questionController = TextEditingController();

  bool questionSubmitted = false;
  String userQuestion = "";
  bool showReadingAnimation = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadLastReadingTime();
  }

  @override
  void dispose() {
    _questionController.dispose(); // ✅ Clean up the controller
    countdownTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadLastReadingTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTime = prefs.getString('last_reading_time');
    if (lastTime != null) {
      setState(() {
        lastReadingTime = DateTime.parse(lastTime);
        _updateRemainingTime();
        _startCountdownTimer();
      });
    }
  }

  Future<void> _saveLastReadingTime() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString('last_reading_time', now.toIso8601String());
    setState(() {
      lastReadingTime = now;
      _updateRemainingTime();
      _startCountdownTimer();
    });
  }

  void _updateRemainingTime() {
    if (lastReadingTime != null) {
      final now = DateTime.now();
      final nextReadingTime = lastReadingTime!.add(Duration(hours: 4));
      remainingTime = nextReadingTime.difference(now).isNegative
          ? Duration.zero
          : nextReadingTime.difference(now);
    } else {
      remainingTime = Duration.zero;
    }
  }

  void _startCountdownTimer() {
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _updateRemainingTime();
        if (remainingTime == Duration.zero) {
          timer.cancel();
        }
      });
    });
  }

  bool _canStartNewReading() {
    return remainingTime == null || remainingTime == Duration.zero;
  }

  Future<String> getTarotReadingAI(String selectedCard) async {
    try {
      final String? apiKey = dotenv.env['OPENROUTER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception("❌ Missing OpenRouter AI Key in .env file!");
      }

      String prompt = "You are a mystical tarot expert giving a deep, insightful, and spiritual interpretation of the tarot card '$selectedCard'.";

      if (userQuestion.isNotEmpty) {
        prompt += " The user asked: '$userQuestion'. Provide a personalized reading that connects with their question.";
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
            {"role": "system", "content": "You are a mystical tarot expert."},
            {"role": "user", "content": prompt}
          ],
          "max_tokens": 100
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData["choices"][0]["message"]["content"].trim();
      } else {
        print("❌ OpenRouter API Error: ${responseData["error"]["message"]}");
        return "Spiritual insight could not be retrieved.";
      }
    } catch (e) {
      print("❌ Error getting AI-generated tarot reading: $e");
      return "Spiritual insight unavailable.";
    }
  }

  void _playCardFlipSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/card_flip.mp3'));
    } catch (e) {
      print("❌ Error playing sound: $e");
    }
  }

  void _selectRandomCard() async {
    if (selectedCards.length < 3) {
      int randomIndex;
      do {
        randomIndex = Random().nextInt(tarotCards.length);
      } while (selectedCards.contains(tarotCards[randomIndex]));

      _playCardFlipSound();

      String chosenCard = tarotCards[randomIndex];
      String aiReading = await getTarotReadingAI(chosenCard);

      setState(() {
        selectedCards.add(chosenCard);
        tarotInterpretations[chosenCard] = aiReading;
        cardsSelected++;
      });

      if (selectedCards.length == 3) {
        _saveLastReadingTime();
        setState(() {
          showReadingAnimation = true;
        });
      }
    }
  }

  void _startReading() {
    setState(() {
      isSpinning = true;
    });

    Timer(Duration(seconds: 2), () {
      setState(() {
        isSpinning = false;
        _selectRandomCard();
      });
    });
  }

  void _resetReading() {
    setState(() {
      selectedCards.clear();
      tarotInterpretations.clear();
      cardsSelected = 0;
      questionSubmitted = false;
      userQuestion = "";
      showReadingAnimation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFB3E5FC),
                Color(0xFF81D4FA),
                Color(0xFF9575CD),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Tarot Reading',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/27.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: BannerAdWidget(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildInstructionBox(),
                        if (!questionSubmitted) _buildQuestionBox(),
                        if (questionSubmitted) ...[
                          SizedBox(height: 20),
                          _buildCardSelection(),
                          SizedBox(height: 20),
                          _buildPickCardButton(),
                          if (selectedCards.length == 3) ...[
                            SizedBox(height: 20),
                            _buildReadingBox(),
                          ],
                        ],
                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 1,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Your Tarot Reading',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Ask your question and let the cards reveal their wisdom.\nPick three cards to unlock your reading.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          TextField(
            controller: _questionController, // ✅ FIXED: use the controller at the top
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'What would you like to ask?',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.black54,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              if (_questionController.text.trim().isEmpty) return;

              setState(() {
                userQuestion = _questionController.text.trim();
                questionSubmitted = true;

                print("✅ Question submitted: $userQuestion");
              });
            },
            icon: Icon(Icons.send, color: Colors.white),
            label: Text('Submit Question'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCardSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        3,
            (index) => Container(
          height: 140,
          width: 100,
          margin: EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 8,
                offset: Offset(2, 4),
              ),
            ],
          ),
          child: selectedCards.length > index
              ? Image.asset(
            'assets/images/tarot/${selectedCards[index].toLowerCase().replaceAll(" ", "_")}.png',
            fit: BoxFit.cover,
          )
              : Container(
            color: Colors.black26,
            child: Center(
              child: Text(
                '?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickCardButton() {
    return ElevatedButton(
      onPressed: !_canStartNewReading()
          ? null
          : (isSpinning || cardsSelected >= 3)
          ? null
          : _startReading,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black87,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        !_canStartNewReading()
            ? 'Next Reading in ${remainingTime?.inHours ?? 0}h ${(remainingTime?.inMinutes ?? 0) % 60}m'
            : cardsSelected >= 3
            ? 'Max Cards Selected'
            : 'Pick a Card',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Widget _buildReadingBox() {
    return Animate(
      effects: showReadingAnimation
          ? [
        ScaleEffect(
          duration: Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          begin: Offset(0.8, 0.8),
          end: Offset(1.0, 1.0),
        ),
        FadeEffect(duration: Duration(milliseconds: 800)),
      ]
          : [],
      child: Container(
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.symmetric(horizontal: 16),
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
            Text('Your Reading:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            ...selectedCards.map((card) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(tarotInterpretations[card] ?? 'Loading...'),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

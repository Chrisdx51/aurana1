import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart'; // ✅ For animations
import '../widgets/banner_ad_widget.dart'; // ✅ Make sure this path matches yours!
import 'osho_zen_reading_screen.dart';

class TarotReadingScreen extends StatefulWidget {
  @override
  _TarotReadingScreenState createState() => _TarotReadingScreenState();
}

class _TarotReadingScreenState extends State<TarotReadingScreen> {
  final List<String> tarotCards = [
    'The Chariot',
    'Death',
    'The Devil',
    'The Emperor',
    'The Empress',
    'The Fool',
    'The Hanging Man',
    'The Hermit',
    'The Hierophant',
    'The High Priestess',
    'The Judgement',
    'The Justice',
    'The Lovers',
    'The Magician',
    'The Moon',
    'The Star',
    'The Strength',
    'The Sun',
    'The Temperance',
    'The Tower',
    'The Wheel of Fortune',
    'The World',
    'Ace of Cups',
    'Ace of Pentacles',
    'Ace of Swords',
    'Ace of Wands',
    'Two of Cups',
    'Two of Pentacles',
    'Two of Swords',
    'Two of Wands',
    'Three of Cups',
    'Three of Pentacles',
    'Three of Swords',
    'Three of Wands',
    'Four of Cups',
    'Four of Pentacles',
    'Four of Swords',
    'Four of Wands',
    'Five of Cups',
    'Five of Pentacles',
    'Five of Swords',
    'Five of Wands',
    'Six of Cups',
    'Six of Pentacles',
    'Six of Swords',
    'Six of Wands',
    'Seven of Cups',
    'Seven of Pentacles',
    'Seven of Swords',
    'Seven of Wands',
    'Eight of Cups',
    'Eight of Pentacles',
    'Eight of Swords',
    'Eight of Wands',
    'Nine of Cups',
    'Nine of Pentacles',
    'Nine of Swords',
    'Nine of Wands',
    'Ten of Cups',
    'Ten of Pentacles',
    'Ten of Swords',
    'Ten of Wands',
    'Page of Cups',
    'Page of Pentacles',
    'Page of Swords',
    'Page of Wands',
    'Knight of Cups',
    'Knight of Pentacles',
    'Knight of Swords',
    'Knight of Wands',
    'Queen of Cups',
    'Queen of Pentacles',
    'Queen of Swords',
    'Queen of Wands',
    'King of Cups',
    'King of Pentacles',
    'King of Swords',
    'King of Wands',
  ];


  final Map<String, String> tarotInterpretations = {};
  final List<String> selectedCards = [];

  DateTime? lastReadingTime;
  bool isSpinning = false;
  int readingCount = 0;
  int cardsSelected = 0;
  Timer? countdownTimer;
  Duration? remainingTime;
  late AudioPlayer _audioPlayer;
  final TextEditingController _questionController = TextEditingController();



  bool questionSubmitted = false;
  String userQuestion = "";
  bool showReadingAnimation = false;
  bool hasSpoken = false;
  bool isDisposed = false;
  bool isSpeaking = false;
  bool cancelSpeech = false;

  late FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadLastReadingTime();
    _initVoice();
  }


  void _initVoice() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage("en-GB");
    flutterTts.setPitch(1);
    flutterTts.setSpeechRate(0.40);
    flutterTts.setVoice({"name": "en-GB-Wavenet-C", "locale": "en-GB"});
    flutterTts.awaitSpeakCompletion(true); // ✅ Wait for each speech to finish
  }


  Future<void> _speakTarotReadings() async {
    if (hasSpoken || isDisposed || isSpeaking) return;
    hasSpoken = true;
    isSpeaking = true;
    cancelSpeech = false;

    for (String card in selectedCards) {
      if (isDisposed || cancelSpeech) break;

      final intro = "The card is $card. Here is the reading:";
      final reading = tarotInterpretations[card] ?? '';
      await flutterTts.speak("$intro $reading");

      // Wait until speaking is done or canceled
      await flutterTts.awaitSpeakCompletion(true);

      // Add small gap between readings unless cancelled
      if (!cancelSpeech) await Future.delayed(Duration(seconds: 1));
    }

    isSpeaking = false;
  }




  @override
  void dispose() {
    isDisposed = true;
    cancelSpeech = true;
    flutterTts.stop();
    flutterTts.awaitSpeakCompletion(false);

    _audioPlayer.dispose();
    _questionController.dispose();
    countdownTimer?.cancel();
    super.dispose();
  }



  Future<void> _loadLastReadingTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTime = prefs.getString('last_reading_time');
    final counter = prefs.getInt('reading_count') ?? 0;

    if (lastTime != null) {
      lastReadingTime = DateTime.parse(lastTime);
      final now = DateTime.now();
      final difference = now.difference(lastReadingTime!);

      if (difference >= Duration(hours: 12)) {
        // Reset count and timestamp
        readingCount = 0;
        await prefs.setInt('reading_count', 0);
        await prefs.setString('last_reading_time', now.toIso8601String());
      }
    }
    readingCount = counter;
    _updateRemainingTime();
    _startCountdownTimer();
  }


  Future<void> _saveLastReadingTime() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    readingCount++;

    await prefs.setString('last_reading_time', now.toIso8601String());
    await prefs.setInt('reading_count', readingCount);

    setState(() {
      lastReadingTime = now;
      _updateRemainingTime();
      _startCountdownTimer();
    });
  }


  void _updateRemainingTime() {
    if (lastReadingTime != null) {
      final now = DateTime.now();
      final nextReadingTime = lastReadingTime!.add(Duration(hours: 0));
      remainingTime = nextReadingTime
          .difference(now)
          .isNegative
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
    return readingCount < 2 || (remainingTime == null || remainingTime == Duration.zero);
  }


  Future<String> getTarotReadingAI(String selectedCard) async {
    try {
      final String? apiKey = dotenv.env['OPENROUTER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception("❌ Missing OpenRouter API Key in .env file!");
      }

      // 🪄 Clean card name for the AI
      String cleanCard = selectedCard.replaceAll('-', ' ').trim();

      String prompt = """
You are a mystical tarot expert. Provide a spiritual and poetic interpretation of the tarot card '$cleanCard'. 
First give a mystical plaque-style summary in 1–2 sentences.
Then provide a deeper intuitive meaning that connects to the soul.

If the user has asked a question, respond in a way that feels personally connected to their energy.
""";

      if (userQuestion.isNotEmpty) {
        prompt += "\nThe user asks: '$userQuestion'. Please channel an answer that links to their card.";
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
            {"role": "system", "content": "You are a mystical tarot reader."},
            {"role": "user", "content": prompt}
          ],
          "max_tokens": 300, // ⬆️ More space for deep readings
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData["choices"][0]["message"]["content"].trim();
      } else {
        print("❌ OpenRouter API Error: ${responseData["error"]["message"]}");
        return "Spiritual insight unavailable.";
      }
    } catch (e) {
      print("❌ AI Tarot Error: $e");
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

        // 🗣️ Speak after short delay so all is rendered first
        Future.delayed(Duration(seconds: 2), () {
          _speakTarotReadings(); // ✅ Only trigger after 3 cards
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
      hasSpoken = false; // ✅ Reset flag on new reading
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
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
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

                          SizedBox(height: 12), // 👈 spacing for Zen button
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => OshoZenReadingScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              shape: CircleBorder(),
                              padding: EdgeInsets.all(24),
                              backgroundColor: Colors.purpleAccent,
                              shadowColor: Colors.deepPurple,
                              elevation: 12,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.brightness_3, size: 30, color: Colors.white),
                                SizedBox(height: 4),
                                Text('Zen', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),

                          if (selectedCards.length == 3) ...[
                            SizedBox(height: 20),

                          ],

                        ],




                        if (selectedCards.length == 3) ...[
                            SizedBox(height: 20),
                            _buildReadingBox(),
                          ],
                        _buildLimitNoticeCard(),

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
                fontSize: 16,
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
            controller: _questionController,
            // ✅ FIXED: use the controller at the top
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'What would you like to ask?',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.black54,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              if (_questionController.text
                  .trim()
                  .isEmpty) return;

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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
  String formatCardImagePath(String cardName) {
    // Convert "Wheel of Fortune" to "the-wheel-of-fortune-gilded-tarot.png"
    String clean = cardName.toLowerCase().replaceAll(" ", "-");

    // Add "the-" prefix if missing
    if (cardName.toLowerCase().startsWith("the ") && !clean.startsWith("the-")) {
      clean = "the-" + clean;
    }

    return 'assets/images/tarot/$clean-gilded-tarot.png';
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
            formatCardImagePath(selectedCards[index]),
            fit: BoxFit.cover,
          )
              : Container(
            color: Colors.black26,
            child: Center(
              child: Text(
                '?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
            ? 'Next Reading in ${remainingTime?.inHours ?? 0}h ${(remainingTime
            ?.inMinutes ?? 0) % 60}m'
            : cardsSelected >= 3
            ? 'Max Cards Selected'
            : 'Pick a Card',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
  Widget _buildLimitNoticeCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.purpleAccent.withOpacity(0.5),
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Spiritual insights may be limited right now. Please check back soon. You may receive 2 readings per day.",
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Reading:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),

              // Show all 3 cards
              ...selectedCards.map((card) =>
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(tarotInterpretations[card] ?? 'Loading...'),
                      ],
                    ),
                  )),

              SizedBox(height: 16),

              // 🎤 Speak + Stop Buttons Row (No overflow now!)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (isSpeaking) return;

                        hasSpoken = false;
                        await _speakTarotReadings();
                      },

                      icon: Icon(
                          Icons.volume_up, color: Colors.white, size: 20),
                      label: Text(
                        "Speak Again",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        cancelSpeech = true;
                        flutterTts.stop();
                        isSpeaking = false;
                      },
                      icon:
                      Icon(Icons.stop_circle, color: Colors.white, size: 20),
                      label: Text(
                        "Stop",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                    ),

                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

  }
}


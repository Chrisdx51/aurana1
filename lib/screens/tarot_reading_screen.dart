import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:aurana/screens/home_screen.dart';

class TarotReadingScreen extends StatefulWidget {
  @override
  _TarotReadingScreenState createState() => _TarotReadingScreenState();
}

class _TarotReadingScreenState extends State<TarotReadingScreen> with SingleTickerProviderStateMixin {
  final List<String> tarotCards = [
    'The Fool', 'The Magician', 'The High Priestess', 'The Empress', 'The Emperor',
    'The Hierophant', 'The Lovers', 'The Chariot', 'Strength', 'The Hermit',
    'Wheel of Fortune', 'Justice', 'The Hanged Man', 'Death', 'Temperance',
    'The Devil', 'The Tower', 'The Star', 'The Moon', 'The Sun', 'Judgment', 'The World',
  ];

  final Map<String, String> tarotInterpretations = {
    'The Fool': 'A fresh start, new beginnings, and infinite possibilities.',
    'The Magician': 'You have the power to manifest your desires.',
    'The High Priestess': 'Trust your intuition and inner wisdom.',
    'The Empress': 'Fertility, abundance, and nurturing energy surround you.',
    'The Emperor': 'Establish structure and take charge of your life.',
    'The Hierophant': 'Seek spiritual wisdom and tradition.',
    'The Lovers': 'A choice must be made in your relationships or values.',
    'The Chariot': 'Victory through determination and willpower.',
    'Strength': 'Inner strength and courage will guide you.',
    'The Hermit': 'Take time for introspection and solitude.',
    'Wheel of Fortune': 'Change is inevitable. Embrace the cycles of life.',
    'Justice': 'Fairness, truth, and accountability are key.',
    'The Hanged Man': 'A time of pause and letting go is needed.',
    'Death': 'Transformation and rebirth are at hand.',
    'Temperance': 'Find balance and harmony in your life.',
    'The Devil': 'Beware of temptations and unhealthy attachments.',
    'The Tower': 'Sudden upheaval will bring clarity.',
    'The Star': 'Hope, inspiration, and renewal guide you.',
    'The Moon': 'Pay attention to dreams and subconscious messages.',
    'The Sun': 'Joy, success, and clarity await you.',
    'Judgment': 'A time of awakening and self-assessment.',
    'The World': 'Completion, accomplishment, and fulfillment.'
  };

  final List<String> selectedCards = [];
  DateTime? lastReadingTime;
  bool isSpinning = false;
  int cardsSelected = 0;
  Timer? countdownTimer;
  Duration? remainingTime;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadLastReadingTime();
  }

  @override
  void dispose() {
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
      final nextReadingTime = lastReadingTime!.add(Duration(hours: 6));
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
      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "openai/gpt-3.5-turbo",
          "messages": [
            {
              "role": "system",
              "content": "You are a mystical tarot expert that gives deep and insightful interpretations of tarot cards."
            },
            {
              "role": "user",
              "content": "What is the spiritual meaning of the tarot card: $selectedCard?"
            }
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(
          'Tarot Reading',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
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
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Text(
                  'Your Tarot Reading',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                Row(
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
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: !_canStartNewReading()
                      ? null
                      : (isSpinning || cardsSelected >= 3)
                      ? null
                      : _startReading,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    !_canStartNewReading()
                        ? 'Next Reading Available in ${remainingTime?.inHours ?? 0}h ${(remainingTime?.inMinutes ?? 0) % 60}m'
                        : cardsSelected >= 3
                        ? 'Max Cards Selected'
                        : 'Pick a Card',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                if (selectedCards.length == 3) ...[
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Reading:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 12),
                        ...selectedCards.map((card) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 4),
                              FutureBuilder<String>(
                                future: getTarotReadingAI(card),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  } else if (snapshot.hasError) {
                                    return Text("❌ Error fetching tarot reading.");
                                  } else {
                                    return Text(
                                      snapshot.data ?? "No interpretation found.",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 20),
                Text(
                  selectedCards.length < 3
                      ? "🔮 Choose three cards to unlock your reading! 🔮"
                      : "✨ Your fate is revealed! ✨",
                  style: TextStyle(color: Colors.yellowAccent, fontSize: 18, fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
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
}
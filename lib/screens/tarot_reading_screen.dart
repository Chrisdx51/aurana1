import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TarotReadingScreen extends StatefulWidget {

  @override
  _TarotReadingScreenState createState() => _TarotReadingScreenState();
}

class _TarotReadingScreenState extends State<TarotReadingScreen> {
  final List<String> tarotCards = [
    'The Fool',
    'The Magician',
    'The High Priestess',
    'The Empress',
    'The Emperor',
    'The Hierophant',
    'The Lovers',
    'The Chariot',
    'Strength',
    'The Hermit',
    'Wheel of Fortune',
    'Justice',
    'The Hanged Man',
    'Death',
    'Temperance',
    'The Devil',
    'The Tower',
    'The Star',
    'The Moon',
    'The Sun',
    'Judgment',
    'The World',
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
  DateTime? lastReadingTime; // Track the last reading time
  bool isSpinning = false;
  int cardsSelected = 0; // Track how many cards have been selected for the current reading
  Timer? countdownTimer; // Timer for countdown updates
  Duration? remainingTime; // Time remaining until the next reading

  @override
  void initState() {
    super.initState();
    _loadLastReadingTime();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
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
      final nextReadingTime = lastReadingTime!.add(Duration(hours: 12));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87, // Mystic black color
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Tarot Reading',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/parchment_background.png'),
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                // Display selected cards
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
                  // Show reading below cards
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
                                  Text(
                                    tarotInterpretations[card] ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
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

  void _selectRandomCard() {
    if (selectedCards.length < 3) {
      int randomIndex;
      do {
        randomIndex = Random().nextInt(tarotCards.length);
      } while (selectedCards.contains(tarotCards[randomIndex]));

      setState(() {
        selectedCards.add(tarotCards[randomIndex]);
        cardsSelected++;
      });

      if (selectedCards.length == 3) {
        _saveLastReadingTime(); // Save the last reading time
      }
    }
  }
}

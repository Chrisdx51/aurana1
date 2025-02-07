import 'dart:math'; // ✅ For random example questions & answers
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt; // ✅ Import speech-to-text

class SpiritualGuidanceScreen extends StatefulWidget {
  @override
  _SpiritualGuidanceScreenState createState() => _SpiritualGuidanceScreenState();
}

class _SpiritualGuidanceScreenState extends State<SpiritualGuidanceScreen> {
  final TextEditingController _questionController = TextEditingController();
  final FocusNode _focusNode = FocusNode(); // ✅ Handles keyboard behavior
  stt.SpeechToText _speech = stt.SpeechToText(); // ✅ Speech recognition
  bool _isListening = false; // ✅ Tracks if voice input is active

  final List<String> exampleQuestions = [
    "How can I bring more peace into my daily life?",
    "What spiritual practice should I focus on today?",
    "How can I improve my connection with the universe?",
    "What is blocking my personal growth?",
    "What energy is guiding me this week?",
    "How can I attract positive vibrations today?",
  ];

  final List<String> spiritualAnswers = [
    "🌿 Trust in the journey; every step brings growth.",
    "✨ Your energy attracts what you align with. Stay positive.",
    "🧘 Breathe deeply. Your soul is guiding you to clarity.",
    "🌟 The universe supports you. Open your heart to receive.",
    "🔮 Focus on gratitude, and the universe will bless you in return.",
    "🌈 Let go of fear, and embrace the light within.",
  ];

  String response = ""; // ✅ Placeholder for AI response
  bool isLoading = false; // ✅ Show loading effect

  @override
  Widget build(BuildContext context) {
    String randomExample = exampleQuestions[Random().nextInt(exampleQuestions.length)];

    return Scaffold(
      appBar: AppBar(
        title: Text("Spiritual Guidance"),
        backgroundColor: Colors.blue.shade300, // ✅ Tranquil blue
      ),
      body: GestureDetector(
        onTap: () => _focusNode.unfocus(), // ✅ Hide keyboard when tapping outside
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Spiritual Journey 🌿",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Ask for daily wisdom, insights, and inspiration to guide your soul and uplift your spirit.",
                        style: TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                      SizedBox(height: 10),

                      // 📌 Response Display (Now Appears Above the Example)
                      if (isLoading) Center(child: CircularProgressIndicator()),
                      if (response.isNotEmpty)
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              response,
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),

                      SizedBox(height: 8),

                      // 📌 Example Question (Now Much Smaller)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: EdgeInsets.all(5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "🌟 Example Question",
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "\"$randomExample\"",
                                style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 📌 Chat Input Bar with Voice Input Button
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: "Ask a spiritual question...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),

                  // 🎙 Voice Input Button
                  IconButton(
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.blue),
                    onPressed: _listen,
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      String question = _questionController.text.trim();

                      if (question.length < 5) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Please ask a full question."),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        isLoading = true;
                        response = "";
                      });

                      await Future.delayed(Duration(seconds: 2));

                      setState(() {
                        isLoading = false;
                        response = spiritualAnswers[Random().nextInt(spiritualAnswers.length)];
                      });

                      _questionController.clear();
                      _focusNode.unfocus();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600),
                    child: Text("Ask"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎙 **Voice Input Function**
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == "notListening") {
            setState(() => _isListening = false);
          }
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _questionController.text = val.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }
}

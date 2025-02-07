import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpiritualGuidanceScreen extends StatefulWidget {
  @override
  _SpiritualGuidanceScreenState createState() => _SpiritualGuidanceScreenState();
}

class _SpiritualGuidanceScreenState extends State<SpiritualGuidanceScreen> {
  final TextEditingController _questionController = TextEditingController();
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _response = ""; // AI response placeholder

  // 🎤 Start Listening
  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Status: $status'),
      onError: (error) => print('Error: $error'),
    );

    if (available) {
      setState(() {
        _isListening = true;
      });

      _speech.listen(
        onResult: (result) {
          setState(() {
            _questionController.text = result.recognizedWords;
          });
        },
      );
    } else {
      setState(() {
        _isListening = false;
      });
    }
  }

  // 🎤 Stop Listening
  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  // 🔮 Handle Asking a Question
  void _askQuestion() {
    String question = _questionController.text.trim();

    if (question.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please ask a full question.")),
      );
      return;
    }

    setState(() {
      _response = _generateSpiritualResponse(question);
    });

    // Clear input after asking
    _questionController.clear();
  }

  // 🔮 Generate a Spiritual Response (Simulated for Now)
  String _generateSpiritualResponse(String question) {
    List<String> responses = [
      "🌿 Trust in the universe, and clarity will come.",
      "🌙 Meditate and align with your higher self.",
      "✨ Embrace the journey, and the answers will reveal themselves.",
    ];
    return responses[question.length % responses.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // ✅ Fixes Overflow Issue
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Spiritual Guidance"),
        backgroundColor: Colors.blue.shade300,
      ),
      body: SingleChildScrollView( // ✅ Prevents overflow when keyboard appears
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📌 Page Introduction (Smaller Font)
              Text(
                "Your Spiritual Journey",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                "Ask for daily wisdom, insights, and inspiration to guide your soul and uplift your spirit.",
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              SizedBox(height: 15),

              // 🌟 AI Response Display
              if (_response.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _response,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              SizedBox(height: 10),

              // ✨ Example Question Box (Fixed Overflow)
              Container(
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10), // Smaller Padding
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "🌟 Example Question",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "\"How can I attract positive energy?\"",
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // 📌 Chat Input with Mystic Ball Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      decoration: InputDecoration(
                        hintText: "Ask a spiritual question...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    color: _isListening ? Colors.red : Colors.blue,
                    onPressed: () {
                      if (_isListening) {
                        _stopListening();
                      } else {
                        _startListening();
                      }
                    },
                  ),
                  GestureDetector(
                    onTap: _askQuestion,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue, // ✅ Changed to Blue
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "🔮",
                        style: TextStyle(fontSize: 22),
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

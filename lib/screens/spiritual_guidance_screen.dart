import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ✅ Import your BannerAdWidget here
import '../widgets/banner_ad_widget.dart'; // Adjust the path if needed!

class SpiritualGuidanceScreen extends StatefulWidget {
  @override
  _SpiritualGuidanceScreenState createState() => _SpiritualGuidanceScreenState();
}

class _SpiritualGuidanceScreenState extends State<SpiritualGuidanceScreen> {
  final TextEditingController _questionController = TextEditingController();
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _response = "";

  @override
  void initState() {
    super.initState();
  }

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

  // 🔮 Call OpenRouter AI
  Future<String> _fetchAIResponse(String question) async {
    final String? apiKey = dotenv.env['OPENROUTER_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      print("❌ Missing OpenRouter API Key");
      return "🔒 API key not found. Please check your configuration.";
    }

    final url = Uri.parse("https://openrouter.ai/api/v1/chat/completions");

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "model": "openai/gpt-3.5-turbo",
          "messages": [
            {"role": "system", "content": "You are a spiritual guide offering calm and uplifting advice."},
            {"role": "user", "content": question},
          ],
          "max_tokens": 200,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final String reply = jsonResponse['choices'][0]['message']['content'];
        return reply.trim();
      } else {
        print("❌ Error: ${response.body}");
        return "⚠️ The stars are silent. Please try again later.";
      }
    } catch (error) {
      print("❌ Error fetching AI response: $error");
      return "⚠️ Connection to the cosmos failed. Please try again.";
    }
  }

  // 🌟 Ask a Spiritual Question
  void _askQuestion() async {
    String question = _questionController.text.trim();

    if (question.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please ask a full question.")),
      );
      return;
    }

    setState(() {
      _response = "";
    });

    // Show Loading Animation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)),
    );

    String aiResponse = await _fetchAIResponse(question);

    Navigator.pop(context); // Close Loading

    setState(() {
      _response = aiResponse;
    });

    _questionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 🌌 Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/misc2.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🌟 Overlay + Content
          SafeArea(
            child: Column(
              children: [
                // ✅ BANNER AD WIDGET RIGHT BELOW SAFEAREA!
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: BannerAdWidget(),
                ),

                // Custom AppBar Replacement
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          "Spiritual Guidance",
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Body Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ✨ Instructions
                        Text(
                          "Ask for daily wisdom, insights, and inspiration.\nLet the universe guide your soul.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 20),

                        // 🔮 AI Response Box
                        if (_response.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withOpacity(0.6), Colors.deepPurple.withOpacity(0.4)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              _response,
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),

                        SizedBox(height: 20),

                        // 🌠 Example Question
                        Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "🌟 Example Question",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "\"What guidance does the universe have for me today?\"",
                                style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // 🗣️ Question Input Bar with Mic and Crystal Ball
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Question Text Field
                      Expanded(
                        child: TextField(
                          controller: _questionController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Ask your spiritual question...",
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      // Microphone Button
                      IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.redAccent : Colors.white,
                        ),
                        onPressed: () {
                          if (_isListening) {
                            _stopListening();
                          } else {
                            _startListening();
                          }
                        },
                      ),

                      // Crystal Ball Button
                      GestureDetector(
                        onTap: _askQuestion,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.deepPurpleAccent, Colors.purpleAccent],
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Text("🔮", style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

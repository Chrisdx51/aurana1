import 'dart:math'; // ✅ For random example questions & answers
import 'package:flutter/material.dart';

class SpiritualGuidanceScreen extends StatefulWidget {
  @override
  _SpiritualGuidanceScreenState createState() => _SpiritualGuidanceScreenState();
}

class _SpiritualGuidanceScreenState extends State<SpiritualGuidanceScreen> {
  final TextEditingController _questionController = TextEditingController();
  final FocusNode _focusNode = FocusNode(); // ✅ Handles keyboard behavior

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
    // ✅ Select a different example each time
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
                child: SingleChildScrollView( // ✅ Prevents overflow when keyboard appears
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Spiritual Journey 🌿",
                        style: TextStyle(
                          fontSize: 13, // ✅ Small so it fits on **ONE line**
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1, // ✅ Ensures it does not wrap to the next line
                        overflow: TextOverflow.ellipsis, // ✅ Prevents overflow issues
                      ),
                      SizedBox(height: 3), // ✅ Adjusted spacing
                      Text(
                        "Ask for daily wisdom, insights, and inspiration to guide your soul and uplift your spirit.",
                        style: TextStyle(fontSize: 11, color: Colors.black87), // ✅ Small enough for neat display
                      ),
                      SizedBox(height: 10),

                      // 📌 Response Display (Now Appears Above the Example)
                      if (isLoading)
                        Center(child: CircularProgressIndicator()), // ✅ Show loading animation
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

                      SizedBox(height: 8), // ✅ Adjusted spacing

                      // 📌 Example Question (Now Much Smaller)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        color: Colors.blue.shade50, // ✅ Light blue background
                        child: Padding(
                          padding: EdgeInsets.all(5), // ✅ Reduced padding significantly
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "🌟 Example Question",
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800), // ✅ Smaller header
                              ),
                              SizedBox(height: 2), // ✅ Minimized spacing
                              Text(
                                "\"$randomExample\"",
                                style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.black87), // ✅ Smaller example text
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

            // 📌 Chat Input Bar
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
                      focusNode: _focusNode, // ✅ Allows dismissing keyboard when tapping outside
                      decoration: InputDecoration(
                        hintText: "Ask a spiritual question...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      String question = _questionController.text.trim();
                      
                      // ✅ Validation: Ensure input is a real question (no single letters)
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

                      await Future.delayed(Duration(seconds: 2)); // ✅ Simulate processing time

                      setState(() {
                        isLoading = false;
                        response = spiritualAnswers[Random().nextInt(spiritualAnswers.length)];
                      });

                      _questionController.clear(); // ✅ Clears input after asking
                      _focusNode.unfocus(); // ✅ Hides keyboard after pressing "Ask"
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
}

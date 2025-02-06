import 'package:flutter/material.dart';

class AIInsightsScreen extends StatefulWidget {
  @override
  _AIInsightsScreenState createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _response = "Ask a question or share your thoughts...";

  void _generateInsight() {
    String userInput = _inputController.text.trim();
    if (userInput.isNotEmpty) {
      setState(() {
        _response = "AI Response: Your spiritual journey is unfolding beautifully. Trust in the universe! 🌌";
        _inputController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Insight generated!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Insights & Guidance')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ask for spiritual insights:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: "Type your question here...",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: _generateInsight,
                child: Text('Get AI Insight'),
              ),
            ),
            SizedBox(height: 20),
            Text(
              _response,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.purple),
            ),
          ],
        ),
      ),
    );
  }
}

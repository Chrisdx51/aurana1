import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SessionDetailsScreen extends StatelessWidget {
  final Map<String, String> session;

  SessionDetailsScreen({required this.session});

  // 📌 Function to open video URL
  Future<void> _launchURL() async {
    final Uri url = Uri.parse(session['videoUrl'] ?? "");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(session['title'] ?? "Session"), backgroundColor: Colors.blue.shade300),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session['title'] ?? "",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              session['description'] ?? "",
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: _launchURL,
                icon: Icon(Icons.play_arrow),
                label: Text("Watch Session"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

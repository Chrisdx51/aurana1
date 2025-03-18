import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../models/journal_entry.dart';

class JournalScreen extends StatefulWidget {
  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with SingleTickerProviderStateMixin {
  List<JournalEntry> journalEntries = [];
  final TextEditingController _contentController = TextEditingController();

  bool _showFullLastEntry = false;

  // Animation for floating orbs
  late AnimationController _orbController;
  late Animation<double> _orbAnimation;

  @override
  void initState() {
    super.initState();
    _loadJournalEntries();

    // Floating Orbs Animation Controller
    _orbController =
    AnimationController(vsync: this, duration: Duration(seconds: 8))
      ..repeat(reverse: true);
    _orbAnimation = Tween<double>(begin: 0, end: 50).animate(
      CurvedAnimation(parent: _orbController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _orbController.dispose();
    super.dispose();
  }

  Future<void> _loadJournalEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedEntries = prefs.getString('journal_entries');
    if (savedEntries != null) {
      setState(() {
        List<dynamic> decodedData = json.decode(savedEntries);
        journalEntries =
            decodedData.map((item) => JournalEntry.fromJson(item)).toList();
      });
    }
  }

  Future<void> _saveJournalEntries() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> entryList =
    journalEntries.map((entry) => entry.toJson()).toList();
    await prefs.setString('journal_entries', json.encode(entryList));
  }

  void _addJournalEntry() {
    String content = _contentController.text.trim();
    if (content.isNotEmpty) {
      setState(() {
        journalEntries.insert(
          0,
          JournalEntry(
            title: "Entry",
            content: content,
            dateTime: DateTime.now().toString(),
            mood: "Neutral",
          ),
        );
      });
      _saveJournalEntries();
      _contentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✨ Your thoughts are safely stored.')),
      );
    }
  }

  void _deleteJournalEntry(int index) {
    setState(() {
      journalEntries.removeAt(index);
    });
    _saveJournalEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // fallback if image fails
      appBar: AppBar(
        title: Text(
          "Aurana Journal",
          style: TextStyle(
            fontFamily: 'DancingScript',
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple.withOpacity(0.8),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background + Orbs
          _buildBackground(),
          AnimatedBuilder(
            animation: _orbAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  _floatingOrb(left: 50, top: 100 + _orbAnimation.value),
                  _floatingOrb(right: 30, top: 300 - _orbAnimation.value),
                ],
              );
            },
          ),
          // Journal Content
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildLastEntry(),
                      SizedBox(height: 20),
                      _buildJournalInput(),
                      SizedBox(height: 20),
                      _buildPastEntries(),
                    ],
                  ),
                ),
              ),
              _buildChatBar(),
            ],
          ),
        ],
      ),
    );
  }

  // ⬇️ BACKGROUND
  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/misc2.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // ⬇️ FLOATING ORBS
  Widget _floatingOrb({double? left, double? right, required double top}) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.purpleAccent.withOpacity(0.4),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  // ⬇️ LAST ENTRY CARD (Tap to Expand)
  Widget _buildLastEntry() {
    if (journalEntries.isEmpty) return SizedBox();

    final entry = journalEntries.first;

    return GestureDetector(
      onTap: () {
        setState(() {
          _showFullLastEntry = !_showFullLastEntry;
        });
      },
      child: Card(
        color: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 3,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Last Entry",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.amberAccent,
                ),
              ),
              Divider(color: Colors.white24),
              SizedBox(height: 8),
              Text(
                _showFullLastEntry
                    ? entry.content
                    : (entry.content.length > 100
                    ? entry.content.substring(0, 100) + "..."
                    : entry.content),
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                entry.dateTime,
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ⬇️ JOURNAL INPUT AREA
  Widget _buildJournalInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Write in your Journal",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _contentController,
          decoration: InputDecoration(
            hintText: "Start writing your thoughts here...",
            hintStyle: TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          maxLines: 6,
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        SizedBox(height: 10),
        Center(
          child: ElevatedButton(
            onPressed: _addJournalEntry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent.withOpacity(0.8),
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 10,
              shadowColor: Colors.deepPurple,
            ),
            child: Text(
              "Save Entry",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ⬇️ PAST ENTRIES LIST
  Widget _buildPastEntries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Past Journal Entries",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: journalEntries.length,
          itemBuilder: (context, index) {
            final entry = journalEntries[index];
            return Card(
              color: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  entry.content.length > 50
                      ? entry.content.substring(0, 50) + "..."
                      : entry.content,
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  entry.dateTime,
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete_forever, color: Colors.redAccent),
                  onPressed: () => _deleteJournalEntry(index),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ⬇️ AURA CHAT BAR (for fast thoughts)
  Widget _buildChatBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurpleAccent.withOpacity(0.7), Colors.black87],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _contentController,
              decoration: InputDecoration(
                hintText: "Quick thought...",
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
              style: TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.amberAccent),
            onPressed: _addJournalEntry,
          ),
        ],
      ),
    );
  }
}

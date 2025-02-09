import 'package:flutter/material.dart';
import 'dart:convert'; // For decoding JSON data
import 'package:http/http.dart' as http;

class MoonCycleScreen extends StatefulWidget {
  @override
  _MoonCycleScreenState createState() => _MoonCycleScreenState();
}

class _MoonCycleScreenState extends State<MoonCycleScreen> {
  String currentPhase = "Loading...";
  String illumination = "";
  String phaseMeaning = "Fetching the current moon phase...";

  final Map<String, String> phaseMeanings = {
    'New Moon': 'A time for new beginnings and setting intentions.',
    'Waxing Crescent': 'Focus on growth and learning.',
    'First Quarter': 'Take action and overcome obstacles.',
    'Waxing Gibbous': 'Refine your goals and prepare for success.',
    'Full Moon': 'Celebrate achievements and let go of negativity.',
    'Waning Gibbous': 'Reflect on lessons learned and give thanks.',
    'Last Quarter': 'Release and forgive to make space for new things.',
    'Waning Crescent': 'Rest, recharge, and prepare for new cycles.',
  };

  @override
  void initState() {
    super.initState();
    fetchMoonPhase();
  }

  Future<void> fetchMoonPhase() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.farmsense.net/v1/moonphases/?d=${DateTime.now().millisecondsSinceEpoch}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final moonPhase = data[0]['Phase']; // Adjusted based on the API response
        final moonIllumination = data[0]['Illumination'];

        setState(() {
          currentPhase = moonPhase;
          illumination = "$moonIllumination%";
          phaseMeaning = phaseMeanings[moonPhase] ?? "No meaning available.";
        });
      } else {
        setState(() {
          currentPhase = "Error";
          phaseMeaning = "Failed to fetch moon phase data.";
        });
      }
    } catch (e) {
      setState(() {
        currentPhase = "Error";
        phaseMeaning = "Failed to fetch moon phase data.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text('Moon Cycle Tracker'),
      ),
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/parchment_background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: 20),
              Text(
                'Current Moon Phase',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 10),
              // Moon Phase Info
              Card(
                margin: EdgeInsets.symmetric(horizontal: 16),
                color: Colors.black54,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentPhase,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.yellowAccent,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        phaseMeaning,
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      if (illumination.isNotEmpty)
                        Text(
                          'Illumination: $illumination',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Moon Phase Meanings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: phaseMeanings.length,
                  itemBuilder: (context, index) {
                    final phase = phaseMeanings.keys.elementAt(index);
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.black54,
                      child: ListTile(
                        title: Text(
                          phase,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Text(
                          phaseMeanings[phase]!,
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

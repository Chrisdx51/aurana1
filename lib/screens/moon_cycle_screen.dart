import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/banner_ad_widget.dart'; // ✅ Your existing banner ad widget

class MoonCycleScreen extends StatefulWidget {
  @override
  _MoonCycleScreenState createState() => _MoonCycleScreenState();
}

class _MoonCycleScreenState extends State<MoonCycleScreen> {
  String currentPhase = "Loading...";
  String illumination = "";
  String phaseMeaning = "Fetching the current moon phase...";

  final Map<String, String> phaseMeanings = {
    'New Moon': '🌑 A time for new beginnings and setting intentions.',
    'Waxing Crescent': '🌒 Focus on growth and learning.',
    'First Quarter': '🌓 Take action and overcome obstacles.',
    'Waxing Gibbous': '🌔 Refine your goals and prepare for success.',
    'Full Moon': '🌕 Celebrate achievements and let go of negativity.',
    'Waning Gibbous': '🌖 Reflect on lessons learned and give thanks.',
    'Last Quarter': '🌗 Release and forgive to make space for new things.',
    'Waning Crescent': '🌘 Rest, recharge, and prepare for new cycles.',
  };

  @override
  void initState() {
    super.initState();
    fetchMoonPhase();
  }

  Future<void> fetchMoonPhase() async {
    try {
      final response = await http.get(Uri.parse(
        'https://api.farmsense.net/v1/moonphases/?d=${DateTime.now().millisecondsSinceEpoch}',
      ));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final moonPhase = data[0]['Phase'];
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
        backgroundColor: Colors.deepPurple.withOpacity(0.9),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          '🌙 Moon Cycle',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 🌌 Background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/misc2.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              // 🌟 Ad Banner at the Top
              BannerAdWidget(),
              SizedBox(height: 12),

              // 🌕 Moon Icon
              Icon(Icons.brightness_2_rounded, size: 64, color: Colors.white70),
              SizedBox(height: 10),

              Text(
                currentPhase,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellowAccent,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),

              if (illumination.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'Illumination: $illumination',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  phaseMeaning,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 10),

              ElevatedButton.icon(
                onPressed: fetchMoonPhase,
                icon: Icon(Icons.refresh),
                label: Text("Refresh Moon Data"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple,
                ),
              ),

              SizedBox(height: 20),

              Text(
                'Moon Phase Meanings',
                style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: phaseMeanings.length,
                  itemBuilder: (context, index) {
                    final phase = phaseMeanings.keys.elementAt(index);
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      color: Colors.black54,
                      child: ListTile(
                        leading: Icon(Icons.circle, color: Colors.amberAccent, size: 12),
                        title: Text(
                          phase,
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Text(
                          phaseMeanings[phase]!,
                          style: TextStyle(color: Colors.white70),
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

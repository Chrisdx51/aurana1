import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import '../services/supabase_service.dart';

class NewFeaturesSliderScreen extends StatefulWidget {
  const NewFeaturesSliderScreen({Key? key}) : super(key: key);

  @override
  State<NewFeaturesSliderScreen> createState() => _NewFeaturesSliderScreenState();
}

class _NewFeaturesSliderScreenState extends State<NewFeaturesSliderScreen> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final _dreamController = TextEditingController();
  final _pastLifeController = TextEditingController();
  String _dreamResult = '';
  String _pastLifeResult = '';
  String _spiritAnimal = '';
  String _ritual = '';


  @override
  void initState() {
    super.initState();
    _loadMoonInfo();
    _loadSpiritAnimal();
  }

  Future<void> _loadMoonInfo() async {
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd').format(now);
    final moonPhase = now.day % 4; // quick fake phase
    final phases = ['New Moon', 'Waxing Moon', 'Full Moon', 'Waning Moon'];
    final rituals = ['Set intentions', 'Manifest goals', 'Gratitude ritual', 'Release negativity'];
    setState(() {
      _ritual = '${phases[moonPhase]}: ${rituals[moonPhase]}';
    });
  }

  Future<void> _loadSpiritAnimal() async {
    final key = dotenv.env['OPENROUTER_API_KEY'] ?? '';
    if (key.isEmpty) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Fetch user profile for DOB
    final profile = await supabase.from('profiles').select('dob').eq('id', user.id).single();
    final dob = profile['dob'] ?? '';

    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "mistralai/mistral-7b-instruct",
        "messages": [
          {
            "role": "user",
            "content": "Using ancient spiritual wisdom and the birthdate $dob, assign a spirit animal and explain its spiritual meaning."
          }
        ],
        "max_tokens": 300
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _spiritAnimal = data['choices'][0]['message']['content'];
      });
    } else {
      setState(() {
        _spiritAnimal = 'Unable to retrieve your spirit animal right now.';
      });
    }
  }


  Future<void> _interpretDream() async {
    final dream = _dreamController.text.trim();
    if (dream.isEmpty) return;

    final key = dotenv.env['OPENROUTER_API_KEY'] ?? '';
    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "mistralai/mistral-7b-instruct",
        "messages": [
          {"role": "user", "content": "Interpret this dream spiritually: $dream"}
        ],
        "max_tokens": 300
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _dreamResult = data['choices'][0]['message']['content'];
      });
    }
  }

  Future<void> _analyzePastLife() async {
    final input = _pastLifeController.text.trim();
    if (input.isEmpty) return;

    final key = dotenv.env['OPENROUTER_API_KEY'] ?? '';
    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "mistralai/mistral-7b-instruct",
        "messages": [
          {"role": "user", "content": "Give a spiritual past life reading based on: $input"}
        ],
        "max_tokens": 300
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _pastLifeResult = data['choices'][0]['message']['content'];
      });
    }
  }

  void _onRevealDream() async {
    final input = _dreamController.text.trim();
    if (input.isEmpty) return;

    // Show loading result temporarily
    setState(() {
      _dreamResult = '';
    });

    // 👁 Replace this with your actual Supabase/AI call
    final meaning = await SupabaseService().interpretDream(input);

    setState(() {
      _dreamResult = meaning;
    });
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.deepPurple.shade700,
          title: Text('🔮 Explore Realms'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Dreams'),
              Tab(text: 'Past Life'),
              Tab(text: 'Spirit Animal'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Dream Journal
            _buildDreamTab(
              controller: _dreamController,
              onReveal: _onRevealDream,
              result: _dreamResult,
            ),


            // Past Life
            _buildPastLifeTab(
              controller: _pastLifeController,
              onReveal: _analyzePastLife,
              result: _pastLifeResult,
            ),
            // Spirit Animal
            _buildStaticResultWithShuffle(
              result: _spiritAnimal,
              onShuffle: _loadSpiritAnimal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputPage({
    required String title,
    required TextEditingController controller,
    required VoidCallback onPressed,
    required String result,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text(title, style: TextStyle(color: Colors.white, fontSize: 18)),
          SizedBox(height: 12),
          TextField(
            controller: controller,
            style: TextStyle(color: Colors.white),
            maxLines: 5,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white10,
              hintText: "Type here...",
              hintStyle: TextStyle(color: Colors.white54),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(Icons.auto_awesome),
            label: Text("Reveal with AI"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          ),
          if (result.isNotEmpty) ...[
            SizedBox(height: 20),
            Text("🔮 Result:", style: TextStyle(color: Colors.white70)),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(result, style: TextStyle(color: Colors.white70)),
            ),
            if (result.isNotEmpty) ...[
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Share.share(
                    "🦉 My Spirit Animal is...\n\n$result\n\nDiscovered on Aurana 🌌",
                    subject: "My Spirit Animal on Aurana",
                  );
                },
                icon: Icon(Icons.share),
                label: Text("Share"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],

          ]
        ],
      ),
    );
  }

  Widget _buildPastLifeTab({
    required TextEditingController controller,
    required VoidCallback onReveal,
    required String result,
  }) {
    final examplePrompts = [
      "I'm a curious dreamer who loves old temples.",
      "I feel drawn to the ocean and the stars.",
      "I'm fascinated by ancient wisdom and healing.",
      "I’ve always felt connected to nature and rituals.",
      "I'm a peaceful soul with a love for music and poetry.",
    ];

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/misc2.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // 🌌 Title
          Text(
            "🌌 Discover Who You Were...",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 10, color: Colors.black)],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),

          // ✨ Subtitle
          Text(
            "Tap a suggestion below or write your own to begin.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 20),

          // 💬 Suggestion Boxes
          Column(
            children: examplePrompts.map((text) {
              return Container(
                margin: EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => controller.text = text,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Center(
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 20),

          // ✍️ User Input
          TextField(
            controller: controller,
            maxLines: 4,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white10,
              hintText: "Write about your energy or feelings...",
              hintStyle: TextStyle(color: Colors.white54),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          SizedBox(height: 20),

          // 🔮 Reveal Button
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: 1.05),
              duration: Duration(seconds: 2),
              curve: Curves.easeInOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purpleAccent.withOpacity(0.7),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: onReveal,
                      icon: Icon(Icons.psychology),
                      label: Text("Reveal My Past Life"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 28),

          // 🔮 Result Display
          if (result.isNotEmpty)
            Column(
              children: [
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 700),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    );
                  },
                  child: Container(
                    key: ValueKey(result),
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.5),
                          blurRadius: 18,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      result,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Share.share("🌌 My Past Life Reading:\n\n$result\n\n✨ Find your own with Aurana!");
                  },
                  icon: Icon(Icons.share),
                  label: Text("Share"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            )

          else
            Shimmer.fromColors(
              baseColor: Colors.white10,
              highlightColor: Colors.white30,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

          SizedBox(height: 28),

          // ⚠️ Disclaimer
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "⚠️ This past life reading is for spiritual fun and inspiration only. It’s not a factual analysis, but a glimpse into your soul’s potential journey.",
              style: TextStyle(color: Colors.white60, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDreamTab({
    required TextEditingController controller,
    required VoidCallback onReveal,
    required String result,
  }) {
    final examplePrompts = [
      "Flying above a city",
      "Teeth falling out",
      "Chased by shadows",
      "Talking animals",
      "Lost in a forest",
      "Meeting a past loved one",
      "Drowning in water",
      "Floating in space",
    ];

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/misc2.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            "🌙 Discover the Deeper Meaning of Your Dream",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 10, color: Colors.black)],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            "Tap a symbol that matches your dream, or describe it in your own words. The universe will help decode the message 💭✨",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: examplePrompts.map((prompt) {
              return GestureDetector(
                onTap: () {
                  controller.text = prompt;
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurpleAccent.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    prompt,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          TextField(
            controller: controller,
            maxLines: 4,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white10,
              hintText: "What happened in your dream? Be specific...",
              hintStyle: TextStyle(color: Colors.white54),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: 1.05),
              duration: Duration(seconds: 2),
              curve: Curves.easeInOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.tealAccent.withOpacity(0.7),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: onReveal,
                      icon: Icon(Icons.nightlight_round),
                      label: Text("Reveal the Meaning"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 30),
          if (result.isNotEmpty)
            Column(
              children: [
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 600),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    );
                  },
                  child: Container(
                    key: ValueKey(result),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.tealAccent.withOpacity(0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.tealAccent.withOpacity(0.5),
                          blurRadius: 18,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      result,
                      style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Share.share("💤 My Dream Meaning:\n\n$result\n\n🌙 Find your own with Aurana!");
                  },
                  icon: Icon(Icons.share),
                  label: Text("Share"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            )
          else
            Shimmer.fromColors(
              baseColor: Colors.white10,
              highlightColor: Colors.white30,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          SizedBox(height: 30),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "🌀 This dream interpretation is guided by AI and spiritual symbolism. While it's often insightful, dreams are deeply personal and mysterious — results may vary based on your energy, intent, and clarity.",
              style: TextStyle(color: Colors.white60, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticResultWithShuffle({
  required String result,
  required VoidCallback onShuffle,
}) {
  return Container(
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/images/misc2.png'),
        fit: BoxFit.cover,
      ),
    ),
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          "🧘 Your Inner Spirit Animal Guide Awaits...",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 10, color: Colors.black)],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Text(
          "Tap Shuffle to reveal your spirit animal — let the energies align...",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 30),

        // 🔮 Glowing Shuffle Button
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: 1.05),
            duration: Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purpleAccent.withOpacity(0.8),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: onShuffle,
                    icon: Icon(Icons.shuffle),
                    label: Text("Shuffle"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        SizedBox(height: 30),

        // ✨ Result Box with shimmer while waiting
        AnimatedSwitcher(
          duration: Duration(milliseconds: 600),
          child: result.isEmpty
              ? Shimmer.fromColors(
            baseColor: Colors.white24,
            highlightColor: Colors.white54,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
              : Column(
            key: ValueKey(result),
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  result,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20),

              // 📤 Share Button
              ElevatedButton.icon(
                onPressed: () {
                  Share.share(
                    "🦉 My Spirit Animal is...\n\n$result\n\nDiscovered on Aurana 🌌",
                    subject: "My Spirit Animal on Aurana",
                  );
                },
                icon: Icon(Icons.share),
                label: Text("Share"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
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
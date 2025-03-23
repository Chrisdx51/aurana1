import 'dart:io';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AuraDetailScreen extends StatefulWidget {
  final String imagePath;
  final String auraMeaning;
  final Color auraColor;
  final String timestamp;

  const AuraDetailScreen({
    Key? key,
    required this.imagePath,
    required this.auraMeaning,
    required this.auraColor,
    required this.timestamp,
  }) : super(key: key);

  @override
  State<AuraDetailScreen> createState() => _AuraDetailScreenState();
}

class _AuraDetailScreenState extends State<AuraDetailScreen> with SingleTickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late AnimationController _glowController;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initBannerAd();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _glowController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _initBannerAd() async {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // ✅ Replace with live ad ID before launch!
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );

    await _bannerAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // fallback
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/profile.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                if (_isAdLoaded && _bannerAd != null)
                  Container(
                    color: Colors.transparent,
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildAuraImage(),
                          const SizedBox(height: 20),
                          _buildAuraMeaning(),
                          const SizedBox(height: 10),
                          _buildTimestamp(),
                          const SizedBox(height: 20),
                          _buildInsightCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildConfetti(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "Aura Details",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48), // for symmetry
        ],
      ),
    );
  }

  Widget _buildAuraImage() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: widget.auraColor, width: 3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.cover,
            ),
          ),
        ).animate().fadeIn(duration: 500.ms),
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: RadialGradient(
                  colors: [
                    widget.auraColor.withOpacity(0.4 + (_glowController.value * 0.3)),
                    Colors.transparent
                  ],
                  radius: 1.0,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAuraMeaning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Text(
        widget.auraMeaning,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: widget.auraColor,
        ),
        textAlign: TextAlign.center,
      ),
    ).animate().fadeIn(duration: 700.ms);
  }

  Widget _buildTimestamp() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        'Captured on: ${widget.timestamp}',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    ).animate().fadeIn();
  }

  Widget _buildInsightCard() {
    return Card(
      color: Colors.white.withOpacity(0.15),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Personal Insight",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              _generateInsight(widget.auraColor),
              style: const TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.3);
  }

  Widget _buildConfetti() {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _confettiController,
        blastDirectionality: BlastDirectionality.explosive,
        numberOfParticles: 20,
        shouldLoop: false,
        colors: [widget.auraColor, Colors.white, Colors.amberAccent],
      ),
    );
  }

  String _generateInsight(Color color) {
    if (color.red > color.green && color.red > color.blue) {
      return "Your vibrant red aura shows you're bursting with passion and vitality. Today is your day to take bold action and lead with confidence!";
    } else if (color.green > color.red && color.green > color.blue) {
      return "Your green aura radiates healing and balance. Spend time reconnecting with nature and focus on nurturing both yourself and others.";
    } else if (color.blue > color.red && color.blue > color.green) {
      return "Your calming blue aura reveals a deep sense of peace and clarity. Embrace open communication and trust your inner wisdom today.";
    } else if (color == Colors.purple) {
      return "Your purple aura reflects spiritual insight and deep intuition. Trust your inner guide and take time for reflection and meditation.";
    } else if (color == Colors.yellow) {
      return "A bright yellow aura shows your joy and intellect shining through. Spread positivity and explore new creative ideas!";
    } else {
      return "An energetic orange aura surrounds you with enthusiasm and adventure. Embrace change and open yourself to exciting new opportunities!";
    }
  }
}

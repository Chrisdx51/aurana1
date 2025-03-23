import 'dart:io';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'aura_detail_screen.dart';
import '../database/aura_database_helper.dart';

class AuraHistoryScreen extends StatefulWidget {
  const AuraHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AuraHistoryScreen> createState() => _AuraHistoryScreenState();
}

class _AuraHistoryScreenState extends State<AuraHistoryScreen> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
    _initBannerAd();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _initBannerAd() async {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Replace with your live ad unit ID before launch!
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
      backgroundColor: Colors.black,
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
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: AuraDatabaseHelper().fetchAuraDetails(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading history: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                        return _buildEmptyState();
                      } else if (snapshot.hasData) {
                        final data = snapshot.data!;
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            final aura = data[index];
                            return _buildAuraCard(aura).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.3);
                          },
                        );
                      } else {
                        return const Center(
                          child: Text(
                            'Unexpected error occurred.',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }
                    },
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
                "Aura History",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildAuraCard(Map<String, dynamic> aura) {
    final auraPath = aura['imagePath'];
    final auraMeaning = aura['auraMeaning'];
    final timestamp = aura['timestamp'] ?? 'Unknown Date';
    final String colorString = aura['auraColor'] ?? '#000000';
    late Color auraColor;

    try {
      auraColor = Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      auraColor = Colors.black;
      print('Error parsing color: $e');
    }

    return Dismissible(
      key: ValueKey(aura['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        await AuraDatabaseHelper().deleteAuraDetail(aura['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aura entry deleted.')),
        );
        setState(() {}); // refresh the list
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: auraColor.withOpacity(0.7), width: 2),
          boxShadow: [
            BoxShadow(
              color: auraColor.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ListTile(
          leading: auraPath != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(auraPath),
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          )
              : const Icon(Icons.image_not_supported, size: 50, color: Colors.white70),
          title: Text(
            auraMeaning ?? 'Unknown Meaning',
            style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Saved on: $timestamp',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AuraDetailScreen(
                  imagePath: auraPath ?? '',
                  auraMeaning: auraMeaning ?? 'Unknown Meaning',
                  auraColor: auraColor,
                  timestamp: timestamp,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.white.withOpacity(0.5)),
          const SizedBox(height: 20),
          const Text(
            'No aura history found.',
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 10),
          const Text(
            'Capture your first aura to see it here!',
            style: TextStyle(fontSize: 14, color: Colors.white54),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.3),
    );
  }

  Widget _buildConfetti() {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _confettiController,
        blastDirectionality: BlastDirectionality.explosive,
        numberOfParticles: 20,
        shouldLoop: false,
        colors: [
          Colors.amberAccent,
          Colors.white,
          Colors.blueAccent,
          Colors.purpleAccent,
        ],
      ),
    );
  }
}

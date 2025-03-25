import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'all_ads_page.dart';
import 'home_screen.dart';

class PaymentPage extends StatefulWidget {
  final String adId;

  const PaymentPage({
    Key? key,
    required this.adId,
  }) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(duration: const Duration(seconds: 5));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Ad Submission Successful!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildBackground(),
          _buildConfetti(),
          _buildMainContent(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/misc2.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _confettiController,
        blastDirectionality: BlastDirectionality.explosive,
        emissionFrequency: 0.05,
        numberOfParticles: 20,
        gravity: 0.2,
        colors: const [
          Colors.redAccent,
          Colors.orangeAccent,
          Colors.yellowAccent,
          Colors.greenAccent,
          Colors.blueAccent,
          Colors.indigoAccent,
          Colors.purpleAccent,
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            const Text(
              'Congratulations!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.amberAccent,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurpleAccent),
              ),
              child: const Text(
                'Your ad has been submitted successfully.\n\n'
                    '✨ All ads are currently FREE! ✨\n\n'
                    'Once approved, it will be live in our Sacred Marketplace.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Celebrate your success! 🎉\nShare your ad with friends and grow your sacred business.',
              style: TextStyle(
                color: Colors.amberAccent,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            _seeAllAdsButton(),
            const SizedBox(height: 20),

            _returnHomeButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _seeAllAdsButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AllAdsPage()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 10,
        shadowColor: Colors.deepPurpleAccent.withOpacity(0.6),
      ),
      icon: const Icon(Icons.list_alt, color: Colors.white),
      label: const Text(
        'See All Ads',
        style: TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _returnHomeButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(userName: '')),
              (route) => false,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amberAccent,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 10,
        shadowColor: Colors.amberAccent.withOpacity(0.6),
      ),
      icon: const Icon(Icons.home, color: Colors.black),
      label: const Text(
        'Return Home',
        style: TextStyle(
          fontSize: 16,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

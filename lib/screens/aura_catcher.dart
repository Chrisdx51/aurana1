import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../database/aura_database_helper.dart';
import 'aura_history_screen.dart';
import 'aura_analysis_screen.dart';

class AuraCatcherScreen extends StatefulWidget {
  const AuraCatcherScreen({Key? key}) : super(key: key);

  @override
  _AuraCatcherScreenState createState() => _AuraCatcherScreenState();
}

class _AuraCatcherScreenState extends State<AuraCatcherScreen> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  XFile? _capturedImage;
  Color _auraColor = Colors.transparent;
  String _auraColorName = '';
  String _auraMeaning = '';

  int _currentCameraIndex = 0;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  final dbHelper = AuraDatabaseHelper();

  GlobalKey _previewContainerKey = GlobalKey();

  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initBannerAd();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _bannerAd?.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();

    if (_cameras != null && _cameras!.isNotEmpty) {
      // Start with the first available camera (default)
      _currentCameraIndex = 0;
      _setCamera(_cameras![_currentCameraIndex]);
    }
  }

  Future<void> _setCamera(CameraDescription cameraDescription) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    setState(() {
      _isCameraInitialized = true;
    });
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.isEmpty) return;

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    _setCamera(_cameras![_currentCameraIndex]);
  }

  Future<void> _initBannerAd() async {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );

    await _bannerAd!.load();
  }

  Future<void> _captureImage() async {
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final image = await _cameraController!.takePicture();

        bool isPersonDetected = await _detectPerson(image.path);

        if (isPersonDetected) {
          final colorData = await _generateAuraReading();

          setState(() {
            _capturedImage = image;
            _auraColor = colorData['color'];
            _auraColorName = colorData['colorName'];
            _auraMeaning = colorData['meaning'];
          });

          String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

          await dbHelper.saveAuraDetail(
            image.path,
            _auraMeaning,
            _auraColorName,
            timestamp,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuraAnalysisScreen(
                imagePath: image.path,
                auraColor: _auraColor,
                auraMeaning: _auraMeaning,
                affirmations: _generateAffirmations(_auraColor),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No person detected. Please try again.")),
          );
        }
      }
    } catch (e) {
      print("❌ Error capturing image: $e");
    }
  }

  Future<bool> _detectPerson(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final poseDetector = GoogleMlKit.vision.poseDetector();
      final poses = await poseDetector.processImage(inputImage);
      await poseDetector.close();
      return poses.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _generateAuraReading() async {
    final random = math.Random();

    final readings = [
      {
        'color': Colors.red,
        'colorName': 'Red',
        'meaning':
        'Your aura is Red. You are full of life energy, passion, and power. It’s time to act boldly and lead with strength. Today, ground yourself and pursue your ambitions fearlessly. 🔥'
      },
      {
        'color': Colors.green,
        'colorName': 'Green',
        'meaning':
        'Your aura is Green. You are healing and growing in balance. This is a time of renewal and heart-centered connections. Surround yourself with nature for deeper alignment. 🌿'
      },
      {
        'color': Colors.blue,
        'colorName': 'Blue',
        'meaning':
        'Your aura is Blue. Calm, clarity, and honesty radiate from you. You have a gift for communication and empathy—express yourself openly and listen to others. 🌊'
      },
      {
        'color': Colors.purple,
        'colorName': 'Purple',
        'meaning':
        'Your aura is Purple. You are deeply intuitive and spiritually aware. Trust your inner guidance and seek wisdom within. This is a powerful time for self-reflection and vision. 🔮'
      },
      {
        'color': Colors.yellow,
        'colorName': 'Yellow',
        'meaning':
        'Your aura is Yellow. Joy, optimism, and intellect surround you. You light up any space with your radiant energy. Use this time to inspire others and unleash your creativity! ☀️'
      },
      {
        'color': Colors.orange,
        'colorName': 'Orange',
        'meaning':
        'Your aura is Orange. You radiate excitement, enthusiasm, and vitality. Embrace your creative passions and take bold steps forward. The world is ready for your energy! 🧡'
      },
    ];

    final selected = readings[random.nextInt(readings.length)];
    return selected;
  }

  List<String> _generateAffirmations(Color color) {
    if (color == Colors.red) {
      return ["I am grounded and strong.", "I lead with confidence and passion."];
    } else if (color == Colors.green) {
      return ["Healing energy flows through me.", "I am balanced in body and spirit."];
    } else if (color == Colors.blue) {
      return ["I express myself with clarity and compassion.", "Peace begins with me."];
    } else if (color == Colors.purple) {
      return ["I trust my intuition.", "I am connected to universal wisdom."];
    } else if (color == Colors.yellow) {
      return ["I radiate joy and creativity.", "I am confident and inspired."];
    } else if (color == Colors.orange) {
      return ["I embrace new adventures.", "My passion fuels my success."];
    } else {
      return ["I am whole and complete.", "I am aligned with my highest self."];
    }
  }

  void _resetForNewPhoto() {
    setState(() {
      _capturedImage = null;
      _auraColor = Colors.transparent;
      _auraColorName = '';
      _auraMeaning = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              _auraColor.withOpacity(0.4 + (_glowController.value * 0.3)),
                              Colors.transparent
                            ],
                            radius: 1.0,
                          ),
                        ),
                      );
                    },
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
                          child: Column(
                            children: [
                              _buildInstructionCard(),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 20),
                                    _capturedImage != null
                                        ? _buildCapturedImageView(context)
                                        : _isCameraInitialized
                                        ? _buildCameraPreview(context)
                                        : const CircularProgressIndicator(),
                                    const SizedBox(height: 30),
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 10,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        _buildButton("Capture Aura", _captureImage),
                                        _buildButton("Switch Camera (Front/Back)", _switchCamera),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    _buildButton("View Aura History", () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const AuraHistoryScreen()),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                "Aura Catcher",
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        color: Colors.white.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStep(1, "Hold the camera steady and face it."),
              const SizedBox(height: 8),
              _buildStep(2, "Tap 'Capture Aura' to scan."),
              const SizedBox(height: 8),
              _buildStep(3, "View your aura analysis!"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$number.",
          style: const TextStyle(
            color: Colors.amberAccent,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview(BuildContext context) {
    return Container(
      key: _previewContainerKey,
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CameraPreview(_cameraController!),
      ),
    );
  }

  Widget _buildCapturedImageView(BuildContext context) {
    return Column(
      children: [
        RepaintBoundary(
          key: _previewContainerKey,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    File(_capturedImage!.path),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: RadialGradient(
                    colors: [_auraColor.withOpacity(0.4), Colors.transparent],
                    radius: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildButton("Retake", _resetForNewPhoto),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        elevation: 5,
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}

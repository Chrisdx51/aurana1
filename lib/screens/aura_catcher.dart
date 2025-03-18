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

class _AuraCatcherScreenState extends State<AuraCatcherScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  XFile? _capturedImage;
  Color _auraColor = Colors.transparent;
  int _currentCameraIndex = 0;

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  final dbHelper = AuraDatabaseHelper();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initBannerAd();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();

    if (_cameras != null && _cameras!.isNotEmpty) {
      // Look for front camera first
      final frontCamera = _cameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras![0],
      );

      _currentCameraIndex = _cameras!.indexOf(frontCamera);
      _setCamera(frontCamera);
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
        onAdLoaded: (ad) {
          setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
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
          setState(() {
            _capturedImage = image;
            _auraColor = _generateRandomColor();
          });

          String auraMeaning = "You radiate positive energy.";
          List<String> affirmations = _generateAffirmations(_auraColor);

          String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

          await dbHelper.saveAuraDetail(
            image.path,
            auraMeaning,
            _getColorName(_auraColor),
            timestamp,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuraAnalysisScreen(
                imagePath: image.path,
                auraColor: _auraColor,
                auraMeaning: auraMeaning,
                affirmations: affirmations,
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

  Color _generateRandomColor() {
    final random = math.Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  String _getColorName(Color color) {
    if (color.red > color.green && color.red > color.blue) return "Red";
    if (color.green > color.red && color.green > color.blue) return "Green";
    if (color.blue > color.red && color.blue > color.green) return "Blue";
    return "Purple";
  }

  List<String> _generateAffirmations(Color color) {
    List<String> affirmations = [];
    if (color.red > color.green && color.red > color.blue) {
      affirmations = ["I am powerful.", "I radiate energy."];
    } else if (color.green > color.red && color.green > color.blue) {
      affirmations = ["I am in harmony.", "My heart is open."];
    } else if (color.blue > color.red && color.blue > color.green) {
      affirmations = ["I am calm.", "I speak my truth."];
    } else {
      affirmations = ["I embrace change.", "I trust my journey."];
    }

    affirmations.shuffle();
    return affirmations.take(2).toList();
  }

  void _resetForNewPhoto() {
    setState(() {
      _capturedImage = null;
      _auraColor = Colors.transparent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/guide.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                if (_isAdLoaded && _bannerAd != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: SizedBox(
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
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

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildButton("Capture Aura", _captureImage),
                              _buildButton("Switch Camera", _switchCamera),
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(BuildContext context) {
    return Container(
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
        Stack(
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
                  colors: [_auraColor.withOpacity(0.5), Colors.transparent],
                  radius: 1.0,
                ),
              ),
            ),
          ],
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

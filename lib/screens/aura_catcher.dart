import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Initialize the camera
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _setCamera(_cameras![_currentCameraIndex]);
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  // Set the active camera
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

  // Capture image and navigate to analysis page
  Future<void> _captureImage() async {
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final image = await _cameraController!.takePicture();

        // Detect if a person is in the image
        bool isPersonDetected = await _detectPerson(image.path);

        if (isPersonDetected) {
          setState(() {
            _capturedImage = image;
            _auraColor = _generateRandomColor(); // Generate a random aura color
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuraAnalysisScreen(
                imagePath: image.path,
                auraColor: _auraColor, // Pass the generated aura color
                auraMeaning: _getAuraMeaning(_auraColor), // Pass the calculated aura meaning
                affirmations: _generateAffirmations(_auraColor), // Generate random affirmations
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("No person detected in the image. Please try again."),
            ),
          );
        }
      }
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  Future<bool> _detectPerson(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final poseDetector = GoogleMlKit.vision.poseDetector();
      final poses = await poseDetector.processImage(inputImage);
      await poseDetector.close();
      return poses.isNotEmpty; // Return true if a pose is detected
    } catch (e) {
      print("Error detecting person: $e");
      return false;
    }
  }

  // Generate a random aura color
  Color _generateRandomColor() {
    final math.Random random = math.Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  // Get meaning of the aura color
  String _getAuraMeaning(Color color) {
    if (color.red > color.green && color.red > color.blue) {
      return "Energetic and Passionate";
    } else if (color.green > color.red && color.green > color.blue) {
      return "Grounded and Balanced";
    } else if (color.blue > color.red && color.blue > color.green) {
      return "Calm and Peaceful";
    }
    return "Unique Energy Detected";
  }

  // Generate affirmations for the aura color
  List<String> _generateAffirmations(Color color) {
    List<String> affirmations = [];
    if (color.red > color.green && color.red > color.blue) {
      affirmations = [
        "I am bold and full of energy.",
        "My passion drives me to success.",
        "I embrace my vibrant energy."
      ];
    } else if (color.green > color.red && color.green > color.blue) {
      affirmations = [
        "I am in harmony with myself and nature.",
        "I feel balanced and whole.",
        "My heart radiates love and compassion."
      ];
    } else if (color.blue > color.red && color.blue > color.green) {
      affirmations = [
        "I am calm, peaceful, and centered.",
        "I communicate with clarity and confidence.",
        "My inner voice guides me."
      ];
    } else {
      affirmations = [
        "I embrace my unique energy.",
        "I trust the path unfolding before me.",
        "My spirit shines bright and free."
      ];
    }

    affirmations.shuffle(); // Randomize the affirmations
    return affirmations.take(2).toList(); // Return a few affirmations
  }

  // Reset for a new photo
  void _resetForNewPhoto() {
    setState(() {
      _capturedImage = null;
      _auraColor = Colors.transparent;
    });
  }

  // Switch between front and back cameras
  void _switchCamera() {
    setState(() {
      _isCameraInitialized = false;
      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
      _setCamera(_cameras![_currentCameraIndex]);
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aura Catcher'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade100, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_capturedImage != null)
                  Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: MediaQuery.of(context).size.height * 0.4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.blue.shade700,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
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
                              borderRadius: BorderRadius.circular(15),
                              gradient: RadialGradient(
                                colors: [_auraColor, Colors.transparent],
                                radius: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _resetForNewPhoto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Retake',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  )
                else if (_isCameraInitialized)
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue.shade700, width: 2),
                    ),
                    child: AspectRatio(
                      aspectRatio: _cameraController!.value.aspectRatio,
                      child: CameraPreview(_cameraController!),
                    ),
                  )
                else
                  const CircularProgressIndicator(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _captureImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Capture Aura',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _switchCamera,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Switch Camera',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuraHistoryScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'View Aura History',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
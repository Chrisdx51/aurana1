import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:intl/intl.dart'; // Add this for formatting timestamps
import '../database/aura_database_helper.dart'; // Added database helper import
import 'aura_history_screen.dart'; // Import for the Aura History Screen
import 'aura_analysis_screen.dart'; // Import for the Aura Analysis Screen

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
  Color _auraColor = Colors.transparent; // Default transparent color
  bool _personDetected = false;
  int _currentCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

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

  Future<void> _captureImage() async {
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final image = await _cameraController!.takePicture();
        final isPerson = await _detectPerson(image.path); // Check for human presence
        setState(() {
          _capturedImage = image;
          _personDetected = isPerson;
          if (_personDetected) {
            _auraColor = _analyzeAuraWithAI(image.path); // Use the new AI-based function
          } else {
            _auraColor = Colors.transparent; // No aura color if no person detected
          }
        });

        // Navigate to Aura Analysis Screen
        if (_personDetected) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuraAnalysisScreen(
                imagePath: image.path,
                auraColor: _auraColor,
                auraMeaning: _getAuraMeaning(_auraColor),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No person detected in the image!')),
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
      return poses.isNotEmpty; // Returns true if a pose (human) is detected
    } catch (e) {
      print("Error detecting person: $e");
      return false;
    }
  }

  Future<void> _saveAuraImage() async {
    if (_capturedImage != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = File(_capturedImage!.path);
        final newImagePath =
            '${directory.path}/aura_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await imagePath.copy(newImagePath);

        // Save to the database
        final auraMeaning = _personDetected ? _getAuraMeaning(_auraColor) : "No Aura Detected";
        final auraColorHex = '#${_auraColor.value.toRadixString(16).substring(2)}'; // Convert color to hex
        final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

        final dbHelper = AuraDatabaseHelper();
        await dbHelper.saveAuraDetail(newImagePath, auraMeaning, auraColorHex, timestamp);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aura image and details saved!'),
          ),
        );
      } catch (e) {
        print("Error saving image: $e");
      }
    }
  }

  void _resetForNewPhoto() {
    setState(() {
      _capturedImage = null;
      _auraColor = Colors.transparent; // Reset aura color
      _personDetected = false; // Reset detection
    });
  }

  void _switchCamera() {
    setState(() {
      _isCameraInitialized = false;
      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
      _setCamera(_cameras![_currentCameraIndex]);
    });
  }

  Color _analyzeAuraWithAI(String imagePath) {
    // Simulated AI-based analysis for now.
    // This can be enhanced with a pre-trained model for actual analysis.
    final hash = imagePath.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = (hash & 0x0000FF);
    return Color.fromARGB(200, r, g, b); // Generated aura color
  }

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
                          if (_personDetected)
                            Container(
                              width: MediaQuery.of(context).size.width * 0.8,
                              height: MediaQuery.of(context).size.height * 0.4,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: RadialGradient(
                                  colors: [
                                    _auraColor,
                                    Colors.transparent,
                                  ],
                                  radius: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _auraColor.withOpacity(0.6),
                                    blurRadius: 15,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _personDetected
                            ? _getAuraMeaning(_auraColor)
                            : "No person detected",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_personDetected)
                        ElevatedButton(
                          onPressed: _saveAuraImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text(
                            'Save Aura',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _resetForNewPhoto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
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
                      border: Border.all(
                        color: Colors.blue.shade700,
                        width: 2,
                      ),
                    ),
                    child: Transform.rotate(
                      angle: 0,
                      child: AspectRatio(
                        aspectRatio: _cameraController!.value.aspectRatio,
                        child: CameraPreview(_cameraController!),
                      ),
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
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
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
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
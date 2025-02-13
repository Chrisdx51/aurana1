import 'package:tflite/tflite.dart';

class AuraAIHelper {
  // Load the TensorFlow Lite model
  Future<void> loadModel() async {
    try {
      String? result = await Tflite.loadModel(
        model: "assets/model.tflite",
      );
      print("Model loaded: $result");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  // Run the model on an image
  Future<List<dynamic>?> analyzeImage(String imagePath) async {
    try {
      return await Tflite.runModelOnImage(
        path: imagePath,
        numResults: 5, // Adjust based on the model's output
        threshold: 0.5, // Confidence threshold
      );
    } catch (e) {
      print("Error running model: $e");
      return null;
    }
  }

  // Unload the model when not needed
  Future<void> disposeModel() async {
    await Tflite.close();
  }
}

import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';

class AuraSnapshotScreen extends StatefulWidget {
  @override
  _AuraSnapshotScreenState createState() => _AuraSnapshotScreenState();
}

class _AuraSnapshotScreenState extends State<AuraSnapshotScreen> {
  late ARSessionManager arSessionManager;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aura Snapshot'),
        backgroundColor: Colors.blue.shade300,
      ),
      body: Stack(
        children: [
          // AR camera view
          ARView(
            onARViewCreated: (sessionManager, objectManager, anchorManager, locationManager) {
              _onARViewCreated(sessionManager);
            },
          ),
          // Capture button at the bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _captureSnapshot,
              child: Text('Capture Aura'),
            ),
          ),
        ],
      ),
    );
  }

  void _onARViewCreated(ARSessionManager sessionManager) {
    arSessionManager = sessionManager;
    arSessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: false,
      showWorldOrigin: false,
    );
  }

  void _captureSnapshot() async {
    final filePath = await arSessionManager.captureScreenshot();
    if (filePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Snapshot saved to: $filePath')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture snapshot')),
      );
    }
  }

  @override
  void dispose() {
    arSessionManager.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoWidget extends StatefulWidget {
  final String videoUrl;

  VideoWidget({required this.videoUrl});

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ✅ Function to toggle Play/Pause
  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  // ✅ Function to enter Fullscreen Mode
  void _goFullScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenVideo(videoUrl: widget.videoUrl),
      ),
    );
  }

  // ✅ Function to seek forward
  void _seekForward() {
    final currentPosition = _controller.value.position;
    final targetPosition = currentPosition + Duration(seconds: 10);
    _controller.seekTo(targetPosition);
  }

  // ✅ Function to seek backward
  void _seekBackward() {
    final currentPosition = _controller.value.position;
    final targetPosition = currentPosition - Duration(seconds: 10);
    _controller.seekTo(targetPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // ✅ Prevent overflow
      children: [
        if (_controller.value.isInitialized)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              height: 250, // ✅ Fixed height for video
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  AspectRatio(
                    aspectRatio: _controller.value.aspectRatio, // ✅ Keeps correct aspect ratio
                    child: VideoPlayer(_controller),
                  ),
                  VideoProgressIndicator(_controller, allowScrubbing: true),

                  // ✅ Positioned control buttons correctly
                  Positioned(
                    bottom: 10, // ✅ Placed at bottom
                    left: 10,
                    child: _buildControlButton(
                      icon: Icons.replay_10,
                      onTap: _seekBackward,
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 60,
                    child: _buildControlButton(
                      icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                      onTap: _togglePlayPause,
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 60,
                    child: _buildControlButton(
                      icon: Icons.forward_10,
                      onTap: _seekForward,
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: _buildControlButton(
                      icon: Icons.fullscreen,
                      onTap: _goFullScreen,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            height: 250,
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  // ✅ Helper function to create buttons with better visibility
  Widget _buildControlButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5), // ✅ Semi-transparent background
          shape: BoxShape.circle,
        ),
        padding: EdgeInsets.all(8),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24, // ✅ Optimized size for better visibility
        ),
      ),
    );
  }
}

// ✅ Fullscreen Video Page
class FullScreenVideo extends StatefulWidget {
  final String videoUrl;
  FullScreenVideo({required this.videoUrl});

  @override
  _FullScreenVideoState createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<FullScreenVideo> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _controller.value.isInitialized
            ? GestureDetector(
          onTap: () {
            setState(() {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
            });
          },
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
              VideoProgressIndicator(_controller, allowScrubbing: true),
              Positioned(
                bottom: 10,
                right: 10,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        )
            : CircularProgressIndicator(),
      ),
    );
  }
}

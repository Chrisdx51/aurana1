import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedBackground extends StatefulWidget {
  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // 🌟 Create Animation Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // 2-second fade in/out
    )..repeat(reverse: true); // 🔥 Makes the glow continuously fade in and out

    _opacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 📌 Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/images/bg0.png', // ✅ Use a static image instead of GIF
            fit: BoxFit.cover,
          ),
        ),

        // 📌 Glowing Chakras (Animated)
        _glowingChakra(top: 100, color: Colors.purple),
        _glowingChakra(top: 200, color: Colors.indigo),
        _glowingChakra(top: 300, color: Colors.blue),
        _glowingChakra(top: 400, color: Colors.green),
        _glowingChakra(top: 500, color: Colors.yellow),
        _glowingChakra(top: 600, color: Colors.orange),
        _glowingChakra(top: 700, color: Colors.red),

        // 📌 "Aurana" Name Typing Effect
        Positioned(
          bottom: 50,
          left: MediaQuery.of(context).size.width * 0.2,
          child: _typingEffect(),
        ),
      ],
    );
  }

  // 🌟 Animated Chakra Glow (Using AnimationController)
  Widget _glowingChakra({required double top, required Color color}) {
    return Positioned(
      top: top,
      left: MediaQuery.of(context).size.width * 0.5 - 25,
      child: AnimatedBuilder(
        animation: _opacityAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.7),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ✨ Typing Effect for "Aurana"
  Widget _typingEffect() {
    return Text(
      "Aurana",
      style: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          Shadow(blurRadius: 10, color: Colors.white),
        ],
      ),
    ).animate().fade(duration: 1000.ms).then().shimmer(duration: 2000.ms);
  }
}
import 'package:flutter/material.dart';

class AuranaGlow extends StatefulWidget {
  final double size;
  AuranaGlow({this.size = 30});

  @override
  _AuranaGlowState createState() => _AuranaGlowState();
}

class _AuranaGlowState extends State<AuranaGlow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.6 * _controller.value),
                blurRadius: 12 * _controller.value + 8,
                spreadRadius: 4 * _controller.value,
              ),
            ],
            color: Colors.deepPurpleAccent,
          ),
        );
      },
    );
  }
}

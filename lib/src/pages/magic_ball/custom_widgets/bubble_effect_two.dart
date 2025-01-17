import 'dart:math';
import 'package:flutter/material.dart';

//More realistic bubbles moving from bottom to top
/*TODO: Add config page. 1) Add Options bubble effect 1, More realist bubble effect 2) change the number of bubbles and the speed of the bubbles*/

class BubbleEffectTwo extends StatefulWidget {
  final double width;
  final double height;
  final int numberOfBubbles;
  const BubbleEffectTwo(
      {super.key,
      this.width = 300,
      this.height = 300,
      this.numberOfBubbles = 50});

  @override
  BubbleEffectTwoState createState() => BubbleEffectTwoState();
}

class BubbleEffectTwoState extends State<BubbleEffectTwo>
    with TickerProviderStateMixin {
  late final List<Bubble> bubbles;

  @override
  void initState() {
    super.initState();
    bubbles = List.generate(widget.numberOfBubbles,
        (index) => Bubble(width: widget.width, height: widget.height));
    bubbles.forEach((bubble) {
      bubble.controller = AnimationController(
        duration: Duration(seconds: bubble.durationInSeconds),
        vsync: this,
      )..repeat();
    });
  }

  @override
  void dispose() {
    bubbles.forEach((bubble) => bubble.controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue.withOpacity(0.3),
        ),
        child: ClipOval(
          child: Stack(
            children:
                bubbles.map((bubble) => _buildAnimatedBubble(bubble)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBubble(Bubble bubble) {
    return AnimatedBuilder(
      animation: bubble.controller,
      builder: (context, child) {
        final value = bubble.controller.value;
        final newY = bubble.getY(value);
        final newX = bubble.getX(value);
        return Positioned(
          left: newX,
          top: newY - bubble.size / 2,
          child: Opacity(
            opacity: bubble.opacity,
            child: Container(
              width: bubble.size,
              height: bubble.size,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class Bubble {
  final random = Random();
  late AnimationController controller;

  final double size;
  final int durationInSeconds;
  final double opacity;
  final double width;
  final double height;

  late double _startX;
  late double _startY;
  late double _endX;
  late double _endY;

  Bubble({required this.width, required this.height})
      : size = Random().nextInt(20).toDouble() + 2,
        durationInSeconds = Random().nextInt(10) + 5,
        opacity = Random().nextDouble() * 0.5 + 0.3 {
    _resetPositions();
  }

  void _resetPositions() {
    _startX = random.nextDouble() * width;
    _startY = height + size;
    _endX = random.nextDouble() * width;
    _endY = -size;
  }

  double getX(double t) {
    if (t == 0) _resetPositions();
    return _startX + (_endX - _startX) * t;
  }

  double getY(double t) {
    return _startY + (_endY - _startY) * t;
  }
}

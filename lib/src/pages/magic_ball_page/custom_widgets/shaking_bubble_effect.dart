import 'dart:math' as math;
import 'package:flutter/material.dart';

class ShakingBubbleEffect extends StatefulWidget {
  final String magicAnswer;
  final double size;

  const ShakingBubbleEffect({
    super.key,
    required this.magicAnswer,
    required this.size,
  });

  @override
  State<ShakingBubbleEffect> createState() => _ShakingBubbleEffectState();
}

class _ShakingBubbleEffectState extends State<ShakingBubbleEffect>
    with TickerProviderStateMixin {
  late final AnimationController _bubbleController;
  late final List<Bubble> _bubbles;

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      duration: const Duration(seconds: 3), // Slower animation
      vsync: this,
    );
    _bubbleController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bubbles = List.generate(
      30,
      (index) => Bubble(
        controller: _bubbleController,
        initialOffset: Offset(
          math.Random().nextDouble() * widget.size,
          widget.size + 50 * index,
        ),
        size: 10 + math.Random().nextDouble() * 20,
      ),
    );
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: AlignmentDirectional.topCenter,
          children: [
            ..._bubbles.map((bubble) => bubble),
            Center(
              child: Text(
                widget.magicAnswer,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(3, 3),
                      blurRadius: 3.0,
                      color: Color.fromARGB(40, 35, 125, 0),
                    ),
                    Shadow(
                      offset: Offset(5.0, 5.0),
                      blurRadius: 8.0,
                      color: Color.fromARGB(40, 35, 125, 255),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Bubble extends AnimatedWidget {
  final Offset initialOffset;
  final double size;

  const Bubble({
    super.key,
    required AnimationController controller,
    required this.initialOffset,
    required this.size,
  }) : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: listenable as AnimationController,
      curve: Curves.easeInOut, // Smooth animation
    );
    final offset = Tween<Offset>(
      begin: initialOffset,
      end: Offset(
        initialOffset.dx + (math.Random().nextDouble() - 0.5) * 200,
        -50,
      ),
    ).animate(animation);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final randomX = (math.Random().nextDouble() - 0.5) * 2;
        const randomY = -1.0;
        final dx = offset.value.dx + randomX * animation.value * 50;
        final dy = offset.value.dy + randomY * animation.value * 50;

        return Positioned(
          left: dx,
          top: dy,
          child: Opacity(
            opacity: 1.0 - animation.value,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white70,
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';

class ShakingBubbleEffect extends StatefulWidget {
  final String magicAnswer;
  final double size;

  // NOTA: shakeBurst ha sido eliminado por completo de aquí
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
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(); // Animación continua en bucle
    
    _generateBubbles();
  }

  void _generateBubbles() {
    _bubbles = List.generate(
      30,
      (index) => Bubble(
        controller: _bubbleController,
        initialOffset: Offset(
          math.Random().nextDouble() * widget.size,
          widget.size + 40 * index,
        ),
        size: 8 + math.Random().nextDouble() * 18,
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
        decoration: const BoxDecoration(shape: BoxShape.circle),
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
                    Shadow(offset: Offset(3, 3), blurRadius: 3.0, color: Color.fromARGB(40, 35, 125, 0)),
                    Shadow(offset: Offset(5.0, 5.0), blurRadius: 8.0, color: Color.fromARGB(40, 35, 125, 255)),
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
      curve: Curves.linear,
    );
    
    final offset = Tween<Offset>(
      begin: initialOffset,
      end: Offset(
        initialOffset.dx + (math.Random().nextDouble() - 0.5) * 100,
        -50,
      ),
    ).animate(animation);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final dx = offset.value.dx;
        final dy = initialOffset.dy + (offset.value.dy - initialOffset.dy) * animation.value;

        return Positioned(
          left: dx,
          top: dy,
          child: Opacity(
            opacity: (1.0 - animation.value).clamp(0.0, 1.0),
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
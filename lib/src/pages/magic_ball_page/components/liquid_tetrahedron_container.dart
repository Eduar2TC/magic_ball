import 'package:flutter/material.dart';
import 'package:magic_ball/src/pages/magic_ball_page/custom_widgets/liquid_tetrahedron.dart';

class LiquidTetrahedronContainer extends StatefulWidget {
  final String initialAnswer;
  final double sensorIntensity;

  const LiquidTetrahedronContainer({
    super.key,
    required this.initialAnswer,
    this.sensorIntensity = 0.0,
  });

  @override
  State<LiquidTetrahedronContainer> createState() =>
      _LiquidTetrahedronContainerState();
}

class _LiquidTetrahedronContainerState extends State<LiquidTetrahedronContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ballSize = MediaQuery.of(context).size.width * 0.4;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final rotationAngle =
            _rotationAnimation.value * widget.sensorIntensity;

        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Transform.rotate(
              angle: rotationAngle,
              child: ClipOval(
                child: SizedBox(
                  width: ballSize,
                  height: ballSize,
                  child: LiquidTetrahedron(
                    key: ValueKey('liquid_${widget.initialAnswer}'),
                    size: MediaQuery.of(context).size.width * 0.5,
                    answer: widget.initialAnswer,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
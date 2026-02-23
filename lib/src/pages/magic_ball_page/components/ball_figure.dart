import 'dart:math';

import 'package:flutter/material.dart';
import 'package:magic_ball/src/pages/magic_ball_page/custom_widgets/animations.dart';
import 'package:magic_ball/src/pages/magic_ball_page/custom_widgets/sphere_figure.dart';

class BallFigure extends StatelessWidget {
  final BallAnimations ballAnimations;

  const BallFigure({
    super.key,
    required this.ballAnimations,
  });

  double bounce(double animation) {
    const double amplitude = 20.0;
    const double frequency = 4.0;
    return amplitude * sin(frequency * 2 * pi * animation);
  }

  @override
  Widget build(BuildContext context) {
    final double sphereWidth = MediaQuery.of(context).size.width * 0.9;
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 3000),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.fastEaseInToSlowEaseOut,
      builder: (context, value, _) {
        return Transform.scale(
          scale: value,
          child: Transform.rotate(
            angle: (2 * pi) * value,
            child: AnimatedBuilder(
              animation: ballAnimations.ballAnimation,
              builder: (context, _) {
                return Transform.translate(
                  offset: Offset(
                    bounce(ballAnimations.ballAnimation.value),
                    sin(ballAnimations.ballAnimation.value * 500) * 25,
                  ),
                  child: SphereFigure(
                      size: sphereWidth,
                      shakeAnimation: ballAnimations
                          .ballAnimation //sincronizacion de la animacion
                      ), //figure of the magic ball
                );
              },
            ),
          ),
        );
      },
    );
  }
}

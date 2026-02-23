import 'dart:math';

import 'package:flutter/material.dart';

class BallShadow extends StatelessWidget {
  const BallShadow({super.key});
  @override
  Widget build(BuildContext context) {
    final sizeWhidth = MediaQuery.of(context).size.width * 0.9;

    return TweenAnimationBuilder(
      duration: const Duration(seconds: 3),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeIn,
      builder: (context, value, _) {
        return Transform(
          transform: Matrix4.identity()
            ..scale(1.3, 1.3)
            ..rotateX(pi / 2.1),
          origin: Offset(sizeWhidth - sizeWhidth * 0.65, sizeWhidth),
          child: Container(
            width: value * sizeWhidth * 0.5,
            height: 240,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  blurStyle: BlurStyle.inner,
                  blurRadius: 100,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

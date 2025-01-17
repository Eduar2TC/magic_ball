import 'package:flutter/material.dart';
import 'dart:math' as math;

class SphereFigure extends StatelessWidget {
  final double size;

  const SphereFigure({super.key, this.size = 300});

  @override
  Widget build(BuildContext context) {
    final internalCircleSize = size * 0.5;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Colors.black54,
            Colors.black87,
            Colors.black,
          ],
          stops: [0.6, 0.8, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Efecto de luz grande desde la parte superior
          CustomPaint(
            size: Size(size, size),
            painter: LightEffectPainter(),
          ),
          // Círculo interno con borde realista y efecto de profundidad
          Center(
            child: Container(
              width: internalCircleSize, // Reducido de 0.65 a 0.55
              height: internalCircleSize, // Reducido de 0.65 a 0.55
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.7, 0.8, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.8),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: -5,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: BorderEffectPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LightEffectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = RadialGradient(
      center: const Alignment(0, -0.5),
      radius: 1.0,
      colors: [
        Colors.white.withOpacity(0.7),
        Colors.white.withOpacity(0.3),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.6],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..blendMode = BlendMode.screen;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BorderEffectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final gradientPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.topCenter,
        startAngle: 0,
        endAngle: math.pi * 2,
        /*simlulacion de colores que se ven en el borde de la bola. desde la parte central izquierda a derecha
        son grises claros y desde la parte central derecha hasta la parte central izquierda y abajo son mas obscuros
        el color mas claro es  Colors.grey[600]*/
        colors: [
          Colors.grey[600]!,
          Colors.grey[700]!,
          Colors.grey[800]!,
          Colors.grey[900]!,
          Colors.grey[900]!,
          Colors.grey[800]!,
          Colors.grey[700]!,
          Colors.grey[600]!,
        ],
        stops: const [
          0.0,
          0.1,
          0.2,
          0.3,
          0.7,
          0.8,
          0.9,
          1.0,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05;

    canvas.drawCircle(center, radius, gradientPaint);

    final innerShadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.deepPurple.withOpacity(0.5), //centro
          Colors.transparent,
        ],
        stops: const [0.9, 3.0],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.95, innerShadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

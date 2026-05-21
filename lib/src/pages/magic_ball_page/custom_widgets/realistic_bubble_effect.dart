import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class RealisticBubbleEffect extends StatefulWidget {
  final double size;
  final int maxBubbles;
  const RealisticBubbleEffect({
    super.key,
    this.size = 300,
    this.maxBubbles = 12,
  });

  @override
  State<RealisticBubbleEffect> createState() => _RealisticBubbleEffectState();
}

class _RealisticBubbleEffectState extends State<RealisticBubbleEffect> with TickerProviderStateMixin {
  final List<_BubbleModel> _bubbles = [];
  late Timer _timer;
  bool _running = true;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!_running) return;
      if (_bubbles.length < widget.maxBubbles && _random.nextBool()) {
        setState(() {
          _bubbles.add(_BubbleModel.random(widget.size, this));
        });
      }
    });
    // Actualiza la física de las burbujas cada frame (~60fps)
    WidgetsBinding.instance.addPostFrameCallback(_updatePhysics);
  }

  void _updatePhysics(Duration timeStamp) {
    if (!_running) return;
    setState(() {
      for (final bubble in _bubbles) {
        bubble.updatePhysics(_bubbles, widget.size);
      }
      _bubbles.removeWhere((b) => b.isDead);
    });
    WidgetsBinding.instance.scheduleFrameCallback(_updatePhysics);
  }

  @override
  void dispose() {
    _running = false;
    _timer.cancel();
    for (final b in _bubbles) {
      b.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          children: _bubbles.map((b) => b.build()).toList(),
        ),
      ),
    );
  }
}

class _BubbleModel {
  static final Random _random = Random();
  late AnimationController controller;
  double x, y;
  double vx, vy;
  final double radius;
  final double opacity;
  double lifeTime;
  double floatTime;
  bool isDead = false;

  _BubbleModel._(
    this.controller,
    this.x,
    this.y,
    this.vx,
    this.vy,
    this.radius,
    this.opacity,
    this.lifeTime,
    this.floatTime,
  );

  factory _BubbleModel.random(double size, TickerProvider vsync) {
    final radius = _random.nextDouble() * 1 + 5;
    final angle = _random.nextDouble() * 2 * pi;
    final distance = _random.nextDouble() * (size / 2 - radius);
    final x = size / 2 + distance * cos(angle);
    final y = size / 2 + distance * sin(angle);

    // Velocidad inicial hacia arriba con algo de variación horizontal
    final vx = (_random.nextDouble() - 0.5) * 0.8;
    final vy = -(_random.nextDouble() * 1.5 + 1.0);

    final opacity = _random.nextDouble() * 0.3 + 0.7;
    final lifeTime = _random.nextDouble() * 1.2 + 1.2; // segundos subiendo
    final floatTime = _random.nextDouble() * 1.5 + 0.5; // segundos flotando

    final controller = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: ((lifeTime + floatTime) * 10000).toInt()),
    )..forward();

    return _BubbleModel._(
      controller,
      x,
      y,
      vx,
      vy,
      radius,
      opacity,
      lifeTime,
      floatTime,
    );
  }

  void updatePhysics(List<_BubbleModel> bubbles, double size) {
    if (controller.isCompleted) {
      isDead = true;
      return;
    }
    final t = controller.value * (lifeTime + floatTime);
    if (t < lifeTime) {
      // Fase de subida: aceleración hacia arriba, resistencia
      vy -= 0.01; // flotabilidad
      vx *= 0.98; // resistencia horizontal
      vy *= 0.98; // resistencia vertical

      x += vx;
      y += vy;

      // Rebote con el borde del círculo
      final centerX = size / 2;
      final centerY = size / 2;
      final dx = x - centerX;
      final dy = y - centerY;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist + radius > size / 2) {
        // Rebote simple: invierte la velocidad y reduce energía
        final normX = dx / dist;
        final normY = dy / dist;
        final dot = vx * normX + vy * normY;
        vx -= 2 * dot * normX;
        vy -= 2 * dot * normY;
        vx *= 0.7;
        vy *= 0.7;
        // Reposiciona dentro del círculo
        x = centerX + (size / 2 - radius - 1) * normX;
        y = centerY + (size / 2 - radius - 1) * normY;
      }

      // Colisión con otras burbujas
      for (final other in bubbles) {
        if (other == this || other.isDead) continue;
        final dx2 = other.x - x;
        final dy2 = other.y - y;
        final dist2 = sqrt(dx2 * dx2 + dy2 * dy2);
        if (dist2 < radius + other.radius) {
          // Rebote simple: separa burbujas y ajusta velocidades
          final overlap = radius + other.radius - dist2;
          final nx = dx2 / (dist2 + 0.01);
          final ny = dy2 / (dist2 + 0.01);
          x -= nx * overlap / 2;
          y -= ny * overlap / 2;
          other.x += nx * overlap / 2;
          other.y += ny * overlap / 2;
          // Intercambia velocidades parcialmente
          final tempVx = vx;
          final tempVy = vy;
          vx = other.vx * 0.5 + vx * 0.5;
          vy = other.vy * 0.5 + vy * 0.5;
          other.vx = tempVx * 0.5 + other.vx * 0.5;
          other.vy = tempVy * 0.5 + other.vy * 0.5;
        }
      }
    } else if (t < lifeTime + floatTime) {
      // Fase de flotación: burbuja se queda quieta
      vx *= 0.95;
      vy *= 0.95;
      x += vx;
      y += vy;
    } else {
      // Fase de desaparición
      isDead = true;
    }
  }

  void dispose() => controller.dispose();

  Widget build() {
    final t = controller.value * (lifeTime + floatTime);
    double scale = 1.0;
    double bubbleOpacity = opacity;
    if (t < 0.2) {
      // Animación de aparición
      scale = t / 0.2;
      bubbleOpacity *= scale;
    } else if (t > lifeTime + floatTime - 0.3) {
      // Animación de desaparición
      scale = 1.0 - ((t - (lifeTime + floatTime - 0.3)) / 0.3).clamp(0.0, 1.0);
      bubbleOpacity *= scale;
    }
    return Positioned(
      left: x - radius,
      top: y - radius,
      child: Opacity(
        opacity: bubbleOpacity,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
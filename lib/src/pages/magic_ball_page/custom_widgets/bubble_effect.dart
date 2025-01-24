import 'dart:math';
import 'package:flutter/material.dart';

import 'package:vector_math/vector_math.dart' as vector;
/*TODO: Add config page. 1) Add Options bubble effect 1, More realist bubble effect 2) change the number of bubbles and the speed of the bubbles*/

class BubbleEffect extends StatefulWidget {
  final double width;
  final double height;
  final int numberOfBubbles;
  const BubbleEffect(
      {super.key,
      this.width = 300,
      this.height = 300,
      this.numberOfBubbles = 50});

  @override
  BubbleEffectState createState() => BubbleEffectState();
}

class BubbleEffectState extends State<BubbleEffect>
    with TickerProviderStateMixin {
  late final List<Bubble> bubbles;
  int get numberOfBubbles => widget.numberOfBubbles;

  @override
  void initState() {
    super.initState();
    bubbles = List.generate(numberOfBubbles,
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
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          //color: Colors.blue.withOpacity(0.3),
        ),
        child: ClipOval(
          child: Stack(
            children: [
              ...bubbles.map((bubble) => _buildAnimatedBubble(bubble)),
              /*MagicTetrahedron(
                onAnimationComplete: () {},
              ),*/
              //const AnimatedTetrahedron(), //<--- TODO: MODIFY THIS ANIMATION
            ],
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
        final newY = bubble.initialY - (widget.height * value);
        return Positioned(
          left: bubble.x,
          top: newY % widget.height - bubble.size,
          child: Opacity(
            opacity: bubble.opacity,
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(seconds: 3),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                //scale bubble initially
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: bubble.size,
                    height: bubble.size,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
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

  double size;
  double x;
  double initialY;
  int durationInSeconds;
  double opacity;
  final double width;
  final double height;

  Bubble({required this.width, required this.height})
      : size = Random().nextInt(20).toDouble() + 2,
        x = Random().nextInt(width.toInt()).toDouble(),
        initialY = Random().nextInt(height.toInt()).toDouble(),
        durationInSeconds = Random().nextInt(10) + 5,
        opacity = Random().nextDouble() * 0.3 + 0.2;

  void updatePosition() {
    x = Random().nextInt(width.toInt()).toDouble();
    initialY = Random().nextInt(height.toInt()).toDouble();
  }
}
/*
class MagicTetrahedron extends StatefulWidget {
  final double size;
  final VoidCallback onAnimationComplete;

  const MagicTetrahedron({
    Key? key,
    this.size = 300,
    required this.onAnimationComplete,
  }) : super(key: key);

  @override
  _MagicTetrahedronState createState() => _MagicTetrahedronState();
}

class _MagicTetrahedronState extends State<MagicTetrahedron>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Vector3 _rotationAxis;
  late double _rotationAngle;
  final _random = math.Random();
  late int _targetFace;

  final List<String> _responses = [
    "Yes",
    "No",
    "Maybe",
    "Ask\nagain",
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.addStatusListener(_handleAnimationStatus);
    _startRotation();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onAnimationComplete();
    }
  }

  void _startRotation() {
    _targetFace = _random.nextInt(4);
    _rotationAxis = _calculateRotationAxis(_targetFace);
    _rotationAngle = math.pi + _random.nextDouble() * math.pi;
    _controller.forward(from: 0.0);
  }

  Vector3 _calculateRotationAxis(int targetFace) {
    final phi = math.acos(1 / math.sqrt(3));
    final theta = 2 * math.pi * targetFace / 4;
    return Vector3(
      math.sin(phi) * math.cos(theta),
      math.sin(phi) * math.sin(theta),
      math.cos(phi),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!_controller.isAnimating) {
          _startRotation();
        }
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: TetrahedronPainter(
              _animation.value,
              _rotationAxis,
              _rotationAngle,
              _responses,
              _targetFace,
            ),
          );
        },
      ),
    );
  }
}

class TetrahedronPainter extends CustomPainter {
  final double animationValue;
  final Vector3 rotationAxis;
  final double rotationAngle;
  final List<String> responses;
  final int targetFace;

  TetrahedronPainter(this.animationValue, this.rotationAxis, this.rotationAngle,
      this.responses, this.targetFace);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 2; // Reduced the radius for better proportions

    final tetrahedron = _createTetrahedron();
    final rotatedTetrahedron = _rotateTetrahedron(
        tetrahedron, rotationAxis, rotationAngle * animationValue);

    rotatedTetrahedron.sort((a, b) {
      final zA = (a[0].z + a[1].z + a[2].z) / 3;
      final zB = (b[0].z + b[1].z + b[2].z) / 3;
      return zB.compareTo(zA);
    });

    for (var i = 0; i < rotatedTetrahedron.length; i++) {
      final face = rotatedTetrahedron[i];
      final path = Path();
      final startPoint = _projectPoint(face[0], center, radius);
      path.moveTo(startPoint.dx, startPoint.dy);

      for (var j = 1; j < face.length; j++) {
        final point = _projectPoint(face[j], center, radius);
        path.lineTo(point.dx, point.dy);
      }

      path.close();

      final isTargetFace = i == targetFace;
      final faceColor = _getFaceColor(i, isTargetFace);
      final paint = Paint()
        ..color = faceColor
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);

      final borderPaint = Paint()
        ..color = isTargetFace ? Colors.white : Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isTargetFace ? 3 : 1;

      canvas.drawPath(path, borderPaint);

      _drawTextOnFace(canvas, face, center, radius, responses[i], isTargetFace);
    }
  }

  List<List<Vector3>> _createTetrahedron() {
    final a = 1.0;
    final b = a * math.sqrt(2) / 2;
    final c = a * math.sqrt(6) / 3;

    final vertices = [
      Vector3(0, 0, c), // Top vertex
      Vector3(-b, -a / 2, -c / 3), // Bottom left vertex
      Vector3(b, -a / 2, -c / 3), // Bottom right vertex
      Vector3(0, a, -c / 3), // Front vertex
    ];

    return [
      [vertices[0], vertices[1], vertices[2]],
      [vertices[0], vertices[2], vertices[3]],
      [vertices[0], vertices[3], vertices[1]],
      [vertices[1], vertices[3], vertices[2]],
    ];
  }

  List<List<Vector3>> _rotateTetrahedron(
      List<List<Vector3>> tetrahedron, Vector3 axis, double angle) {
    final rotationMatrix = _createRotationMatrix(axis, angle);
    return tetrahedron.map((face) {
      return face
          .map((vertex) => _applyMatrix(rotationMatrix, vertex))
          .toList();
    }).toList();
  }

  List<List<double>> _createRotationMatrix(Vector3 axis, double angle) {
    final c = math.cos(angle);
    final s = math.sin(angle);
    final t = 1 - c;
    final x = axis.x, y = axis.y, z = axis.z;

    return [
      [t * x * x + c, t * x * y - z * s, t * x * z + y * s],
      [t * x * y + z * s, t * y * y + c, t * y * z - x * s],
      [t * x * z - y * s, t * y * z + x * s, t * z * z + c],
    ];
  }

  Vector3 _applyMatrix(List<List<double>> matrix, Vector3 vector) {
    return Vector3(
      matrix[0][0] * vector.x +
          matrix[0][1] * vector.y +
          matrix[0][2] * vector.z,
      matrix[1][0] * vector.x +
          matrix[1][1] * vector.y +
          matrix[1][2] * vector.z,
      matrix[2][0] * vector.x +
          matrix[2][1] * vector.y +
          matrix[2][2] * vector.z,
    );
  }

  Color _getFaceColor(int index, bool isTargetFace) {
    if (isTargetFace) {
      return Color.fromRGBO(0, 0, 200, 0.9);
    }
    return Color.fromRGBO(0, 0, 150, 0.7);
  }

  Offset _projectPoint(Vector3 point, Offset center, double radius) {
    final scale = 1 / (2 - point.z);
    final x = point.x * scale * radius + center.dx;
    final y = -point.y * scale * radius + center.dy; // Inverted y-axis
    return Offset(x, y);
  }

  void _drawTextOnFace(Canvas canvas, List<Vector3> face, Offset center,
      double radius, String text, bool isTargetFace) {
    final faceCenter = Vector3(
      (face[0].x + face[1].x + face[2].x) / 3,
      (face[0].y + face[1].y + face[2].y) / 3,
      (face[0].z + face[1].z + face[2].z) / 3,
    );

    final projectedCenter = _projectPoint(faceCenter, center, radius);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: isTargetFace ? 20 : 16,
          fontWeight: isTargetFace ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(minWidth: 0, maxWidth: radius);

    final offset = Offset(
      projectedCenter.dx - textPainter.width / 2,
      projectedCenter.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Vector3 {
  final double x;
  final double y;
  final double z;

  Vector3(this.x, this.y, this.z);
}
*/

/////TODO: personalize figure

class AnimatedTetrahedron extends StatefulWidget {
  const AnimatedTetrahedron({super.key});

  @override
  AnimatedTetrahedronState createState() => AnimatedTetrahedronState();
}

class AnimatedTetrahedronState extends State<AnimatedTetrahedron>
    with TickerProviderStateMixin {
  late AnimationController _buttonController;
  late AnimationController _sensorController;
  late Animation<double> _buttonAnimation;

  bool _isAnimating = true;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..forward();

    _sensorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _buttonAnimation = Tween<double>(begin: 0, end: pi * 2).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_buttonController, _sensorController]),
      builder: (context, _) {
        double rotation = _isAnimating
            ? _buttonAnimation.value
            : _sensorController.value * 2 * pi - pi;
        //rotate the tetrahedron
        return Transform(
          transform: Matrix4.rotationZ(rotation)
            ..setEntry(3, 2, 0.001)
            ..rotateY(pi * 3)
            ..rotateX(pi * 3)
            ..rotateZ(pi * 3),
          alignment: Alignment.center,
          child: CustomPaint(
            isComplex: true,
            painter: TetrahedronPainter(rotation),
            size: const Size(500, 500),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _sensorController.dispose();
    super.dispose();
  }
}

class TetrahedronPainter extends CustomPainter {
  final double rotation;

  TetrahedronPainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final red = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final green = Paint()
      ..color = Colors.green.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final yellow = Paint()
      ..color = Colors.amberAccent.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final h = size.height;
    final w = size.width;

    final Offset c = Offset(w / 2, h * 0.5);
    final double len = h * 0.6;

    final top = c + Offset(0, -len);
    final left = _getCoord(c, len, rotation);
    final right = _getCoord(c, len, rotation + pi * 2 / 3);
    final bottom = _getCoord(c, len, rotation + pi * 4 / 3);

    final faces = [
      (topFace: _createFace(top, left, right), paint: blue, text: 'Azul'),
      (topFace: _createFace(top, left, bottom), paint: red, text: 'Rojo'),
      (topFace: _createFace(top, right, bottom), paint: green, text: 'Verde'),
      (
        topFace: _createFace(left, right, bottom),
        paint: yellow,
        text: 'Amarillo'
      ),
    ];

    // Ordenar las caras por profundidad
    faces.sort((a, b) {
      double zA = (a.topFace.getBounds().center - c).distance;
      double zB = (b.topFace.getBounds().center - c).distance;
      return zB.compareTo(zA);
    });

    // Dibujar las caras en orden
    for (var face in faces) {
      canvas.drawPath(face.topFace, face.paint);
      _drawTextOnFace(canvas, face.topFace, face.text, Colors.white);
    }
  }

  void _drawTextOnFace(Canvas canvas, Path path, String text, Color color) {
    final Rect bounds = path.getBounds();
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Calcular el centro de la cara
    final center = bounds.center;

    // Calcular la rotación del texto basada en la normal de la cara
    final normal = _calculateNormalFromPath(path);
    final angle = atan2(normal.y, normal.x);

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Posicionar el texto en el centro de la cara
    Offset offset;

    if (angle > pi / 2 || angle < -pi / 2) {
      offset = Offset(-textPainter.width, -textPainter.height / 2);
    } else {
      offset = Offset(-textPainter.width / 2, -textPainter.height / 2);
    }

    switch (text) {
      case 'Azul':
        offset = Offset(-textPainter.width, -textPainter.height / 2);
        break;
      case 'Amarillo':
        offset = Offset(-textPainter.width / 2, 0);
        break;
      case 'Verde':
        offset = Offset(-textPainter.width * 0.75, -textPainter.height / 2);
        break;
      default:
        offset = Offset(-textPainter.width / 2 + (textPainter.width / 2),
            -textPainter.height / 2 + (textPainter.height / 2));
    }

    canvas.scale(-1, 1); // Invertir el texto
    textPainter.paint(canvas, offset);
    canvas.restore();
  }

  vector.Vector3 _calculateNormalFromPath(Path path) {
    final metrics = path.computeMetrics().first;
    final start = metrics.getTangentForOffset(0)!.position;
    final middle = metrics.getTangentForOffset(metrics.length / 2)!.position;
    final end = metrics.getTangentForOffset(metrics.length)!.position;

    final v1 = vector.Vector3(middle.dx - start.dx, middle.dy - start.dy, 0);
    final v2 = vector.Vector3(end.dx - start.dx, end.dy - start.dy, 0);
    return v1.cross(v2)..normalize();
  }

  @override
  bool shouldRepaint(TetrahedronPainter old) => true;

  Offset _getCoord(Offset c, double len, double angle) {
    return Offset(c.dx - len * sin(angle), c.dy - len * cos(angle));
  }

  Path _createFace(Offset p1, Offset p2, Offset p3) {
    final path = Path();
    path.moveTo(p1.dx, p1.dy);
    path.lineTo(p2.dx, p2.dy);
    path.lineTo(p3.dx, p3.dy);
    path.close();
    return path;
  }
}

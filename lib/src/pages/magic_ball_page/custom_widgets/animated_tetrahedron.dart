import 'package:flutter/material.dart';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vector_math/vector_math.dart' as vector;
/*
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tetraedro Animado',
      home: Scaffold(
        body: Center(
          child: AnimatedTetrahedron(),
        ),
      ),
    );
  }
}

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

  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _sensorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _buttonAnimation = Tween<double>(begin: 0, end: pi * 2).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.easeInOutCubicEmphasized,
      ),
    );

    userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      double targetValue = event.y.clamp(-pi, pi);
      _sensorController.animateTo(
        (targetValue + pi) / (2 * pi),
        duration: const Duration(milliseconds: 100),
        curve: Curves.linear,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_buttonController, _sensorController]),
            builder: (context, child) {
              double rotation = _isAnimating
                  ? _buttonAnimation.value
                  : _sensorController.value * 2 * pi - pi;
              //rotate the tetrahedron
              return Transform(
                transform: Matrix4.rotationZ(rotation)
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(-pi * 3),
                alignment: Alignment.center,
                child: CustomPaint(
                  painter: TetrahedronPainter(rotation),
                  size: const Size(500, 500),
                ),
              );
            },
          ),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _isAnimating = !_isAnimating;
              if (_isAnimating) {
                _buttonController.reset();
                _buttonController.repeat();
              } else {
                _buttonController.stop();
              }
            });
          },
          child: Text(_isAnimating ? "Detener" : "Animar"),
        ),
      ],
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
      ..color = Colors.amberAccent.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final h = size.height;
    final w = size.width;

    final Offset c = Offset(w / 2, h * 0.7);
    final double len = h * 0.3;

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
    canvas.rotate(angle);

    // Posicionar el texto en el centro de la cara
    final offset = Offset(
      -textPainter.width / 2,
      -textPainter.height / 2,
    );

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
*/

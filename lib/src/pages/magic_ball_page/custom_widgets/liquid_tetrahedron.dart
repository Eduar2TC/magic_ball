import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' as vmath;

class LiquidTetrahedron extends StatefulWidget {
  final double size;
  final String answer;

  const LiquidTetrahedron({
    super.key,
    this.size = 220,
    required this.answer,
  });

  @override
  State<LiquidTetrahedron> createState() => _LiquidTetrahedronState();
}

class _LiquidTetrahedronState extends State<LiquidTetrahedron>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _floatController;
  late AnimationController _bubbleController;

  late Animation<double> _mainAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _bubbleAnimation;

  late vmath.Vector3 _initialAxis;
  late double _initialAngle;
  late vmath.Matrix4 _finalMatrix;
  late double _originX;
  late double _originY;
  late double _finalZRotation; // Rotación aleatoria final en Z

  // Parámetros de física de líquido
  late double _liquidDensity;
  late double _buoyancyForce;
  late List<Bubble> _bubbles;

  @override
  void initState() {
    super.initState();
    final rand = math.Random();

    // Posición inicial más dramática
    final angle = rand.nextDouble() * 2 * math.pi;
    final distance = 150.0 + rand.nextDouble() * 100.0;
    _originX = math.cos(angle) * distance;
    _originY = math.sin(angle) * distance;

    // Eje de rotación inicial más suave
    _initialAxis = vmath.Vector3(
      rand.nextDouble() * 2 - 1,
      rand.nextDouble() * 2 - 1,
      rand.nextDouble() * 2 - 1,
    )..normalize();
    _initialAngle = rand.nextDouble() * math.pi * 1.5; // Reducir rotación inicial para movimiento más suave

    // Rotación final aleatoria en Z (más sutil)
    _finalZRotation = rand.nextDouble() * math.pi * 0.8; // Reducir para evitar giros extremos

    _finalMatrix = _calculateFinalMatrix();

    // Parámetros de líquido
    _liquidDensity = 0.8 + rand.nextDouble() * 0.4; // Densidad variable
    _buoyancyForce = 0.3 + rand.nextDouble() * 0.2;

    // Generar burbujas aleatorias
    _bubbles = List.generate(5, (i) => Bubble.random(rand));

    // Animación principal (entrada y estabilización)
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3000), // Más tiempo para suavizar
      vsync: this,
    );

    _mainAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutExpo // Curva más suave para evitar movimientos bruscos
    );

    // Animación de flotación continua
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );
    _floatAnimation = CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut
    );

    // Animación de burbujas
    _bubbleController = AnimationController(
      duration: const Duration(milliseconds: 4500),
      vsync: this,
    );
    _bubbleAnimation = CurvedAnimation(
      parent: _bubbleController,
      curve: Curves.linear
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mainController.forward();
      //_mainController.repeat(reverse: false);
      _floatController.repeat(reverse: true);
      _bubbleController.repeat();
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  double _smoothStep(double t) {
    // Función smoothstep para transiciones ultra suaves
    return t * t * (3.0 - 2.0 * t);
  }

  vmath.Matrix4 _rotationMatrix(vmath.Vector3 axis, double angle) {
    final q = vmath.Quaternion.axisAngle(axis, angle);
    final m3 = q.asRotationMatrix();
    final m4 = vmath.Matrix4.identity();
    m4.setRotation(m3);
    return m4;
  }

  vmath.Matrix4 _slerpMatrix(vmath.Matrix4 a, vmath.Matrix4 b, double t) {
    // Interpola con transición suave sin cortes
    final smoothT = t; // Usar t directamente para evitar cortes

    final m3a = vmath.Matrix3.zero();
    final m3b = vmath.Matrix3.zero();
    a.copyRotation(m3a);
    b.copyRotation(m3b);
    final qa = vmath.Quaternion.identity()..setFromRotation(m3a);
    final qb = vmath.Quaternion.identity()..setFromRotation(m3b);

    double dot = qa.x * qb.x + qa.y * qb.y + qa.z * qb.z + qa.w * qb.w;
    if (dot < 0.0) {
      qb.setValues(-qb.x, -qb.y, -qb.z, -qb.w);
      dot = -dot;
    }

    const double epsilon = 1e-6;
    vmath.Quaternion qm;
    if (dot > 1.0 - epsilon) {
      qm = vmath.Quaternion(
        qa.x + smoothT * (qb.x - qa.x),
        qa.y + smoothT * (qb.y - qa.y),
        qa.z + smoothT * (qb.z - qa.z),
        qa.w + smoothT * (qb.w - qa.w),
      )..normalize();
    } else {
      final double theta0 = math.acos(dot);
      final double theta = theta0 * smoothT;
      final double sinTheta = math.sin(theta);
      final double sinTheta0 = math.sin(theta0);
      final double s0 = math.cos(theta) - dot * sinTheta / sinTheta0;
      final double s1 = sinTheta / sinTheta0;
      qm = vmath.Quaternion(
        (qa.x * s0) + (qb.x * s1),
        (qa.y * s0) + (qb.y * s1),
        (qa.z * s0) + (qb.z * s1),
        (qa.w * s0) + (qb.w * s1),
      );
    }
    final m3 = qm.asRotationMatrix();
    final m4 = vmath.Matrix4.identity();
    m4.setRotation(m3);
    return m4;
  }

  vmath.Matrix4 _calculateFinalMatrix() {
    final v0 = vmath.Vector3.array(_tetrahedronVertices[0]);
    final v1 = vmath.Vector3.array(_tetrahedronVertices[1]);
    final v2 = vmath.Vector3.array(_tetrahedronVertices[2]);
    final normal = (v1 - v0).cross(v2 - v0).normalized();
    final targetNormal = vmath.Vector3(0, 0, 1);

    vmath.Quaternion q1;
    if ((normal - targetNormal).length < 1e-6) {
      q1 = vmath.Quaternion.identity();
    } else if ((normal + targetNormal).length < 1e-6) {
      q1 = vmath.Quaternion.axisAngle(vmath.Vector3(1, 0, 0), math.pi);
    } else {
      final axis = normal.cross(targetNormal).normalized();
      final angle = math.acos(normal.dot(targetNormal).clamp(-1.0, 1.0));
      q1 = vmath.Quaternion.axisAngle(axis, angle);
    }
    final m3_1 = q1.asRotationMatrix();
    final m1 = vmath.Matrix4.identity();
    m1.setRotation(m3_1);

    final b4 = m1.transform3(v1);
    final c4 = m1.transform3(v2);
    final baseVec = (c4 - b4).normalized();
    double baseAngle = math.atan2(baseVec.y, baseVec.x);
    final m2 = vmath.Matrix4.rotationZ(-baseAngle);

    final a4 = (m2 * m1).transform3(v0);
    final b2 = (m2 * m1).transform3(v1);
    final c2 = (m2 * m1).transform3(v2);
    final projected = [a4, b2, c2].map((v) => vmath.Vector2(v.x, v.y)).toList();
    int topIndex = 0;
    double minY = projected[0].y;
    for (int i = 1; i < 3; i++) {
      if (projected[i].y < minY) {
        minY = projected[i].y;
        topIndex = i;
      }
    }
    if (topIndex != 0) {
      return vmath.Matrix4.rotationZ(math.pi) * m2 * m1;
    }
    return m2 * m1;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _floatAnimation, _bubbleAnimation]),
      builder: (context, _) {
        final mainT = _mainAnimation.value;
        final floatT = _floatAnimation.value;
        final bubbleT = _bubbleAnimation.value;

        // Movimiento principal con resistencia del líquido
        final liquidResistance = math.pow(mainT, 1.2).toDouble();
        final scale = 0.7 + 0.3 * liquidResistance; //0.8 FIX SCALE
        final opacity = 0.2 + 0.8 * mainT;

        // Movimiento de entrada con efecto de líquido (mantener aleatorio)
        final xTranslate = (1 - mainT) * _originX * (1 + 0.08 * math.sin(mainT * math.pi * 1.5));
        final yTranslate = (1 - mainT) * _originY * (1 + 0.08 * math.cos(mainT * math.pi * 1.5));

        // Flotación continua suave (sin cortes)
        final floatIntensity = mainT > 0.7 ? math.min((mainT - 0.7) / 0.3, 1.0) : 0.0;
        final floatX = floatIntensity * 6 * math.sin(floatT * math.pi * 2) * _buoyancyForce;
        final floatY = floatIntensity * 8 * math.cos(floatT * math.pi * 2 * 0.8) * _buoyancyForce;
        final floatRotation = floatIntensity * 0.03 * math.sin(floatT * math.pi * 2 * 1.2);

        // Rotación con inercia del líquido (transición muy suave)
        final rotationProgress = _smoothStep(mainT);

        // Rotación inicial que se desvanece gradualmente
        final initialRotationIntensity = math.pow(1 - mainT, 2.0).toDouble();
        final mStart = _rotationMatrix(_initialAxis, _initialAngle * initialRotationIntensity);

        // Interpolación suave hacia la matriz final
        final mEnd = _finalMatrix;
        final mBase = _slerpMatrix(mStart, mEnd, rotationProgress);

        // Aplicar rotación aleatoria final en Z de forma muy gradual
        final finalZProgress = _smoothStep(math.max(0, (mainT - 0.3) / 0.7));
        final finalZRotation = vmath.Matrix4.rotationZ(_finalZRotation * finalZProgress);
        final mWithFinalZ = finalZRotation * mBase;

        // Pequeñas oscilaciones de rotación por la flotación
        final floatRotationMatrix = vmath.Matrix4.identity()
          ..rotateX(floatRotation * 0.4)
          ..rotateY(floatRotation * 0.6)
          ..rotateZ(floatRotation * 0.8);

        final finalMatrix = floatRotationMatrix * mWithFinalZ;

        return Container(
          width: widget.size,
          height: widget.size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Burbujas de fondo
              ..._bubbles.map((bubble) => Positioned(
                left: widget.size/2 + bubble.getX(bubbleT) - bubble.size/2,
                top: widget.size/2 + bubble.getY(bubbleT) - bubble.size/2,
                child: Opacity(
                  opacity: bubble.getOpacity(bubbleT) * mainT * 0.7,
                  child: Container(
                    width: bubble.size,
                    height: bubble.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          blurRadius: 3,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                  ),
                ),
              )),

              // Tetraedro principal - centrado y sin cortes
              Center(
                child: Opacity(
                  opacity: opacity,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..translate(xTranslate + floatX, yTranslate + floatY)
                      ..scale(scale, scale),
                    child: CustomPaint(
                      size: Size(widget.size * 0.8, widget.size * 0.8),
                      painter: LiquidTetrahedronPainter(
                        matrix: finalMatrix,
                        answer: widget.answer,
                        animationProgress: mainT,
                        floatProgress: floatT,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class Bubble {
  final double x, y;
  final double size;
  final double speed;
  final double phase;

  Bubble(this.x, this.y, this.size, this.speed, this.phase);

  factory Bubble.random(math.Random rand) {
    return Bubble(
      (rand.nextDouble() - 0.5) * 200, // x
      (rand.nextDouble() - 0.5) * 200, // y
      2 + rand.nextDouble() * 4, // size
      0.5 + rand.nextDouble() * 0.5, // speed
      rand.nextDouble() * 2 * math.pi, // phase
    );
  }

  double getX(double t) {
    return x + 10 * math.sin(t * 2 * math.pi * speed + phase);
  }

  double getY(double t) {
    return y + 15 * math.cos(t * 2 * math.pi * speed * 0.7 + phase);
  }

  double getOpacity(double t) {
    return 0.3 + 0.3 * math.sin(t * 2 * math.pi * speed * 2 + phase);
  }
}

final List<List<double>> _tetrahedronVertices = [
  [0, 0, 1],
  [math.sqrt(8 / 9), 0, -1 / 3],
  [-math.sqrt(2 / 9), math.sqrt(2 / 3), -1 / 3],
  [-math.sqrt(2 / 9), -math.sqrt(2 / 3), -1 / 3],
];

const List<List<int>> _tetrahedronFaces = [
  [0, 1, 2],
  [0, 2, 3],
  [0, 3, 1],
  [1, 2, 3],
];

String wrapTextByWords(String text, double maxWidth, TextStyle style) {
  if (text.isEmpty || maxWidth <= 0) {
    return text;
  }

  final words = text.trim().split(RegExp(r'\s+'));
  if (words.isEmpty) return text;

  final textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.left,
  );

  final List<String> lines = [];
  String currentLine = '';

  for (int i = 0; i < words.length; i++) {
    final word = words[i];
    final testLine = currentLine.isEmpty ? word : '$currentLine $word';

    textPainter.text = TextSpan(text: testLine, style: style);
    textPainter.layout(maxWidth: double.infinity);

    if (textPainter.width > maxWidth && currentLine.isNotEmpty) {
      // La línea actual es demasiado larga, agregar línea anterior
      lines.add(currentLine.trim());
      currentLine = word;
    } else {
      currentLine = testLine;
    }
  }

  // Agregar la última línea si no está vacía
  if (currentLine.trim().isNotEmpty) {
    lines.add(currentLine.trim());
  }

  textPainter.dispose(); // Limpiar recursos
  return lines.join('\n');
}

double calculateFontSize(String text, double width, double height, TextStyle baseStyle) {
  if (text.isEmpty || width <= 0 || height <= 0) {
    return 12.0; // Valor por defecto seguro
  }

  double fontSize = 30.0;
  const double minFontSize = 8.0;
  const double maxIterations = 100; // Prevenir bucles infinitos
  int iterations = 0;

  while (fontSize > minFontSize && iterations < maxIterations) {
    final currentStyle = baseStyle.copyWith(fontSize: fontSize);

    // Primero envolvemos el texto con el tamaño actual
    final wrappedText = wrapTextByWords(text, width, currentStyle);

    final textPainter = TextPainter(
      text: TextSpan(text: wrappedText, style: currentStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: null,
    );

    textPainter.layout(maxWidth: width);

    // Verificamos si el texto cabe tanto en ancho como en alto
    if (textPainter.width <= width && textPainter.height <= height * 0.7) {
      textPainter.dispose(); // Limpiamos recursos
      return fontSize;
    }

    textPainter.dispose(); // Limpiamos recursos
    fontSize -= 1.0; // Decrementos más grandes para mayor eficiencia
    iterations++;
  }

  return fontSize; // Retorna el último tamaño válido
}

double calculateFontSizeRobust(String text, double width, double height, TextStyle baseStyle) {
  if (text.isEmpty || width <= 0 || height <= 0) {
    return 12.0;
  }

  // Usar búsqueda binaria para mayor eficiencia
  double minSize = 6.0;
  double maxSize = 50.0;
  double bestSize = minSize;
  const int maxIterations = 20;

  for (int i = 0; i < maxIterations; i++) {
    final currentSize = (minSize + maxSize) / 2;
    final currentStyle = baseStyle.copyWith(fontSize: currentSize);

    final wrappedText = wrapTextByWords(text, width, currentStyle);

    final textPainter = TextPainter(
      text: TextSpan(text: wrappedText, style: currentStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: null,
    );

    textPainter.layout(maxWidth: width);

    final fitsWidth = textPainter.width <= width;
    final fitsHeight = textPainter.height <= height * 0.7;

    textPainter.dispose();

    if (fitsWidth && fitsHeight) {
      bestSize = currentSize;
      minSize = currentSize; // Intentar un tamaño más grande
    } else {
      maxSize = currentSize; // El tamaño es demasiado grande
    }

    // Si la diferencia es muy pequeña, terminar
    if (maxSize - minSize < 0.5) {
      break;
    }
  }

  return bestSize;
}

/// Crea un path de triángulo con vértices redondeados
Path roundedTriangle(List<Offset> points, double radius) {
  assert(points.length == 3);
  final path = Path();

  for (int i = 0; i < 3; i++) {
    final prev = points[(i + 2) % 3];
    final curr = points[i];
    final next = points[(i + 1) % 3];

    final v1 = (prev - curr);
    final v2 = (next - curr);

    final v1Norm = v1 / v1.distance * radius;
    final v2Norm = v2 / v2.distance * radius;

    final p1 = curr + v1Norm;
    final p2 = curr + v2Norm;

    if (i == 0) {
      path.moveTo(p1.dx, p1.dy);
    } else {
      path.lineTo(p1.dx, p1.dy);
    }
    path.quadraticBezierTo(curr.dx, curr.dy, p2.dx, p2.dy);
  }
  path.close();
  return path;
}


class LiquidTetrahedronPainter extends CustomPainter {
  final vmath.Matrix4 matrix;
  final String answer;
  final double animationProgress;
  final double floatProgress;

  LiquidTetrahedronPainter({
    required this.matrix,
    required this.answer,
    required this.animationProgress,
    required this.floatProgress,
  });

  /// Crea un path de triángulo con vértices redondeados
  Path roundedTriangle(List<Offset> points, double radius) {
    assert(points.length == 3);
    final path = Path();

    for (int i = 0; i < 3; i++) {
      final prev = points[(i + 2) % 3];
      final curr = points[i];
      final next = points[(i + 1) % 3];

      final v1 = (prev - curr);
      final v2 = (next - curr);

      final v1Norm = v1 / v1.distance * radius;
      final v2Norm = v2 / v2.distance * radius;

      final p1 = curr + v1Norm;
      final p2 = curr + v2Norm;

      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.quadraticBezierTo(curr.dx, curr.dy, p2.dx, p2.dy);
    }
    path.close();
    return path;
  }

  final List<Color> colors = [
    Color(0xFF1565C0), // Cara frontal (azul más intenso)
    Color(0xFF0D47A1), // Lateral 1
    Color(0xFF0D47A1), // Lateral 2
    Color(0xFF002171), // Base trasera
  ];

  Offset project(vmath.Vector3 v, double size) {
    double scale = size * 0.65; //FIX scale old value: size/3
    // Efecto de refracción sutil del líquido
    double refractionEffect = 1.0 + 0.02 * math.sin(floatProgress * math.pi * 2);
    double perspective = 2 / (2 + v.z) * refractionEffect;
    return Offset(
      size / 2 + v.x * scale * perspective,
      size / 2 - v.y * scale * perspective,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rotated = _tetrahedronVertices
        .map((v) => matrix.transform3(vmath.Vector3.array(v)))
        .toList();

    // Ordena las caras por profundidad
    final faceDepths = List.generate(_tetrahedronFaces.length, (i) {
      final face = _tetrahedronFaces[i];
      final zAvg = (rotated[face[0]].z + rotated[face[1]].z + rotated[face[2]].z) / 3;
      return {'index': i, 'z': zAvg};
    });
    faceDepths.sort((a, b) => (a['z'] as num).compareTo(b['z'] as num));

    for (final faceInfo in faceDepths) {
      final i = (faceInfo['index'] as num).toInt();
      final face = _tetrahedronFaces[i];
      final facePoints = [
        project(rotated[face[0]], size.width),
        project(rotated[face[1]], size.width),
        project(rotated[face[2]], size.width),
      ];

      // Usar un radio proporcional al tamaño para las esquinas curvas
      final path = roundedTriangle(facePoints, size.width * 0.06);

      // Efecto de ondulación del líquido en los colores
      final liquidEffect = 0.95 + 0.05 * math.sin(floatProgress * math.pi * 4);
      final faceColor = colors[i].withOpacity((i == 0 ? 0.95 : 0.75) * liquidEffect);

      canvas.drawPath(
        path,
        Paint()
          ..color = faceColor
          ..style = PaintingStyle.fill,
      );

      // Sombras más suaves para simular el efecto del líquido
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withOpacity(i == 0 ? 0.4 : 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Dibuja el texto SOLO en la cara frontal
      if (i == 0 && animationProgress > 0.5) {
        final textOpacity = math.min((animationProgress - 0.5) / 0.5, 1.0);
        drawTextOnFace(canvas, facePoints, answer, textOpacity, size);
      }
    }
  }

  Size calculateTriangleInscribedArea(List<Offset> points) {
    if (points.length != 3) {
      return Size(20, 15); // Tamaño por defecto
    }

    // Calcular las longitudes de los lados
    double side1 = math.sqrt(math.pow(points[1].dx - points[0].dx, 2) + math.pow(points[1].dy - points[0].dy, 2));
    double side2 = math.sqrt(math.pow(points[2].dx - points[1].dx, 2) + math.pow(points[2].dy - points[1].dy, 2));
    double side3 = math.sqrt(math.pow(points[0].dx - points[2].dx, 2) + math.pow(points[0].dy - points[2].dy, 2));

    // Calcular el área del triángulo usando la fórmula de Herón
    double s = (side1 + side2 + side3) / 2; // Semiperímetro
    double area = math.sqrt(s * (s - side1) * (s - side2) * (s - side3));

    if (area <= 0) {
      return Size(20, 15); // Tamaño por defecto si hay error
    }

    // Calcular el radio del círculo inscrito
    double inRadius = area / s;

    // El rectángulo inscrito más grande en un triángulo tiene aproximadamente:
    // Ancho ≈ 2.3 * radio_inscrito
    // Alto ≈ 1.4 * radio_inscrito
    double rectWidth = inRadius * 2.3;
    double rectHeight = inRadius * 1.4;

    // Aplicar límites mínimos y máximos basados en el bounding box
    double minX = points.map((p) => p.dx).reduce(math.min);
    double maxX = points.map((p) => p.dx).reduce(math.max);
    double minY = points.map((p) => p.dy).reduce(math.min);
    double maxY = points.map((p) => p.dy).reduce(math.max);

    double maxPossibleWidth = (maxX - minX) * 0.6; // 60% del ancho del bounding box
    double maxPossibleHeight = (maxY - minY) * 0.4; // 40% del alto del bounding box

    rectWidth = math.min(rectWidth, maxPossibleWidth);
    rectHeight = math.min(rectHeight, maxPossibleHeight);

    // Asegurar dimensiones mínimas
    rectWidth = math.max(rectWidth, 15.0);
    rectHeight = math.max(rectHeight, 10.0);

    return Size(rectWidth, rectHeight);
  }


  void drawTextOnFace(Canvas canvas, List<Offset> facePoints, String text, double textOpacity, Size size) {
    final center = Offset(
      (facePoints[0].dx + facePoints[1].dx + facePoints[2].dx) / 3,
      (facePoints[0].dy + facePoints[1].dy + facePoints[2].dy) / 3,
    );

    final baseVec = facePoints[2] - facePoints[1];
    final angle = math.atan2(baseVec.dy, baseVec.dx);

    // Efecto de ondulación sutil en el texto
    final textWave = 1.0 + 0.005 * math.sin(floatProgress * math.pi * 2.5);

    final inscribedArea = calculateTriangleInscribedArea(facePoints);
     double availableWidth = inscribedArea.width;
     double availableHeight = inscribedArea.height;
     double minWidth = size.width * 0.1;
     double minHeight = size.height * 0.08;

    // Asegurar dimensiones mínimas
     availableWidth = math.max(availableWidth, minWidth);
     availableHeight = math.max(availableHeight, minHeight);

    TextStyle baseStyle = TextStyle(
      color: Colors.white.withOpacity(textOpacity),
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          offset: Offset(1, 1),
          blurRadius: 4,
          color: Colors.black54.withOpacity(textOpacity),
        ),
        Shadow(
          offset: Offset(0, 0),
          blurRadius: 8,
          color: Colors.blue.withOpacity(0.2 * textOpacity),
        ),
      ],
    );

    // Usar la función mejorada de cálculo de fontSize
    double fontSize = calculateFontSizeRobust(text, availableWidth, availableHeight, baseStyle);

    final finalStyle = baseStyle.copyWith(fontSize: fontSize);
    final wrappedText = wrapTextByWords(text, availableWidth, finalStyle);

    final textPainter =  TextPainter(
         text: TextSpan(text: wrappedText, style: finalStyle),
         textDirection: TextDirection.ltr,
         textAlign: TextAlign.center,
         maxLines: null,
       );
    textPainter.layout(maxWidth: availableWidth);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.scale(textWave, textWave); // Aplicar efecto de ondulación
    canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LiquidTetrahedronPainter oldDelegate) => true;
}
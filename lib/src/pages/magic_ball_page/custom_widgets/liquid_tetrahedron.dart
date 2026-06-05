import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
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
  late double _finalZRotation;

  late double _liquidDensity;
  late double _buoyancyForce;
  late List<Bubble> _bubbles;

  @override
  void initState() {
    super.initState();
    log('LiquidTetrahedron initState → answer: ${widget.answer}');
    _initRandom();
    _initControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mainController.forward();
        _floatController.repeat(reverse: true);
        _bubbleController.repeat();
      }
    });
  }

  void _initRandom() {
    final rand = math.Random();
    final angle = rand.nextDouble() * 2 * math.pi;
    final distance = 150.0 + rand.nextDouble() * 100.0;
    _originX = math.cos(angle) * distance;
    _originY = math.sin(angle) * distance;

    _initialAxis = vmath.Vector3(
      rand.nextDouble() * 2 - 1,
      rand.nextDouble() * 2 - 1,
      rand.nextDouble() * 2 - 1,
    )..normalize();
    _initialAngle = rand.nextDouble() * math.pi * 1.5;
    _finalZRotation = rand.nextDouble() * math.pi * 0.8;
    _finalMatrix = _calculateFinalMatrix();

    _liquidDensity = 0.8 + rand.nextDouble() * 0.4;
    _buoyancyForce = 0.3 + rand.nextDouble() * 0.2;
    _bubbles = List.generate(6, (i) => Bubble.random(rand));
  }

  void _initControllers() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _mainAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutCubic,
    );

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );
    _floatAnimation =
        CurvedAnimation(parent: _floatController, curve: Curves.easeInOut);

    _bubbleController = AnimationController(
      duration: const Duration(milliseconds: 4500),
      vsync: this,
    );
    _bubbleAnimation =
        CurvedAnimation(parent: _bubbleController, curve: Curves.linear);
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  double _smoothStep(double t) => t * t * (3.0 - 2.0 * t);

  vmath.Matrix4 _rotationMatrix(vmath.Vector3 axis, double angle) {
    final q = vmath.Quaternion.axisAngle(axis, angle);
    final m4 = vmath.Matrix4.identity();
    m4.setRotation(q.asRotationMatrix());
    return m4;
  }

  vmath.Matrix4 _slerpMatrix(vmath.Matrix4 a, vmath.Matrix4 b, double t) {
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

    vmath.Quaternion qm;
    const double epsilon = 1e-6;
    if (dot > 1.0 - epsilon) {
      qm = vmath.Quaternion(
        qa.x + t * (qb.x - qa.x),
        qa.y + t * (qb.y - qa.y),
        qa.z + t * (qb.z - qa.z),
        qa.w + t * (qb.w - qa.w),
      )..normalize();
    } else {
      final theta0 = math.acos(dot);
      final theta = theta0 * t;
      final sinTheta = math.sin(theta);
      final sinTheta0 = math.sin(theta0);
      final s0 = math.cos(theta) - dot * sinTheta / sinTheta0;
      final s1 = sinTheta / sinTheta0;
      qm = vmath.Quaternion(
        qa.x * s0 + qb.x * s1,
        qa.y * s0 + qb.y * s1,
        qa.z * s0 + qb.z * s1,
        qa.w * s0 + qb.w * s1,
      );
    }
    final m4 = vmath.Matrix4.identity();
    m4.setRotation(qm.asRotationMatrix());
    return m4;
  }

  vmath.Matrix4 _calculateFinalMatrix() {
    final firstFace = _icoFaces[0];
    final v0 = vmath.Vector3.array(_icoVertices[firstFace[0]]);
    final v1 = vmath.Vector3.array(_icoVertices[firstFace[1]]);
    final v2 = vmath.Vector3.array(_icoVertices[firstFace[2]]);
    final normal = (v1 - v0).cross(v2 - v0).normalized();
    final targetNormal = vmath.Vector3(0, 0, 1);

    vmath.Quaternion q1;
    if ((normal - targetNormal).length < 1e-6) {
      q1 = vmath.Quaternion.identity();
    } else if ((normal + targetNormal).length < 1e-6) {
      q1 = vmath.Quaternion.axisAngle(vmath.Vector3(1, 0, 0), math.pi);
    } else {
      final axis = normal.cross(targetNormal).normalized();
      final ang = math.acos(normal.dot(targetNormal).clamp(-1.0, 1.0));
      q1 = vmath.Quaternion.axisAngle(axis, ang);
    }
    final m1 = vmath.Matrix4.identity()..setRotation(q1.asRotationMatrix());

    final b4 = m1.transform3(v1);
    final c4 = m1.transform3(v2);
    final baseVec = (c4 - b4).normalized();
    final m2 = vmath.Matrix4.rotationZ(-math.atan2(baseVec.y, baseVec.x));

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
    if (topIndex != 0) return vmath.Matrix4.rotationZ(math.pi) * m2 * m1;
    return m2 * m1;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation:
          Listenable.merge([_mainAnimation, _floatAnimation, _bubbleAnimation]),
      builder: (context, _) {
        final mainT = _mainAnimation.value;
        final floatT = _floatAnimation.value;
        final bubbleT = _bubbleAnimation.value;

        final liquidResistance = math.pow(mainT, 1.2).toDouble();
        final scale = 0.7 + 0.3 * liquidResistance;
        final opacity = 0.2 + 0.8 * mainT;

        final xTranslate =
            (1 - mainT) * _originX * (1 + 0.08 * math.sin(mainT * math.pi * 1.5));
        final yTranslate =
            (1 - mainT) * _originY * (1 + 0.08 * math.cos(mainT * math.pi * 1.5));

        final floatIntensity =
            mainT > 0.7 ? math.min((mainT - 0.7) / 0.3, 1.0) : 0.0;
        final floatX =
            floatIntensity * 6 * math.sin(floatT * math.pi * 2) * _buoyancyForce;
        final floatY =
            floatIntensity * 8 * math.cos(floatT * math.pi * 2 * 0.8) * _buoyancyForce;
        final floatRotation =
            floatIntensity * 0.03 * math.sin(floatT * math.pi * 2 * 1.2);

        final rotationProgress = _smoothStep(mainT);
        final initialRotationIntensity = math.pow(1 - mainT, 2.0).toDouble();
        final mStart = _rotationMatrix(
            _initialAxis, _initialAngle * initialRotationIntensity);
        final mBase = _slerpMatrix(mStart, _finalMatrix, rotationProgress);

        final finalZProgress = _smoothStep(math.max(0, (mainT - 0.3) / 0.7));
        final mWithFinalZ =
            vmath.Matrix4.rotationZ(_finalZRotation * finalZProgress) * mBase;

        final floatRotationMatrix = vmath.Matrix4.identity()
          ..rotateX(floatRotation * 0.4)
          ..rotateY(floatRotation * 0.6)
          ..rotateZ(floatRotation * 0.8);
        final finalMatrix = floatRotationMatrix * mWithFinalZ;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ..._bubbles.map((bubble) => Positioned(
                    left: widget.size / 2 +
                        bubble.getX(bubbleT) -
                        bubble.size / 2,
                    top: widget.size / 2 +
                        bubble.getY(bubbleT) -
                        bubble.size / 2,
                    child: Opacity(
                      opacity:
                          (bubble.getOpacity(bubbleT) * mainT * 0.7).clamp(0, 1),
                      child: _BubbleWidget(size: bubble.size),
                    ),
                  )),

              Center(
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..translate(xTranslate + floatX, yTranslate + floatY)
                      ..scale(scale, scale),
                    child: CustomPaint(
                      size: Size(widget.size * 0.8, widget.size * 0.8),
                      painter: RealisticIcosahedronPainter(
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

class _BubbleWidget extends StatelessWidget {
  final double size;
  const _BubbleWidget({required this.size});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _BubblePainter(size: size),
      );
}

class _BubblePainter extends CustomPainter {
  final double size;
  const _BubblePainter({required this.size});

  @override
  void paint(Canvas canvas, Size s) {
    final r = size / 2;
    final c = Offset(r, r);
    canvas.drawCircle(c, r, Paint()..color = const Color(0x1A90CAF9));
    canvas.drawCircle(
        c, r - 0.4,
        Paint()
          ..color = const Color(0x6090CAF9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7);
    canvas.drawOval(
      Rect.fromCenter(
          center: c + Offset(-r * 0.18, -r * 0.32),
          width: r * 0.48,
          height: r * 0.24),
      Paint()
        ..color = const Color(0x99FFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class Bubble {
  final double x, y, size, speed, phase;
  Bubble(this.x, this.y, this.size, this.speed, this.phase);

  factory Bubble.random(math.Random rand) => Bubble(
        (rand.nextDouble() - 0.5) * 200,
        (rand.nextDouble() - 0.5) * 200,
        2 + rand.nextDouble() * 4,
        0.5 + rand.nextDouble() * 0.5,
        rand.nextDouble() * 2 * math.pi,
      );

  double getX(double t) => x + 10 * math.sin(t * 2 * math.pi * speed + phase);
  double getY(double t) =>
      y + 15 * math.cos(t * 2 * math.pi * speed * 0.7 + phase);
  double getOpacity(double t) =>
      0.3 + 0.3 * math.sin(t * 2 * math.pi * speed * 2 + phase);
}

final List<List<double>> _icoVertices = (() {
  final double phi = (1.0 + math.sqrt(5.0)) / 2.0;
  return <List<double>>[
    [-1, phi, 0], [1, phi, 0], [-1, -phi, 0], [1, -phi, 0],
    [0, -1, phi], [0, 1, phi], [0, -1, -phi], [0, 1, -phi],
    [phi, 0, -1], [phi, 0, 1], [-phi, 0, -1], [-phi, 0, 1],
  ];
})();

const List<List<int>> _icoFaces = [
  [0, 11, 5], [0, 5, 1],  [0, 1, 7],  [0, 7, 10], [0, 10, 11],
  [1, 5, 9],  [5, 11, 4], [11, 10, 2],[10, 7, 6], [7, 1, 8],
  [3, 9, 4],  [3, 4, 2],  [3, 2, 6],  [3, 6, 8],  [3, 8, 9],
  [4, 9, 5],  [2, 4, 11], [6, 2, 10], [8, 6, 7],  [9, 8, 1],
];

class RealisticIcosahedronPainter extends CustomPainter {
  final vmath.Matrix4 matrix;
  final String answer;
  final double animationProgress;
  final double floatProgress;

  static final vmath.Vector3 _keyLight =
      vmath.Vector3(-0.35, -0.65, 0.85).normalized();
  static final vmath.Vector3 _fillLight =
      vmath.Vector3(0.55, 0.45, 0.35).normalized();

  static const Color _deepBlue    = Color(0xFF060E2B);
  static const Color _midBlue     = Color(0xFF0D3B8E);
  static const Color _brightBlue  = Color(0xFF1565C0);
  static const Color _accentBlue  = Color(0xFF4FC3F7);
  static const Color _frostWhite  = Color(0xFFE3F2FD);

  const RealisticIcosahedronPainter({
    required this.matrix,
    required this.answer,
    required this.animationProgress,
    required this.floatProgress,
  });

  Offset _project(vmath.Vector3 v, double size) {
    const double d = 2.0;
    final double perspective = d / (d + v.z);
    final double scale = size * 0.65;
    return Offset(
      size / 2 + v.x * scale * perspective,
      size / 2 - v.y * scale * perspective,
    );
  }

  double _fresnel(vmath.Vector3 n) {
    final cosA = n.dot(vmath.Vector3(0, 0, 1)).clamp(0.0, 1.0);
    const double f0 = 0.06;
    return f0 + (1.0 - f0) * math.pow(1.0 - cosA, 5.0);
  }

  double _specular(vmath.Vector3 n, {double shine = 96.0}) {
    final h = (_keyLight + vmath.Vector3(0, 0, 1)).normalized();
    return math.pow(n.dot(h).clamp(0.0, 1.0), shine).toDouble();
  }

  Path _roundedTri(List<Offset> pts, double radius) {
    final path = Path();
    for (int i = 0; i < 3; i++) {
      final prev = pts[(i + 2) % 3];
      final curr = pts[i];
      final next = pts[(i + 1) % 3];
      final v1 = prev - curr;
      final v2 = next - curr;
      final r1 = v1 / v1.distance * radius;
      final r2 = v2 / v2.distance * radius;
      final p1 = curr + r1;
      final p2 = curr + r2;
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

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    final rotated = _icoVertices
        .map((v) => matrix.transform3(vmath.Vector3.array(v)))
        .toList();

    final faceDepths = List.generate(_icoFaces.length, (i) {
      final f = _icoFaces[i];
      final zAvg = (rotated[f[0]].z + rotated[f[1]].z + rotated[f[2]].z) / 3;
      return {'index': i, 'z': zAvg};
    });

    final focalEntry =
        faceDepths.reduce((a, b) => (a['z'] as num) > (b['z'] as num) ? a : b);
    final int focalIdx = (focalEntry['index'] as num).toInt();

    faceDepths.sort((a, b) => (a['z'] as num).compareTo(b['z'] as num));

    double minZ = (faceDepths.first['z'] as num).toDouble();
    double maxZ = (faceDepths.last['z'] as num).toDouble();
    final double depthRange = (maxZ - minZ) < 1e-6 ? 1.0 : maxZ - minZ;

    final focalVerts = _icoFaces[focalIdx];

    for (final fd in faceDepths) {
      final i = (fd['index'] as num).toInt();
      final face = _icoFaces[i];

      final va = rotated[face[0]];
      final vb = rotated[face[1]];
      final vc = rotated[face[2]];

      final pts = [
        _project(va, w),
        _project(vb, w),
        _project(vc, w),
      ];
      final path = _roundedTri(pts, w * 0.05);

      final normal = (vb - va).cross(vc - va).normalized();
      final viewDot = normal.dot(vmath.Vector3(0, 0, 1));

      final bool facingCam = viewDot > 0.12;

      final bool isFocal = (i == focalIdx);
      final sharedCount =
          [face[0], face[1], face[2]].where(focalVerts.contains).length;
      final bool isAdjacent = sharedCount >= 2 && !isFocal;

      final double zAvg = (fd['z'] as num).toDouble();
      final double depthNorm = ((zAvg - minZ) / depthRange).clamp(0.0, 1.0);

      if (!facingCam) {
        final backDot = (-viewDot).clamp(0.0, 1.0);
        final subsurface = backDot * depthNorm * 0.18;
        canvas.drawPath(
          path,
          Paint()
            ..color = _midBlue.withOpacity(subsurface.clamp(0.0, 0.12)),
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = _accentBlue.withOpacity((backDot * 0.22).clamp(0, 1))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.6,
        );
        continue;
      }

      final double lambertKey  = normal.dot(_keyLight).clamp(0.0, 1.0);
      final double lambertFill = normal.dot(_fillLight).clamp(0.0, 1.0) * 0.22;
      const double ambient     = 0.07;
      final double diffuse     = ambient + lambertKey * 0.60 + lambertFill;

      final double fresnelVal = _fresnel(normal);
      final double specVal    = isFocal ? _specular(normal, shine: 110) : _specular(normal, shine: 60);

      final Color baseColor = isFocal
          ? _brightBlue
          : isAdjacent
              ? _midBlue
              : Color.lerp(_deepBlue, _midBlue, depthNorm * 0.6)!;

      Color litColor = Color.fromARGB(
        255,
        (baseColor.red   * diffuse).clamp(0, 255).round(),
        (baseColor.green * diffuse).clamp(0, 255).round(),
        (baseColor.blue  * diffuse).clamp(0, 255).round(),
      );

      final double opacity = isFocal
          ? 0.93
          : isAdjacent
              ? (0.55 + depthNorm * 0.20).clamp(0.0, 0.80)
              : (0.20 + depthNorm * 0.25).clamp(0.0, 0.55);

      canvas.drawPath(path, Paint()..color = litColor.withOpacity(opacity));

      canvas.save();
      canvas.clipPath(path);

      final centroid = Offset(
        (pts[0].dx + pts[1].dx + pts[2].dx) / 3,
        (pts[0].dy + pts[1].dy + pts[2].dy) / 3,
      );

      {
        final gradR = w * (isFocal ? 0.13 : 0.08);
        canvas.drawCircle(
          centroid,
          gradR,
          Paint()
            ..shader = ui.Gradient.radial(
              centroid,
              gradR,
              [
                _accentBlue.withOpacity(isFocal ? 0.50 : 0.18),
                _brightBlue.withOpacity(isFocal ? 0.22 : 0.06),
                Colors.transparent,
              ],
              [0.0, 0.5, 1.0],
            )
            ..blendMode = ui.BlendMode.screen,
        );
      }

      if (specVal > 0.04) {
        final topPt = pts.reduce((a, b) => a.dy < b.dy ? a : b);
        final specPos = Offset.lerp(centroid, topPt, 0.50)!;
        final specR = w * 0.040 * (isFocal ? 1.0 : 0.60);
        canvas.drawCircle(
          specPos,
          specR,
          Paint()
            ..shader = ui.Gradient.radial(
              specPos,
              specR,
              [
                _frostWhite.withOpacity(specVal * (isFocal ? 0.95 : 0.55)),
                _accentBlue.withOpacity(specVal * 0.30),
                Colors.transparent,
              ],
              [0.0, 0.45, 1.0],
            )
            ..blendMode = ui.BlendMode.screen,
        );
      }

      if (isFocal || isAdjacent) {
        final causticsT = floatProgress;
        final cx = centroid.dx + w * 0.04 * math.cos(causticsT * math.pi * 2.3);
        final cy = centroid.dy + w * 0.025 * math.sin(causticsT * math.pi * 1.8);
        final causticsOp =
            (isFocal ? 0.32 : 0.14) * (0.75 + 0.25 * math.sin(causticsT * math.pi * 4));
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width:  w * (isFocal ? 0.16 : 0.09),
            height: w * (isFocal ? 0.05 : 0.03),
          ),
          Paint()
            ..color = _accentBlue.withOpacity(causticsOp)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5)
            ..blendMode = ui.BlendMode.screen,
        );
      }

      canvas.restore();

      final double edgeOpacity =
          (fresnelVal * 0.85 + (isAdjacent ? 0.12 : 0.0)) * opacity;
      canvas.drawPath(
        path,
        Paint()
          ..color = _frostWhite.withOpacity(edgeOpacity.clamp(0, 1))
          ..style = PaintingStyle.stroke
          ..strokeWidth = isFocal ? 1.1 : 0.65
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      if (isFocal) {
        final textOp = (animationProgress * 2.0).clamp(0.0, 1.0);
        _drawText(canvas, pts, textOp, Size(w, w));
      }
    }
  }

  void _drawText(Canvas canvas, List<Offset> pts, double textOp, Size size) {
    final center = Offset(
      (pts[0].dx + pts[1].dx + pts[2].dx) / 3,
      (pts[0].dy + pts[1].dy + pts[2].dy) / 3,
    );

    final Offset viewCenter = Offset(size.width / 2, size.height / 2);
    final Offset refrOffset = (center - viewCenter) * 0.025;
    final double parScale = 0.97;

    final baseVec = pts[2] - pts[1];
    final angle = math.atan2(baseVec.dy, baseVec.dx);
    final wave = 1.0 + 0.004 * math.sin(floatProgress * math.pi * 2.5);

    final inscribed = _calcInscribed(pts);
    final availW = math.max(inscribed.width,  size.width  * 0.10);
    final availH = math.max(inscribed.height, size.height * 0.08);

    final baseStyle = TextStyle(
      color: Colors.white.withOpacity(textOp),
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
      shadows: [
        Shadow(
          offset: const Offset(0, 0),
          blurRadius: 7,
          color: _accentBlue.withOpacity(0.75 * textOp),
        ),
        Shadow(
          offset: const Offset(1, 1.5),
          blurRadius: 3,
          color: Colors.black.withOpacity(0.85 * textOp),
        ),
      ],
    );

    final fontSize = _fitFontSize(answer, availW, availH, baseStyle);
    final style   = baseStyle.copyWith(fontSize: fontSize);
    final wrapped = _wrap(answer, availW, style);

    final tp = TextPainter(
      text: TextSpan(text: wrapped, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: null,
    )..layout(maxWidth: availW);

    canvas.save();
    canvas.translate(center.dx + refrOffset.dx, center.dy + refrOffset.dy);
    canvas.rotate(angle);
    canvas.scale(wave * parScale, wave * parScale);
    canvas.translate(-tp.width / 2, -tp.height / 2);
    tp.paint(canvas, Offset.zero);
    tp.dispose();
    canvas.restore();
  }

  Size _calcInscribed(List<Offset> pts) {
    final s1 = (pts[1] - pts[0]).distance;
    final s2 = (pts[2] - pts[1]).distance;
    final s3 = (pts[0] - pts[2]).distance;
    final s  = (s1 + s2 + s3) / 2;
    final area = math.sqrt((s * (s - s1) * (s - s2) * (s - s3)).abs());
    if (area <= 0) return const Size(20, 15);
    final inR = area / s;
    final minX = pts.map((p) => p.dx).reduce(math.min);
    final maxX = pts.map((p) => p.dx).reduce(math.max);
    final minY = pts.map((p) => p.dy).reduce(math.min);
    final maxY = pts.map((p) => p.dy).reduce(math.max);
    return Size(
      math.max(math.min(inR * 2.2, (maxX - minX) * 0.52) - 3, 15),
      math.max(math.min(inR * 1.3, (maxY - minY) * 0.32) - 3, 10),
    );
  }

  double _fitFontSize(String text, double w, double h, TextStyle base) {
    double lo = 5.0, hi = 50.0, best = lo;
    for (int k = 0; k < 20; k++) {
      final mid = (lo + hi) / 2;
      final st  = base.copyWith(fontSize: mid);
      final tp  = TextPainter(
        text: TextSpan(text: _wrap(text, w, st), style: st),
        textDirection: TextDirection.ltr,
        maxLines: null,
      )..layout(maxWidth: w);
      if (tp.width <= w && tp.height <= h * 0.72) {
        best = mid; lo = mid;
      } else {
        hi = mid;
      }
      tp.dispose();
      if (hi - lo < 0.4) break;
    }
    return best;
  }

  String _wrap(String text, double maxW, TextStyle style) {
    final words = text.trim().split(RegExp(r'\s+'));
    final lines = <String>[];
    var cur = '';
    for (final w in words) {
      final test = cur.isEmpty ? w : '$cur $w';
      final tp = TextPainter(
        text: TextSpan(text: test, style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: double.infinity);
      if (tp.width > maxW && cur.isNotEmpty) {
        lines.add(cur); cur = w;
      } else {
        cur = test;
      }
      tp.dispose();
    }
    if (cur.isNotEmpty) lines.add(cur);
    return lines.join('\n');
  }

  @override
  bool shouldRepaint(covariant RealisticIcosahedronPainter old) =>
      old.answer != answer ||
      old.animationProgress != animationProgress ||
      old.floatProgress != floatProgress ||
      old.matrix != matrix;
}
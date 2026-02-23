import 'dart:ui';
import 'package:flutter/material.dart';

class GlowingRingWidget extends StatefulWidget {
  final double size;
  final Duration duration;
  final double inner;
  final double outer;
  final Color color1;
  final Color color2;
  final Color innerColor;
  final double edge;

  const GlowingRingWidget({
    super.key,
    required this.size,
    this.duration = const Duration(seconds: 4),
    this.inner = 0.48,
    this.outer = 0.5,
    this.color1 = const Color(0xFF4DE0FF),
    this.color2 = const Color(0xFFFFFFFF),
    this.innerColor = Colors.black,
    this.edge = 0.0,
  });

  @override
  State<GlowingRingWidget> createState() => _GlowingRingWidgetState();
}

class _GlowingRingWidgetState extends State<GlowingRingWidget> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  FragmentProgram? _program;
  Offset? _widgetGlobalOffset;
  final GlobalKey _paintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(_updateOffset)
      ..repeat();
    _loadShader();
    // Inicializa el offset después de construir el widget
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateOffset());
  }

  @override
  void didChangeMetrics() {
    _updateOffset();
  }

  Future<void> _loadShader() async {
    final program = await FragmentProgram.fromAsset('shaders/glow_ring.frag');
    setState(() {
      _program = program;
    });
  }

  void _updateOffset() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? box = _paintKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final offset = box.localToGlobal(Offset.zero);
        final pixelRatio = window.devicePixelRatio;
        final globalOffset = offset * pixelRatio;
        if (_widgetGlobalOffset != globalOffset) {
          setState(() {
            _widgetGlobalOffset = globalOffset;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_updateOffset);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_program == null || _widgetGlobalOffset == null) {
      return SizedBox(key: _paintKey, width: widget.size, height: widget.size);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          key: _paintKey,
          size: Size.square(widget.size),
          painter: GlowingRingPainter(
            program: _program!,
            time: _controller.value * 2 * 3.1416,
            uOffset: _widgetGlobalOffset!,
            widgetSize: widget.size,
            inner: widget.inner,
            outer: widget.outer,
            color1: widget.color1,
            color2: widget.color2,
            innerColor: widget.innerColor,
            edge: widget.edge,
          ),
        );
      },
    );
  }
}

class GlowingRingPainter extends CustomPainter {
  final FragmentProgram program;
  final double time;
  final Offset uOffset; // <-- offset global en píxeles físicos
  final double widgetSize;
  final double inner;
  final double outer;
  final Color color1;
  final Color color2;
  final Color innerColor;
  final double edge;

  GlowingRingPainter({
    required this.program,
    required this.time,
    required this.uOffset,
    required this.widgetSize,
    required this.inner,
    required this.outer,
    required this.color1,
    required this.color2,
    required this.innerColor,
    required this.edge,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pixelRatio = window.devicePixelRatio;
    final shader = program.fragmentShader();
    shader.setFloat(0, time); // u_time
    shader.setFloat(1, widgetSize * pixelRatio); // u_resolution.x
    shader.setFloat(2, widgetSize * pixelRatio); // u_resolution.y
    shader.setFloat(3, uOffset.dx); // u_offset.x (global en píxeles físicos)
    shader.setFloat(4, uOffset.dy); // u_offset.y (global en píxeles físicos)
    shader.setFloat(5, inner); // u_inner
    shader.setFloat(6, outer); // u_outer

    // color1
    shader.setFloat(7, color1.red / 255.0);
    shader.setFloat(8, color1.green / 255.0);
    shader.setFloat(9, color1.blue / 255.0);
    shader.setFloat(10, color1.opacity);

    // color2
    shader.setFloat(11, color2.red / 255.0);
    shader.setFloat(12, color2.green / 255.0);
    shader.setFloat(13, color2.blue / 255.0);
    shader.setFloat(14, color2.opacity);

    // innerColor
    shader.setFloat(15, innerColor.red / 255.0);
    shader.setFloat(16, innerColor.green / 255.0);
    shader.setFloat(17, innerColor.blue / 255.0);
    shader.setFloat(18, innerColor.opacity);

    shader.setFloat(19, edge);

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width / 2, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant GlowingRingPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.uOffset != uOffset ||
      oldDelegate.inner != inner ||
      oldDelegate.outer != outer ||
      oldDelegate.color1 != color1 ||
      oldDelegate.color2 != color2 ||
      oldDelegate.innerColor != innerColor ||
      oldDelegate.edge != edge;
}

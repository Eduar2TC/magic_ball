import 'package:flutter/material.dart';

class MagicBallTriangle extends StatefulWidget {
  final String magicAnswer;
  final double size;

  const MagicBallTriangle(
      {required this.magicAnswer, required this.size, super.key});

  @override
  MagicBallTriangleState createState() => MagicBallTriangleState();
}

class MagicBallTriangleState extends State<MagicBallTriangle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, 10 * (0.5 - _animation.value)),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: ClipPath(
              clipper: TriangleClipper(),
              child: CustomPaint(
                painter: TrianglePainter(context),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double height = constraints.maxHeight;
                    double width = constraints.maxWidth;
                    double fontSize = calculateFontSize(
                      widget.magicAnswer,
                      width,
                      height,
                    );
                    return Container(
                      margin: EdgeInsets.only(
                        top: height / 4,
                      ),
                      alignment: Alignment.center,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: widget.magicAnswer.split(' ').map((word) {
                            return TextSpan(
                              text: '$word\n',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: fontSize,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double calculateFontSize(String text, double width, double height) {
    double fontSize = 30.0; // Default font size
    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    //Ajust the font size until the text fits inside the triangle
    while (true) {
      textPainter.layout();
      if (textPainter.width <= width && textPainter.height <= height) {
        break;
      }
      fontSize -= 0.5;
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
        ),
      );
    }

    return fontSize;
  }
}

class TrianglePainter extends CustomPainter {
  final BuildContext context;
  TrianglePainter(this.context);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint0 = Paint()
      ..color = const Color.fromARGB(255, 14, 113, 242)
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0;

    Path path0 = Path();
    path0.moveTo(size.width * 0.0083125, size.height * 0.9266667);
    path0.cubicTo(
        size.width * 0.0115625,
        size.height * 0.9930000,
        size.width * 0.9936250,
        size.height * 0.9929667,
        size.width * 0.9912188,
        size.height * 0.9271000);
    path0.cubicTo(
        size.width * 0.9900000,
        size.height * 0.8221667,
        size.width * 0.5850313,
        size.height * 0.0098667,
        size.width * 0.4768125,
        size.height * 0.0064333);
    path0.cubicTo(
        size.width * 0.3799063,
        size.height * 0.0112333,
        size.width * 0.0086250,
        size.height * 0.8110667,
        size.width * 0.0083125,
        size.height * 0.9266667);
    path0.close();

    canvas.drawPath(path0, paint0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width * 0.0083125, size.height * 0.9266667);
    path.cubicTo(
        size.width * 0.0115625,
        size.height * 0.9930000,
        size.width * 0.9936250,
        size.height * 0.9929667,
        size.width * 0.9912188,
        size.height * 0.9271000);
    path.cubicTo(
        size.width * 0.9900000,
        size.height * 0.8221667,
        size.width * 0.5850313,
        size.height * 0.0098667,
        size.width * 0.4768125,
        size.height * 0.0064333);
    path.cubicTo(
        size.width * 0.3799063,
        size.height * 0.0112333,
        size.width * 0.0086250,
        size.height * 0.8110667,
        size.width * 0.0083125,
        size.height * 0.9266667);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

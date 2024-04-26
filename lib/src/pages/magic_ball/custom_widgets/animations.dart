import 'package:flutter/material.dart';
import 'package:magic_ball/src/pages/magic_ball/magic_ball_page.dart';

class BallAnimations extends StatefulWidget {
  late Animation<double> animation0;
  late Animation<double> animation1;
  late AnimationController animationController0;
  late AnimationController animationController1;

  BallAnimations({Key? key}) : super(key: key);

  @override
  State<BallAnimations> createState() => _BallAnimationsState();

  void initializeAnimations(MagicBallState magicBallState) {
    animationController0 = AnimationController(
      vsync: magicBallState,
      duration: const Duration(milliseconds: 1225),
    )
      ..addListener(() => magicBallState.setState(() {}))
      ..addStatusListener((status) {
        //AnimationStatus gives the current status of our animation, we want to go back to its previous state after completing its animation
        if (status == AnimationStatus.forward) {
          animationController1.reverse();
        } else if (status == AnimationStatus.completed) {
          animationController0
              .reverse(); //reverse the animation back here if its completed
        } else if (status == AnimationStatus.dismissed) {
          animationController1.forward();
        }
      });

    animationController1 = AnimationController(
      vsync: magicBallState,
      duration: const Duration(milliseconds: 1000),
    )
      ..addListener(() => magicBallState.setState(() {}))
      ..addStatusListener((status) {
        //AnimationStatus gives the current status of our animation, we want to go back to its previous state after completing its animation
        if (status == AnimationStatus.completed) {
          //this.audio.playPop();
        }
      });

    animation0 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController0,
        curve: Curves.easeInOut,
      ),
    );

    animation1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController1,
        curve: Curves.easeInOut,
      ),
    );
  }
}

class _BallAnimationsState extends State<BallAnimations>
    with TickerProviderStateMixin {
  @override
  void initState() {
    widget.initializeAnimations(this as MagicBallState);
    super.initState();
  }

  @override
  void dispose() {
    widget.animationController0.dispose();
    widget.animationController1.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BallAnimations();
  }
}

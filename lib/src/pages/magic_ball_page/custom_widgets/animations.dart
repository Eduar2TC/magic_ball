import 'package:flutter/material.dart';

class BallAnimations {
  late Animation<double> ballAnimation; //animation0
  late Animation<double> answerAnimation; //animation1
  late AnimationController ballAnimationController; //controller0
  late AnimationController answerAnimationController; //controller1
  final ValueNotifier<void> stateNotifier;

  BallAnimations(this.stateNotifier);

  void initializeAnimations(TickerProvider vsync, VoidCallback playPopSound) {
    ballAnimationController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1225),
    )
      ..addListener(() => stateNotifier.value = null)
      ..addStatusListener((status) {
        if (status == AnimationStatus.forward) {
          answerAnimationController.reverse();
        } else if (status == AnimationStatus.completed) {
         ballAnimationController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          answerAnimationController.forward();
        }
      });

    answerAnimationController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1500),
    )
      ..addListener(() => stateNotifier.value = null)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          answerAnimationController.duration = const Duration(milliseconds: 500);
          playPopSound();
        }
      });

    ballAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: ballAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    answerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: answerAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void dispose() {
    ballAnimationController.dispose();
    answerAnimationController.dispose();
  }
}
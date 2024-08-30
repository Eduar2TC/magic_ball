import 'package:flutter/material.dart';

class BallAnimations {
  late Animation<double> animation0;
  late Animation<double> animation1;
  late AnimationController animationController0;
  late AnimationController animationController1;
  final ValueNotifier<void> notifier;

  BallAnimations(this.notifier);

  void initializeAnimations(TickerProvider vsync, VoidCallback playPop) {
    animationController0 = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1225),
    )
      ..addListener(() => notifier.value = null)
      ..addStatusListener((status) {
        if (status == AnimationStatus.forward) {
          animationController1.reverse();
        } else if (status == AnimationStatus.completed) {
          animationController0.reverse();
        } else if (status == AnimationStatus.dismissed) {
          animationController1.forward();
        }
      });

    animationController1 = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1000),
    )
      ..addListener(() => notifier.value = null)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          animationController1.duration = const Duration(milliseconds: 500);
          playPop();
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

  void dispose() {
    animationController0.dispose();
    animationController1.dispose();
  }
}

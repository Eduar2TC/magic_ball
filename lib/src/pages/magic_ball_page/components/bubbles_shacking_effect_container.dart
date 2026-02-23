import 'package:flutter/material.dart';
import 'package:magic_ball/src/pages/magic_ball_page/custom_widgets/shaking_bubble_effect.dart';

class BubblesShackingEffectContainer extends StatelessWidget {
  final ValueNotifier<bool> showBubbles;
  final String? anwer;
  const BubblesShackingEffectContainer({
    super.key,
    required this.showBubbles,
    this.anwer,
  });
  @override
  Widget build(BuildContext context) {
    final double containerSize = MediaQuery.of(context).size.width * 0.40;
    return ValueListenableBuilder<bool>(
      valueListenable: showBubbles,
      builder: (context, showBubbles, _) {
        return showBubbles
            ? ShakingBubbleEffect(
                //pesonalize widget bubble shaking effect class
                size: containerSize,
                magicAnswer: anwer ?? '',
              )
            : Container();
      },
    );
  }
}

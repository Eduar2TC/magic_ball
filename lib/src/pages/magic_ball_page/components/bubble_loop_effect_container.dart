import 'dart:math';

import 'package:flutter/material.dart';
import 'package:magic_ball/src/pages/magic_ball_page/custom_widgets/bubble_effect.dart';

class BubbleLoopEffectContainer extends StatelessWidget {
  final ValueNotifier<bool> showBubbles;
  const BubbleLoopEffectContainer({super.key, required this.showBubbles});

  @override
  Widget build(BuildContext context) {
    //generate random bubbles between 3 to 5
    int randomBubbles = Random().nextInt(3) + 2;
    return ValueListenableBuilder<bool>(
      valueListenable: showBubbles,
      builder: (context, showBubblesVal, _) {
        return showBubblesVal
            ? ClipOval(
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: MediaQuery.of(context).size.width * 0.4,
                  child: BubbleEffect(
                    //personalize widget bubble loop effect class
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: MediaQuery.of(context).size.width * 0.4,
                    numberOfBubbles: randomBubbles,
                  ),
                ),
              )
            : Container();
      },
    );
  }
}

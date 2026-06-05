import 'package:flutter/material.dart';
import 'package:magic_ball/src/pages/magic_ball_page/custom_widgets/shaking_bubble_effect.dart';

class BubblesShackingEffectContainer extends StatelessWidget {
  final bool showBubbles;
  final String? answer;

  // NOTA: shakeBurst ha sido eliminado por completo de aquí también
  const BubblesShackingEffectContainer({
    super.key,
    required this.showBubbles,
    this.answer,
  });

  @override
  Widget build(BuildContext context) {
    final double containerSize = MediaQuery.of(context).size.width * 0.40;
    return showBubbles
        ? ShakingBubbleEffect(
            size: containerSize,
            magicAnswer: answer ?? '',
          )
        : const SizedBox.shrink();
  }
}
import 'package:flutter/material.dart';
import 'package:magic_ball/src/pages/magic_ball_page/custom_widgets/liquid_tetrahedron.dart';

class LiquidTetrahedronContainer extends StatelessWidget {
  final ValueNotifier<bool> showLiquid;
  final ValueNotifier<String?> magicAnswerNotifier;
  const LiquidTetrahedronContainer({
    super.key,
    required this.showLiquid,
    required this.magicAnswerNotifier,
  });
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: showLiquid,
      builder: (context, showLiquid, _) {
        return showLiquid
            ? ClipOval(
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: MediaQuery.of(context).size.width * 0.4,
                  child: LiquidTetrahedron(
                    // personalize widget liquid tetrahedron class
                    size: MediaQuery.of(context).size.width * 0.5,
                    answer: magicAnswerNotifier.value ?? 'Tap to find out your fortune',
                  ),
                ),
              )
            : Container();
      },
    );
  }
}

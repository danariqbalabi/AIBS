// Onboarding progress bar (B1–B5 = steps 1–5, C1–C9 = steps 6–14).
//
//   StepProgress(step: 3)   // total defaults to 14
//
// Sits in the top bar between the back button and the "Nanti"/"Lewati" link.

import 'package:flutter/material.dart';

import '../../core/theme/aibs_tokens.dart';

class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step, this.total = 14});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final value = (step / total).clamp(0.0, 1.0);
    return Semantics(
      label: 'Langkah $step dari $total',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AibsSize.progress / 2),
        child: SizedBox(
          height: AibsSize.progress,
          child: ColoredBox(
            color: context.aibsColor(AibsColors.line),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: value),
              duration: reduce ? Duration.zero : AibsMotion.progress,
              curve: AibsMotion.standard,
              builder: (context, v, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: v,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.aibsColor(AibsColors.primary),
                    borderRadius: BorderRadius.all(
                      Radius.circular(AibsSize.progress / 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

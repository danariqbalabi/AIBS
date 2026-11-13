// Koala mascot.
//
//   Koala(KoalaMood.senang, size: 120)
//   KoalaBubble(mood: KoalaMood.senang, text: 'Ada keluhan setelah makan pagi tadi?')
//
// Needs flutter_svg and assets/brand/koala_{senang,mikir,khawatir}.svg.
// Rule: max one koala per screen, never recolored, never extra shadows.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/aibs_tokens.dart';

enum KoalaMood { senang, mikir, khawatir }

class Koala extends StatelessWidget {
  const Koala(this.mood, {super.key, this.size = 120, this.semanticLabel});

  final KoalaMood mood;

  /// Sizes used in the design: bubble 84–96, verdict 140–150,
  /// hero/empty 170–200, welcome 230.
  final double size;

  /// Null = decorative (when nearby text already says what matters).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/brand/koala_${mood.name}.svg',
      width: size,
      height: size,
      excludeFromSemantics: semanticLabel == null,
      semanticsLabel: semanticLabel,
    );
  }
}

/// Koala asking something through a speech bubble (Hari Ini prompt, H1p).
///
/// Layout: koala + bubble aligned to the bottom. The bubble keeps a bottom
/// margin so its text never rises above the koala's ear tips. Keep [text]
/// to one short question; put the actions below this widget.
class KoalaBubble extends StatelessWidget {
  const KoalaBubble({
    super.key,
    required this.text,
    this.mood = KoalaMood.senang,
    this.koalaSize = 84,
  });

  final String text;
  final KoalaMood mood;
  final double koalaSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Koala(mood, size: koalaSize),
        const SizedBox(width: AibsSpace.s6),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: koalaSize >= 96 ? 16 : 14),
            padding: const EdgeInsets.symmetric(
              horizontal: AibsSpace.s14,
              vertical: AibsSpace.s12,
            ),
            decoration: const BoxDecoration(
              color: AibsColors.card,
              borderRadius: AibsRadius.bubbleShape,
              boxShadow: AibsShadows.bubble,
            ),
            child: Text(
              text,
              style: AibsType.bodyStrong.copyWith(
                fontSize: koalaSize >= 96 ? 16 : 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Result hero: koala bottom-left, short headline bottom-aligned to its right.
/// Used on F6 (status soft background) and B6 (hero gradient).
class VerdictCard extends StatelessWidget {
  const VerdictCard({
    super.key,
    required this.mood,
    required this.headline,
    this.label,
    this.detail,
    this.headlineColor = AibsColors.ink,
    this.color,
    this.gradient,
    this.koalaSize = 140,
  });

  final KoalaMood mood;
  final String
  headline; // keep it short: one or two lines, never above the ears
  final String? label; // small line above the headline
  final String? detail; // one short reason line under the headline
  final Color headlineColor;
  final Color? color;
  final Gradient? gradient;
  final double koalaSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AibsRadius.xxl),
      ),
      child: Stack(
        children: [
          Positioned(left: 4, bottom: -8, child: Koala(mood, size: koalaSize)),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: koalaSize),
            child: Align(
              alignment: Alignment.bottomLeft,
              heightFactor: 1,
              child: Padding(
                padding: EdgeInsets.fromLTRB(koalaSize + 4, 20, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (label != null)
                      Text(
                        label!,
                        style: AibsType.caption.copyWith(
                          color: AibsColors.primaryStrong,
                          fontWeight: AibsType.w800,
                        ),
                      ),
                    Text(
                      headline,
                      style: AibsType.verdict.copyWith(color: headlineColor),
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: AibsSpace.s4),
                      Text(detail!, style: AibsType.caption),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/theme/aibs_tokens.dart';
import '../shared/widgets/koala.dart';
import '../theme/aibs_theme.dart';

class AibsCard extends StatelessWidget {
  const AibsCard({
    required this.child,
    super.key,
    this.padding = AibsSpace.s16,
  });

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AibsColors.card,
        borderRadius: BorderRadius.circular(AibsRadius.lg),
        boxShadow: AibsShadows.card,
      ),
      child: child,
    );
  }
}

class AibsPrimaryButton extends StatelessWidget {
  const AibsPrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AibsSize.button,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? const LinearGradient(colors: [AibsColors.line, AibsColors.line])
              : AibsGradients.brand,
          borderRadius: BorderRadius.circular(AibsRadius.lg),
          boxShadow: onPressed == null ? null : AibsShadows.glow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AibsRadius.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: AibsColors.onPrimary,
                    size: AibsSize.navIcon,
                  ),
                  const SizedBox(width: AibsSpace.s8),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: AibsType.button.copyWith(
                        color: AibsColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AibsSecondaryButton extends StatelessWidget {
  const AibsSecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AibsSize.button,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AibsColors.primaryStrong,
          side: const BorderSide(color: AibsColors.line, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AibsRadius.lg),
          ),
          textStyle: AibsType.button,
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
      ),
    );
  }
}

class AibsMascot extends StatelessWidget {
  const AibsMascot({required this.expression, super.key, this.size = 136});

  final String expression;
  final double size;

  @override
  Widget build(BuildContext context) {
    final mood = switch (expression) {
      'senang' => KoalaMood.senang,
      'mikir' => KoalaMood.mikir,
      'khawatir' => KoalaMood.khawatir,
      _ => throw ArgumentError.value(expression, 'expression'),
    };
    return Koala(mood, size: size, semanticLabel: 'Koala AIBS');
  }
}

class AibsChoiceChip extends StatelessWidget {
  const AibsChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AibsColors.primary : AibsColors.card,
      borderRadius: BorderRadius.circular(AibsRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AibsRadius.pill),
        child: Container(
          constraints: const BoxConstraints(minHeight: AibsSize.chip),
          padding: const EdgeInsets.symmetric(
            horizontal: AibsSpace.s16,
            vertical: AibsSpace.s10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AibsRadius.pill),
            border: Border.all(
              color: selected ? AibsColors.primary : AibsColors.line,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AibsSpace.s6),
              ],
              if (selected) ...[
                const Icon(Icons.check, color: AibsColors.onPrimary, size: 16),
                const SizedBox(width: AibsSpace.s6),
              ],
              Text(
                label,
                style: AibsType.bodyStrong.copyWith(
                  color: selected ? AibsColors.onPrimary : AibsColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

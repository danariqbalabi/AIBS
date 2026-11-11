import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/aibs_theme.dart';

class AibsCard extends StatelessWidget {
  const AibsCard({required this.child, super.key, this.padding = 16});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AibsColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19476FED),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
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
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? const LinearGradient(
                  colors: [AibsColors.unknown, AibsColors.unknown],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AibsColors.sky, AibsColors.primaryStrong],
                ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AibsColors.primaryStrong,
          side: const BorderSide(color: AibsColors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
        child: Text(label),
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
    return SvgPicture.asset(
      'assets/maskot/koala-$expression.svg',
      width: size,
      height: size,
      semanticsLabel: 'Koala AIBS',
      placeholderBuilder: (_) => SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: Icon(Icons.pets, color: AibsColors.primary, size: 44),
        ),
      ),
    );
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
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AibsColors.primary : AibsColors.line,
              width: selected ? 1 : 1.4,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 6)],
              if (selected) ...[
                const Icon(Icons.check, color: Colors.white, size: 16),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AibsColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

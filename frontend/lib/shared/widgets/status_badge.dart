// Food-check status: the only place status colors are used.
//
//   StatusBadge(CheckStatus.ok)          → "✓ Sesuai" pill
//   StatusGroupHeader(CheckStatus.warn)  → dot + "Perlu hati-hati" (Menu list)
//   StatusDot(CheckStatus.bad)           → 24px circle with "×" (ingredient rows)

import 'package:flutter/material.dart';

import '../../core/theme/aibs_tokens.dart';

enum CheckStatus { ok, warn, bad, unknown }

extension CheckStatusStyle on CheckStatus {
  String get symbol => switch (this) {
    CheckStatus.ok => '✓',
    CheckStatus.warn => '!',
    CheckStatus.bad => '×',
    CheckStatus.unknown => '?',
  };

  /// Short label for badges.
  String get label => switch (this) {
    CheckStatus.ok => 'Sesuai',
    CheckStatus.warn => 'Perlu hati-hati',
    CheckStatus.bad => 'Tidak sesuai',
    CheckStatus.unknown => 'Belum bisa dinilai',
  };

  /// Group header label in Menu (M1).
  String get groupLabel => switch (this) {
    CheckStatus.ok => 'Sesuai arahanmu',
    CheckStatus.warn => 'Perlu hati-hati',
    CheckStatus.bad => 'Tidak sesuai arahan',
    CheckStatus.unknown => 'Belum bisa dinilai',
  };

  Color get color => switch (this) {
    CheckStatus.ok => AibsColors.ok,
    CheckStatus.warn => AibsColors.warn,
    CheckStatus.bad => AibsColors.bad,
    CheckStatus.unknown => AibsColors.unknown,
  };

  Color get ink => switch (this) {
    CheckStatus.ok => AibsColors.okInk,
    CheckStatus.warn => AibsColors.warnInk,
    CheckStatus.bad => AibsColors.badInk,
    CheckStatus.unknown => AibsColors.inkMuted,
  };

  Color get soft => switch (this) {
    CheckStatus.ok => AibsColors.okSoft,
    CheckStatus.warn => AibsColors.warnSoft,
    CheckStatus.bad => AibsColors.badSoft,
    CheckStatus.unknown => AibsColors.unknownSoft,
  };
}

/// Pill: symbol + label, status ink on status soft. Padding 3 / 10, 12/800.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key, this.text});

  final CheckStatus status;

  /// Override the label, e.g. "Nasi 1½ porsi". The symbol is always kept.
  final String? text;

  @override
  Widget build(BuildContext context) {
    final label = '${status.symbol} ${text ?? status.label}';
    return Semantics(
      label: 'Status: ${text ?? status.label}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: status.soft,
          borderRadius: BorderRadius.circular(AibsRadius.pill),
        ),
        child: Text(label, style: AibsType.badge.copyWith(color: status.ink)),
      ),
    );
  }
}

/// Group header for lists grouped by status. Rows under it don't repeat the badge.
class StatusGroupHeader extends StatelessWidget {
  const StatusGroupHeader(this.status, {super.key});

  final CheckStatus status;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AibsSpace.s6),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: status.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AibsSpace.s8),
            Text(
              status.groupLabel,
              style: AibsType.caption.copyWith(
                color: status.ink,
                fontWeight: AibsType.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filled circle with the status symbol, used at the start of ingredient rows.
class StatusDot extends StatelessWidget {
  const StatusDot(this.status, {super.key, this.size = 24});

  final CheckStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: status.label,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
        child: Text(
          status.symbol,
          style: AibsType.badge.copyWith(
            color: AibsColors.onPrimary,
            fontSize: size * 0.5,
          ),
        ),
      ),
    );
  }
}

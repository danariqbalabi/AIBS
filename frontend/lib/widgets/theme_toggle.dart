import 'package:flutter/material.dart';

import '../core/theme/aibs_tokens.dart';
import '../data/theme_preferences.dart';
import 'aibs_widgets.dart';

class ThemeToggleCard extends StatelessWidget {
  const ThemeToggleCard({super.key, required this.preferences});
  final ThemePreferences preferences;

  Future<void> _save(BuildContext context, ThemeMode mode) async {
    try {
      await preferences.setMode(mode);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilihan tampilan belum tersimpan. Coba lagi.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: preferences,
    builder: (context, _) {
      final dark =
          preferences.mode == ThemeMode.dark ||
          (preferences.mode == ThemeMode.system &&
              Theme.of(context).brightness == Brightness.dark);
      final duration = MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AibsMotion.select;
      return AibsCard(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tampilan',
                        style: context.aibsText(AibsType.bodyStrong),
                      ),
                      const SizedBox(height: AibsSpace.s4),
                      Text(
                        dark ? 'Gelap' : 'Terang',
                        style: context.aibsText(AibsType.caption),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: 'Mode gelap',
                  toggled: dark,
                  enabled: !preferences.saving,
                  child: Tooltip(
                    message: dark
                        ? 'Ganti ke tema terang'
                        : 'Ganti ke tema gelap',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: preferences.saving
                            ? null
                            : () => _save(
                                context,
                                dark ? ThemeMode.light : ThemeMode.dark,
                              ),
                        borderRadius: BorderRadius.circular(AibsRadius.pill),
                        child: AnimatedContainer(
                          duration: duration,
                          curve: AibsMotion.standard,
                          width: AibsSize.themeToggleWidth,
                          height: AibsSize.themeToggleHeight,
                          padding: const EdgeInsets.all(AibsSpace.s6),
                          decoration: BoxDecoration(
                            color: dark
                                ? AibsDarkColors.primarySoft
                                : AibsColors.primarySoft,
                            borderRadius: BorderRadius.circular(
                              AibsRadius.pill,
                            ),
                            border: Border.all(
                              color: context.aibsColor(AibsColors.line),
                            ),
                          ),
                          child: ExcludeSemantics(
                            child: Stack(
                              children: [
                                Align(
                                  alignment: dark
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AibsSpace.s6,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          dark
                                              ? Icons.star_rounded
                                              : Icons.wb_sunny_outlined,
                                          size: dark
                                              ? AibsSize.themeStar
                                              : AibsSize.navIcon,
                                          color: dark
                                              ? AibsDarkColors.primaryTint
                                              : AibsColors.primaryStrong,
                                        ),
                                        if (dark)
                                          const Padding(
                                            padding: EdgeInsets.only(
                                              top: AibsSpace.s12,
                                            ),
                                            child: Icon(
                                              Icons.star_rounded,
                                              size: AibsSize.themeStar,
                                              color: AibsDarkColors.primaryTint,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                AnimatedAlign(
                                  duration: duration,
                                  curve: AibsMotion.standard,
                                  alignment: dark
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    width: AibsSize.themeThumb,
                                    height: AibsSize.themeThumb,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: dark
                                          ? AibsDarkColors.ink
                                          : AibsColors.card,
                                    ),
                                    child: Icon(
                                      dark
                                          ? Icons.nightlight_round
                                          : Icons.wb_sunny_rounded,
                                      size: AibsSize.navIcon,
                                      color: AibsColors.primaryStrong,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AibsSpace.s12),
            Divider(
              height: AibsSpace.s12,
              color: context.aibsColor(AibsColors.line),
            ),
            Material(
              color: Colors.transparent,
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Ikuti perangkat',
                  style: context.aibsText(AibsType.caption),
                ),
                value: preferences.mode == ThemeMode.system,
                onChanged: preferences.saving
                    ? null
                    : (value) => _save(
                        context,
                        value
                            ? ThemeMode.system
                            : (dark ? ThemeMode.dark : ThemeMode.light),
                      ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

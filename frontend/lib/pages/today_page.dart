import 'package:flutter/material.dart';

import '../shared/widgets/koala.dart';
import '../shared/widgets/status_badge.dart';
import '../theme/aibs_theme.dart';
import '../widgets/aibs_widgets.dart';

enum TodayMode { profileComplete, loggingOnly, empty }

class TodayLogEntry {
  const TodayLogEntry({required this.time, required this.title});

  final String time;
  final String title;
}

class TodayPage extends StatelessWidget {
  const TodayPage({
    required this.name,
    required this.mode,
    required this.records,
    required this.showSymptomPrompt,
    required this.onOpenCamera,
    required this.onOpenMenu,
    required this.onOpenJournal,
    required this.onOpenProfile,
    required this.onDismissSymptomPrompt,
    super.key,
  });

  final String name;
  final TodayMode mode;
  final List<TodayLogEntry> records;
  final bool showSymptomPrompt;
  final VoidCallback onOpenCamera;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenJournal;
  final VoidCallback onOpenProfile;
  final VoidCallback onDismissSymptomPrompt;

  static const _recommendedMenus = [
    _TodayMenu(
      name: 'Nasi ayam bakar kecap',
      details: 'Beli · Rp22.000',
      icon: Icons.rice_bowl_outlined,
      imageColors: AibsColors.foodBlue,
    ),
    _TodayMenu(
      name: 'Tumis tahu wortel',
      details: 'Masak · Rp15.000',
      icon: Icons.soup_kitchen_outlined,
      imageColors: AibsColors.foodPink,
    ),
    _TodayMenu(
      name: 'Sup ayam jahe',
      details: 'Beli · Rp18.000',
      icon: Icons.soup_kitchen_outlined,
      imageColors: AibsColors.foodGrey,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final meal = _mealLabel(DateTime.now());
    return Stack(
      children: [
        Positioned(
          top: -(AibsSize.homeGlow / 4),
          right: -(AibsSize.homeGlow / 4),
          child: IgnorePointer(
            child: Container(
              width: AibsSize.homeGlow,
              height: AibsSize.homeGlow,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AibsGradients.glow,
              ),
            ),
          ),
        ),
        ListView(
          padding: const EdgeInsets.only(bottom: AibsSpace.s28),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AibsSpace.s20,
                AibsSpace.s24,
                AibsSpace.s20,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hai, $name', style: AibsType.greeting),
                  const SizedBox(height: AibsSpace.s2),
                  Text(
                    mode == TodayMode.loggingOnly
                        ? 'Mau catat apa hari ini?'
                        : 'Mau $meal apa?',
                    style: AibsType.title,
                  ),
                ],
              ),
            ),
            switch (mode) {
              TodayMode.profileComplete => _buildProfileComplete(),
              TodayMode.loggingOnly => _buildLoggingOnly(),
              TodayMode.empty => _buildEmptyProfile(),
            },
          ],
        ),
      ],
    );
  }

  Widget _buildProfileComplete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AibsSpace.s20),
        _buildRecommendations(),
        if (showSymptomPrompt) ...[
          const SizedBox(height: AibsSpace.s20),
          _buildSymptomPrompt(),
        ],
        const SizedBox(height: AibsSpace.s24),
        _buildWeeklySummary(),
      ],
    );
  }

  Widget _buildRecommendations() {
    return SizedBox(
      height: AibsSize.homeSliderHeight,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AibsSpace.s20,
          AibsSpace.s4,
          AibsSpace.s20,
          AibsSpace.s12,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: _recommendedMenus.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AibsSpace.s12),
        itemBuilder: (context, index) {
          if (index == _recommendedMenus.length) {
            return _SeeAllCard(onTap: onOpenMenu);
          }
          return _RecommendationCard(
            menu: _recommendedMenus[index],
            onTap: onOpenMenu,
          );
        },
      ),
    );
  }

  Widget _buildSymptomPrompt() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AibsSpace.s20),
      child: Container(
        padding: const EdgeInsets.all(AibsSpace.s12),
        decoration: BoxDecoration(
          color: AibsColors.primarySoft,
          borderRadius: BorderRadius.circular(AibsRadius.lg),
        ),
        child: Column(
          children: [
            const KoalaBubble(
              text: 'Ada keluhan setelah makan pagi tadi?',
              mood: KoalaMood.senang,
              koalaSize: 84,
            ),
            const SizedBox(height: AibsSpace.s8),
            Row(
              children: [
                Expanded(
                  child: _HomeActionButton(
                    label: 'Nggak ada',
                    style: _HomeActionStyle.neutral,
                    height: AibsSize.buttonInCard,
                    onTap: onDismissSymptomPrompt,
                  ),
                ),
                const SizedBox(width: AibsSpace.s10),
                Expanded(
                  child: _HomeActionButton(
                    label: 'Catat',
                    style: _HomeActionStyle.primary,
                    height: AibsSize.buttonInCard,
                    onTap: onOpenJournal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummary() {
    const severities = [null, 2, null, 3, 2, null, 2];
    final today = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AibsSpace.s20),
      child: AibsCard(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('7 hari terakhir', style: AibsType.sectionTitle),
                ),
                Text('4 hari ada gejala', style: AibsType.caption),
              ],
            ),
            const SizedBox(height: AibsSpace.s14),
            Row(
              children: [
                for (var index = 0; index < severities.length; index++)
                  Expanded(
                    child: _SymptomDayDot(
                      label: _weekdayLetter(
                        today.subtract(Duration(days: 6 - index)),
                      ),
                      severity: severities[index],
                      isToday: index == severities.length - 1,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AibsSpace.s16),
            Row(
              children: [
                Expanded(
                  child: _HomeActionButton(
                    label: 'Baca pola',
                    style: _HomeActionStyle.soft,
                    height: AibsSize.buttonInCard,
                    onTap: onOpenJournal,
                  ),
                ),
                const SizedBox(width: AibsSpace.s10),
                Expanded(
                  child: _HomeActionButton(
                    label: 'Lihat riwayat',
                    style: _HomeActionStyle.soft,
                    height: AibsSize.buttonInCard,
                    onTap: onOpenJournal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggingOnly() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AibsSpace.s20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AibsSpace.s20),
          child: Container(
            padding: const EdgeInsets.all(AibsSpace.s16),
            decoration: BoxDecoration(
              color: AibsColors.primarySoft,
              borderRadius: BorderRadius.circular(AibsRadius.lg),
            ),
            child: Column(
              children: [
                const KoalaBubble(
                  text:
                      'Isi arahan dietmu biar aku bisa kasih rekomendasi menu.',
                  mood: KoalaMood.mikir,
                  koalaSize: 96,
                ),
                const SizedBox(height: AibsSpace.s12),
                _HomeActionButton(
                  label: 'Isi arahan diet',
                  style: _HomeActionStyle.primary,
                  height: AibsSize.button,
                  onTap: onOpenProfile,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AibsSpace.s24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AibsSpace.s20),
          child: Text('Hari ini', style: AibsType.sectionTitle),
        ),
        const SizedBox(height: AibsSpace.s12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AibsSpace.s20),
          child: AibsCard(
            child: records.isEmpty
                ? Text('Belum ada catatan hari ini.', style: AibsType.body)
                : Column(
                    children: [
                      for (var index = 0; index < records.length; index++) ...[
                        if (index > 0) const Divider(height: AibsSpace.s20),
                        _TodayLogRow(
                          entry: records[index],
                          onTap: onOpenJournal,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyProfile() {
    return Column(
      children: [
        const SizedBox(height: AibsSpace.s20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AibsSpace.s20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpenMenu,
              borderRadius: BorderRadius.circular(AibsRadius.lg),
              child: AibsCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Lihat 12 menu yang sesuai',
                        style: AibsType.bodyStrong,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AibsColors.inkMuted),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AibsSpace.s20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AibsSpace.s20),
          child: AibsCard(
            child: Column(
              children: [
                const AibsMascot(expression: 'senang', size: 120),
                const SizedBox(height: AibsSpace.s8),
                Text('Belum ada catatan', style: AibsType.verdict),
                const SizedBox(height: AibsSpace.s16),
                _HomeActionButton(
                  label: 'Catat makan pertama',
                  style: _HomeActionStyle.soft,
                  height: AibsSize.button,
                  onTap: onOpenCamera,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _mealLabel(DateTime now) {
    if (now.hour >= 5 && now.hour < 11) return 'sarapan';
    if (now.hour >= 11 && now.hour < 15) return 'makan siang';
    if (now.hour >= 15 && now.hour < 18) return 'camilan';
    return 'makan malam';
  }

  String _weekdayLetter(DateTime date) =>
      const ['S', 'S', 'R', 'K', 'J', 'S', 'M'][date.weekday - 1];
}

class _TodayMenu {
  const _TodayMenu({
    required this.name,
    required this.details,
    required this.icon,
    required this.imageColors,
  });

  final String name;
  final String details;
  final IconData icon;
  final List<Color> imageColors;
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.menu, required this.onTap});

  final _TodayMenu menu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AibsSize.menuSliderCard,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AibsRadius.lg),
          child: AibsCard(
            padding: AibsSpace.s12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: AibsSize.menuSliderImage,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AibsGradients.food(menu.imageColors),
                    borderRadius: BorderRadius.circular(AibsRadius.md),
                  ),
                  child: Icon(
                    menu.icon,
                    size: AibsSize.menuArtworkIcon,
                    color: AibsColors.primaryStrong,
                  ),
                ),
                const SizedBox(height: AibsSpace.s8),
                Text(
                  menu.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AibsType.bodyStrong,
                ),
                const Spacer(),
                Text(menu.details, style: AibsType.caption),
                const SizedBox(height: AibsSpace.s4),
                const StatusBadge(CheckStatus.ok),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeeAllCard extends StatelessWidget {
  const _SeeAllCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AibsSize.seeAllCard,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AibsRadius.lg),
          child: AibsCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.arrow_forward,
                  color: AibsColors.primaryStrong,
                ),
                const SizedBox(height: AibsSpace.s8),
                Text(
                  'Lihat semua',
                  textAlign: TextAlign.center,
                  style: AibsType.label,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayLogRow extends StatelessWidget {
  const _TodayLogRow({required this.entry, required this.onTap});

  final TodayLogEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AibsRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AibsSpace.s6),
        child: Row(
          children: [
            SizedBox(
              width: AibsSize.logTime,
              child: Text(entry.time, style: AibsType.small),
            ),
            Expanded(child: Text(entry.title, style: AibsType.bodyStrong)),
            const Icon(Icons.chevron_right, color: AibsColors.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _SymptomDayDot extends StatelessWidget {
  const _SymptomDayDot({
    required this.label,
    required this.severity,
    required this.isToday,
  });

  final String label;
  final int? severity;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final dotColor = switch (severity) {
      null => AibsColors.unknownSoft,
      <= 2 => AibsColors.sky,
      _ => AibsColors.primary,
    };
    final textColor = severity != null && severity! >= 3
        ? AibsColors.onPrimary
        : AibsColors.ink;
    return Column(
      children: [
        Container(
          width: isToday ? AibsSize.dayDot + AibsSpace.s10 : AibsSize.dayDot,
          height: isToday ? AibsSize.dayDot + AibsSpace.s10 : AibsSize.dayDot,
          alignment: Alignment.center,
          decoration: isToday
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AibsColors.primary, width: 2),
                )
              : null,
          child: Container(
            width: AibsSize.dayDot,
            height: AibsSize.dayDot,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            child: severity == null
                ? null
                : Text(
                    '$severity',
                    style: AibsType.bodyStrong.copyWith(color: textColor),
                  ),
          ),
        ),
        const SizedBox(height: AibsSpace.s4),
        Text(label, style: AibsType.small),
      ],
    );
  }
}

enum _HomeActionStyle { primary, soft, neutral }

class _HomeActionButton extends StatelessWidget {
  const _HomeActionButton({
    required this.label,
    required this.style,
    required this.height,
    required this.onTap,
  });

  final String label;
  final _HomeActionStyle style;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPrimary = style == _HomeActionStyle.primary;
    final foreground = switch (style) {
      _HomeActionStyle.primary => AibsColors.onPrimary,
      _HomeActionStyle.soft => AibsColors.primaryStrong,
      _HomeActionStyle.neutral => AibsColors.ink,
    };
    return SizedBox(
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AibsRadius.sm),
          child: Ink(
            decoration: BoxDecoration(
              color: switch (style) {
                _HomeActionStyle.primary => null,
                _HomeActionStyle.soft => AibsColors.primarySoft,
                _HomeActionStyle.neutral => AibsColors.card,
              },
              gradient: isPrimary ? AibsGradients.brand : null,
              border: style == _HomeActionStyle.neutral
                  ? Border.all(color: AibsColors.line, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(AibsRadius.sm),
              boxShadow: isPrimary ? AibsShadows.glow : null,
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AibsType.button.copyWith(color: foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

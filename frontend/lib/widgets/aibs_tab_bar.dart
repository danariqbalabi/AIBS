import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme/aibs_tokens.dart';

class AibsTabBar extends StatelessWidget {
  const AibsTabBar({
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onCameraPressed,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCameraPressed;

  static const _tabs = [
    _TabItem(label: 'Hari Ini', asset: 'home.svg'),
    _TabItem(label: 'Menu', asset: 'menu.svg'),
    _TabItem(label: 'Jurnal', asset: 'jurnal.svg'),
    _TabItem(label: 'Profil', asset: 'profil.svg'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AibsColors.card,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AibsRadius.xxl),
        ),
        boxShadow: AibsShadows.bar,
      ),
      child: SizedBox(
        height: AibsSize.tabBar,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Expanded(child: _tabButton(0)),
                Expanded(child: _tabButton(1)),
                const Expanded(child: SizedBox.shrink()),
                Expanded(child: _tabButton(2)),
                Expanded(child: _tabButton(3)),
              ],
            ),
            Positioned(
              top:
                  (AibsSize.tabBar - AibsSize.cameraButton) / 2 -
                  AibsSize.cameraLift,
              left: 0,
              right: 0,
              child: Center(child: _CameraButton(onPressed: onCameraPressed)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(int index) {
    return _TabButton(
      item: _tabs[index],
      selected: selectedIndex == index,
      onTap: () => onTabSelected(index),
    );
  }
}

class _TabItem {
  const _TabItem({required this.label, required this.asset});

  final String label;
  final String asset;
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _TabItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AibsColors.primaryStrong : AibsColors.inkMuted;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AibsRadius.md),
          child: AnimatedContainer(
            duration: AibsMotion.tab,
            curve: AibsMotion.standard,
            constraints: const BoxConstraints(
              minWidth: AibsSize.tapMin,
              minHeight: AibsSize.tapMin,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AibsSpace.s8,
              vertical: AibsSpace.s6,
            ),
            decoration: BoxDecoration(
              color: selected ? AibsColors.primarySoft : Colors.transparent,
              borderRadius: BorderRadius.circular(AibsRadius.md),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/${item.asset}',
                  width: AibsSize.navIcon,
                  height: AibsSize.navIcon,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
                const SizedBox(height: AibsSpace.s2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AibsType.micro.copyWith(
                    color: color,
                    fontWeight: selected ? AibsType.w800 : AibsType.w700,
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

class _CameraButton extends StatelessWidget {
  const _CameraButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AibsSize.cameraButton,
      height: AibsSize.cameraButton,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AibsGradients.brand,
        boxShadow: AibsShadows.camera,
      ),
      child: IconButton(
        tooltip: 'Tambah catatan',
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.add,
          size: AibsSize.navIcon,
          color: AibsColors.onPrimary,
        ),
      ),
    );
  }
}

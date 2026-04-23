import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/vedge_bottom_nav.dart';

/// Spec §C1 — five-tab bottom-nav shell using StatefulShellRoute so each
/// tab keeps its own scroll position + nav stack.
class ShellScreen extends StatelessWidget {
  const ShellScreen({required this.shell, super.key});

  final StatefulNavigationShell shell;

  static const _destinations = [
    VedgeNavDestination(
      icon: Icons.today_outlined,
      activeIcon: Icons.today_rounded,
      label: 'Today',
    ),
    VedgeNavDestination(
      icon: Icons.science_outlined,
      activeIcon: Icons.science_rounded,
      label: 'Records',
    ),
    VedgeNavDestination(
      icon: Icons.health_and_safety_outlined,
      activeIcon: Icons.health_and_safety_rounded,
      label: 'Care',
    ),
    VedgeNavDestination(
      icon: Icons.people_outline,
      activeIcon: Icons.people_rounded,
      label: 'Family',
    ),
    VedgeNavDestination(
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'You',
    ),
  ];

  void _onTap(int i) {
    shell.goBranch(i, initialLocation: i == shell.currentIndex);
  }

  void _onLongPress(int i) {
    // Long-press resets that tab's nav stack to its root (iOS pattern).
    shell.goBranch(i, initialLocation: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: VedgeBottomNav(
        currentIndex: shell.currentIndex,
        destinations: _destinations,
        onTap: _onTap,
        onLongPress: _onLongPress,
      ),
    );
  }
}

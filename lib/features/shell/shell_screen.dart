import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom-nav shell for the patient app.
///
/// Tabs: Home / Results / Appointments / Me. Larger icons than the staff
/// app since older patients form a larger share of the audience.
class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _ShellTab(
      path: '/home',
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
    ),
    _ShellTab(
      path: '/results',
      label: 'Results',
      icon: Icons.science_outlined,
      activeIcon: Icons.science,
    ),
    _ShellTab(
      path: '/appointments',
      label: 'Visits',
      icon: Icons.event_outlined,
      activeIcon: Icons.event,
    ),
    _ShellTab(
      path: '/me',
      label: 'Me',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  int _indexFromLocation(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon, size: 26),
              selectedIcon: Icon(tab.activeIcon, size: 26),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _ShellTab {
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _ShellTab({
    required this.path,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

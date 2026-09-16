import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';
import 'package:glam/src/features/home/presentation/more_sheet.dart';

/// One entry in the app's primary navigation.
class NavDestination {
  const NavDestination({
    required this.branch,
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  /// Index of this destination's branch in the [StatefulShellRoute].
  final int branch;
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Every top-level section. Order = branch order. The first
/// [primaryCount] entries show in the mobile bottom bar; the rest are
/// reachable through the "More" sheet (mobile) or the rail (desktop).
const navDestinations = <NavDestination>[
  NavDestination(
    branch: 0,
    path: '/home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: 'Home',
  ),
  NavDestination(
    branch: 1,
    path: '/projects',
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder,
    label: 'Projects',
  ),
  NavDestination(
    branch: 2,
    path: '/settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: 'Settings',
  ),
];

/// Branches below this index show in the mobile bottom bar; the rest
/// live behind "More".
const primaryNavCount = 2;

/// Adaptive scaffold: [NavigationRail] on wide screens, bottom
/// [NavigationBar] on phones. Wraps a [StatefulNavigationShell] so each
/// section keeps its own navigation stack.
class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  bool _isPrimary(int branch) => branch < primaryNavCount;

  int _selectedMobileIndex() {
    final branch = shell.currentIndex;
    return _isPrimary(branch) ? branch : primaryNavCount;
  }

  void _goBranch(int branch, {bool initial = false}) {
    shell.goBranch(branch, initialLocation: initial);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    if (wide) {
      return _DesktopShell(shell: shell, onSelect: _goBranch);
    }
    return _MobileShell(
      shell: shell,
      selectedIndex: _selectedMobileIndex(),
      onSelect: (index) {
        if (index >= primaryNavCount) {
          unawaited(showMoreSheet(context, shell));
        } else {
          _goBranch(index, initial: shell.currentIndex == index);
        }
      },
    );
  }
}

class _DesktopShell extends ConsumerWidget {
  const _DesktopShell({required this.shell, required this.onSelect});

  final StatefulNavigationShell shell;
  final void Function(int branch) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final session = ref.watch(sessionProvider).value;
    final expanded = MediaQuery.sizeOf(context).width >= 1200;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: expanded,
            minExtendedWidth: 176,
            selectedIndex: shell.currentIndex,
            onDestinationSelected: onSelect,
            labelType: expanded
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(top: Insets.sm, bottom: Insets.lg),
              child: _RailLogo(expanded: expanded),
            ),
            destinations: [
              for (final d in navDestinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          VerticalDivider(width: 1, color: colors.border),
          Expanded(child: shell),
          if (session != null) const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _RailLogo extends StatelessWidget {
  const _RailLogo({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final mark = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.accent, colors.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: Radii.borderMd,
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
    if (!expanded) {
      return mark;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
      child: Row(
        children: [
          mark,
          const SizedBox(width: Insets.sm),
          Text('Glam', style: Theme.of(context).textTheme.displaySmall),
        ],
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.shell,
    required this.selectedIndex,
    required this.onSelect,
  });

  final StatefulNavigationShell shell;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final primary = navDestinations.take(primaryNavCount).toList();
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelect,
        destinations: [
          for (final d in primary)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_services.dart';
import '../../../domain/models/app_user.dart';
import '../../controllers/auth_controller.dart';
import 'dashboard_screen.dart';
import 'feature_catalog.dart';
import 'feature_router.dart';
import 'inbox_screen.dart';
import 'module_hub_screen.dart';
import 'profile_screen.dart';
import 'saved_updates_screen.dart';

class RoleHomeShell extends StatefulWidget {
  const RoleHomeShell({
    required this.user,
    required this.controller,
    required this.services,
    super.key,
  });

  final AppUser user;
  final AuthController controller;
  final AppServices services;

  @override
  State<RoleHomeShell> createState() => _RoleHomeShellState();
}

class _RoleHomeShellState extends State<RoleHomeShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    unawaited(
      widget.services.reminders.start(
        user: widget.user,
        care: widget.services.care,
      ),
    );
  }

  @override
  void dispose() {
    unawaited(widget.services.reminders.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        user: widget.user,
        services: widget.services,
        onMenu: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      ModuleHubScreen(user: widget.user, services: widget.services),
      SavedUpdatesScreen(user: widget.user, services: widget.services),
      InboxScreen(user: widget.user, services: widget.services),
      ProfileScreen(
        user: widget.user,
        controller: widget.controller,
        services: widget.services,
      ),
    ];
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.cream,
      extendBody: true,
      drawerScrimColor: AppColors.ink.withValues(alpha: .42),
      drawer: _RoleDrawer(
        user: widget.user,
        selectedIndex: _index,
        onSelectTab: _selectTabFromDrawer,
        onOpenFeature: _openFeatureFromDrawer,
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 28,
                offset: Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            backgroundColor: AppColors.ink,
            indicatorColor: AppColors.orange,
            height: 68,
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: Colors.white70),
                selectedIcon: Icon(Icons.home_rounded, color: AppColors.ink),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined, color: Colors.white70),
                selectedIcon: Icon(Icons.explore_rounded, color: AppColors.ink),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.favorite_border_rounded,
                  color: Colors.white70,
                ),
                selectedIcon: Icon(
                  Icons.favorite_rounded,
                  color: AppColors.ink,
                ),
                label: 'Saved',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.white70,
                ),
                selectedIcon: Icon(
                  Icons.chat_bubble_rounded,
                  color: AppColors.ink,
                ),
                label: 'Messages',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, color: Colors.white70),
                selectedIcon: Icon(Icons.person_rounded, color: AppColors.ink),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTabFromDrawer(int index) {
    Navigator.of(context).pop();
    setState(() => _index = index);
  }

  void _openFeatureFromDrawer(FeatureAction feature) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FeatureRouter.open(
        context,
        feature: feature,
        user: widget.user,
        services: widget.services,
      );
    });
  }
}

class _RoleDrawer extends StatelessWidget {
  const _RoleDrawer({
    required this.user,
    required this.selectedIndex,
    required this.onSelectTab,
    required this.onOpenFeature,
  });

  final AppUser user;
  final int selectedIndex;
  final ValueChanged<int> onSelectTab;
  final ValueChanged<FeatureAction> onOpenFeature;

  @override
  Widget build(BuildContext context) {
    final tools = FeatureCatalog.forRole(user.role);
    final initials = user.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Drawer(
      width: 330,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(34)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.ink, Color(0xFF332B24)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: AppColors.orange,
                        child: Icon(Icons.pets_rounded, color: AppColors.ink),
                      ),
                      SizedBox(width: 11),
                      Text(
                        'PawfectCare',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.peach,
                        child: Text(
                          initials.isEmpty ? 'P' : initials,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user.role.label,
                              style: const TextStyle(
                                color: Color(0xFFD8D0C8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                children: [
                  const _DrawerLabel('NAVIGATION'),
                  _DrawerDestination(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: selectedIndex == 0,
                    onTap: () => onSelectTab(0),
                  ),
                  _DrawerDestination(
                    icon: Icons.explore_rounded,
                    label: 'Explore all tools',
                    selected: selectedIndex == 1,
                    onTap: () => onSelectTab(1),
                  ),
                  _DrawerDestination(
                    icon: Icons.favorite_rounded,
                    label: 'Saved',
                    selected: selectedIndex == 2,
                    onTap: () => onSelectTab(2),
                  ),
                  _DrawerDestination(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Messages',
                    selected: selectedIndex == 3,
                    onTap: () => onSelectTab(3),
                  ),
                  _DrawerDestination(
                    icon: Icons.person_rounded,
                    label: 'Profile & settings',
                    selected: selectedIndex == 4,
                    onTap: () => onSelectTab(4),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: AppColors.border),
                  ),
                  _DrawerLabel('${user.role.label.toUpperCase()} WORKSPACE'),
                  ...tools.map(
                    (feature) => _DrawerDestination(
                      icon: feature.icon,
                      label: feature.title,
                      selected: false,
                      trailing: const Icon(
                        Icons.arrow_outward_rounded,
                        size: 16,
                        color: AppColors.muted,
                      ),
                      onTap: () => onOpenFeature(feature),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerLabel extends StatelessWidget {
  const _DrawerLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    ),
  );
}

class _DrawerDestination extends StatelessWidget {
  const _DrawerDestination({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: ListTile(
      selected: selected,
      selectedColor: AppColors.ink,
      selectedTileColor: AppColors.orange,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: .8)
              : AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 19),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      trailing: trailing,
      onTap: onTap,
    ),
  );
}

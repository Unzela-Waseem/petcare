import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_services.dart';
import '../../../domain/models/app_user.dart';
import '../../controllers/auth_controller.dart';
import 'dashboard_screen.dart';
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
      DashboardScreen(user: widget.user, services: widget.services),
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
      backgroundColor: AppColors.cream,
      extendBody: true,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
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
            height: 68,
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_border_rounded),
                selectedIcon: Icon(Icons.favorite_rounded),
                label: 'Saved',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline_rounded),
                selectedIcon: Icon(Icons.chat_bubble_rounded),
                label: 'Messages',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

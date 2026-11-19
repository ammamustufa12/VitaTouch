import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/shell_controller.dart';
import '../dashboard/dashboard_screen.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();
    const pages = [
      HomeScreen(),
      DashboardScreen(),
      HistoryScreen(),
      ProfileScreen(),
    ];
    if (MediaQuery.sizeOf(context).width >= 720) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: shell.index,
                onDestinationSelected: shell.openTab,
                labelType: NavigationRailLabelType.all,
                backgroundColor: Colors.white,
                indicatorColor: AppColors.mist,
                selectedIconTheme: const IconThemeData(color: AppColors.navy),
                unselectedIconTheme: const IconThemeData(color: AppColors.muted),
                selectedLabelTextStyle: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                unselectedLabelTextStyle: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.fingerprint_outlined),
                    selectedIcon: Icon(Icons.fingerprint),
                    label: Text('Scan'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.monitor_heart_outlined),
                    selectedIcon: Icon(Icons.monitor_heart),
                    label: Text('Monitor'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.insights_outlined),
                    selectedIcon: Icon(Icons.insights),
                    label: Text('History'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: Text('Profile'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1, color: AppColors.line),
              Expanded(
                child: IndexedStack(
                  index: shell.index,
                  children: pages,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: IndexedStack(
        index: shell.index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.index,
        onDestinationSelected: shell.openTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: 'Monitor',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

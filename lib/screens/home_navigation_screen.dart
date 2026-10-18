import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'hud/live_hud_screen.dart';
import 'drowsiness/drowsiness_monitor_screen.dart';
import 'hotspots/crash_hotspots_screen.dart';
import 'analytics/trip_analytics_screen.dart';
import 'profile/profile_screen.dart';

/// Central Hub containing the Bottom Navigation Bar linking all 5 core modules.
class HomeNavigationScreen extends StatefulWidget {
  const HomeNavigationScreen({super.key});

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    LiveHudScreen(),
    DrowsinessMonitorScreen(),
    CrashHotspotsScreen(),
    TripAnalyticsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.borderSubtle, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.speed_rounded),
              activeIcon: Icon(Icons.speed_rounded, color: AppTheme.cyanAccent),
              label: "Live HUD",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.visibility_outlined),
              activeIcon: Icon(Icons.visibility, color: AppTheme.amberWarning),
              label: "Drowsiness",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.radar_outlined),
              activeIcon: Icon(Icons.radar, color: AppTheme.purpleRadar),
              label: "Hotspots",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.eco_outlined),
              activeIcon: Icon(Icons.eco, color: AppTheme.greenEco),
              label: "Eco-Drive",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, color: AppTheme.cyanAccent),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}

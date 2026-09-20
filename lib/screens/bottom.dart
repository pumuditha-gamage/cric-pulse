import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'home_screen.dart';
import 'match_viewer_screen.dart';
import 'tournament_viewer_screen.dart';
import 'points_table_screen.dart';
import 'login.dart';
import '../theme.dart';

class BottomNavBar extends StatefulWidget {
  final int initialIndex;
  const BottomNavBar({super.key, this.initialIndex = 0});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
  }
  
  List<Widget> get pages => [
    const HomeScreen(),
    const MatchViewerScreen(),
    const PointsTableScreen(),
    const TournamentViewerScreen(),
    if (kIsWeb) const LoginPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: pages[index],
      extendBody: true, // Allows content to flow behind the floating navigation bar
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 28), // Elevated slightly higher
        decoration: AppTheme.glassDecoration(borderRadius: 28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: BottomNavigationBar(
                currentIndex: index,
                onTap: (int newIndex) {
                  setState(() {
                    index = newIndex;
                  });
                },
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                type: BottomNavigationBarType.fixed,
                selectedItemColor: AppTheme.primary,
                unselectedItemColor: AppTheme.textSecondary.withValues(alpha: 0.5),
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
                elevation: 0,
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home, color: AppTheme.primary),
                    label: "Home",
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_today_outlined),
                    activeIcon: Icon(Icons.calendar_today, color: AppTheme.primary),
                    label: "Matches",
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.leaderboard_outlined),
                    activeIcon: Icon(Icons.leaderboard, color: AppTheme.primary),
                    label: "Standings",
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.emoji_events_outlined),
                    activeIcon: Icon(Icons.emoji_events, color: AppTheme.primary),
                    label: "Tournaments",
                  ),
                  if (kIsWeb)
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.admin_panel_settings_outlined),
                      activeIcon: Icon(Icons.admin_panel_settings, color: AppTheme.primary),
                      label: "Admin Portal",
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
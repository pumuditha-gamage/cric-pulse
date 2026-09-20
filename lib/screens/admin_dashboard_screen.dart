import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_session.dart';
import 'bottom.dart';
import 'tournament_screen.dart';
import 'team_screen.dart';
import 'match_screen.dart';
import 'live_scoring_screen.dart';
import 'admin_points_table_editor.dart';
import '../theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedMenuIndex = 0; // 0: Overview, 1: Tournaments, 2: Teams, 3: Matches, 4: Live Scoring, 5: Points Table

  final List<Map<String, dynamic>> _menuItems = [
    {
      "title": "Overview",
      "icon": Icons.dashboard_outlined,
      "activeIcon": Icons.dashboard,
    },
    {
      "title": "Tournaments",
      "icon": Icons.emoji_events_outlined,
      "activeIcon": Icons.emoji_events,
    },
    {
      "title": "Teams & Players",
      "icon": Icons.group_outlined,
      "activeIcon": Icons.group,
    },
    {
      "title": "Matches",
      "icon": Icons.sports_cricket_outlined,
      "activeIcon": Icons.sports_cricket,
    },
    {
      "title": "Live Scoring",
      "icon": Icons.live_tv_outlined,
      "activeIcon": Icons.live_tv,
    },
    {
      "title": "Points Table",
      "icon": Icons.table_chart_outlined,
      "activeIcon": Icons.table_chart,
    },
  ];

  Widget _getDetailScreen(int index) {
    switch (index) {
      case 1:
        return const TournamentScreen();
      case 2:
        return const TeamScreen();
      case 3:
        return const MatchScreen();
      case 4:
        return const LiveScoringScreen();
      case 5:
        return const AdminPointsTableEditor();
      case 0:
      default:
        return _buildOverviewContent();
    }
  }

  Widget _buildOverviewContent() {
    final String adminEmail = AdminSession.currentAdmin ?? "admin@cricpulse.com";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Overview Dashboard",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Welcome back, ${adminEmail.split('@')[0]}! Manage your cricket portal in real-time.",
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              // Server status indicator with pulse animation
              const PulsingStatusIndicator(label: "Firebase Online"),
            ],
          ),
          const SizedBox(height: 36),

          // Stat cards grid
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final int crossAxisCount = width > 1000 ? 3 : (width > 600 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: width > 1200 ? 2.0 : (width > 900 ? 1.8 : 2.0),
                children: [
                  // Tournaments Card
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('tournaments')
                        .where('createdBy', isEqualTo: adminEmail)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return _statCard(
                        count.toString(),
                        "Your Tournaments",
                        Icons.emoji_events_outlined,
                        AppTheme.primary,
                        "Manage tournaments",
                        () => setState(() => _selectedMenuIndex = 1),
                      );
                    },
                  ),
                  // Matches Card
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('matches')
                        .where('createdBy', isEqualTo: adminEmail)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return _statCard(
                        count.toString(),
                        "Matches Scheduled",
                        Icons.sports_cricket_outlined,
                        AppTheme.secondary,
                        "View scheduled fixtures",
                        () => setState(() => _selectedMenuIndex = 3),
                      );
                    },
                  ),
                  // Live matches Card
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('matches')
                        .where('createdBy', isEqualTo: adminEmail)
                        .where('status', isEqualTo: 'Live')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return _statCard(
                        count.toString(),
                        "Active Live Matches",
                        Icons.live_tv_outlined,
                        Colors.redAccent,
                        "Manage live scores",
                        () => setState(() => _selectedMenuIndex = 4),
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 40),

          // Quick shortcuts
          const Text(
            "QUICK PORTAL ACTIONS",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              // 4 columns on large screens, 2 on medium, 1 on small mobile
              final int crossAxisCount = width > 1100 ? 4 : (width > 600 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: width > 1100 ? 1.6 : (width > 600 ? 1.8 : 2.2),
                children: [
                  _quickActionCard(
                    "Create Tournament",
                    "Add new league brackets",
                    Icons.emoji_events_outlined,
                    AppTheme.primary,
                    1,
                  ),
                  _quickActionCard(
                    "Schedule a Match",
                    "Set up upcoming matches",
                    Icons.calendar_today_outlined,
                    AppTheme.secondary,
                    3,
                  ),
                  _quickActionCard(
                    "Live Score Manager",
                    "Run ball-by-ball scorecards",
                    Icons.sports_kabaddi,
                    Colors.redAccent,
                    4,
                  ),
                  _quickActionCard(
                    "Update Standings",
                    "Edit team points tables",
                    Icons.assessment_outlined,
                    Colors.indigoAccent,
                    5,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 40),
          const Text(
            "DANGER ZONE",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.shade50.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 0.02),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Reset Portal Data",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "This will permanently delete all your tournaments, scheduled matches, live scorecards, and standings. Teams and players will not be affected. This action cannot be undone.",
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _showResetConfirmationDialog(context, adminEmail),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.redAccent.withValues(alpha: 0.3),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                        icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                        label: const Text(
                          "Delete All Tournaments & Matches",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String title, IconData icon, Color color, String helperText, VoidCallback onTap) {
    return DashboardHoverWidget(
      onTap: onTap,
      builder: (context, isHovered) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: AppTheme.dashboardCardDecoration(accentColor: color, isHovered: isHovered),
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          helperText,
                          style: TextStyle(
                            fontSize: 11,
                            color: isHovered ? color : AppTheme.textMuted,
                            fontWeight: isHovered ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 11,
                          color: isHovered ? color : AppTheme.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isHovered ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _quickActionCard(
    String title,
    String desc,
    IconData icon,
    Color color,
    int targetIndex,
  ) {
    return DashboardHoverWidget(
      onTap: () {
        setState(() {
          _selectedMenuIndex = targetIndex;
        });
      },
      builder: (context, isHovered) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.dashboardCardDecoration(
            accentColor: color,
            isHovered: isHovered,
            borderRadius: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isHovered ? color.withValues(alpha: 0.16) : color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  Icon(
                    Icons.arrow_outward_rounded,
                    color: isHovered ? color : AppTheme.textMuted,
                    size: 18,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showResetConfirmationDialog(BuildContext context, String adminEmail) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F1411),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: Colors.redAccent, size: 24),
              SizedBox(width: 8),
              Text(
                "Confirm Reset",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: const Text(
            "Are you absolutely sure you want to delete all matches, tournaments, scorecards, and standings? This is permanent and cannot be undone.",
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                _performReset(context, adminEmail);
              },
              child: const Text(
                "Yes, Delete All",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performReset(BuildContext context, String adminEmail) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          color: Color(0xFF0F1411),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primary),
                SizedBox(height: 16),
                Text(
                  "Resetting portal data...",
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Fetch tournaments created by this admin
      final tournamentsSnapshot = await firestore
          .collection('tournaments')
          .where('createdBy', isEqualTo: adminEmail)
          .get();

      // 2. Fetch matches created by this admin
      final matchesSnapshot = await firestore
          .collection('matches')
          .where('createdBy', isEqualTo: adminEmail)
          .get();

      final batch = firestore.batch();

      // Delete matches and their scorecards
      for (var doc in matchesSnapshot.docs) {
        batch.delete(doc.reference);
        batch.delete(firestore.collection('scorecards').doc(doc.id));
      }

      // Delete tournaments and their points table entries
      for (var doc in tournamentsSnapshot.docs) {
        batch.delete(doc.reference);
        
        final ptsSnapshot = await firestore
            .collection('points_tables')
            .where('tournamentId', isEqualTo: doc.id)
            .get();
            
        for (var ptDoc in ptsSnapshot.docs) {
          batch.delete(ptDoc.reference);
        }
      }

      await batch.commit();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("All matches, tournaments, scorecards, and standings deleted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error resetting data: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _logout() {
    AdminSession.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const BottomNavBar(initialIndex: 0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900;
    final String adminEmail = AdminSession.currentAdmin ?? "admin@cricpulse.com";

    Widget sidebarContent() {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F1411), Color(0xFF070B09)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border(right: BorderSide(color: Colors.white10, width: 1.0)),
        ),
        child: Column(
          children: [
            // Panel Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white10, width: 1.0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.sports_cricket_rounded, color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    "Cric Pulse Web",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),

            // Admin email card
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.admin_panel_settings, color: AppTheme.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "LOGGED IN AS",
                            style: TextStyle(
                              color: Colors.white30,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            adminEmail,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  final bool isSelected = _selectedMenuIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  AppTheme.primary.withValues(alpha: 0.16),
                                  AppTheme.primary.withValues(alpha: 0.02),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : null,
                        border: isSelected
                            ? const Border(
                                left: BorderSide(color: AppTheme.primary, width: 4),
                              )
                            : null,
                      ),
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            _selectedMenuIndex = index;
                          });
                          if (!isDesktop) {
                            Navigator.pop(context); // Close drawer
                          }
                        },
                        contentPadding: EdgeInsets.only(
                          left: isSelected ? 12 : 16,
                          right: 16,
                          top: 2,
                          bottom: 2,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        selected: isSelected,
                        leading: Icon(
                          isSelected ? item["activeIcon"] : item["icon"],
                          color: isSelected ? AppTheme.primary : Colors.white30,
                        ),
                        title: Text(
                          item["title"],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white60,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Sign Out
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.08),
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: const Text(
                    "Sign Out",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isDesktop) {
      // Desktop Sidebar + Content Layout
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Row(
          children: [
            SizedBox(
              width: 280,
              child: sidebarContent(),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.backgroundGradient,
                ),
                child: _getDetailScreen(_selectedMenuIndex),
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile Drawer + Top Bar Layout
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F1411),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            _menuItems[_selectedMenuIndex]["title"],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        drawer: Drawer(
          child: sidebarContent(),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: _getDetailScreen(_selectedMenuIndex),
        ),
      );
    }
  }
}

// Custom widgets for premium dashboard experience

class PulsingStatusIndicator extends StatefulWidget {
  final String label;
  const PulsingStatusIndicator({super.key, required this.label});

  @override
  State<PulsingStatusIndicator> createState() => _PulsingStatusIndicatorState();
}

class _PulsingStatusIndicatorState extends State<PulsingStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: _animation.value * 0.6),
                      blurRadius: _animation.value * 8,
                      spreadRadius: _animation.value * 2,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardHoverWidget extends StatefulWidget {
  final Widget Function(BuildContext context, bool isHovered) builder;
  final VoidCallback? onTap;
  const DashboardHoverWidget({super.key, required this.builder, this.onTap});

  @override
  State<DashboardHoverWidget> createState() => _DashboardHoverWidgetState();
}

class _DashboardHoverWidgetState extends State<DashboardHoverWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: widget.builder(context, _isHovered),
        ),
      ),
    );
  }
}


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/match.dart'; // To reference ScheduledMatch and matchesList
import 'live_score_viewer.dart';

class MatchViewerScreen extends StatefulWidget {
  const MatchViewerScreen({super.key});

  @override
  State<MatchViewerScreen> createState() => _MatchViewerScreenState();
}

class _MatchViewerScreenState extends State<MatchViewerScreen> {
  String _searchQuery = "";
  String _selectedStatus = "All";

  // Helper to seed mock matches if Firestore matches collection is empty
  void _seedMockMatchesIfEmpty(List<DocumentSnapshot> docs) {
    if (docs.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final collection = FirebaseFirestore.instance.collection('matches');
        for (var m in matchesList) {
          await collection.doc(m.id).set(m.toFirestore());
          
          // Seed corresponding scorecards to prevent loading errors
          await FirebaseFirestore.instance.collection('scorecards').doc(m.id).set({
            'matchId': m.id,
            'runs': m.id == "1" ? 156 : 0,
            'wickets': m.id == "1" ? 7 : 0,
            'overs': m.id == "1" ? 20 : 0,
            'balls': 0,
            'target': m.id == "1" ? 157 : 0,
            'innings': m.id == "1" ? 2 : 1,
            'battingTeam': m.id == "1" ? m.teamB : m.teamA,
            'bowlingTeam': m.id == "1" ? m.teamA : m.teamB,
            'batsman1': m.id == "1" ? 'Kusal Mendis *' : 'Striker',
            'batsman1Runs': m.id == "1" ? 48 : 0,
            'batsman1Balls': m.id == "1" ? 32 : 0,
            'batsman1Fours': m.id == "1" ? 5 : 0,
            'batsman1Sixes': m.id == "1" ? 2 : 0,
            'batsman2': m.id == "1" ? 'Sahan Arachchige' : 'Non-Striker',
            'batsman2Runs': m.id == "1" ? 12 : 0,
            'batsman2Balls': m.id == "1" ? 10 : 0,
            'batsman2Fours': m.id == "1" ? 1 : 0,
            'batsman2Sixes': m.id == "1" ? 0 : 0,
            'bowler': m.id == "1" ? 'Alex Mark' : 'Bowler',
            'bowlerBalls': m.id == "1" ? 14 : 0,
            'bowlerMaidens': 0,
            'bowlerRuns': m.id == "1" ? 18 : 0,
            'bowlerWickets': m.id == "1" ? 2 : 0,
            'history': [],
            'lastWicketText': m.id == "1" ? 'Pathum Nissanka 24 (15b) - c Gunathilaka b Alex Mark' : 'None',
          });
        }
      });
    }
  }

  Widget _buildSearchBarAndTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
            decoration: AppTheme.inputDecoration(
              label: "Search teams, tournaments, or venues...",
              prefixIcon: Icons.search,
            ),
          ),
        ),
        
        // Status filter tabs
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildFilterTab("All", Icons.grid_view_outlined, null),
              _buildFilterTab("Live", Icons.radio_button_checked, Colors.red.shade600),
              _buildFilterTab("Upcoming", Icons.calendar_today_outlined, Colors.blue.shade600),
              _buildFilterTab("Finished", Icons.emoji_events_outlined, Colors.green.shade600),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTab(String status, IconData icon, Color? activeColor) {
    final bool isSelected = _selectedStatus == status;
    final Color selectedBg = activeColor ?? AppTheme.primary;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStatus = status;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? selectedBg : AppTheme.border,
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: selectedBg.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status == "Live" && isSelected) ...[
                const LiveBadgePulse(size: 8, color: Colors.white),
                const SizedBox(width: 6),
              ] else ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                status,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "MATCH SCHEDULE",
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 2,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildSearchBarAndTabs(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('matches').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                _seedMockMatchesIfEmpty(docs);

                final matches = docs.map((doc) => ScheduledMatch.fromFirestore(doc)).where((match) {
                  final matchesSearch = match.teamA.toLowerCase().contains(_searchQuery) ||
                      match.teamB.toLowerCase().contains(_searchQuery) ||
                      match.tournamentName.toLowerCase().contains(_searchQuery) ||
                      match.venue.toLowerCase().contains(_searchQuery);
                  
                  if (!matchesSearch) return false;

                  if (_selectedStatus != "All") {
                    return match.status.toLowerCase() == _selectedStatus.toLowerCase();
                  }
                  return true;
                }).toList();

                if (matches.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_cricket_outlined, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        const Text(
                          "No matching fixtures scheduled.",
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                      
                    Color statusColor;
                    switch (match.status) {
                      case "Live":
                        statusColor = Colors.red.shade600;
                        break;
                      case "Finished":
                        statusColor = Colors.green.shade600;
                        break;
                      case "Upcoming":
                      default:
                        statusColor = Colors.blue.shade600;
                        break;
                    }

                    final bool isLive = match.status == "Live";

                    return GestureDetector(
                      onTap: () {
                        if (match.status == "Live" || match.status == "Finished") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LiveScoreViewer(
                                matchId: match.id,
                                matchTitle: "${match.teamA} vs ${match.teamB}",
                                isLive: isLive,
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: AppTheme.cardDecoration(borderRadius: 20, hasHighlight: isLive),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Card Header (Banner Image overlay)
                              SizedBox(
                                height: 120,
                                width: double.infinity,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.network(
                                        match.bannerPath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          decoration: const BoxDecoration(
                                            gradient: AppTheme.headerGradient,
                                          ),
                                          child: const Icon(Icons.sports_cricket, color: Colors.white30, size: 40),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.black.withValues(alpha: 0.6),
                                            Colors.black.withValues(alpha: 0.1),
                                            Colors.black.withValues(alpha: 0.8),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                    
                                    // Badges
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: statusColor.withValues(alpha: 0.3),
                                              blurRadius: 6,
                                            )
                                          ]
                                        ),
                                        child: Row(
                                          children: [
                                            if (isLive) ...[
                                              const LiveBadgePulse(size: 6, color: Colors.white),
                                              const SizedBox(width: 6),
                                            ],
                                            Text(
                                              match.status.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "${match.matchType} • ${match.overs} OVS",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    // Tournament Name
                                    Positioned(
                                      bottom: 12,
                                      left: 12,
                                      right: 12,
                                      child: Text(
                                        match.tournamentName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          letterSpacing: 0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Card Body (Teams Row)
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            children: [
                                              _buildTeamLogo(match.teamALogo, size: 54),
                                              const SizedBox(height: 8),
                                              Text(
                                                match.teamA,
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w900,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withValues(alpha: 0.08),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2), width: 1.5),
                                          ),
                                          child: const Text(
                                            "VS",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: AppTheme.primary,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              _buildTeamLogo(match.teamBLogo, size: 54),
                                              const SizedBox(height: 8),
                                              Text(
                                                match.teamB,
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w900,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // Info pass-style container
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.background,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: AppTheme.border, width: 1),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.primary),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Text("DATE", style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold)),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            match.date,
                                                            style: const TextStyle(
                                                              color: AppTheme.textPrimary,
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.access_time_outlined, size: 14, color: AppTheme.primary),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Text("TIME", style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold)),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            match.time,
                                                            style: const TextStyle(
                                                              color: AppTheme.textPrimary,
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.primary),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Text("VENUE", style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold)),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            match.venue,
                                                            style: const TextStyle(
                                                              color: AppTheme.textPrimary,
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.bold,
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
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.groups_outlined, size: 14, color: AppTheme.primary),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Text("PLAYERS", style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold)),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            "${match.playersPerSide} a side",
                                                            style: const TextStyle(
                                                              color: AppTheme.textPrimary,
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (match.tossDecision.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            const Divider(color: AppTheme.border, height: 1),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                const Icon(Icons.toll_outlined, size: 14, color: AppTheme.primary),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text("TOSS DECISION", style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold)),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        match.tossDecision,
                                                        style: const TextStyle(
                                                          color: AppTheme.textPrimary,
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    
                                    // Glowing Status Banners / Results display
                                    if (match.status == "Finished") ...[
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(top: 16),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade500.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.amber.shade500.withValues(alpha: 0.25), width: 1.2),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.emoji_events, color: Colors.amber.shade600, size: 20),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                "Result: ${match.result}",
                                                style: TextStyle(
                                                  color: Colors.amber.shade900,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ] else if (isLive) ...[
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(top: 16),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade500.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.red.shade500.withValues(alpha: 0.25), width: 1.2),
                                        ),
                                        child: Row(
                                          children: [
                                            const LiveBadgePulse(size: 8, color: Colors.red),
                                            const SizedBox(width: 10),
                                            const Expanded(
                                              child: Text(
                                                "Live match in progress! Tap card to view live scorecard.",
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],

                                    const SizedBox(height: 14),
                                    const Divider(color: AppTheme.border, height: 1),
                                    const SizedBox(height: 14),

                                    // Organizer & Action Buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Org: ${match.organizerName}",
                                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "Tel: ${match.contactDetails}",
                                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w500),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                                            foregroundColor: AppTheme.primary,
                                            elevation: 0,
                                            side: BorderSide(
                                              color: AppTheme.primary.withValues(alpha: 0.2),
                                              width: 1,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                          ),
                                          onPressed: () => _showSquadsBottomSheet(context, match),
                                          icon: const Icon(Icons.groups_rounded, size: 16),
                                          label: const Text(
                                            "Squads",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String logoBase64OrUrlOrPath, {double size = 40}) {
    Widget fallbackLogo() => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppTheme.border,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.sports_cricket, size: size * 0.55, color: Colors.white70),
        );

    Widget rawLogo;
    if (logoBase64OrUrlOrPath.isEmpty) {
      rawLogo = fallbackLogo();
    } else if (logoBase64OrUrlOrPath.startsWith('http') || logoBase64OrUrlOrPath.startsWith('https')) {
      rawLogo = ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          logoBase64OrUrlOrPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => fallbackLogo(),
        ),
      );
    } else {
      try {
        final decodedBytes = base64Decode(logoBase64OrUrlOrPath);
        rawLogo = ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Image.memory(
            decodedBytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => fallbackLogo(),
          ),
        );
      } catch (_) {
        rawLogo = ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Image.network(
            logoBase64OrUrlOrPath,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => fallbackLogo(),
          ),
        );
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: rawLogo,
    );
  }

  void _showSquadsBottomSheet(BuildContext context, ScheduledMatch match) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SquadsBottomSheetContent(
        match: match,
        logoBuilder: _buildTeamLogo,
      ),
    );
  }
}

class LiveBadgePulse extends StatefulWidget {
  final double size;
  final Color color;

  const LiveBadgePulse({super.key, this.size = 8, this.color = Colors.white});

  @override
  State<LiveBadgePulse> createState() => _LiveBadgePulseState();
}

class _LiveBadgePulseState extends State<LiveBadgePulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.5 + _controller.value * 0.5),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _controller.value * 0.6),
                blurRadius: widget.size * (1 + _controller.value * 1.5),
                spreadRadius: widget.size * 0.4 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}


class SquadsBottomSheetContent extends StatefulWidget {
  final ScheduledMatch match;
  final Widget Function(String, {double size}) logoBuilder;

  const SquadsBottomSheetContent({
    super.key,
    required this.match,
    required this.logoBuilder,
  });

  @override
  State<SquadsBottomSheetContent> createState() => _SquadsBottomSheetContentState();
}

class _SquadsBottomSheetContentState extends State<SquadsBottomSheetContent> {
  bool showTeamA = true;

  @override
  Widget build(BuildContext context) {
    final players = showTeamA ? widget.match.teamAPlayers : widget.match.teamBPlayers;
    final teamName = showTeamA ? widget.match.teamA : widget.match.teamB;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1412),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Center(
            child: Text(
              "Match Squads",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Segmented selector (tab selection)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => showTeamA = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: showTeamA
                            ? AppTheme.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          widget.logoBuilder(widget.match.teamALogo, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.match.teamA,
                              style: TextStyle(
                                color: showTeamA ? AppTheme.primary : Colors.white60,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => showTeamA = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !showTeamA
                            ? AppTheme.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          widget.logoBuilder(widget.match.teamBLogo, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.match.teamB,
                              style: TextStyle(
                                color: !showTeamA ? AppTheme.primary : Colors.white60,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Player list container
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: players.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.groups_outlined,
                                color: Colors.white.withValues(alpha: 0.25),
                                size: 48),
                            const SizedBox(height: 12),
                            Text(
                              "No players registered for $teamName",
                              style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: players.length,
                      itemBuilder: (context, idx) {
                        final player = players[idx];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppTheme.border.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Player index badge
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color:
                                          AppTheme.primary.withValues(alpha: 0.4),
                                      width: 1),
                                ),
                                child: Center(
                                  child: Text(
                                    "${idx + 1}",
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Player name and details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      player.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            "Age: ${player.age}",
                                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            player.battingStyle,
                                            style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (player.bowlingStyle != "None") ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        "Bowl: ${player.bowlingStyle}",
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.sports_cricket_outlined,
                                color: AppTheme.primary.withValues(alpha: 0.6),
                                size: 20,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

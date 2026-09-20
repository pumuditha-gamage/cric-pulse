import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/tournament.dart'; // To reference Tournament and tournamentsList

class TournamentViewerScreen extends StatefulWidget {
  const TournamentViewerScreen({super.key});

  @override
  State<TournamentViewerScreen> createState() => _TournamentViewerScreenState();
}

class _TournamentViewerScreenState extends State<TournamentViewerScreen> {
  String _searchQuery = "";
  String _selectedStatus = "All";

  // Helper to seed mock data if Firestore tournaments collection is empty
  void _seedMockTournamentsIfEmpty(List<DocumentSnapshot> docs) {
    if (docs.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final collection = FirebaseFirestore.instance.collection('tournaments');
        for (var t in tournamentsList) {
          await collection.doc(t.id).set(t.toFirestore());
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
              label: "Search tournaments, venues, or organizers...",
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
              _buildFilterTab("Active", Icons.radio_button_checked, Colors.green.shade600),
              _buildFilterTab("Upcoming", Icons.calendar_today_outlined, Colors.blue.shade600),
              _buildFilterTab("Completed", Icons.emoji_events_outlined, Colors.amber.shade600),
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
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
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
          "TOURNAMENTS",
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
              stream: FirebaseFirestore.instance.collection('tournaments').snapshots(),
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
                _seedMockTournamentsIfEmpty(docs);

                final tournaments = docs.map((doc) => Tournament.fromFirestore(doc)).where((t) {
                  final matchesSearch = t.name.toLowerCase().contains(_searchQuery) ||
                      t.venue.toLowerCase().contains(_searchQuery) ||
                      t.organizerName.toLowerCase().contains(_searchQuery);
                  
                  if (!matchesSearch) return false;

                  if (_selectedStatus != "All") {
                    return t.status.toLowerCase() == _selectedStatus.toLowerCase();
                  }
                  return true;
                }).toList();

                if (tournaments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events_outlined, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        const Text(
                          "No matching tournaments found.",
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: tournaments.length,
                  itemBuilder: (context, index) {
                    final tournament = tournaments[index];
                    final bool isNetworkImage = tournament.bannerPath.startsWith("http") || tournament.bannerPath.startsWith("data:");

                    Color statusColor;
                    switch (tournament.status.toLowerCase()) {
                      case "active":
                        statusColor = Colors.green.shade600;
                        break;
                      case "completed":
                        statusColor = Colors.amber.shade700;
                        break;
                      case "upcoming":
                      default:
                        statusColor = Colors.blue.shade600;
                        break;
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: AppTheme.cardDecoration(borderRadius: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tournament Banner header
                            GestureDetector(
                              onTap: () => _showFullScreenBanner(context, tournament.bannerPath, isNetworkImage),
                              child: SizedBox(
                                height: 130,
                                width: double.infinity,
                                child: Stack(
                                  children: [
                                    // Blurred Background image
                                    Positioned.fill(
                                      child: ClipRRect(
                                        child: ImageFiltered(
                                          imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                          child: isNetworkImage
                                              ? Image.network(
                                                  tournament.bannerPath,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                                )
                                              : kIsWeb
                                                  ? Image.network(
                                                      tournament.bannerPath,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                                    )
                                                  : Image.file(
                                                      File(tournament.bannerPath),
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                                    ),
                                        ),
                                      ),
                                    ),
                                    // Dark tint over the blurred background
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black.withValues(alpha: 0.35),
                                      ),
                                    ),
                                    // Foreground Banner Image (Fit Contain)
                                    Positioned.fill(
                                      child: isNetworkImage
                                          ? Image.network(
                                              tournament.bannerPath,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                decoration: const BoxDecoration(
                                                  gradient: AppTheme.headerGradient,
                                                ),
                                                child: const Icon(Icons.sports_cricket, color: Colors.white60, size: 40),
                                              ),
                                            )
                                          : kIsWeb
                                              ? Image.network(
                                                  tournament.bannerPath,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    decoration: const BoxDecoration(
                                                      gradient: AppTheme.headerGradient,
                                                    ),
                                                    child: const Icon(Icons.sports_cricket, color: Colors.white60, size: 40),
                                                  ),
                                                )
                                              : Image.file(
                                                  File(tournament.bannerPath),
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    decoration: const BoxDecoration(
                                                      gradient: AppTheme.headerGradient,
                                                    ),
                                                    child: const Icon(Icons.sports_cricket, color: Colors.white60, size: 40),
                                                  ),
                                                ),
                                    ),
                                    
                                    // Scrim overlay
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.black.withValues(alpha: 0.35),
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.8),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                    
                                    // Badges Overlay
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
                                        child: Text(
                                          tournament.status.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
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
                                          "${tournament.overs} OVERS",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    // Tournament Name & Fullscreen Button
                                    Positioned(
                                      bottom: 4,
                                      left: 12,
                                      right: 12,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              tournament.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black54,
                                                    offset: Offset(0, 2),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            tooltip: "View Full Banner",
                                            onPressed: () => _showFullScreenBanner(context, tournament.bannerPath, isNetworkImage),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Body of Tournament Card
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Prize pool display
                                  const Text(
                                    "REWARDS & PRIZES",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textSecondary,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade500.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.amber.shade500.withValues(alpha: 0.2), width: 1),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.emoji_events, color: Colors.amber.shade600, size: 15),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  "1st: ${tournament.firstPlacePrize}",
                                                  style: TextStyle(
                                                    color: Colors.amber.shade900,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade500.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.grey.shade500.withValues(alpha: 0.2), width: 1),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.emoji_events_outlined, color: Colors.grey.shade600, size: 15),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  "2nd: ${tournament.secondPlacePrize}",
                                                  style: TextStyle(
                                                    color: Colors.grey.shade800,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  if (tournament.status == "Completed" ||
                                      tournament.champion.isNotEmpty ||
                                      tournament.runnerUp.isNotEmpty ||
                                      tournament.semiFinalists.isNotEmpty ||
                                      tournament.playerOfTheTournament.isNotEmpty ||
                                      tournament.bestBatter.isNotEmpty ||
                                      tournament.bestBowler.isNotEmpty) ...[
                                    const Divider(color: AppTheme.border, height: 1),
                                    const SizedBox(height: 14),
                                    const Text(
                                      "TOURNAMENT AWARDS & RESULTS",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15), width: 1.2),
                                      ),
                                      child: Column(
                                        children: [
                                          if (tournament.champion.isNotEmpty) ...[
                                            Row(
                                              children: [
                                                const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                                                const SizedBox(width: 8),
                                                const Text("Champion: ", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                                                Expanded(
                                                  child: Text(
                                                    tournament.champion,
                                                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w900),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (tournament.runnerUp.isNotEmpty) ...[
                                            if (tournament.champion.isNotEmpty) const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Icon(Icons.wine_bar, color: Colors.grey.shade400, size: 18),
                                                const SizedBox(width: 8),
                                                const Text("Runner-up: ", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                                                Expanded(
                                                  child: Text(
                                                    tournament.runnerUp,
                                                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (tournament.semiFinalists.isNotEmpty) ...[
                                            if (tournament.champion.isNotEmpty || tournament.runnerUp.isNotEmpty) const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                const Icon(Icons.military_tech, color: Colors.brown, size: 18),
                                                const SizedBox(width: 8),
                                                const Text("Semi Finalists: ", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                                                Expanded(
                                                  child: Text(
                                                    tournament.semiFinalists,
                                                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (tournament.playerOfTheTournament.isNotEmpty) ...[
                                            if (tournament.champion.isNotEmpty || tournament.runnerUp.isNotEmpty || tournament.semiFinalists.isNotEmpty) const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                const Icon(Icons.stars_rounded, color: Colors.orange, size: 18),
                                                const SizedBox(width: 8),
                                                const Text("Man of the Tournament: ", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                                                Expanded(
                                                  child: Text(
                                                    tournament.playerOfTheTournament,
                                                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (tournament.bestBatter.isNotEmpty) ...[
                                            if (tournament.champion.isNotEmpty || tournament.runnerUp.isNotEmpty || tournament.semiFinalists.isNotEmpty || tournament.playerOfTheTournament.isNotEmpty) const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                const Icon(Icons.sports_cricket, color: Colors.blueAccent, size: 18),
                                                const SizedBox(width: 8),
                                                const Text("Best Batter: ", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                                                Expanded(
                                                  child: Text(
                                                    tournament.bestBatter,
                                                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (tournament.bestBowler.isNotEmpty) ...[
                                            if (tournament.champion.isNotEmpty || tournament.runnerUp.isNotEmpty || tournament.semiFinalists.isNotEmpty || tournament.playerOfTheTournament.isNotEmpty || tournament.bestBatter.isNotEmpty) const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                const Icon(Icons.sports_baseball, color: Colors.teal, size: 18),
                                                const SizedBox(width: 8),
                                                const Text("Best Bowler: ", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                                                Expanded(
                                                  child: Text(
                                                    tournament.bestBowler,
                                                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                  const Divider(color: AppTheme.border, height: 1),
                                  const SizedBox(height: 12),

                                  // Schedule & Venue Info
                                  const Text(
                                    "DETAILS & SCHEDULE",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textSecondary,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 15, color: AppTheme.primary),
                                      const SizedBox(width: 6),
                                      const Text(
                                        "Venue: ",
                                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                                      ),
                                      Expanded(
                                        child: Text(
                                          tournament.venue,
                                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Icon(Icons.access_time, size: 15, color: AppTheme.primary),
                                            const SizedBox(width: 6),
                                            const Text(
                                              "Start: ",
                                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                                            ),
                                            Expanded(
                                              child: Text(
                                                tournament.startTime,
                                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Icon(Icons.groups_outlined, size: 15, color: AppTheme.primary),
                                            const SizedBox(width: 6),
                                            const Text(
                                              "Rules: ",
                                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                                            ),
                                            Expanded(
                                              child: Text(
                                                "${tournament.playersPerSide} A Side",
                                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  const Divider(color: AppTheme.border, height: 1),
                                  const SizedBox(height: 12),
                                  
                                  // Organizer info
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    "Organizer: ${tournament.organizerName}",
                                                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.phone_outlined, size: 14, color: AppTheme.textSecondary),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    "Contact: ${tournament.contactDetails}",
                                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
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


  void _showFullScreenBanner(BuildContext context, String bannerPath, bool isNetworkImage) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: isNetworkImage
                      ? Image.network(
                          bannerPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white, size: 60),
                        )
                      : kIsWeb
                          ? Image.network(
                              bannerPath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white, size: 60),
                            )
                          : Image.file(
                              File(bannerPath),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white, size: 60),
                            ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

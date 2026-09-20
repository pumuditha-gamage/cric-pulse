import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/tournament.dart';

class PointsTableEntry {
  final String id;
  final String tournamentId;
  final String tournamentName;
  final String teamName;
  final int played;
  final int won;
  final int lost;
  final double nrr;
  final int points;

  PointsTableEntry({
    required this.id,
    required this.tournamentId,
    required this.tournamentName,
    required this.teamName,
    required this.played,
    required this.won,
    required this.lost,
    required this.nrr,
    required this.points,
  });

  factory PointsTableEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    int parseInt(dynamic val, int defaultVal) {
      if (val == null) return defaultVal;
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) {
        return int.tryParse(val) ?? defaultVal;
      }
      return defaultVal;
    }

    double parseDouble(dynamic val, double defaultVal) {
      if (val == null) return defaultVal;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      if (val is String) {
        return double.tryParse(val) ?? defaultVal;
      }
      return defaultVal;
    }

    return PointsTableEntry(
      id: doc.id,
      tournamentId: data['tournamentId'] ?? '',
      tournamentName: data['tournamentName'] ?? '',
      teamName: data['teamName'] ?? '',
      played: parseInt(data['played'], 0),
      won: parseInt(data['won'], 0),
      lost: parseInt(data['lost'], 0),
      nrr: parseDouble(data['nrr'], 0.0),
      points: parseInt(data['points'], 0),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tournamentId': tournamentId,
      'tournamentName': tournamentName,
      'teamName': teamName,
      'played': played,
      'won': won,
      'lost': lost,
      'nrr': nrr,
      'points': points,
    };
  }
}

class PointsTableScreen extends StatefulWidget {
  const PointsTableScreen({super.key});

  @override
  State<PointsTableScreen> createState() => _PointsTableScreenState();
}

class _PointsTableScreenState extends State<PointsTableScreen> {
  Tournament? _selectedTournament;

  Widget _buildTeamMiniBadge(String teamName, bool isFirst) {
    final char = teamName.isNotEmpty ? teamName[0].toUpperCase() : "T";
    final Color color = isFirst ? AppTheme.primary : AppTheme.secondary;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge(int index) {
    Color bgColor;
    Widget iconOrText;
    if (index == 0) {
      bgColor = Colors.amber.shade100;
      iconOrText = Icon(Icons.emoji_events, color: Colors.amber.shade800, size: 14);
    } else if (index == 1) {
      bgColor = Colors.grey.shade200;
      iconOrText = Icon(Icons.workspace_premium, color: Colors.grey.shade600, size: 14);
    } else if (index == 2) {
      bgColor = Colors.orange.shade100;
      iconOrText = Icon(Icons.workspace_premium, color: Colors.orange.shade700, size: 14);
    } else {
      bgColor = const Color(0xFFF3F7F5);
      iconOrText = Text(
        "${index + 1}",
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      );
    }
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
      ),
      child: Center(child: iconOrText),
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
          "STANDINGS",
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('tournaments').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error loading tournaments: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tournaments = snapshot.data!.docs
                      .map((doc) => Tournament.fromFirestore(doc))
                      .toList();

                  if (tournaments.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.cardDecoration(),
                      child: const Center(
                        child: Text(
                          "No Tournaments Found",
                          style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }

                  if (_selectedTournament == null || !tournaments.any((t) => t.id == _selectedTournament!.id)) {
                    _selectedTournament = tournaments.first;
                  } else {
                    _selectedTournament = tournaments.firstWhere((t) => t.id == _selectedTournament!.id);
                  }

                  return DropdownButtonFormField<Tournament>(
                    initialValue: _selectedTournament,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                    decoration: AppTheme.inputDecoration(
                      label: "Select Tournament",
                      prefixIcon: Icons.emoji_events,
                    ),
                    items: tournaments.map((t) {
                      return DropdownMenuItem<Tournament>(
                        value: t,
                        child: Text(t.name, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedTournament = val;
                      });
                    },
                  );
                },
              ),
            ),

            Expanded(
              child: _selectedTournament == null
                  ? const Center(child: Text("Select a tournament to view standings"))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('points_tables')
                          .where('tournamentId', isEqualTo: _selectedTournament!.id)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text("Error: ${snapshot.error}"));
                        }
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final entries = snapshot.data!.docs
                            .map((doc) => PointsTableEntry.fromFirestore(doc))
                            .toList();

                        entries.sort((a, b) {
                          int comp = b.points.compareTo(a.points);
                          if (comp != 0) return comp;
                          comp = b.nrr.compareTo(a.nrr);
                          if (comp != 0) return comp;
                          comp = b.won.compareTo(a.won);
                          if (comp != 0) return comp;
                          comp = a.played.compareTo(b.played);
                          if (comp != 0) return comp;
                          return a.teamName.compareTo(b.teamName);
                        });

                        if (entries.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.leaderboard_outlined, size: 80, color: AppTheme.textMuted),
                                const SizedBox(height: 16),
                                const Text(
                                  "No standings recorded yet.",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Check back later when matches are recorded.",
                                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        final firstPlaceTeam = entries.first.teamName;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withValues(alpha: 0.25),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    const Positioned(
                                      right: -30,
                                      bottom: -30,
                                      child: Opacity(
                                        opacity: 0.12,
                                        child: Icon(Icons.emoji_events, size: 160, color: Colors.white),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(22.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              _selectedTournament!.name.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            "$firstPlaceTeam Leads the Table!",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            "Top teams will qualify for the grand finale of this championship.",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F1EC),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: const [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "POS  TEAM",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 25,
                                      child: Text(
                                        "P",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 25,
                                      child: Text(
                                        "W",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 25,
                                      child: Text(
                                        "L",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        "NRR",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 35,
                                      child: Text(
                                        "PTS",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(width: 40),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: entries.length,
                                itemBuilder: (context, index) {
                                  final entry = entries[index];
                                  final bool isFirst = index == 0;
                                  final String teamName = entry.teamName;
                                  final String nrrText = entry.nrr >= 0 ? "+${entry.nrr.toStringAsFixed(3)}" : entry.nrr.toStringAsFixed(3);
                                  
                                  Color nrrColor = entry.nrr > 0 
                                      ? Colors.green.shade700 
                                      : (entry.nrr < 0 ? Colors.red.shade600 : AppTheme.textSecondary);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isFirst ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.border,
                                        width: isFirst ? 1.5 : 1.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              children: [
                                                _buildRankBadge(index),
                                                const SizedBox(width: 12),
                                                _buildTeamMiniBadge(teamName, isFirst),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    teamName,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: 25,
                                            child: Text(
                                              "${entry.played}",
                                              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 25,
                                            child: Text(
                                              "${entry.won}",
                                              style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 25,
                                            child: Text(
                                              "${entry.lost}",
                                              style: const TextStyle(fontSize: 13, color: Colors.redAccent),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 60,
                                            child: Text(
                                              nrrText,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: nrrColor,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 35,
                                            child: Text(
                                              "${entry.points}",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: entry.points < 0 ? Colors.redAccent : AppTheme.primary,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 40,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 80),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: null,
    );
  }
}

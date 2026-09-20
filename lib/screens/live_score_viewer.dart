import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class LiveScoreViewer extends StatelessWidget {
  final String? matchId;
  final String matchTitle;
  final String score;
  final String overs;
  final bool isLive;
  final String statusMessage;
  final String batsman1Name;
  final int batsman1Runs;
  final int batsman1Balls;
  final int batsman1Fours;
  final int batsman1Sixes;
  final String batsman2Name;
  final int batsman2Runs;
  final int batsman2Balls;
  final int batsman2Fours;
  final int batsman2Sixes;
  final String bowlerName;
  final String bowlerOvers;
  final int bowlerMaidens;
  final int bowlerRuns;
  final int bowlerWickets;
  final String lastWicketText;
  final String infoMessage;

  const LiveScoreViewer({
    super.key,
    this.matchId,
    this.matchTitle = "Live Match",
    this.score = "156 / 7",
    this.overs = "18.2",
    this.isLive = true,
    this.statusMessage = "Warriors need 32 runs in 11 balls",
    this.batsman1Name = "Kusal Mendis *",
    this.batsman1Runs = 48,
    this.batsman1Balls = 32,
    this.batsman1Fours = 5,
    this.batsman1Sixes = 2,
    this.batsman2Name = "Sahan Arachchige",
    this.batsman2Runs = 12,
    this.batsman2Balls = 10,
    this.batsman2Fours = 1,
    this.batsman2Sixes = 0,
    this.bowlerName = "Alex Mark",
    this.bowlerOvers = "2.2",
    this.bowlerMaidens = 0,
    this.bowlerRuns = 18,
    this.bowlerWickets = 2,
    this.lastWicketText = "Pathum Nissanka 24 (15b) - c Gunathilaka b Alex Mark",
    this.infoMessage = "Match updates are synced live from the ground.",
  });

  @override
  Widget build(BuildContext context) {
    if (matchId != null) {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('scorecards').doc(matchId).snapshots(),
        builder: (context, scorecardSnapshot) {
          if (scorecardSnapshot.hasError || !scorecardSnapshot.hasData || !scorecardSnapshot.data!.exists) {
            // Offline fallback
            final double fallbackCrr = _parseCrr(this.score, this.overs);
            final String crr = fallbackCrr > 0 ? fallbackCrr.toStringAsFixed(2) : "4.86";

            final double fallbackRrr = _parseRrr(this.statusMessage);
            final String? rrr = (fallbackRrr > 0) ? fallbackRrr.toStringAsFixed(2) : (this.statusMessage.contains("need") ? "8.72" : null);

            return _buildScaffold(
              context,
              matchTitle: this.matchTitle,
              score: this.score,
              overs: this.overs,
              isLive: this.isLive,
              statusMessage: this.statusMessage,
              batsman1Name: this.batsman1Name,
              batsman1Runs: this.batsman1Runs,
              batsman1Balls: this.batsman1Balls,
              batsman1Fours: this.batsman1Fours,
              batsman1Sixes: this.batsman1Sixes,
              batsman2Name: this.batsman2Name,
              batsman2Runs: this.batsman2Runs,
              batsman2Balls: this.batsman2Balls,
              batsman2Fours: this.batsman2Fours,
              batsman2Sixes: this.batsman2Sixes,
              bowlerName: this.bowlerName,
              bowlerOvers: this.bowlerOvers,
              bowlerMaidens: this.bowlerMaidens,
              bowlerRuns: this.bowlerRuns,
              bowlerWickets: this.bowlerWickets,
              lastWicketText: this.lastWicketText,
              infoMessage: "${this.infoMessage} (Offline Fallback)",
              crr: crr,
              rrr: rrr,
            );
          }
          
          final cardData = scorecardSnapshot.data!.data() as Map<String, dynamic>;
          
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('matches').doc(matchId).snapshots(),
            builder: (context, matchSnapshot) {
              if (matchSnapshot.hasError || !matchSnapshot.hasData || !matchSnapshot.data!.exists) {
                // Nested match details fallback
                final double fallbackCrr = _parseCrr(this.score, this.overs);
                final String crr = fallbackCrr > 0 ? fallbackCrr.toStringAsFixed(2) : "4.86";

                final double fallbackRrr = _parseRrr(this.statusMessage);
                final String? rrr = (fallbackRrr > 0) ? fallbackRrr.toStringAsFixed(2) : (this.statusMessage.contains("need") ? "8.72" : null);

                return _buildScaffold(
                  context,
                  matchTitle: this.matchTitle,
                  score: this.score,
                  overs: this.overs,
                  isLive: this.isLive,
                  statusMessage: this.statusMessage,
                  batsman1Name: this.batsman1Name,
                  batsman1Runs: this.batsman1Runs,
                  batsman1Balls: this.batsman1Balls,
                  batsman1Fours: this.batsman1Fours,
                  batsman1Sixes: this.batsman1Sixes,
                  batsman2Name: this.batsman2Name,
                  batsman2Runs: this.batsman2Runs,
                  batsman2Balls: this.batsman2Balls,
                  batsman2Fours: this.batsman2Fours,
                  batsman2Sixes: this.batsman2Sixes,
                  bowlerName: this.bowlerName,
                  bowlerOvers: this.bowlerOvers,
                  bowlerMaidens: this.bowlerMaidens,
                  bowlerRuns: this.bowlerRuns,
                  bowlerWickets: this.bowlerWickets,
                  lastWicketText: this.lastWicketText,
                  infoMessage: "${this.infoMessage} (Offline Fallback)",
                  crr: crr,
                  rrr: rrr,
                );
              }
              final matchDoc = matchSnapshot.data!;
              final matchData = matchDoc.exists ? matchDoc.data() as Map<String, dynamic> : {};
              
              int parseInt(dynamic val, int defaultVal) {
                if (val == null) return defaultVal;
                if (val is int) return val;
                if (val is double) return val.toInt();
                if (val is String) return int.tryParse(val) ?? defaultVal;
                return defaultVal;
              }
              final String teamA = matchData['teamA'] ?? 'Team A';
              final String teamB = matchData['teamB'] ?? 'Team B';
              final String status = matchData['status'] ?? 'Live';
              final String matchResult = matchData['result'] ?? 'TBD';
              final int matchOvers = parseInt(matchData['overs'], 20);
              
              final bool isLive = status == 'Live';
              final String matchTitle = "$teamA vs $teamB";
              
              final int r = parseInt(cardData['runs'], 0);
              final int w = parseInt(cardData['wickets'], 0);
              final int o = parseInt(cardData['overs'], 0);
              final int b = parseInt(cardData['balls'], 0);
              final int target = parseInt(cardData['target'], 0);
              final String battingTeam = cardData['battingTeam'] ?? teamA;
              
              final String score = "$battingTeam: $r / $w";
              final String overs = "$o.$b";
              
              String localStatusMessage = matchResult;
              if (isLive) {
                if (target > 0) {
                  final int runsNeeded = target - r;
                  final int ballsRemaining = (matchOvers * 6) - (o * 6 + b);
                  localStatusMessage = "$teamB need $runsNeeded runs in $ballsRemaining balls";
                } else {
                  localStatusMessage = "First innings in progress";
                }
              }
              
              final String localBatsman1Name = cardData['batsman1'] ?? 'Striker';
              final int localBatsman1Runs = parseInt(cardData['batsman1Runs'], 0);
              final int localBatsman1Balls = parseInt(cardData['batsman1Balls'], 0);
              final int localBatsman1Fours = parseInt(cardData['batsman1Fours'], 0);
              final int localBatsman1Sixes = parseInt(cardData['batsman1Sixes'], 0);
              
              final String localBatsman2Name = cardData['batsman2'] ?? 'Non-Striker';
              final int localBatsman2Runs = parseInt(cardData['batsman2Runs'], 0);
              final int localBatsman2Balls = parseInt(cardData['batsman2Balls'], 0);
              final int localBatsman2Fours = parseInt(cardData['batsman2Fours'], 0);
              final int localBatsman2Sixes = parseInt(cardData['batsman2Sixes'], 0);
              
              final String localBowlerName = cardData['bowler'] ?? 'Bowler';
              final int bowlerBalls = parseInt(cardData['bowlerBalls'], 0);
              final String localBowlerOvers = "${bowlerBalls ~/ 6}.${bowlerBalls % 6}";
              final int localBowlerMaidens = parseInt(cardData['bowlerMaidens'], 0);
              final int localBowlerRuns = parseInt(cardData['bowlerRuns'], 0);
              final int localBowlerWickets = parseInt(cardData['bowlerWickets'], 0);
              
              final String localLastWicketText = cardData['lastWicketText'] ?? 'None';
              final String localInfoMessage = isLive ? "Match updates are synced live from the ground." : "Match finished • Scorecard finalized.";

              // Calculate run rates dynamically
              final double totalOvers = o + (b / 6.0);
              final String crr = totalOvers > 0 ? (r / totalOvers).toStringAsFixed(2) : "0.00";
              
              String? rrr;
              if (isLive && target > 0) {
                final int runsNeeded = target - r;
                final int ballsRemaining = (matchOvers * 6) - (o * 6 + b);
                if (ballsRemaining > 0 && runsNeeded > 0) {
                  rrr = ((runsNeeded * 6.0) / ballsRemaining).toStringAsFixed(2);
                } else if (runsNeeded <= 0) {
                  rrr = "0.00";
                } else {
                  rrr = "-";
                }
              }

              return _buildScaffold(
                context,
                matchTitle: matchTitle,
                score: score,
                overs: overs,
                isLive: isLive,
                statusMessage: localStatusMessage,
                batsman1Name: localBatsman1Name,
                batsman1Runs: localBatsman1Runs,
                batsman1Balls: localBatsman1Balls,
                batsman1Fours: localBatsman1Fours,
                batsman1Sixes: localBatsman1Sixes,
                batsman2Name: localBatsman2Name,
                batsman2Runs: localBatsman2Runs,
                batsman2Balls: localBatsman2Balls,
                batsman2Fours: localBatsman2Fours,
                batsman2Sixes: localBatsman2Sixes,
                bowlerName: localBowlerName,
                bowlerOvers: localBowlerOvers,
                bowlerMaidens: localBowlerMaidens,
                bowlerRuns: localBowlerRuns,
                bowlerWickets: localBowlerWickets,
                lastWicketText: localLastWicketText,
                infoMessage: localInfoMessage,
                crr: crr,
                rrr: rrr,
              );
            }
          );
        }
      );
    }

    // Default static fallback:
    final double fallbackCrr = _parseCrr(score, overs);
    final String crr = fallbackCrr > 0 ? fallbackCrr.toStringAsFixed(2) : "4.86";

    final double fallbackRrr = _parseRrr(statusMessage);
    final String? rrr = (fallbackRrr > 0) ? fallbackRrr.toStringAsFixed(2) : (statusMessage.contains("need") ? "8.72" : null);

    return _buildScaffold(
      context,
      matchTitle: matchTitle,
      score: score,
      overs: overs,
      isLive: isLive,
      statusMessage: statusMessage,
      batsman1Name: batsman1Name,
      batsman1Runs: batsman1Runs,
      batsman1Balls: batsman1Balls,
      batsman1Fours: batsman1Fours,
      batsman1Sixes: batsman1Sixes,
      batsman2Name: batsman2Name,
      batsman2Runs: batsman2Runs,
      batsman2Balls: batsman2Balls,
      batsman2Fours: batsman2Fours,
      batsman2Sixes: batsman2Sixes,
      bowlerName: bowlerName,
      bowlerOvers: bowlerOvers,
      bowlerMaidens: bowlerMaidens,
      bowlerRuns: bowlerRuns,
      bowlerWickets: bowlerWickets,
      lastWicketText: lastWicketText,
      infoMessage: infoMessage,
      crr: crr,
      rrr: rrr,
    );
  }

  Widget _buildScorecardLogo(String teamName, Color gradientColor, String matchId) {
    return Hero(
      tag: "logo_${matchId}_$teamName",
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [gradientColor, gradientColor.withValues(alpha: 0.65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: gradientColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Text(
              teamName.isNotEmpty ? teamName[0].toUpperCase() : "T",
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context, {
    required String matchTitle,
    required String score,
    required String overs,
    required bool isLive,
    required String statusMessage,
    required String batsman1Name,
    required int batsman1Runs,
    required int batsman1Balls,
    required int batsman1Fours,
    required int batsman1Sixes,
    required String batsman2Name,
    required int batsman2Runs,
    required int batsman2Balls,
    required int batsman2Fours,
    required int batsman2Sixes,
    required String bowlerName,
    required String bowlerOvers,
    required int bowlerMaidens,
    required int bowlerRuns,
    required int bowlerWickets,
    required String lastWicketText,
    required String infoMessage,
    required String crr,
    required String? rrr,
  }) {
    final teams = matchTitle.split(" vs ");
    final String team1 = teams.isNotEmpty ? teams[0] : "Team A";
    final String team2 = teams.length > 1 ? teams[1] : "Team B";
    final String mId = matchId ?? "";

    final Color logoColor1 = team1 == "Falcons" ? Colors.blueAccent : (team1 == "Titans" ? Colors.amber : Colors.green);
    final Color logoColor2 = team2 == "Warriors" ? Colors.redAccent : (team2 == "Strikers" ? Colors.purpleAccent : Colors.orange);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          matchTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.headerGradient,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📊 1. Premium Score Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF143D28), Color(0xFF0C2417)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF143D28).withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF2C8A53).withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "SUPER LEAGUE 2026",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            if (isLive) const _LiveBadge(),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Team 1 Logo & Name
                              Expanded(
                                flex: 3,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildScorecardLogo(team1, logoColor1, mId),
                                    const SizedBox(height: 8),
                                    Hero(
                                      tag: "team_name_${mId}_$team1",
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Text(
                                          team1,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.spaceGrotesk(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Score, Overs, Run Rates (Center)
                              Expanded(
                                flex: 5,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      transitionBuilder: (Widget child, Animation<double> animation) {
                                        return ScaleTransition(
                                          scale: animation,
                                          child: child,
                                        );
                                      },
                                      child: Text(
                                        score.contains(':') ? score.split(':')[1].trim() : score,
                                        key: ValueKey<String>(score),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 34,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.av_timer, color: Colors.white70, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Overs: $overs",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            "CRR: $crr",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (rrr != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppTheme.secondary.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.4)),
                                            ),
                                            child: Text(
                                              "RRR: $rrr",
                                              style: const TextStyle(
                                                color: AppTheme.secondary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Team 2 Logo & Name
                              Expanded(
                                flex: 3,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildScorecardLogo(team2, logoColor2, mId),
                                    const SizedBox(height: 8),
                                    Hero(
                                      tag: "team_name_${mId}_$team2",
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Text(
                                          team2,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.spaceGrotesk(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (statusMessage.isNotEmpty && statusMessage != "None") ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info,
                                    color: AppTheme.secondary, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    statusMessage,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),


                const SizedBox(height: 20),

                // 🏏 2. Current Batsmen Card
                Container(
                  decoration: AppTheme.cardDecoration(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.sports_cricket,
                              color: AppTheme.primary, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "CURRENT BATSMEN",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          Expanded(
                            flex: 4,
                            child: Text(
                              "Batsman",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 30,
                            child: Text(
                              "R",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(
                            width: 30,
                            child: Text(
                              "B",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(
                            width: 30,
                            child: Text(
                              "4s",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(
                            width: 30,
                            child: Text(
                              "6s",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      _buildBatsmanRow(
                        batsman1Name,
                        batsman1Runs,
                        batsman1Balls,
                        batsman1Fours,
                        batsman1Sixes,
                      ),
                      const SizedBox(height: 4),
                      _buildBatsmanRow(
                        batsman2Name,
                        batsman2Runs,
                        batsman2Balls,
                        batsman2Fours,
                        batsman2Sixes,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 🔴 3. Last Wicket Info
                if (lastWicketText != "None" && lastWicketText.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade100, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.gavel,
                              color: Colors.redAccent, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "LAST WICKET",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lastWicketText,
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 🏃‍♂️ 4. Current Bowler Card
                Container(
                  decoration: AppTheme.cardDecoration(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.sports_baseball_outlined,
                              color: AppTheme.primary, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "CURRENT BOWLER",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          Expanded(
                            flex: 4,
                            child: Text(
                              "Bowler",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 30,
                            child: Text(
                              "O",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(
                            width: 30,
                            child: Text(
                              "M",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(
                            width: 30,
                            child: Text(
                              "R",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(
                            width: 30,
                            child: Text(
                              "W",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      _buildBowlerRow(
                        bowlerName,
                        bowlerOvers,
                        bowlerMaidens,
                        bowlerRuns,
                        bowlerWickets,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ℹ️ Live Sync Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sync, color: AppTheme.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        infoMessage,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBatsmanRow(
      String name, int runs, int balls, int fours, int sixes) {
    final bool isOnStrike = name.endsWith('*');
    final cleanName = isOnStrike ? name.replaceAll('*', '').trim() : name;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isOnStrike
            ? AppTheme.primary.withValues(alpha: 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnStrike ? AppTheme.primary : Colors.transparent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cleanName,
                    style: TextStyle(
                      fontWeight: isOnStrike ? FontWeight.bold : FontWeight.w500,
                      color: isOnStrike ? AppTheme.primary : AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isOnStrike) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.star, color: AppTheme.secondary, size: 12),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              "$runs",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isOnStrike ? AppTheme.primary : AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              "$balls",
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              "$fours",
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              "$sixes",
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBowlerRow(
      String name, String overs, int maidens, int runs, int wickets) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                const Icon(Icons.sports_cricket, color: AppTheme.primary, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              overs,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              "$maidens",
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              "$runs",
              style: const TextStyle(
                  fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              "$wickets",
              style: const TextStyle(
                  fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  double _parseCrr(String scoreStr, String oversStr) {
    try {
      final cleanScore = scoreStr.contains(':') ? scoreStr.split(':')[1] : scoreStr;
      final runsStr = cleanScore.split('/')[0].trim();
      final runs = int.parse(runsStr);

      final parts = oversStr.split('.');
      final o = int.parse(parts[0]);
      final b = parts.length > 1 ? int.parse(parts[1]) : 0;

      final totalOvers = o + (b / 6.0);
      if (totalOvers > 0) {
        return runs / totalOvers;
      }
    } catch (_) {}
    return 0.0;
  }

  double _parseRrr(String statusMsg) {
    try {
      final regExp = RegExp(r'need\s+(\d+)\s+runs\s+in\s+(\d+)\s+balls');
      final match = regExp.firstMatch(statusMsg);
      if (match != null) {
        final runsNeeded = int.parse(match.group(1)!);
        final ballsRemaining = int.parse(match.group(2)!);
        if (ballsRemaining > 0) {
          return (runsNeeded * 6.0) / ballsRemaining;
        }
      }
    } catch (_) {}
    return 0.0;
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFD50000).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFFF1744).withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _controller,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFF1744),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF1744),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            "LIVE",
            style: TextStyle(
              color: Color(0xFFFF1744),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

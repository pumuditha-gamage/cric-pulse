import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match.dart';
import '../admin_session.dart';
import '../theme.dart';

class LiveScoringScreen extends StatefulWidget {
  const LiveScoringScreen({super.key});

  @override
  State<LiveScoringScreen> createState() => _LiveScoringScreenState();
}

class _LiveScoringScreenState extends State<LiveScoringScreen> {
  ScheduledMatch? _activeMatch;

  Widget _buildMatchSelectionList() {
    final String adminEmail = AdminSession.currentAdmin ?? "admin@cricpulse.com";

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('createdBy', isEqualTo: adminEmail)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        final matches = docs.map((d) => ScheduledMatch.fromFirestore(d)).toList();

        final liveOrUpcoming = matches.where((m) => m.status == 'Live' || m.status == 'Upcoming').toList();

        if (liveOrUpcoming.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tv_off, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text("No active Live or Scheduled matches to score.", style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: liveOrUpcoming.length,
          itemBuilder: (context, index) {
            final m = liveOrUpcoming[index];
            final isLive = m.status == 'Live';

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                title: Text("${m.teamA} vs ${m.teamB}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text("Tournament: ${m.tournamentName}"),
                    const SizedBox(height: 2),
                    Text("Venue: ${m.venue} | Overs: ${m.overs}"),
                  ],
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLive ? Colors.redAccent : AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    // Set match as Live in Firestore if not already
                    if (!isLive) {
                      FirebaseFirestore.instance.collection('matches').doc(m.id).update({'status': 'Live'});
                    }
                    setState(() {
                      _activeMatch = m;
                    });
                  },
                  child: Text(
                    isLive ? "Open Scoring Desk" : "Start Live Scoring",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_activeMatch == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text(
                "Live Scoring Portal",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ),
            Expanded(child: _buildMatchSelectionList()),
          ],
        ),
      );
    }

    return ScoringDesk(
      match: _activeMatch!,
      onBack: () => setState(() => _activeMatch = null),
    );
  }
}

class ScoringDesk extends StatefulWidget {
  final ScheduledMatch match;
  final VoidCallback onBack;

  const ScoringDesk({super.key, required this.match, required this.onBack});

  @override
  State<ScoringDesk> createState() => _ScoringDeskState();
}

class _ScoringDeskState extends State<ScoringDesk> {
  Future<void> _updateScorecard(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('scorecards').doc(widget.match.id).update(data);
  }

  Future<void> _promptNextBatsman(List<PlayerDetails> battingSquad) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final customNameController = TextEditingController();
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.sports_cricket, color: Colors.redAccent, size: 24),
              SizedBox(width: 8),
              Text("Wicket! Select Next Batsman", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
            ],
          ),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (battingSquad.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Select from squad:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: battingSquad.length,
                      itemBuilder: (context, index) {
                        final p = battingSquad[index];
                        return ListTile(
                          dense: true,
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          subtitle: Text("${p.battingStyle} | Age: ${p.age}"),
                          onTap: () async {
                            await _updateScorecard({
                              'batsman1': p.name,
                              'batsman1Runs': 0,
                              'batsman1Balls': 0,
                              'batsman1Fours': 0,
                              'batsman1Sixes': 0,
                            });
                            if (context.mounted) Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 24),
                ],
                TextField(
                  controller: customNameController,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Or enter new batsman name...",
                    prefixIcon: const Icon(Icons.person_add_outlined, color: AppTheme.primary, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final name = customNameController.text.trim();
                if (name.isNotEmpty) {
                  await _updateScorecard({
                    'batsman1': name,
                    'batsman1Runs': 0,
                    'batsman1Balls': 0,
                    'batsman1Fours': 0,
                    'batsman1Sixes': 0,
                  });
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Set Batsman", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _promptNextBowler(List<PlayerDetails> bowlingSquad) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final customNameController = TextEditingController();
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.sports_baseball_outlined, color: AppTheme.primary, size: 24),
              SizedBox(width: 8),
              Text("Over Completed! Select Bowler", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
            ],
          ),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (bowlingSquad.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Select next bowler from squad:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: bowlingSquad.length,
                      itemBuilder: (context, index) {
                        final p = bowlingSquad[index];
                        return ListTile(
                          dense: true,
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          subtitle: Text("${p.bowlingStyle} | Age: ${p.age}"),
                          onTap: () async {
                            await _updateScorecard({
                              'bowler': p.name,
                              'bowlerBalls': 0,
                              'bowlerRuns': 0,
                              'bowlerWickets': 0,
                              'bowlerMaidens': 0,
                            });
                            if (context.mounted) Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 24),
                ],
                TextField(
                  controller: customNameController,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Or enter new bowler name...",
                    prefixIcon: const Icon(Icons.sports_baseball, color: AppTheme.primary, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final name = customNameController.text.trim();
                if (name.isNotEmpty) {
                  await _updateScorecard({
                    'bowler': name,
                    'bowlerBalls': 0,
                    'bowlerRuns': 0,
                    'bowlerWickets': 0,
                    'bowlerMaidens': 0,
                  });
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Set Bowler", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _recordBall(
    int runs,
    bool isWicket,
    int extras,
    String extraType,
    Map<String, dynamic> currentData,
    List<PlayerDetails> battingSquad,
    List<PlayerDetails> bowlingSquad,
  ) async {
    int currentRuns = currentData['runs'] ?? 0;
    int currentWickets = currentData['wickets'] ?? 0;
    int currentOvers = currentData['overs'] ?? 0;
    int currentBalls = currentData['balls'] ?? 0;

    String batsman1 = currentData['batsman1'] ?? 'Striker';
    int b1Runs = currentData['batsman1Runs'] ?? 0;
    int b1Balls = currentData['batsman1Balls'] ?? 0;
    int b1Fours = currentData['batsman1Fours'] ?? 0;
    int b1Sixes = currentData['batsman1Sixes'] ?? 0;

    String batsman2 = currentData['batsman2'] ?? 'Non-Striker';
    int b2Runs = currentData['batsman2Runs'] ?? 0;
    int b2Balls = currentData['batsman2Balls'] ?? 0;
    int b2Fours = currentData['batsman2Fours'] ?? 0;
    int b2Sixes = currentData['batsman2Sixes'] ?? 0;

    String bowler = currentData['bowler'] ?? 'Bowler';
    int bowlerBalls = currentData['bowlerBalls'] ?? 0;
    int bowlerRuns = currentData['bowlerRuns'] ?? 0;
    int bowlerWickets = currentData['bowlerWickets'] ?? 0;
    int bowlerMaidens = currentData['bowlerMaidens'] ?? 0;
    String lastWktText = currentData['lastWicketText'] ?? 'None';

    List<dynamic> history = List.from(currentData['history'] ?? []);
    List<String> currentOverBalls = List<String>.from(currentData['currentOverBalls'] ?? []);
    bool lastOverEnded = currentData['lastOverEnded'] ?? false;

    // Save previous state for undo support
    final previousState = {
      'runs': currentRuns,
      'wickets': currentWickets,
      'overs': currentOvers,
      'balls': currentBalls,
      'batsman1': batsman1,
      'batsman1Runs': b1Runs,
      'batsman1Balls': b1Balls,
      'batsman1Fours': b1Fours,
      'batsman1Sixes': b1Sixes,
      'batsman2': batsman2,
      'batsman2Runs': b2Runs,
      'batsman2Balls': b2Balls,
      'batsman2Fours': b2Fours,
      'batsman2Sixes': b2Sixes,
      'bowler': bowler,
      'bowlerBalls': bowlerBalls,
      'bowlerRuns': bowlerRuns,
      'bowlerWickets': bowlerWickets,
      'bowlerMaidens': bowlerMaidens,
      'lastWicketText': lastWktText,
      'currentOverBalls': List<String>.from(currentOverBalls),
      'lastOverEnded': lastOverEnded,
    };
    history.add(previousState);

    if (lastOverEnded) {
      currentOverBalls = [];
      lastOverEnded = false;
    }

    String ballLabel = "$runs";
    if (isWicket) {
      ballLabel = "W";
    } else if (extraType == 'Wide') {
      ballLabel = "${extras}WD";
    } else if (extraType == 'No Ball') {
      ballLabel = "${runs > 0 ? (runs + extras) : extras}NB";
    } else if (extraType == 'Leg Bye') {
      ballLabel = "${extras}LB";
    } else if (runs == 0) {
      ballLabel = "0";
    }

    currentOverBalls.add(ballLabel);

    // Update variables
    currentRuns += runs + extras;
    
    // Batsman stats update (striker is always batsman1)
    b1Runs += runs;
    if (extraType != 'Wide') {
      b1Balls += 1;
    }
    if (runs == 4) b1Fours += 1;
    if (runs == 6) b1Sixes += 1;

    // Bowler stats update
    if (extraType != 'Leg Bye') {
      bowlerRuns += runs + extras;
    }
    
    if (isWicket) {
      currentWickets += 1;
      bowlerWickets += 1;
      lastWktText = "$batsman1 $b1Runs (${b1Balls}b) - Wicket";
    }

    // Over ball progression
    bool isOverEnded = false;
    if (extraType != 'Wide' && extraType != 'No Ball') {
      currentBalls += 1;
      bowlerBalls += 1;
      if (currentBalls >= 6) {
        currentOvers += 1;
        currentBalls = 0;
        isOverEnded = true;
      }
    }

    // Swap strike logic
    bool shouldSwap = (runs % 2 != 0) ^ isOverEnded;
    if (shouldSwap) {
      final tempName = batsman1;
      final tempRuns = b1Runs;
      final tempBalls = b1Balls;
      final tempFours = b1Fours;
      final tempSixes = b1Sixes;

      batsman1 = batsman2;
      b1Runs = b2Runs;
      b1Balls = b2Balls;
      b1Fours = b2Fours;
      b1Sixes = b2Sixes;

      batsman2 = tempName;
      b2Runs = tempRuns;
      b2Balls = tempBalls;
      b2Fours = tempFours;
      b2Sixes = tempSixes;
    }

    await _updateScorecard({
      'runs': currentRuns,
      'wickets': currentWickets,
      'overs': currentOvers,
      'balls': currentBalls,
      'batsman1': batsman1,
      'batsman1Runs': b1Runs,
      'batsman1Balls': b1Balls,
      'batsman1Fours': b1Fours,
      'batsman1Sixes': b1Sixes,
      'batsman2': batsman2,
      'batsman2Runs': b2Runs,
      'batsman2Balls': b2Balls,
      'batsman2Fours': b2Fours,
      'batsman2Sixes': b2Sixes,
      'bowler': bowler,
      'bowlerBalls': bowlerBalls,
      'bowlerRuns': bowlerRuns,
      'bowlerWickets': bowlerWickets,
      'bowlerMaidens': bowlerMaidens,
      'lastWicketText': lastWktText,
      'currentOverBalls': currentOverBalls,
      'lastOverEnded': isOverEnded,
      'history': history,
    });

    final int currentInnings = currentData['innings'] ?? 1;
    final int target = currentData['target'] ?? 0;

    final int teamSize = (battingSquad.length >= 2)
        ? battingSquad.length
        : (widget.match.playersPerSide > 1 ? widget.match.playersPerSide : 11);
    final int maxWickets = teamSize - 1;

    final bool isAllOut = currentWickets >= maxWickets;
    final bool isTargetReached = (currentInnings == 2 && target > 0 && currentRuns >= target);

    if (mounted) {
      if (isTargetReached) {
        _finishMatch(currentRuns, target, currentWickets);
      } else if (isAllOut) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("ALL OUT! ($currentWickets wickets fallen). Innings ended."),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
        _endInnings({
          ...currentData,
          'runs': currentRuns,
          'wickets': currentWickets,
          'overs': currentOvers,
          'balls': currentBalls,
        });
      } else {
        if (isWicket) {
          await _promptNextBatsman(battingSquad);
        }
        if (isOverEnded && mounted) {
          await _promptNextBowler(bowlingSquad);
        }
      }
    }
  }

  void _undoBall(Map<String, dynamic> currentData) async {
    List<dynamic> history = List.from(currentData['history'] ?? []);
    if (history.isEmpty) return;

    final prev = history.removeLast() as Map<String, dynamic>;
    await _updateScorecard({
      'runs': prev['runs'],
      'wickets': prev['wickets'],
      'overs': prev['overs'],
      'balls': prev['balls'],
      'batsman1': prev['batsman1'],
      'batsman1Runs': prev['batsman1Runs'],
      'batsman1Balls': prev['batsman1Balls'],
      'batsman1Fours': prev['batsman1Fours'],
      'batsman1Sixes': prev['batsman1Sixes'],
      'batsman2': prev['batsman2'],
      'batsman2Runs': prev['batsman2Runs'],
      'batsman2Balls': prev['batsman2Balls'],
      'batsman2Fours': prev['batsman2Fours'],
      'batsman2Sixes': prev['batsman2Sixes'],
      'bowler': prev['bowler'],
      'bowlerBalls': prev['bowlerBalls'],
      'bowlerRuns': prev['bowlerRuns'],
      'bowlerWickets': prev['bowlerWickets'],
      'bowlerMaidens': prev['bowlerMaidens'],
      'lastWicketText': prev['lastWicketText'],
      'currentOverBalls': prev['currentOverBalls'] ?? [],
      'lastOverEnded': prev['lastOverEnded'] ?? false,
      'history': history,
    });
  }

  void _swapStrike(Map<String, dynamic> currentData) async {
    String batsman1 = currentData['batsman1'] ?? 'Striker';
    int b1Runs = currentData['batsman1Runs'] ?? 0;
    int b1Balls = currentData['batsman1Balls'] ?? 0;
    int b1Fours = currentData['batsman1Fours'] ?? 0;
    int b1Sixes = currentData['batsman1Sixes'] ?? 0;

    String batsman2 = currentData['batsman2'] ?? 'Non-Striker';
    int b2Runs = currentData['batsman2Runs'] ?? 0;
    int b2Balls = currentData['batsman2Balls'] ?? 0;
    int b2Fours = currentData['batsman2Fours'] ?? 0;
    int b2Sixes = currentData['batsman2Sixes'] ?? 0;

    await _updateScorecard({
      'batsman1': batsman2,
      'batsman1Runs': b2Runs,
      'batsman1Balls': b2Balls,
      'batsman1Fours': b2Fours,
      'batsman1Sixes': b2Sixes,
      'batsman2': batsman1,
      'batsman2Runs': b1Runs,
      'batsman2Balls': b1Balls,
      'batsman2Fours': b1Fours,
      'batsman2Sixes': b1Sixes,
    });
  }

  void _endInnings(Map<String, dynamic> currentData) async {
    final runs = currentData['runs'] ?? 0;
    final int currentInnings = currentData['innings'] ?? 1;

    if (currentInnings == 1) {
      // Swap teams and set target
      await _updateScorecard({
        'innings': 2,
        'target': runs + 1,
        'runs': 0,
        'wickets': 0,
        'overs': 0,
        'balls': 0,
        'battingTeam': widget.match.teamB,
        'bowlingTeam': widget.match.teamA,
        'batsman1': 'Striker',
        'batsman1Runs': 0,
        'batsman1Balls': 0,
        'batsman1Fours': 0,
        'batsman1Sixes': 0,
        'batsman2': 'Non-Striker',
        'batsman2Runs': 0,
        'batsman2Balls': 0,
        'batsman2Fours': 0,
        'batsman2Sixes': 0,
        'bowler': 'Bowler',
        'bowlerBalls': 0,
        'bowlerWickets': 0,
        'bowlerRuns': 0,
        'bowlerMaidens': 0,
        'history': [],
        'lastWicketText': 'None',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("1st Innings Ended. Target Set!"), backgroundColor: AppTheme.primary),
        );
      }
    } else {
      _finishMatch(runs, currentData['target'] ?? 0, currentData['wickets'] ?? 0);
    }
  }

  void _finishMatch(int finalRuns, int target, [int wicketsFallen = 0]) async {
    String result = "Match Ended";
    final teamA = widget.match.teamA;
    final teamB = widget.match.teamB;

    final int squadSize = widget.match.teamBPlayers.isNotEmpty
        ? widget.match.teamBPlayers.length
        : widget.match.playersPerSide;
    final int maxWkts = (squadSize > 1) ? (squadSize - 1) : 10;
    final int wicketsRemaining = (maxWkts - wicketsFallen).clamp(0, maxWkts);

    if (finalRuns >= target) {
      result = "$teamB won by $wicketsRemaining wicket${wicketsRemaining == 1 ? '' : 's'}";
    } else if (finalRuns < target - 1) {
      result = "$teamA won by ${target - 1 - finalRuns} runs";
    } else {
      result = "Match Tied";
    }

    await FirebaseFirestore.instance.collection('matches').doc(widget.match.id).update({
      'status': 'Finished',
      'result': result,
    });

    widget.onBack();
  }

  void _changeActivePlayers(String role, List<PlayerDetails> squad, String currentName) {
    showDialog(
      context: context,
      builder: (context) {
        final customController = TextEditingController();
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Select $role", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 16)),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (squad.isNotEmpty) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: squad.length,
                      itemBuilder: (context, index) {
                        final p = squad[index];
                        return ListTile(
                          dense: true,
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          subtitle: Text(role == 'Bowler' ? p.bowlingStyle : p.battingStyle),
                          onTap: () async {
                            if (role == 'Striker') {
                              await _updateScorecard({'batsman1': p.name, 'batsman1Runs': 0, 'batsman1Balls': 0});
                            } else if (role == 'Non-Striker') {
                              await _updateScorecard({'batsman2': p.name, 'batsman2Runs': 0, 'batsman2Balls': 0});
                            } else {
                              await _updateScorecard({'bowler': p.name, 'bowlerRuns': 0, 'bowlerWickets': 0, 'bowlerBalls': 0});
                            }
                            if (context.mounted) Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 24),
                ],
                TextField(
                  controller: customController,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Or type custom $role name...",
                    prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primary, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final name = customController.text.trim();
                if (name.isNotEmpty) {
                  if (role == 'Striker') {
                    await _updateScorecard({'batsman1': name, 'batsman1Runs': 0, 'batsman1Balls': 0});
                  } else if (role == 'Non-Striker') {
                    await _updateScorecard({'batsman2': name, 'batsman2Runs': 0, 'batsman2Balls': 0});
                  } else {
                    await _updateScorecard({'bowler': name, 'bowlerRuns': 0, 'bowlerWickets': 0, 'bowlerBalls': 0});
                  }
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Save Player", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('scorecards').doc(widget.match.id).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: CircularProgressIndicator());
        }

        final scorecard = snapshot.data!.data() as Map<String, dynamic>;
        final int runs = scorecard['runs'] ?? 0;
        final int wickets = scorecard['wickets'] ?? 0;
        final int overs = scorecard['overs'] ?? 0;
        final int balls = scorecard['balls'] ?? 0;
        final int target = scorecard['target'] ?? 0;
        final int innings = scorecard['innings'] ?? 1;
        final String battingTeam = scorecard['battingTeam'] ?? widget.match.teamA;

        final striker = scorecard['batsman1'] ?? 'Striker';
        final strikerRuns = scorecard['batsman1Runs'] ?? 0;
        final nonStriker = scorecard['batsman2'] ?? 'Non-Striker';
        final nonStrikerRuns = scorecard['batsman2Runs'] ?? 0;
        final bowler = scorecard['bowler'] ?? 'Bowler';
        final bowlerRuns = scorecard['bowlerRuns'] ?? 0;
        final bowlerWickets = scorecard['bowlerWickets'] ?? 0;
        final List<String> currentOverBalls = List<String>.from(scorecard['currentOverBalls'] ?? []);

        final bool isTeamABatting = (battingTeam == widget.match.teamA);
        final List<PlayerDetails> battingSquad = isTeamABatting ? widget.match.teamAPlayers : widget.match.teamBPlayers;
        final List<PlayerDetails> bowlingSquad = isTeamABatting ? widget.match.teamBPlayers : widget.match.teamAPlayers;

        // Calculate run rates dynamically
        final double totalOvers = overs + (balls / 6.0);
        final String crr = totalOvers > 0 ? (runs / totalOvers).toStringAsFixed(2) : "0.00";

        String? rrr;
        if (target > 0) {
          final int runsNeeded = target - runs;
          final int ballsRemaining = (widget.match.overs * 6) - (overs * 6 + balls);
          if (ballsRemaining > 0 && runsNeeded > 0) {
            rrr = ((runsNeeded * 6.0) / ballsRemaining).toStringAsFixed(2);
          } else if (runsNeeded <= 0) {
            rrr = "0.00";
          } else {
            rrr = "-";
          }
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
              onPressed: widget.onBack,
            ),
            title: Text(
              "Scoring Desk: ${widget.match.teamA} vs ${widget.match.teamB}",
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Top scorecard board
                Container(
                  width: double.infinity,
                  decoration: AppTheme.cardDecoration(hasHighlight: true),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        battingTeam.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1.5, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "$runs / $wickets",
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(width: 24),
                          Text(
                            "Overs: $overs.$balls",
                            style: const TextStyle(fontSize: 20, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "CRR: $crr",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                          ),
                          if (target > 0) ...[
                            const SizedBox(width: 24),
                            Text(
                              "RRR: ${rrr ?? '-'}",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent),
                            ),
                          ],
                        ],
                      ),
                      if (target > 0) ...[
                        const SizedBox(height: 12),
                        Text(
                          "Target: $target  |  Need ${target - runs} runs from ${widget.match.overs * 6 - (overs * 6 + balls)} balls",
                          style: TextStyle(color: Colors.redAccent.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Batsmen and Bowlers active stats
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: AppTheme.cardDecoration(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("BATTING", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                            const SizedBox(height: 12),
                            _clickablePlayerRow("Striker: $striker *", "$strikerRuns Runs", () {
                              _changeActivePlayers('Striker', battingSquad, striker);
                            }),
                            const Divider(height: 20),
                            _clickablePlayerRow("Non-Striker: $nonStriker", "$nonStrikerRuns Runs", () {
                              _changeActivePlayers('Non-Striker', battingSquad, nonStriker);
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: AppTheme.cardDecoration(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("BOWLING", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                            const SizedBox(height: 12),
                            _clickablePlayerRow("Bowler: $bowler", "$bowlerWickets Wkts / $bowlerRuns Runs", () {
                              _changeActivePlayers('Bowler', bowlingSquad, bowler);
                            }),
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Text(
                                  "THIS OVER: ",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: currentOverBalls.isEmpty
                                      ? const Text(
                                          "-",
                                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                        )
                                      : SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: currentOverBalls.map((b) {
                                              Color bg = Colors.grey.shade200;
                                              Color fg = AppTheme.textPrimary;

                                              if (b == 'W') {
                                                bg = Colors.redAccent;
                                                fg = Colors.white;
                                              } else if (b == '4') {
                                                bg = Colors.green.shade600;
                                                fg = Colors.white;
                                              } else if (b == '6') {
                                                bg = AppTheme.primary;
                                                fg = Colors.white;
                                              } else if (b.contains('WD') || b.contains('NB') || b.contains('LB')) {
                                                bg = Colors.orangeAccent.shade700;
                                                fg = Colors.white;
                                              } else if (b == '1' || b == '2' || b == '3') {
                                                bg = const Color(0xFFE8F5E9);
                                                fg = Colors.green.shade900;
                                              }

                                              return Container(
                                                margin: const EdgeInsets.only(right: 6),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: bg,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  b,
                                                  style: TextStyle(
                                                    color: fg,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              );
                                              }).toList(),
                                            ),
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Interactive scoring desk buttons
                Container(
                  decoration: AppTheme.cardDecoration(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("ADD BALL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _ballBtn("DOT", () => _recordBall(0, false, 0, 'Normal', scorecard, battingSquad, bowlingSquad)),
                          _ballBtn("+1", () => _recordBall(1, false, 0, 'Normal', scorecard, battingSquad, bowlingSquad)),
                          _ballBtn("+2", () => _recordBall(2, false, 0, 'Normal', scorecard, battingSquad, bowlingSquad)),
                          _ballBtn("+3", () => _recordBall(3, false, 0, 'Normal', scorecard, battingSquad, bowlingSquad)),
                          _ballBtn("FOUR (4)", () => _recordBall(4, false, 0, 'Normal', scorecard, battingSquad, bowlingSquad), color: Colors.green),
                          _ballBtn("SIX (6)", () => _recordBall(6, false, 0, 'Normal', scorecard, battingSquad, bowlingSquad), color: AppTheme.primary),
                        ],
                      ),
                      const Divider(height: 32),
                      const Text("EXTRAS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _ballBtn("WIDE (WD)", () => _recordBall(0, false, 1, 'Wide', scorecard, battingSquad, bowlingSquad), color: Colors.orange),
                          _ballBtn("NO BALL (NB)", () => _recordBall(0, false, 1, 'No Ball', scorecard, battingSquad, bowlingSquad), color: Colors.orange),
                          _ballBtn("LEG BYE (LB)", () => _recordBall(0, false, 1, 'Leg Bye', scorecard, battingSquad, bowlingSquad), color: Colors.blueGrey),
                        ],
                      ),
                      const Divider(height: 32),
                      const Text("WICKET & DESK CONTROL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                            icon: const Icon(Icons.warning, color: Colors.white, size: 18),
                            label: const Text("OUT! (Wicket)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () => _recordBall(0, true, 0, 'Wicket', scorecard, battingSquad, bowlingSquad),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                            icon: const Icon(Icons.undo, size: 18),
                            label: const Text("Undo"),
                            onPressed: () => _undoBall(scorecard),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                            icon: const Icon(Icons.swap_horiz, size: 18),
                            label: const Text("Swap Strike"),
                            onPressed: () => _swapStrike(scorecard),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                            icon: const Icon(Icons.flag, color: Colors.white, size: 18),
                            label: Text(
                              innings == 1 ? "End Innings" : "End Match",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => _endInnings(scorecard),
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
  }

  Widget _clickablePlayerRow(String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
            Row(
              children: [
                Text(subtitle, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 8),
                const Icon(Icons.swap_horiz, size: 16, color: AppTheme.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ballBtn(String label, VoidCallback onPressed, {Color? color}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.white,
        foregroundColor: color != null ? Colors.white : AppTheme.textPrimary,
        side: color == null ? const BorderSide(color: AppTheme.border) : BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tournament.dart';
import '../theme.dart';
import '../admin_session.dart';
import 'points_table_screen.dart'; // Imports PointsTableEntry

class AdminPointsTableEditor extends StatefulWidget {
  const AdminPointsTableEditor({super.key});

  @override
  State<AdminPointsTableEditor> createState() => _AdminPointsTableEditorState();
}

class _AdminPointsTableEditorState extends State<AdminPointsTableEditor> {
  Tournament? _selectedTournament;

  void _showNrrCalculatorDialog(TextEditingController nrrController, StateSetter setDialogState) {
    final runsScoredController = TextEditingController();
    final oversFacedController = TextEditingController();
    final runsConcededController = TextEditingController();
    final oversBowledController = TextEditingController();
    double calculatedNrr = 0.0;
    bool hasCalculated = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setCalcState) {
            void calculateNrr() {
              final rs = double.tryParse(runsScoredController.text.trim()) ?? 0.0;
              final ofRaw = double.tryParse(oversFacedController.text.trim()) ?? 0.0;
              final rc = double.tryParse(runsConcededController.text.trim()) ?? 0.0;
              final obRaw = double.tryParse(oversBowledController.text.trim()) ?? 0.0;

              // Convert overs like 19.3 -> 19 + 3/6 = 19.5
              double parseOvers(double val) {
                int full = val.floor();
                double balls = ((val - full) * 10).round() / 6.0;
                double total = full + balls;
                return total > 0 ? total : 1.0; // avoid div by 0
              }

              final ofDec = parseOvers(ofRaw);
              final obDec = parseOvers(obRaw);

              final trr = rs / ofDec;
              final orr = rc / obDec;

              setCalcState(() {
                calculatedNrr = trr - orr;
                hasCalculated = true;
              });
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppTheme.border, width: 1.5),
              ),
              title: const Row(
                children: [
                  Icon(Icons.calculate_outlined, color: AppTheme.primary, size: 24),
                  SizedBox(width: 8),
                  Text("NRR Calculator", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Enter total runs and overs for this tournament to calculate exact Net Run Rate (NRR).",
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: runsScoredController,
                            keyboardType: TextInputType.number,
                            decoration: AppTheme.inputDecoration(label: "Runs Scored", prefixIcon: Icons.sports_cricket),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: oversFacedController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: AppTheme.inputDecoration(label: "Overs Faced (e.g. 50.3)", prefixIcon: Icons.timer_outlined),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: runsConcededController,
                            keyboardType: TextInputType.number,
                            decoration: AppTheme.inputDecoration(label: "Runs Conceded", prefixIcon: Icons.shield_outlined),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: oversBowledController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: AppTheme.inputDecoration(label: "Overs Bowled", prefixIcon: Icons.timer_outlined),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: calculateNrr,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        foregroundColor: AppTheme.primary,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.calculate, size: 18),
                      label: const Text("Calculate NRR", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    if (hasCalculated) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: calculatedNrr >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: calculatedNrr >= 0 ? Colors.green.shade200 : Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Calculated NRR:", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            Text(
                              calculatedNrr >= 0 ? "+${calculatedNrr.toStringAsFixed(3)}" : calculatedNrr.toStringAsFixed(3),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: calculatedNrr >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  onPressed: () {
                    if (hasCalculated) {
                      setDialogState(() {
                        nrrController.text = calculatedNrr >= 0
                            ? "+${calculatedNrr.toStringAsFixed(3)}"
                            : calculatedNrr.toStringAsFixed(3);
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Apply NRR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddOrEditEntryDialog([PointsTableEntry? entry]) {
    final isEdit = entry != null;

    String? selectedTeamName = entry?.teamName;
    bool isCustomTeam = false;
    final TextEditingController customTeamController = TextEditingController(text: entry?.teamName ?? '');
    final TextEditingController playedController = TextEditingController(text: entry?.played.toString() ?? '0');
    final TextEditingController wonController = TextEditingController(text: entry?.won.toString() ?? '0');
    final TextEditingController lostController = TextEditingController(text: entry?.lost.toString() ?? '0');
    final TextEditingController nrrController = TextEditingController(text: entry?.nrr.toString() ?? '0.000');
    final TextEditingController pointsController = TextEditingController(text: entry?.points.toString() ?? '0');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void updateFromWonLost() {
              final won = int.tryParse(wonController.text) ?? 0;
              final lost = int.tryParse(lostController.text) ?? 0;
              setDialogState(() {
                playedController.text = (won + lost).toString();
                pointsController.text = ((won * 2) - (lost * 2)).toString();
              });
            }

            Future<void> fetchTeamStats(String teamName) async {
              if (_selectedTournament == null || teamName.isEmpty || teamName == "__CUSTOM__") return;
              try {
                final snapshot = await FirebaseFirestore.instance
                    .collection('points_tables')
                    .where('tournamentId', isEqualTo: _selectedTournament!.id)
                    .where('teamName', isEqualTo: teamName)
                    .limit(1)
                    .get();

                if (snapshot.docs.isNotEmpty) {
                  final existing = PointsTableEntry.fromFirestore(snapshot.docs.first);
                  setDialogState(() {
                    playedController.text = existing.played.toString();
                    wonController.text = existing.won.toString();
                    lostController.text = existing.lost.toString();
                    pointsController.text = existing.points.toString();
                    nrrController.text = existing.nrr.toStringAsFixed(3);
                  });
                }
              } catch (e) {
                debugPrint("Error fetching team stats: $e");
              }
            }

            Widget buildStepperField({
              required String label,
              required IconData icon,
              required TextEditingController controller,
              required VoidCallback onValueUpdated,
              Color iconColor = AppTheme.primary,
              bool allowNegative = false,
            }) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.8), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 16, color: iconColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Material(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              int current = int.tryParse(controller.text) ?? 0;
                              if (allowNegative || current > 0) {
                                controller.text = (current - 1).toString();
                                onValueUpdated();
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.remove, size: 18, color: AppTheme.textPrimary),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            keyboardType: const TextInputType.numberWithOptions(signed: true),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: (int.tryParse(controller.text) ?? 0) < 0 ? Colors.redAccent : AppTheme.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                              border: InputBorder.none,
                            ),
                            onChanged: (_) => onValueUpdated(),
                          ),
                        ),
                        Material(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              int current = int.tryParse(controller.text) ?? 0;
                              controller.text = (current + 1).toString();
                              onValueUpdated();
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.add, size: 18, color: AppTheme.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppTheme.border, width: 1.5),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(isEdit ? Icons.edit_note_rounded : Icons.add_chart_rounded, color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? "Edit Team Entry" : "Add Team Entry",
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Team Selection Dropdown
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('teams')
                            .snapshots(),
                        builder: (context, snapshot) {
                          List<String> registeredTeams = [];
                          if (snapshot.hasData) {
                            registeredTeams = snapshot.data!.docs
                                .map((doc) => (doc.data() as Map<String, dynamic>)['name']?.toString() ?? '')
                                .where((name) => name.isNotEmpty)
                                .toSet()
                                .toList();
                          }

                          if (selectedTeamName != null &&
                              selectedTeamName!.isNotEmpty &&
                              !registeredTeams.contains(selectedTeamName) &&
                              selectedTeamName != "__CUSTOM__") {
                            registeredTeams.add(selectedTeamName!);
                          }

                          if (selectedTeamName == null && registeredTeams.isNotEmpty && !isCustomTeam) {
                            selectedTeamName = registeredTeams.first;
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: isCustomTeam ? "__CUSTOM__" : selectedTeamName,
                                dropdownColor: Colors.white,
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                decoration: AppTheme.inputDecoration(
                                  label: "Select Team",
                                  prefixIcon: Icons.group_outlined,
                                ),
                                items: [
                                  ...registeredTeams.map((t) => DropdownMenuItem<String>(
                                    value: t,
                                    child: Text(t, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                                  )),
                                  const DropdownMenuItem<String>(
                                    value: "__CUSTOM__",
                                    child: Row(
                                      children: [
                                        Icon(Icons.add, color: AppTheme.primary, size: 18),
                                        SizedBox(width: 6),
                                        Text("+ Enter Custom Team", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val == "__CUSTOM__") {
                                    setDialogState(() {
                                      isCustomTeam = true;
                                      selectedTeamName = "__CUSTOM__";
                                    });
                                  } else if (val != null) {
                                    setDialogState(() {
                                      isCustomTeam = false;
                                      selectedTeamName = val;
                                      customTeamController.text = val;
                                    });
                                    if (!isEdit) {
                                      fetchTeamStats(val);
                                    }
                                  }
                                },
                              ),
                              if (isCustomTeam) ...[
                                const SizedBox(height: 12),
                                TextField(
                                  controller: customTeamController,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                                  decoration: AppTheme.inputDecoration(
                                    label: "Custom Team Name",
                                    prefixIcon: Icons.edit_outlined,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Played & Won Row with Steppers
                      Row(
                        children: [
                          Expanded(
                            child: buildStepperField(
                              label: "Played",
                              icon: Icons.sports_cricket_outlined,
                              controller: playedController,
                              onValueUpdated: () {
                                setDialogState(() {});
                              },
                              iconColor: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: buildStepperField(
                              label: "Won",
                              icon: Icons.emoji_events_outlined,
                              controller: wonController,
                              onValueUpdated: () {
                                updateFromWonLost();
                              },
                              iconColor: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Lost & Points Row with Steppers
                      Row(
                        children: [
                          Expanded(
                            child: buildStepperField(
                              label: "Lost",
                              icon: Icons.close_rounded,
                              controller: lostController,
                              onValueUpdated: () {
                                updateFromWonLost();
                              },
                              iconColor: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: buildStepperField(
                              label: "Points",
                              icon: Icons.score_outlined,
                              controller: pointsController,
                              allowNegative: true,
                              onValueUpdated: () {
                                setDialogState(() {});
                              },
                              iconColor: Colors.indigoAccent,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Net Run Rate Field with Auto Calculator Button
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nrrController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                              decoration: AppTheme.inputDecoration(
                                label: "Net Run Rate (NRR)",
                                prefixIcon: Icons.trending_up_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showNrrCalculatorDialog(nrrController, setDialogState),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                              foregroundColor: AppTheme.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.calculate_outlined, size: 18),
                            label: const Text("Calc NRR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text("Cancel", style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final teamName = isCustomTeam
                        ? customTeamController.text.trim()
                        : (selectedTeamName ?? customTeamController.text.trim());
                    final played = int.tryParse(playedController.text.trim()) ?? 0;
                    final won = int.tryParse(wonController.text.trim()) ?? 0;
                    final lost = int.tryParse(lostController.text.trim()) ?? 0;
                    final points = int.tryParse(pointsController.text.trim()) ?? 0;
                    final nrr = double.tryParse(nrrController.text.trim()) ?? 0.0;

                    if (teamName.isEmpty || teamName == "__CUSTOM__") {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select or enter a team name")),
                      );
                      return;
                    }

                    final entryData = PointsTableEntry(
                      id: isEdit ? entry.id : "",
                      tournamentId: _selectedTournament!.id,
                      tournamentName: _selectedTournament!.name,
                      teamName: teamName,
                      played: played,
                      won: won,
                      lost: lost,
                      nrr: nrr,
                      points: points,
                    );

                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    try {
                      final collection = FirebaseFirestore.instance.collection('points_tables');
                      if (isEdit) {
                        await collection.doc(entry.id).set(entryData.toFirestore());
                      } else {
                        await collection.add(entryData.toFirestore());
                      }

                      navigator.pop();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(isEdit ? "Standings updated successfully" : "Team added successfully"),
                          backgroundColor: AppTheme.primary,
                        ),
                      );
                    } catch (e) {
                      debugPrint("Error saving standings: $e");
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text("Error: ${e.toString()}"),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteEntry(String id) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Standings Entry?"),
        content: const Text("Are you sure you want to remove this team standings record?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('points_tables').doc(id).delete();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text("Standings entry deleted successfully!"),
            backgroundColor: AppTheme.primary,
          ),
        );
      } catch (e) {
        debugPrint("Error deleting standings entry: $e");
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("Error deleting standings entry: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String adminEmail = AdminSession.currentAdmin ?? "admin@cricpulse.com";

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _selectedTournament != null
          ? FloatingActionButton(
              backgroundColor: AppTheme.primary,
              onPressed: () => _showAddOrEditEntryDialog(),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Manage Standings (Points Table)",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 20),

            // Tournament Select Dropdown
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tournaments')
                  .where('createdBy', isEqualTo: adminEmail)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final tournaments = snapshot.data!.docs.map((d) => Tournament.fromFirestore(d)).toList();

                if (tournaments.isEmpty) {
                  return const Text("Create a tournament first before adding standings details.", style: TextStyle(color: AppTheme.textSecondary));
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
                  decoration: AppTheme.inputDecoration(label: "Select Tournament", prefixIcon: Icons.emoji_events),
                  items: tournaments.map((t) {
                    return DropdownMenuItem<Tournament>(value: t, child: Text(t.name, style: const TextStyle(fontSize: 14)));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedTournament = val;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Points Table Entries Grid/List
            Expanded(
              child: _selectedTournament == null
                  ? const SizedBox.shrink()
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('points_tables')
                          .where('tournamentId', isEqualTo: _selectedTournament!.id)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                        final docs = snapshot.data!.docs;
                        final entries = docs.map((d) => PointsTableEntry.fromFirestore(d)).toList();

                        // Sort by points desc, then by NRR desc
                        entries.sort((a, b) {
                          int pointsCompare = b.points.compareTo(a.points);
                          if (pointsCompare != 0) return pointsCompare;
                          return b.nrr.compareTo(a.nrr);
                        });

                        if (entries.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.table_chart_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                const Text("No standings recorded for this tournament.", style: TextStyle(color: AppTheme.textSecondary)),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => _showAddOrEditEntryDialog(),
                                  child: const Text("Add Team Standings"),
                                ),
                              ],
                            ),
                          );
                        }

                        return Container(
                          decoration: AppTheme.cardDecoration(),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              columns: const [
                                DataColumn(label: Text("Rank")),
                                DataColumn(label: Text("Team")),
                                DataColumn(label: Text("P")),
                                DataColumn(label: Text("W")),
                                DataColumn(label: Text("L")),
                                DataColumn(label: Text("NRR")),
                                DataColumn(label: Text("Points")),
                                DataColumn(label: Text("Actions")),
                              ],
                              rows: List.generate(entries.length, (index) {
                                final entry = entries[index];
                                return DataRow(
                                  cells: [
                                    DataCell(Text("${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text(entry.teamName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text("${entry.played}")),
                                    DataCell(Text("${entry.won}")),
                                    DataCell(Text("${entry.lost}")),
                                    DataCell(
                                      Text(
                                        entry.nrr >= 0 ? "+${entry.nrr.toStringAsFixed(3)}" : entry.nrr.toStringAsFixed(3),
                                        style: TextStyle(color: entry.nrr >= 0 ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataCell(Text("${entry.points}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary))),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                                            onPressed: () => _showAddOrEditEntryDialog(entry),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                            onPressed: () => _deleteEntry(entry.id),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

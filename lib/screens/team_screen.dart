import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_session.dart';
import '../theme.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = "";

  void _showAddOrEditTeamDialog([DocumentSnapshot? teamDoc]) {
    final isEdit = teamDoc != null;
    final nameController = TextEditingController(
      text: isEdit ? (teamDoc.data() as Map<String, dynamic>)['name'] ?? '' : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppTheme.border, width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.group_outlined, color: AppTheme.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                isEdit ? "Edit Team" : "Add Team",
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: _inputStyle("Team Name", Icons.group_outlined),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final adminEmail = AdminSession.currentAdmin ?? "admin@cricpulse.com";
                final collection = FirebaseFirestore.instance.collection('teams');
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                try {
                  if (isEdit) {
                    await collection.doc(teamDoc.id).update({'name': name});
                  } else {
                    await collection.add({
                      'name': name,
                      'createdBy': adminEmail,
                      'players': [],
                    });
                  }

                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? "Team updated successfully!" : "Team created successfully!"),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                } catch (e) {
                  debugPrint("Error saving team: $e");
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text("Error: ${e.toString()}"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
      prefixIcon: Icon(icon, color: AppTheme.primary, size: 18),
      filled: true,
      fillColor: const Color(0xFFF9FBFB),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFE0EBE6), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.6),
      ),
    );
  }

  void _showManagePlayersDialog(DocumentSnapshot teamDoc) {
    final Map<String, dynamic> data = teamDoc.data() as Map<String, dynamic>;
    final List<dynamic> players = data['players'] ?? [];

    final nameController = TextEditingController();
    String battingStyle = "Right-handed Bat";
    String bowlingStyle = "Right-arm Fast";
    final ageController = TextEditingController(text: "25");

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppTheme.border, width: 1.5),
              ),
              title: Row(
                children: [
                  const Icon(Icons.people_outline, color: AppTheme.primary, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Players of ${data['name']}",
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 550,
                height: 580, // Constrain height to fix RenderFlex crash
                child: Column(
                  children: [
                    // Add new player form
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F7F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Add Player to Squad",
                            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: nameController,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                            decoration: _inputStyle("Player Name", Icons.person_outline),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  initialValue: battingStyle,
                                  isExpanded: true,
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                  decoration: _inputStyle("Batting Style", Icons.sports_cricket_outlined),
                                  items: ["Right-handed Bat", "Left-handed Bat"].map((style) {
                                    return DropdownMenuItem<String>(
                                      value: style,
                                      child: Text(style, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() => battingStyle = val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  initialValue: bowlingStyle,
                                  isExpanded: true,
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                  decoration: _inputStyle("Bowling Style", Icons.sports_cricket_outlined),
                                  items: ["Right-arm Fast", "Right-arm Medium", "Right-arm Off-break", "Right-arm Leg-break", "Left-arm Fast", "Left-arm Orthodox", "None"].map((style) {
                                    return DropdownMenuItem<String>(
                                      value: style,
                                      child: Text(style, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() => bowlingStyle = val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<int>(
                                  initialValue: int.tryParse(ageController.text) ?? 25,
                                  isExpanded: true,
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                                  decoration: _inputStyle("Age", Icons.cake_outlined).copyWith(
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  ),
                                  items: List.generate(49, (i) => i + 12).map((ageVal) {
                                    return DropdownMenuItem<int>(
                                      value: ageVal,
                                      child: Text("$ageVal", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() {
                                        ageController.text = val.toString();
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.add, size: 16, color: Colors.white),
                              label: const Text("Add Player", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: () async {
                                final name = nameController.text.trim();
                                final age = int.tryParse(ageController.text.trim()) ?? 25;
                                if (name.isEmpty) return;

                                final newPlayer = {
                                  'name': name,
                                  'battingStyle': battingStyle,
                                  'bowlingStyle': bowlingStyle,
                                  'age': age,
                                };

                                try {
                                  final updatedPlayers = List.from(players)..add(newPlayer);
                                  await FirebaseFirestore.instance.collection('teams').doc(teamDoc.id).update({
                                    'players': updatedPlayers,
                                  });

                                  setDialogState(() {
                                    players.add(newPlayer);
                                    nameController.clear();
                                  });
                                } catch (e) {
                                  debugPrint("Error adding player: $e");
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Error adding player: ${e.toString()}"),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Registered players list
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Squad List",
                        style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: players.isEmpty
                          ? const Center(
                              child: Text(
                                "No players registered yet.",
                                style: TextStyle(color: AppTheme.textMuted),
                              ),
                            )
                          : ListView.builder(
                              itemCount: players.length,
                              itemBuilder: (context, index) {
                                final p = players[index] as Map<String, dynamic>;
                                return Card(
                                  color: const Color(0xFFF9FBFB),
                                  surfaceTintColor: Colors.transparent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: AppTheme.border, width: 1.0),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 6),
                                  child: ListTile(
                                    title: Text(
                                      p['name'] ?? '',
                                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    subtitle: Text(
                                      "Age: ${p['age']} | ${p['battingStyle']} | Bowl: ${p['bowlingStyle']}",
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 16),
                                      onPressed: () async {
                                        try {
                                          final updated = List.from(players)..removeAt(index);
                                          await FirebaseFirestore.instance.collection('teams').doc(teamDoc.id).update({
                                            'players': updated,
                                          });
                                          setDialogState(() {
                                            players.removeAt(index);
                                          });
                                        } catch (e) {
                                          debugPrint("Error removing player: $e");
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text("Error removing player: ${e.toString()}"),
                                                backgroundColor: Colors.redAccent,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteTeam(String id) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Team?"),
        content: const Text("This will permanently remove the team and all its registered players."),
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
        await FirebaseFirestore.instance.collection('teams').doc(id).delete();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text("Team deleted successfully!"),
            backgroundColor: AppTheme.primary,
          ),
        );
      } catch (e) {
        debugPrint("Error deleting team: $e");
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("Error deleting team: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String adminEmail = AdminSession.currentAdmin ?? "admin@cricpulse.com";

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => _showAddOrEditTeamDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Manage Teams & Squads",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    decoration: AppTheme.inputDecoration(label: "Search teams...", prefixIcon: Icons.search),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('teams')
                    .where('createdBy', isEqualTo: adminEmail)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data!.docs;
                  var filteredDocs = docs;

                  if (_searchQuery.isNotEmpty) {
                    filteredDocs = docs.where((doc) {
                      final name = ((doc.data() as Map<String, dynamic>)['name'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery);
                    }).toList();
                  }

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          const Text("No teams registered yet.", style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 350,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                      final List<dynamic> players = data['players'] ?? [];

                      return Container(
                        decoration: AppTheme.cardDecoration(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        data['name'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                                          onPressed: () => _showAddOrEditTeamDialog(doc),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                          onPressed: () => _deleteTeam(doc.id),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "${players.length} Players Registered",
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                icon: const Icon(Icons.people, color: Colors.white, size: 16),
                                label: const Text("Manage Squad", style: TextStyle(color: Colors.white, fontSize: 13)),
                                onPressed: () => _showManagePlayersDialog(doc),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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

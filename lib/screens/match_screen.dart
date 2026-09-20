import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/match.dart';
import '../admin_session.dart';
import '../theme.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedStatusFilter = "All";

  void _showScheduleMatchDialog([ScheduledMatch? matchToEdit]) {
    final isEdit = matchToEdit != null;

    final venueController = TextEditingController(text: matchToEdit?.venue ?? '');
    final timeController = TextEditingController(text: matchToEdit?.time ?? '');
    final resultController = TextEditingController(text: matchToEdit?.result ?? 'TBD');
    final tossController = TextEditingController(text: matchToEdit?.tossDecision ?? '');
    List<String> teamAPlayersList = matchToEdit?.teamAPlayers.map((p) => p.name).toList() ?? [];
    List<String> teamBPlayersList = matchToEdit?.teamBPlayers.map((p) => p.name).toList() ?? [];

    String? selectedTournamentId = matchToEdit?.tournamentId;
    String? selectedTournamentName = matchToEdit?.tournamentName;
    String? selectedTeamA = matchToEdit?.teamA;
    String? selectedTeamB = matchToEdit?.teamB;
    int overs = matchToEdit?.overs ?? 20;
    int players = matchToEdit?.playersPerSide ?? 11;
    String matchType = matchToEdit?.matchType ?? 'T20';
    String status = matchToEdit?.status ?? 'Upcoming';
    String? tossWinner;
    String? tossChoice;

    String? uploadedImageUrl = matchToEdit?.bannerPath;
    String? uploadedTeamALogoUrl = matchToEdit?.teamALogo;
    String? uploadedTeamBLogoUrl = matchToEdit?.teamBLogo;
    bool isUploading = false;
    bool isUploadingTeamALogo = false;
    bool isUploadingTeamBLogo = false;

    showDialog(
      context: context,
      builder: (context) {
        final String adminEmail = AdminSession.currentAdmin ?? "admin@cricpulse.com";

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> uploadLogo(bool isTeamA) async {
              try {
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 400,
                  maxHeight: 400,
                  imageQuality: 60,
                );
                if (image == null) return;
                
                final bytes = await image.readAsBytes();
                final base64Url = 'data:image/jpeg;base64,${base64Encode(bytes)}';

                // Instant preview - 0s delay for user
                setDialogState(() {
                  if (isTeamA) {
                    uploadedTeamALogoUrl = base64Url;
                    isUploadingTeamALogo = false;
                  } else {
                    uploadedTeamBLogoUrl = base64Url;
                    isUploadingTeamBLogo = false;
                  }
                });

                // Background storage sync
                try {
                  final fileName = 'logos/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
                  final ref = FirebaseStorage.instance.ref().child(fileName);
                  UploadTask uploadTask;
                  if (kIsWeb) {
                    uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
                  } else {
                    final file = File(image.path);
                    uploadTask = ref.putFile(file);
                  }
                  
                  final snapshot = await uploadTask.timeout(const Duration(milliseconds: 1500));
                  final url = await snapshot.ref.getDownloadURL().timeout(const Duration(milliseconds: 1500));
                  if (url.isNotEmpty) {
                    setDialogState(() {
                      if (isTeamA) uploadedTeamALogoUrl = url;
                      else uploadedTeamBLogoUrl = url;
                    });
                  }
                } catch (e) {
                  debugPrint("Background logo upload skipped, using instant Base64 preview: $e");
                }
              } catch (e) {
                setDialogState(() {
                  if (isTeamA) isUploadingTeamALogo = false;
                  else isUploadingTeamBLogo = false;
                });
                debugPrint("Logo upload failed: $e");
              }
            }

            Widget buildTeamLogoUploadWidget({
              required String? logoUrl,
              required bool isUploading,
              required VoidCallback onTap,
            }) {
              return Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border, width: 1),
                ),
                child: InkWell(
                  onTap: isUploading ? null : onTap,
                  child: Center(
                    child: isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                          )
                        : logoUrl != null && logoUrl.isNotEmpty
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(logoUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.edit, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ],
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primary, size: 22),
                                  SizedBox(height: 4),
                                  Text("Upload Logo", style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                                ],
                              ),
                  ),
                ),
              );
            }

            Future<void> pickAndUploadBanner() async {
              try {
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 800,
                  maxHeight: 500,
                  imageQuality: 60,
                );
                
                if (image == null) return;
                
                final bytes = await image.readAsBytes();
                final base64Url = 'data:image/jpeg;base64,${base64Encode(bytes)}';

                // Instant preview - zero wait time
                setDialogState(() {
                  uploadedImageUrl = base64Url;
                  isUploading = false;
                });

                // Asynchronous background upload attempt
                try {
                  final fileName = 'banners/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
                  final ref = FirebaseStorage.instance.ref().child(fileName);
                  
                  UploadTask uploadTask;
                  if (kIsWeb) {
                    uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
                  } else {
                    final file = File(image.path);
                    uploadTask = ref.putFile(file);
                  }
                  
                  final snapshot = await uploadTask.timeout(const Duration(milliseconds: 1500));
                  final url = await snapshot.ref.getDownloadURL().timeout(const Duration(milliseconds: 1500));
                  if (url.isNotEmpty) {
                    setDialogState(() {
                      uploadedImageUrl = url;
                    });
                  }
                } catch (e) {
                  debugPrint("Background upload timed out/skipped, using instant Base64 preview: $e");
                }
              } catch (e) {
                setDialogState(() {
                  isUploading = false;
                });
                debugPrint("Banner pick failed: $e");
              }
            }

            Widget bannerUploadSection() {
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: isUploading ? null : pickAndUploadBanner,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (uploadedImageUrl != null && uploadedImageUrl!.isNotEmpty) ...[
                          Image.network(
                            uploadedImageUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(),
                          ),
                          Container(
                            color: Colors.black.withValues(alpha: 0.3),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 28),
                              const SizedBox(height: 6),
                              const Text(
                                "Change Match Banner",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ] else if (isUploading) ...[
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Uploading Banner...",
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ] else ...[
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: AppTheme.primary,
                                size: 36,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Upload Match Banner",
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Recommended: 800x400 px",
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }

            void quickAddTeam(bool isTeamA) {
              final nameController = TextEditingController();
              final playersController = TextEditingController();

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
                        const Icon(Icons.group_add_outlined, color: AppTheme.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          isTeamA ? "Quick Add Team A" : "Quick Add Team B",
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                          decoration: _inputStyle("Team Name", Icons.group_outlined),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: playersController,
                          maxLines: 3,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          decoration: _inputStyle("Players (Comma separated)", Icons.people_outline),
                        ),
                      ],
                    ),
                    actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;

                          if ((isTeamA && selectedTeamB != null && name.toLowerCase() == selectedTeamB!.toLowerCase()) ||
                              (!isTeamA && selectedTeamA != null && name.toLowerCase() == selectedTeamA!.toLowerCase())) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Team A and Team B cannot be the same team!"),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          final playersList = playersController.text
                              .split(',')
                              .map((p) => p.trim())
                              .where((p) => p.isNotEmpty)
                              .map((p) => {
                                    'name': p,
                                    'battingStyle': 'Right-handed Bat',
                                    'bowlingStyle': 'Right-arm Fast',
                                    'age': 25,
                                  })
                              .toList();

                          try {
                            await FirebaseFirestore.instance.collection('teams').add({
                              'name': name,
                              'createdBy': adminEmail,
                              'players': playersList,
                            });

                            if (context.mounted) {
                              Navigator.pop(context);
                            }

                            final newPlayerNames = playersList.map((p) => p['name'] as String).toList();
                            setDialogState(() {
                              if (isTeamA) {
                                selectedTeamA = name;
                                teamAPlayersList = newPlayerNames;
                              } else {
                                selectedTeamB = name;
                                teamBPlayersList = newPlayerNames;
                              }
                            });
                          } catch (e) {
                            debugPrint("Quick add team failed: $e");
                          }
                        },
                        child: const Text("Add", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  );
                },
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
                  const Icon(Icons.calendar_today_outlined, color: AppTheme.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    isEdit ? "Edit Match Schedule" : "Schedule New Match",
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      // Banner section
                      bannerUploadSection(),

                      // Tournament selector (full width)
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('tournaments')
                            .where('createdBy', isEqualTo: adminEmail)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();
                          final list = snapshot.data!.docs;
                          return DropdownButtonFormField<String>(
                            initialValue: selectedTournamentId,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                            decoration: _inputStyle("Select Tournament", Icons.emoji_events_outlined),
                            items: list.map((doc) {
                              final name = doc['name'] ?? '';
                              return DropdownMenuItem<String>(value: doc.id, child: Text(name));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                final doc = list.firstWhere((d) => d.id == val);
                                final Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;
                                setDialogState(() {
                                  selectedTournamentId = val;
                                  selectedTournamentName = doc['name'];
                                  overs = doc['overs'] is int ? doc['overs'] as int : (doc['overs'] as num?)?.toInt() ?? 20;
                                  players = doc['playersPerSide'] is int ? doc['playersPerSide'] as int : (doc['playersPerSide'] as num?)?.toInt() ?? 11;
                                  venueController.text = docData['venue'] ?? 'TBD';
                                });
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Teams selectors
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('teams')
                            .where('createdBy', isEqualTo: adminEmail)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();
                          final list = snapshot.data!.docs;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: selectedTeamA,
                                      dropdownColor: Colors.white,
                                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                                      decoration: _inputStyle("Team A", Icons.group_outlined),
                                      items: [
                                        ...list.where((doc) => doc['name'] != selectedTeamB).map((doc) {
                                          final name = doc['name'] ?? '';
                                          return DropdownMenuItem<String>(value: name, child: Text(name));
                                        }),
                                        if (selectedTeamA != null && selectedTeamA != selectedTeamB && !list.any((d) => d['name'] == selectedTeamA))
                                          DropdownMenuItem<String>(value: selectedTeamA, child: Text(selectedTeamA!)),
                                        DropdownMenuItem<String>(
                                          value: "__ADD_NEW_TEAM__",
                                          child: Row(
                                            children: const [
                                              Icon(Icons.add, color: AppTheme.primary, size: 18),
                                              SizedBox(width: 6),
                                              Text("Add New Team", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val == "__ADD_NEW_TEAM__") {
                                          quickAddTeam(true);
                                          setDialogState(() {
                                            selectedTeamA = null;
                                          });
                                          return;
                                        }
                                        if (val != null) {
                                          if (val == selectedTeamB) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("Team A and Team B cannot be the same team!"),
                                                backgroundColor: Colors.redAccent,
                                              ),
                                            );
                                            return;
                                          }
                                          final doc = list.firstWhere((d) => d['name'] == val);
                                          final Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;
                                          final List<dynamic> pList = docData['players'] ?? [];
                                          final pNames = pList.map((p) => (p is Map ? (p['name'] ?? '') : p.toString()).toString()).where((n) => n.isNotEmpty).toList();
                                          final logo = docData['logoPath'] ?? '';
                                          setDialogState(() {
                                            selectedTeamA = val;
                                            teamAPlayersList = pNames;
                                            uploadedTeamALogoUrl = logo;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: selectedTeamB,
                                      dropdownColor: Colors.white,
                                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                                      decoration: _inputStyle("Team B", Icons.group_outlined),
                                      items: [
                                        ...list.where((doc) => doc['name'] != selectedTeamA).map((doc) {
                                          final name = doc['name'] ?? '';
                                          return DropdownMenuItem<String>(value: name, child: Text(name));
                                        }),
                                        if (selectedTeamB != null && selectedTeamB != selectedTeamA && !list.any((d) => d['name'] == selectedTeamB))
                                          DropdownMenuItem<String>(value: selectedTeamB, child: Text(selectedTeamB!)),
                                        DropdownMenuItem<String>(
                                          value: "__ADD_NEW_TEAM__",
                                          child: Row(
                                            children: const [
                                              Icon(Icons.add, color: AppTheme.primary, size: 18),
                                              SizedBox(width: 6),
                                              Text("Add New Team", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val == "__ADD_NEW_TEAM__") {
                                          quickAddTeam(false);
                                          setDialogState(() {
                                            selectedTeamB = null;
                                          });
                                          return;
                                        }
                                        if (val != null) {
                                          if (val == selectedTeamA) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("Team A and Team B cannot be the same team!"),
                                                backgroundColor: Colors.redAccent,
                                              ),
                                            );
                                            return;
                                          }
                                          final doc = list.firstWhere((d) => d['name'] == val);
                                          final Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;
                                          final List<dynamic> pList = docData['players'] ?? [];
                                          final pNames = pList.map((p) => (p is Map ? (p['name'] ?? '') : p.toString()).toString()).where((n) => n.isNotEmpty).toList();
                                          final logo = docData['logoPath'] ?? '';
                                          setDialogState(() {
                                            selectedTeamB = val;
                                            teamBPlayersList = pNames;
                                            uploadedTeamBLogoUrl = logo;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Team A & B Logos
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Team A Logo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textSecondary)),
                                const SizedBox(height: 6),
                                buildTeamLogoUploadWidget(
                                  logoUrl: uploadedTeamALogoUrl,
                                  isUploading: isUploadingTeamALogo,
                                  onTap: () => uploadLogo(true),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Team B Logo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textSecondary)),
                                const SizedBox(height: 6),
                                buildTeamLogoUploadWidget(
                                  logoUrl: uploadedTeamBLogoUrl,
                                  isUploading: isUploadingTeamBLogo,
                                  onTap: () => uploadLogo(false),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Automatic Squad Preview Dropdowns (Expandable)
                      if ((selectedTeamA != null && teamAPlayersList.isNotEmpty) || (selectedTeamB != null && teamBPlayersList.isNotEmpty)) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (selectedTeamA != null && teamAPlayersList.isNotEmpty)
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F7F5),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: ExpansionTile(
                                    dense: true,
                                    tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    title: Text(
                                      "$selectedTeamA Squad (${teamAPlayersList.length})",
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                    ),
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: teamAPlayersList.map((name) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppTheme.border),
                                            ),
                                            child: Text(name, style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                                          )).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (selectedTeamA != null && teamAPlayersList.isNotEmpty && selectedTeamB != null && teamBPlayersList.isNotEmpty)
                              const SizedBox(width: 12),
                            if (selectedTeamB != null && teamBPlayersList.isNotEmpty)
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F7F5),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: ExpansionTile(
                                    dense: true,
                                    tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    title: Text(
                                      "$selectedTeamB Squad (${teamBPlayersList.length})",
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                    ),
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: teamBPlayersList.map((name) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppTheme.border),
                                            ),
                                            child: Text(name, style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                                          )).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],



                      // Time selection field (Date removed)
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final TimeOfDay? pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: AppTheme.primary,
                                          onPrimary: Colors.white,
                                          onSurface: AppTheme.textPrimary,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (pickedTime != null) {
                                  final hour = pickedTime.hour > 12 ? pickedTime.hour - 12 : (pickedTime.hour == 0 ? 12 : pickedTime.hour);
                                  final amPm = pickedTime.hour >= 12 ? "PM" : "AM";
                                  final minuteStr = pickedTime.minute.toString().padLeft(2, '0');
                                  final formattedStr = "$hour:$minuteStr $amPm";
                                  
                                  setDialogState(() {
                                    timeController.text = formattedStr;
                                  });
                                }
                              },
                              child: IgnorePointer(
                                child: TextField(
                                  controller: timeController,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                                  decoration: _inputStyle("Start Time (Select)", Icons.access_time_outlined),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Overs per side & Status row (Match Type replaced by Overs)
                      Row(
                        children: [
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final oversOptions = List.generate(50, (i) => i + 1);
                                if (!oversOptions.contains(overs)) {
                                  oversOptions.add(overs);
                                  oversOptions.sort();
                                }
                                return DropdownButtonFormField<int>(
                                  initialValue: overs,
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                                  decoration: _inputStyle("Overs Per Side", Icons.sports_cricket_outlined),
                                  items: oversOptions.map((int val) {
                                    return DropdownMenuItem<int>(
                                      value: val,
                                      child: Text("$val ${val == 1 ? 'Over' : 'Overs'}"),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() {
                                        overs = val;
                                        matchType = val == 20 ? "T20" : (val == 10 ? "T10" : "$val ${val == 1 ? 'Over' : 'Overs'}");
                                      });
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: status,
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                              decoration: _inputStyle("Status", Icons.info_outline),
                              items: ["Upcoming", "Live", "Finished"].map((st) {
                                return DropdownMenuItem<String>(value: st, child: Text(st));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => status = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Toss decision interactive selector section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAF9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.toll_outlined, size: 16, color: AppTheme.primary),
                                SizedBox(width: 6),
                                Text(
                                  "Toss Decision (Select)",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<String>(
                                    value: (selectedTeamA != null && tossWinner == selectedTeamA)
                                        ? selectedTeamA
                                        : ((selectedTeamB != null && tossWinner == selectedTeamB) ? selectedTeamB : null),
                                    dropdownColor: Colors.white,
                                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                    decoration: _inputStyle("Toss Winner", Icons.emoji_events_outlined),
                                    items: [
                                      if (selectedTeamA != null) DropdownMenuItem(value: selectedTeamA, child: Text(selectedTeamA!)),
                                      if (selectedTeamB != null) DropdownMenuItem(value: selectedTeamB, child: Text(selectedTeamB!)),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setDialogState(() {
                                          tossWinner = val;
                                          tossChoice ??= "bat first";
                                          tossController.text = "$tossWinner won the toss & elected to $tossChoice";
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    value: tossChoice ?? "bat first",
                                    dropdownColor: Colors.white,
                                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                    decoration: _inputStyle("Choice", Icons.sports_cricket_outlined),
                                    items: const [
                                      DropdownMenuItem(value: "bat first", child: Text("Bat First")),
                                      DropdownMenuItem(value: "bowl first", child: Text("Bowl First")),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setDialogState(() {
                                          tossChoice = val;
                                          if (tossWinner != null) {
                                            tossController.text = "$tossWinner won the toss & elected to $tossChoice";
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: tossController,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                              decoration: _inputStyle("Toss Summary (Auto-filled or Custom)", Icons.edit_note),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Match Result interactive selector section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAF9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.emoji_events_outlined, size: 16, color: AppTheme.primary),
                                SizedBox(width: 6),
                                Text(
                                  "Match Result (Select Option)",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                ChoiceChip(
                                  label: const Text("TBD (Upcoming)"),
                                  selected: resultController.text == "TBD",
                                  selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setDialogState(() {
                                        resultController.text = "TBD";
                                      });
                                    }
                                  },
                                ),
                                if (selectedTeamA != null)
                                  ChoiceChip(
                                    label: Text("$selectedTeamA Won"),
                                    selected: resultController.text.contains(selectedTeamA!),
                                    selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setDialogState(() {
                                          resultController.text = "$selectedTeamA won the match";
                                        });
                                      }
                                    },
                                  ),
                                if (selectedTeamB != null)
                                  ChoiceChip(
                                    label: Text("$selectedTeamB Won"),
                                    selected: resultController.text.contains(selectedTeamB!),
                                    selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setDialogState(() {
                                          resultController.text = "$selectedTeamB won the match";
                                        });
                                      }
                                    },
                                  ),
                                ChoiceChip(
                                  label: const Text("Match Tied"),
                                  selected: resultController.text == "Match Tied",
                                  selectedColor: Colors.amber.withValues(alpha: 0.25),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setDialogState(() {
                                        resultController.text = "Match Tied";
                                      });
                                    }
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text("No Result / Abandoned"),
                                  selected: resultController.text.contains("No Result"),
                                  selectedColor: Colors.red.withValues(alpha: 0.2),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setDialogState(() {
                                        resultController.text = "No Result (Match Abandoned)";
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: resultController,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                              decoration: _inputStyle("Match Result (Auto-filled or Custom)", Icons.edit_note),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.black12, height: 24, thickness: 1),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                   onPressed: () async {
                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    final venue = venueController.text.trim().isNotEmpty ? venueController.text.trim() : (matchToEdit?.venue ?? 'TBD');
                    final time = timeController.text.trim();
                    final toss = tossController.text.trim();
                    final res = resultController.text.trim();
                    final banner = uploadedImageUrl ?? "https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=800&auto=format&fit=crop";

                    if (selectedTournamentId == null || selectedTeamA == null || selectedTeamB == null) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text("Please select a Tournament, Team A and Team B")),
                      );
                      return;
                    }

                    if (selectedTeamA == selectedTeamB) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text("Team A and Team B cannot be the same team! Please select two different teams."),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    // Query squads players to preserve profiles
                    List<dynamic> dbTeamAPlayers = [];
                    List<dynamic> dbTeamBPlayers = [];
                    
                    final teamsCollection = FirebaseFirestore.instance.collection('teams');
                    final teamADoc = await teamsCollection.where('createdBy', isEqualTo: adminEmail).where('name', isEqualTo: selectedTeamA).limit(1).get();
                    final teamBDoc = await teamsCollection.where('createdBy', isEqualTo: adminEmail).where('name', isEqualTo: selectedTeamB).limit(1).get();

                    if (teamADoc.docs.isNotEmpty) {
                      dbTeamAPlayers = teamADoc.docs.first['players'] ?? [];
                    }
                    if (teamBDoc.docs.isNotEmpty) {
                      dbTeamBPlayers = teamBDoc.docs.first['players'] ?? [];
                    }

                    List<Map<String, dynamic>> buildRoster(String input, List<dynamic> dbPlayers) {
                      return input.split(',')
                          .map((name) => name.trim())
                          .where((name) => name.isNotEmpty)
                          .map((name) {
                            final matched = dbPlayers.firstWhere(
                              (p) => (p is Map ? p['name'] : p.toString()).toString().toLowerCase() == name.toLowerCase(),
                              orElse: () => null,
                            );
                            if (matched is Map) {
                              return {
                                'name': name,
                                'battingStyle': matched['battingStyle'] ?? 'Right-handed Bat',
                                'bowlingStyle': matched['bowlingStyle'] ?? 'Right-arm Fast',
                                'age': matched['age'] ?? 25,
                              };
                            }
                            return {
                              'name': name,
                              'battingStyle': 'Right-handed Bat',
                              'bowlingStyle': 'Right-arm Fast',
                              'age': 25,
                            };
                          }).toList();
                    }

                    final List<Map<String, dynamic>> finalTeamAPlayers = buildRoster(teamAPlayersList.join(', '), dbTeamAPlayers);
                    final List<Map<String, dynamic>> finalTeamBPlayers = buildRoster(teamBPlayersList.join(', '), dbTeamBPlayers);

                    final matchData = {
                      'tournamentId': selectedTournamentId,
                      'tournamentName': selectedTournamentName,
                      'teamA': selectedTeamA,
                      'teamB': selectedTeamB,
                      'venue': venue,
                      'date': '',
                      'time': time,
                      'overs': overs,
                      'playersPerSide': players,
                      'matchType': matchType,
                      'status': status,
                      'tossDecision': toss,
                      'result': res,
                      'organizerName': '',
                      'contactDetails': '',
                      'bannerPath': banner,
                      'teamALogo': uploadedTeamALogoUrl ?? '',
                      'teamBLogo': uploadedTeamBLogoUrl ?? '',
                      'createdBy': adminEmail,
                      'teamAPlayers': finalTeamAPlayers,
                      'teamBPlayers': finalTeamBPlayers,
                    };


                    try {
                      final matchesCol = FirebaseFirestore.instance.collection('matches');
                      if (isEdit) {
                        await matchesCol.doc(matchToEdit.id).update(matchData);
                      } else {
                        // Also add an empty live score sheet in firestore matches/scorecards
                        final newMatchRef = await matchesCol.add(matchData);
                        await FirebaseFirestore.instance.collection('scorecards').doc(newMatchRef.id).set({
                          'matchId': newMatchRef.id,
                          'runs': 0,
                          'wickets': 0,
                          'overs': 0,
                          'balls': 0,
                          'target': 0,
                          'innings': 1,
                          'battingTeam': selectedTeamA,
                          'bowlingTeam': selectedTeamB,
                          'batsman1': 'Striker',
                          'batsman1Runs': 0,
                          'batsman2': 'Non-Striker',
                          'batsman2Runs': 0,
                          'bowler': 'Bowler',
                          'bowlerWickets': 0,
                          'bowlerRuns': 0,
                          'history': [],
                        });
                      }

                      navigator.pop();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(isEdit ? "Match updated!" : "Match scheduled!"),
                          backgroundColor: AppTheme.primary,
                        ),
                      );
                    } catch (e) {
                      debugPrint("Error saving match: $e");
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text("Error: ${e.toString()}"),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  child: Text(
                    isEdit ? "Save" : "Schedule",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteMatch(String id) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Match?"),
        content: const Text("This will permanently delete this fixture and its live scoring records."),
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
        await FirebaseFirestore.instance.collection('matches').doc(id).delete();
        await FirebaseFirestore.instance.collection('scorecards').doc(id).delete();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text("Match fixture and scorecard deleted successfully!"),
            backgroundColor: AppTheme.primary,
          ),
        );
      } catch (e) {
        debugPrint("Error deleting match: $e");
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("Error deleting match: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      filled: true,
      fillColor: const Color(0xFFF9FBF9),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFE0EBE6), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.6),
      ),
    );
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
        onPressed: () => _showScheduleMatchDialog(),
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
                  "Manage Fixtures",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: _selectedStatusFilter,
                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                      items: ["All", "Upcoming", "Live", "Finished"].map((st) {
                        return DropdownMenuItem(value: st, child: Text(st));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatusFilter = val);
                      },
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 250,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                        decoration: AppTheme.inputDecoration(label: "Search matches...", prefixIcon: Icons.search),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('matches')
                    .where('createdBy', isEqualTo: adminEmail)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data!.docs;
                  var matches = docs.map((d) => ScheduledMatch.fromFirestore(d)).toList();

                  if (_selectedStatusFilter != "All") {
                    matches = matches.where((m) => m.status == _selectedStatusFilter).toList();
                  }

                  if (_searchQuery.isNotEmpty) {
                    matches = matches.where((m) {
                      return m.teamA.toLowerCase().contains(_searchQuery) ||
                          m.teamB.toLowerCase().contains(_searchQuery) ||
                          m.tournamentName.toLowerCase().contains(_searchQuery);
                    }).toList();
                  }

                  if (matches.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_cricket_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          const Text("No fixtures matched this filter.", style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final m = matches[index];
                      Color statusColor = Colors.orange;
                      if (m.status == 'Live') statusColor = Colors.redAccent;
                      if (m.status == 'Finished') statusColor = Colors.green;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(Icons.sports_cricket, color: AppTheme.primary, size: 32),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${m.teamA} vs ${m.teamB}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "League: ${m.tournamentName}  |  Type: ${m.matchType}",
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Schedule: ${m.date} at ${m.time}  |  Venue: ${m.venue}",
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      m.status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                    onPressed: () => _showScheduleMatchDialog(m),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () => _deleteMatch(m.id),
                                  ),
                                ],
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
      ),
    );
  }
}

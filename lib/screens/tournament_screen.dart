import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/tournament.dart';
import '../admin_session.dart';
import '../theme.dart';

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = "";

  void _showAddOrEditTournamentDialog([Tournament? tournament]) {
    final isEdit = tournament != null;
    final nameController = TextEditingController(text: tournament?.name ?? '');
    final firstPrizeController = TextEditingController(text: tournament?.firstPlacePrize ?? '');
    final secondPrizeController = TextEditingController(text: tournament?.secondPlacePrize ?? '');
    final venueController = TextEditingController(text: tournament?.venue ?? '');
    final startTimeController = TextEditingController(text: tournament?.startTime ?? '');
    final organizerController = TextEditingController(text: tournament?.organizerName ?? '');
    final contactController = TextEditingController(text: tournament?.contactDetails ?? '');
    final descriptionController = TextEditingController(text: tournament?.description ?? '');
    final championController = TextEditingController(text: tournament?.champion ?? '');
    final runnerUpController = TextEditingController(text: tournament?.runnerUp ?? '');
    final playerOfTheTournamentController = TextEditingController(text: tournament?.playerOfTheTournament ?? '');
    final bestBatterController = TextEditingController(text: tournament?.bestBatter ?? '');
    final bestBowlerController = TextEditingController(text: tournament?.bestBowler ?? '');
    
    final oversController = TextEditingController(text: tournament?.overs.toString() ?? '20');
    final playersController = TextEditingController(text: tournament?.playersPerSide.toString() ?? '11');
    
    String? uploadedImageUrl = tournament?.bannerPath;
    bool isUploading = false;
    String status = tournament?.status ?? 'Active';
    String dayNight = tournament?.dayNight ?? 'Day';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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

                // Instant preview for zero delay
                setDialogState(() {
                  uploadedImageUrl = base64Url;
                  isUploading = false;
                });

                // Background storage upload
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
                debugPrint("Upload failed: $e");
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to upload image: $e")),
                  );
                }
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
                                "Change Tournament Banner",
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
                                "Upload Tournament Banner",
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

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppTheme.border, width: 1.5),
              ),
              title: Row(
                children: [
                  const Icon(Icons.emoji_events_outlined, color: AppTheme.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    isEdit ? "Edit Tournament" : "Create Tournament",
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 550,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      // Banner upload block
                      bannerUploadSection(),
                      
                      // Row 1: Tournament Name
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        decoration: _inputStyle("Tournament Name", Icons.emoji_events_outlined),
                      ),
                      const SizedBox(height: 16),
                      
                      // Row 2: Number of Overs (Dropdown 1 to 50 overs)
                      Builder(
                        builder: (context) {
                          final currentVal = int.tryParse(oversController.text) ?? 20;
                          final oversOptions = List.generate(50, (i) => i + 1);
                          if (!oversOptions.contains(currentVal)) {
                            oversOptions.add(currentVal);
                            oversOptions.sort();
                          }
                          return DropdownButtonFormField<int>(
                            initialValue: currentVal,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                            decoration: _inputStyle("Number of Overs", Icons.sports_cricket_outlined),
                            items: oversOptions.map((int val) {
                              return DropdownMenuItem<int>(
                                value: val,
                                child: Text("$val ${val == 1 ? 'Over' : 'Overs'}"),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  oversController.text = val.toString();
                                });
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Row 3: 1st Place & 2nd Place Prizes
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: firstPrizeController,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                              decoration: _inputStyle("1st Place Prize", Icons.monetization_on_outlined),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: secondPrizeController,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                              decoration: _inputStyle("2nd Place Prize", Icons.money_outlined),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Row 4: Organizer Name
                      TextField(
                        controller: organizerController,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        decoration: _inputStyle("Organizer Name", Icons.business_outlined),
                      ),
                      const SizedBox(height: 16),

                      // Row 5: Contact Details
                      TextField(
                        controller: contactController,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        keyboardType: TextInputType.phone,
                        decoration: _inputStyle("Contact Details", Icons.phone_outlined),
                      ),
                      const SizedBox(height: 16),

                      // Row 6: Venue
                      TextField(
                        controller: venueController,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        decoration: _inputStyle("Venue (e.g. Colombo Stadium)", Icons.location_on_outlined),
                      ),
                      const SizedBox(height: 16),

                      // Row 7: Start Time & Players/Side
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2025),
                                  lastDate: DateTime(2035),
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
                                if (pickedDate != null) {
                                  final months = [
                                    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
                                  ];
                                  final monthStr = months[pickedDate.month - 1];
                                  final formattedStr = "$monthStr ${pickedDate.day}, ${pickedDate.year}";
                                  
                                  setDialogState(() {
                                    startTimeController.text = formattedStr;
                                  });
                                }
                              },
                              child: IgnorePointer(
                                child: TextField(
                                  controller: startTimeController,
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                                  decoration: _inputStyle("Start Date (Select)", Icons.calendar_today_outlined),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: int.tryParse(playersController.text) ?? 11,
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                              decoration: _inputStyle("Players/Side", Icons.group_outlined),
                              items: [5, 6, 7, 8, 9, 10, 11].map((int val) {
                                return DropdownMenuItem<int>(
                                  value: val,
                                  child: Text("$val Players"),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    playersController.text = val.toString();
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Row 8: Status & Day/Night Dropdowns
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: status,
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                              decoration: _inputStyle("Tournament Status", Icons.info_outline),
                              items: const [
                                DropdownMenuItem(value: "Active", child: Text("Active")),
                                DropdownMenuItem(value: "Completed", child: Text("Completed")),
                                DropdownMenuItem(value: "Upcoming", child: Text("Upcoming")),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => status = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: dayNight,
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                              decoration: _inputStyle("Day/Night Type", Icons.wb_sunny_outlined),
                              items: const [
                                DropdownMenuItem(value: "Day", child: Text("Day Only")),
                                DropdownMenuItem(value: "Day/Night", child: Text("Day/Night")),
                                DropdownMenuItem(value: "Night", child: Text("Night Only")),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => dayNight = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description Area
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        decoration: _inputStyle("Tournament Description", Icons.description_outlined),
                      ),
                      const SizedBox(height: 16),

                      // Tournament Awards Fields (Man of the Tournament, Best Batter, Best Bowler, Champion, Runner-Up)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Tournament Awards & Individual Honors",
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: championController,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                              decoration: _inputStyle("Champion Team", Icons.emoji_events),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: runnerUpController,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                              decoration: _inputStyle("Runner-Up Team", Icons.emoji_events_outlined),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: playerOfTheTournamentController,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        decoration: _inputStyle("Man of the Tournament", Icons.star_rounded),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: bestBatterController,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                              decoration: _inputStyle("Best Batter of Tournament", Icons.sports_cricket_outlined),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: bestBowlerController,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                              decoration: _inputStyle("Best Bowler of Tournament", Icons.sports_baseball_outlined),
                            ),
                          ),
                        ],
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
                    final name = nameController.text.trim();
                    final venue = venueController.text.trim();
                    final time = startTimeController.text.trim();
                    final prize1 = firstPrizeController.text.trim();
                    final prize2 = secondPrizeController.text.trim();
                    final org = organizerController.text.trim();
                    final contact = contactController.text.trim();
                    final desc = descriptionController.text.trim();
                    final int overs = int.tryParse(oversController.text.trim()) ?? 20;
                    final int players = int.tryParse(playersController.text.trim()) ?? 11;
                    
                    final banner = uploadedImageUrl ?? "https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=800&auto=format&fit=crop";

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill tournament name")),
                      );
                      return;
                    }

                    final adminEmail = AdminSession.currentAdmin ?? "admin@cricpulse.com";

                    final data = {
                      'name': name,
                      'overs': overs,
                      'playersPerSide': players,
                      'venue': venue,
                      'startTime': time,
                      'firstPlacePrize': prize1,
                      'secondPlacePrize': prize2,
                      'organizerName': org,
                      'contactDetails': contact,
                      'bannerPath': banner,
                      'status': status,
                      'createdBy': adminEmail,
                      'description': desc,
                      'champion': championController.text.trim(),
                      'runnerUp': runnerUpController.text.trim(),
                      'playerOfTheTournament': playerOfTheTournamentController.text.trim(),
                      'bestBatter': bestBatterController.text.trim(),
                      'bestBowler': bestBowlerController.text.trim(),
                      'dayNight': dayNight,
                    };

                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    try {
                      final collection = FirebaseFirestore.instance.collection('tournaments');
                      if (isEdit) {
                        await collection.doc(tournament.id).update(data);
                      } else {
                        await collection.add(data);
                      }

                      navigator.pop();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(isEdit ? "Tournament updated!" : "Tournament created!"),
                          backgroundColor: AppTheme.primary,
                        ),
                      );
                    } catch (e) {
                      debugPrint("Error saving tournament: $e");
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text("Error: ${e.toString()}"),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  child: Text(
                    isEdit ? "Save" : "Create",
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

  Future<void> _deleteTournament(String id) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Tournament?"),
        content: const Text("This will permanently delete this tournament and its fixtures."),
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
        await FirebaseFirestore.instance.collection('tournaments').doc(id).delete();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text("Tournament deleted successfully!"),
            backgroundColor: AppTheme.primary,
          ),
        );
      } catch (e) {
        debugPrint("Error deleting tournament: $e");
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
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
        onPressed: () => _showAddOrEditTournamentDialog(),
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
                  "Manage Tournaments",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    decoration: AppTheme.inputDecoration(label: "Search tournaments...", prefixIcon: Icons.search),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tournaments')
                    .where('createdBy', isEqualTo: adminEmail)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  var tournaments = docs.map((d) => Tournament.fromFirestore(d)).toList();

                  if (_searchQuery.isNotEmpty) {
                    tournaments = tournaments
                        .where((t) => t.name.toLowerCase().contains(_searchQuery) || t.venue.toLowerCase().contains(_searchQuery))
                        .toList();
                  }

                  if (tournaments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          const Text("No tournaments created yet.", style: TextStyle(color: AppTheme.textSecondary)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => _showAddOrEditTournamentDialog(),
                            child: const Text("Create First Tournament"),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: tournaments.length,
                    itemBuilder: (context, index) {
                      final t = tournaments[index];
                      Color statusBgColor;
                      Color statusTextColor;
                      switch (t.status) {
                        case 'Active':
                          statusBgColor = Colors.green.shade50;
                          statusTextColor = Colors.green.shade700;
                          break;
                        case 'Upcoming':
                          statusBgColor = Colors.blue.shade50;
                          statusTextColor = Colors.blue.shade700;
                          break;
                        case 'Completed':
                          statusBgColor = Colors.amber.shade50;
                          statusTextColor = Colors.amber.shade800;
                          break;
                        default:
                          statusBgColor = Colors.blueGrey.shade50;
                          statusTextColor = Colors.blueGrey.shade700;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 1,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              t.bannerPath,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                width: 80,
                                height: 80,
                                child: const Icon(Icons.emoji_events, color: AppTheme.primary),
                              ),
                            ),
                          ),
                          title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(t.venue, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.sports_cricket, size: 14, color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Text("${t.overs} Overs  |  ${t.playersPerSide} Players per side",
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  t.status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: statusTextColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                onPressed: () => _showAddOrEditTournamentDialog(t),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _deleteTournament(t.id),
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

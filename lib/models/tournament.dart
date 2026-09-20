import 'package:cloud_firestore/cloud_firestore.dart';

class Tournament {
  final String id;
  final String name;
  final int overs;
  final String firstPlacePrize;
  final String secondPlacePrize;
  final String bannerPath; // Image path or URL
  final String organizerName;
  final String contactDetails;
  final String status;
  final String venue;
  final String startTime;
  final int playersPerSide;
  final String createdBy;
  final String champion;
  final String runnerUp;
  final String semiFinalists;
  final String playerOfTheTournament;
  final String description;
  final String bestBatter;
  final String bestBowler;
  final String dayNight;

  Tournament({
    required this.id,
    required this.name,
    required this.overs,
    required this.firstPlacePrize,
    required this.secondPlacePrize,
    required this.bannerPath,
    required this.organizerName,
    required this.contactDetails,
    this.status = "Active",
    required this.venue,
    required this.startTime,
    required this.playersPerSide,
    required this.createdBy,
    this.champion = "",
    this.runnerUp = "",
    this.semiFinalists = "",
    this.playerOfTheTournament = "",
    this.description = "",
    this.bestBatter = "",
    this.bestBowler = "",
    this.dayNight = "Day",
  });

  factory Tournament.fromFirestore(DocumentSnapshot doc) {
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

    return Tournament(
      id: doc.id,
      name: data['name'] ?? '',
      overs: parseInt(data['overs'], 20),
      firstPlacePrize: data['firstPlacePrize'] ?? '',
      secondPlacePrize: data['secondPlacePrize'] ?? '',
      bannerPath: data['bannerPath'] ?? '',
      organizerName: data['organizerName'] ?? '',
      contactDetails: data['contactDetails'] ?? '',
      status: data['status'] ?? 'Active',
      venue: data['venue'] ?? 'TBD',
      startTime: data['startTime'] ?? 'TBD',
      playersPerSide: parseInt(data['playersPerSide'], 11),
      createdBy: data['createdBy'] ?? '',
      champion: data['champion'] ?? '',
      runnerUp: data['runnerUp'] ?? '',
      semiFinalists: data['semiFinalists'] ?? '',
      playerOfTheTournament: data['playerOfTheTournament'] ?? '',
      description: data['description'] ?? '',
      bestBatter: data['bestBatter'] ?? '',
      bestBowler: data['bestBowler'] ?? '',
      dayNight: data['dayNight'] ?? 'Day',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'overs': overs,
      'firstPlacePrize': firstPlacePrize,
      'secondPlacePrize': secondPlacePrize,
      'bannerPath': bannerPath,
      'organizerName': organizerName,
      'contactDetails': contactDetails,
      'status': status,
      'venue': venue,
      'startTime': startTime,
      'playersPerSide': playersPerSide,
      'createdBy': createdBy,
      'champion': champion,
      'runnerUp': runnerUp,
      'semiFinalists': semiFinalists,
      'playerOfTheTournament': playerOfTheTournament,
      'description': description,
      'bestBatter': bestBatter,
      'bestBowler': bestBowler,
      'dayNight': dayNight,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tournament &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

final List<Tournament> tournamentsList = [
  Tournament(
    id: "1",
    name: "Lanka Premier Cup 2026",
    overs: 20,
    firstPlacePrize: "LKR 500,000",
    secondPlacePrize: "LKR 250,000",
    bannerPath:
        "https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=800&auto=format&fit=crop",
    organizerName: "Sri Lanka Cricket",
    contactDetails: "0112345678",
    status: "Active",
    venue: "R. Premadasa Stadium, Colombo",
    startTime: "June 20, 2026 - 10:00 AM",
    playersPerSide: 11,
    createdBy: 'admin',
    champion: "",
    runnerUp: "",
    semiFinalists: "",
    playerOfTheTournament: "",
  ),
  Tournament(
    id: "2",
    name: "Colombo T10 Blast",
    overs: 10,
    firstPlacePrize: "LKR 300,000",
    secondPlacePrize: "LKR 150,000",
    bannerPath:
        "https://images.unsplash.com/photo-1540747737956-37872404f8c1?w=800&auto=format&fit=crop",
    organizerName: "Colombo Cricket Club",
    contactDetails: "0777654321",
    status: "Active",
    venue: "CCC Grounds, Colombo",
    startTime: "July 05, 2026 - 02:00 PM",
    playersPerSide: 11,
    createdBy: 'admin',
    champion: "",
    runnerUp: "",
    semiFinalists: "",
    playerOfTheTournament: "",
  ),
];

import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerDetails {
  final String name;
  final String battingStyle;
  final String bowlingStyle;
  final int age;

  PlayerDetails({
    required this.name,
    required this.battingStyle,
    required this.bowlingStyle,
    required this.age,
  });

  factory PlayerDetails.fromMap(Map<String, dynamic> map) {
    return PlayerDetails(
      name: map['name'] ?? '',
      battingStyle: map['battingStyle'] ?? 'Right-handed Bat',
      bowlingStyle: map['bowlingStyle'] ?? 'Right-arm Fast',
      age: map['age'] is int ? map['age'] : (int.tryParse(map['age']?.toString() ?? '') ?? 25),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'battingStyle': battingStyle,
      'bowlingStyle': bowlingStyle,
      'age': age,
    };
  }
}

List<PlayerDetails> _parsePlayersList(dynamic list) {
  if (list == null) return [];
  if (list is List) {
    return list.map((item) {
      if (item is Map) {
        return PlayerDetails.fromMap(Map<String, dynamic>.from(item));
      } else {
        // Handle legacy string format
        return PlayerDetails(
          name: item.toString(),
          battingStyle: 'Right-handed Bat',
          bowlingStyle: 'Right-arm Fast',
          age: 25,
        );
      }
    }).toList();
  }
  return [];
}

class ScheduledMatch {
  final String id;
  final String teamA;
  final String teamB;
  final String date;
  final String time;
  final String venue;
  final String tournamentId;
  final String tournamentName;
  final int overs;
  final int playersPerSide;
  final String matchType; // T20, T10, ODI, Test, Friendly
  final String bannerPath;
  final String organizerName;
  final String contactDetails;
  final String status; // Upcoming, Live, Finished
  final String result; // TBD or Result details
  final String createdBy;
  final String teamALogo; // base64 string or URL
  final String teamBLogo; // base64 string or URL
  final List<PlayerDetails> teamAPlayers;
  final List<PlayerDetails> teamBPlayers;
  final String tossDecision;

  ScheduledMatch({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.date,
    required this.time,
    required this.venue,
    required this.tournamentId,
    required this.tournamentName,
    required this.overs,
    required this.playersPerSide,
    required this.matchType,
    required this.bannerPath,
    required this.organizerName,
    required this.contactDetails,
    required this.status,
    required this.result,
    required this.createdBy,
    required this.teamALogo,
    required this.teamBLogo,
    required this.teamAPlayers,
    required this.teamBPlayers,
    required this.tossDecision,
  });

  factory ScheduledMatch.fromFirestore(DocumentSnapshot doc) {
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

    return ScheduledMatch(
      id: doc.id,
      teamA: data['teamA'] ?? '',
      teamB: data['teamB'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      venue: data['venue'] ?? '',
      tournamentId: data['tournamentId'] ?? '',
      tournamentName: data['tournamentName'] ?? '',
      overs: parseInt(data['overs'], 20),
      playersPerSide: parseInt(data['playersPerSide'], 11),
      matchType: data['matchType'] ?? 'T20',
      bannerPath: data['bannerPath'] ?? '',
      organizerName: data['organizerName'] ?? '',
      contactDetails: data['contactDetails'] ?? '',
      status: data['status'] ?? 'Upcoming',
      result: data['result'] ?? 'TBD',
      createdBy: data['createdBy'] ?? '',
      teamALogo: data['teamALogo'] ?? '',
      teamBLogo: data['teamBLogo'] ?? '',
      teamAPlayers: _parsePlayersList(data['teamAPlayers']),
      teamBPlayers: _parsePlayersList(data['teamBPlayers']),
      tossDecision: data['tossDecision'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'teamA': teamA,
      'teamB': teamB,
      'date': date,
      'time': time,
      'venue': venue,
      'tournamentId': tournamentId,
      'tournamentName': tournamentName,
      'overs': overs,
      'playersPerSide': playersPerSide,
      'matchType': matchType,
      'bannerPath': bannerPath,
      'organizerName': organizerName,
      'contactDetails': contactDetails,
      'status': status,
      'result': result,
      'createdBy': createdBy,
      'teamALogo': teamALogo,
      'teamBLogo': teamBLogo,
      'teamAPlayers': teamAPlayers.map((p) => p.toMap()).toList(),
      'teamBPlayers': teamBPlayers.map((p) => p.toMap()).toList(),
      'tossDecision': tossDecision,
    };
  }
}

final List<ScheduledMatch> matchesList = [
  ScheduledMatch(
    id: "1",
    teamA: "Falcons",
    teamB: "Warriors",
    date: "May 18, 2026",
    time: "2:00 PM",
    venue: "Colombo Stadium",
    tournamentId: "1",
    tournamentName: "Lanka Premier Cup 2026",
    overs: 20,
    playersPerSide: 11,
    matchType: "T20",
    bannerPath:
        "https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=800&auto=format&fit=crop",
    organizerName: "Sri Lanka Cricket",
    contactDetails: "0112345678",
    status: "Finished",
    result: "Falcons won by 12 runs",
    createdBy: 'admin',
    teamALogo: '',
    teamBLogo: '',
    tossDecision: "Falcons won the toss and elected to bat first",
    teamAPlayers: [
      PlayerDetails(name: "A. Perera", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Fast", age: 26),
      PlayerDetails(name: "D. de Silva", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Off-break", age: 29),
      PlayerDetails(name: "K. Mendis", battingStyle: "Right-handed Bat", bowlingStyle: "None", age: 27),
      PlayerDetails(name: "P. Nissanka", battingStyle: "Right-handed Bat", bowlingStyle: "None", age: 25),
      PlayerDetails(name: "C. Asalanka", battingStyle: "Left-handed Bat", bowlingStyle: "Right-arm Off-break", age: 26),
      PlayerDetails(name: "B. Rajapaksa", battingStyle: "Left-handed Bat", bowlingStyle: "None", age: 31),
      PlayerDetails(name: "W. Hasaranga", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Leg-break", age: 27),
      PlayerDetails(name: "M. Theekshana", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Off-break", age: 24),
      PlayerDetails(name: "L. Kumara", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Fast", age: 27),
      PlayerDetails(name: "A. Fernando", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Fast-medium", age: 26),
      PlayerDetails(name: "D. Chameera", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Fast", age: 31),
    ],
    teamBPlayers: [
      PlayerDetails(name: "D. Karunaratne", battingStyle: "Left-handed Bat", bowlingStyle: "Right-arm Medium", age: 35),
      PlayerDetails(name: "P. Jayawickrama", battingStyle: "Right-handed Bat", bowlingStyle: "Left-arm Orthodox", age: 26),
      PlayerDetails(name: "L. Sandakan", battingStyle: "Right-handed Bat", bowlingStyle: "Left-arm Chinaman", age: 32),
      PlayerDetails(name: "K. Rajitha", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Medium-fast", age: 31),
      PlayerDetails(name: "J. Vandersay", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Leg-break", age: 34),
      PlayerDetails(name: "N. Pradeep", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Fast-medium", age: 37),
      PlayerDetails(name: "I. Udana", battingStyle: "Right-handed Bat", bowlingStyle: "Left-arm Fast-medium", age: 36),
      PlayerDetails(name: "T. Perera", battingStyle: "Left-handed Bat", bowlingStyle: "Right-arm Medium-fast", age: 35),
      PlayerDetails(name: "A. Mathews", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Medium", age: 37),
      PlayerDetails(name: "D. Chandimal", battingStyle: "Right-handed Bat", bowlingStyle: "None", age: 34),
      PlayerDetails(name: "B. Fernando", battingStyle: "Left-handed Bat", bowlingStyle: "Left-arm Medium-fast", age: 29),
    ],
  ),
  ScheduledMatch(
    id: "2",
    teamA: "Titans",
    teamB: "Strikers",
    date: "May 20, 2026",
    time: "9:30 AM",
    venue: "Kandy International Ground",
    tournamentId: "2",
    tournamentName: "Colombo T10 Blast",
    overs: 10,
    playersPerSide: 11,
    matchType: "T10",
    bannerPath:
        "https://images.unsplash.com/photo-1540747737956-37872404f8c1?w=800&auto=format&fit=crop",
    organizerName: "Colombo Cricket Club",
    contactDetails: "0777654321",
    status: "Upcoming",
    result: "TBD",
    createdBy: 'admin',
    teamALogo: '',
    teamBLogo: '',
    tossDecision: "Titans won the toss and elected to bowl first",
    teamAPlayers: [
      PlayerDetails(name: "M. Guptill", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Off-break", age: 39),
      PlayerDetails(name: "K. Williamson", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Off-break", age: 35),
      PlayerDetails(name: "R. Taylor", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Off-break", age: 42),
      PlayerDetails(name: "H. Nicholls", battingStyle: "Left-handed Bat", bowlingStyle: "None", age: 34),
      PlayerDetails(name: "T. Latham", battingStyle: "Left-handed Bat", bowlingStyle: "None", age: 34),
      PlayerDetails(name: "C. de Grandhomme", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Medium-fast", age: 39),
      PlayerDetails(name: "M. Santner", battingStyle: "Left-handed Bat", bowlingStyle: "Left-arm Orthodox", age: 34),
      PlayerDetails(name: "T. Southee", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Fast-medium", age: 37),
      PlayerDetails(name: "M. Henry", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Fast-medium", age: 34),
      PlayerDetails(name: "L. Ferguson", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Fast", age: 34),
      PlayerDetails(name: "T. Boult", battingStyle: "Right-handed Bat", bowlingStyle: "Left-arm Fast-medium", age: 36),
    ],
    teamBPlayers: [
      PlayerDetails(name: "J. Bairstow", battingStyle: "Right-handed Bat", bowlingStyle: "None", age: 36),
      PlayerDetails(name: "J. Roy", battingStyle: "Right-handed Bat", bowlingStyle: "None", age: 35),
      PlayerDetails(name: "J. Root", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Off-break", age: 35),
      PlayerDetails(name: "E. Morgan", battingStyle: "Left-handed Bat", bowlingStyle: "None", age: 39),
      PlayerDetails(name: "B. Stokes", battingStyle: "Left-handed Bat", bowlingStyle: "Right-arm Fast-medium", age: 35),
      PlayerDetails(name: "J. Buttler", battingStyle: "Right-handed Bat", bowlingStyle: "None", age: 35),
      PlayerDetails(name: "C. Woakes", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Fast-medium", age: 37),
      PlayerDetails(name: "L. Plunkett", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Fast-medium", age: 41),
      PlayerDetails(name: "A. Rashid", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Leg-break", age: 38),
      PlayerDetails(name: "J. Archer", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Fast", age: 31),
      PlayerDetails(name: "M. Wood", battingStyle: "Right-handed Bat", bowlingStyle: "Right-arm Fast", age: 36),
    ],
  ),
];

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'live_score_viewer.dart';
import 'match_viewer_screen.dart';
import '../models/match.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Slider state
  late PageController _pageController;
  int _activePage = 0;
  Timer? _timer;

  final List<Map<String, String>> _sliderItems = [
    {
      "title": "SOFTBALL MATCH DAY",
      "subtitle": "STREET CRICKET TO CHAMPIONS",
      "image": "assets/slider_1.jpg",
      "type": "live",
      "matchTitle": "Falcons vs Warriors"
    },
    {
      "title": "GULLY CHAMPIONS",
      "subtitle": "LOCAL TAPE-BALL SHOWDOWNS",
      "image": "assets/slider_2.jpg",
      "type": "tournament",
      "matchTitle": "Tournament Hub"
    },
    {
      "title": "TENNIS BALL PULSE",
      "subtitle": "TRACK LOCAL STATS & SCORES",
      "image": "assets/slider_3.jpg",
      "type": "poll",
      "matchTitle": "Match Poll"
    }
  ];

  // Poll state
  int? _selectedPollOption; // null = not voted, 0 = Falcons, 1 = Warriors
  double _falconsVotes = 64.0;
  double _warriorsVotes = 36.0;

  // Trivia state
  bool _showTriviaAnswer = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _activePage + 1;
        if (nextPage >= _sliderItems.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _vote(int option) {
    if (_selectedPollOption != null) return;
    setState(() {
      _selectedPollOption = option;
      if (option == 0) {
        _falconsVotes += 1.0;
      } else {
        _warriorsVotes += 1.0;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Thank you for voting!"),
        backgroundColor: AppTheme.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildPollWidget() {
    double total = _falconsVotes + _warriorsVotes;
    double falconsPercent = (_falconsVotes / total) * 100;
    double warriorsPercent = (_warriorsVotes / total) * 100;

    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: AppTheme.cardDecoration(hasHighlight: false),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.poll_outlined, color: AppTheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                "FAN POLL",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Who will win today's featured match?",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Falcons Option
          GestureDetector(
            onTap: () => _vote(0),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: _selectedPollOption == 0 
                  ? AppTheme.primary.withValues(alpha: 0.05) 
                  : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedPollOption == 0 ? AppTheme.primary : AppTheme.border,
                  width: 1.2,
                ),
              ),
              child: Stack(
                children: [
                  if (_selectedPollOption != null)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: falconsPercent / 100,
                          child: Container(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.sports_cricket, color: AppTheme.textSecondary, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Falcons",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (_selectedPollOption != null)
                          Text(
                            "${falconsPercent.toStringAsFixed(0)}%",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          
          // Warriors Option
          GestureDetector(
            onTap: () => _vote(1),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: _selectedPollOption == 1 
                  ? AppTheme.primary.withValues(alpha: 0.05) 
                  : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedPollOption == 1 ? AppTheme.primary : AppTheme.border,
                  width: 1.2,
                ),
              ),
              child: Stack(
                children: [
                  if (_selectedPollOption != null)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: warriorsPercent / 100,
                          child: Container(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.sports_cricket, color: AppTheme.textSecondary, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Warriors",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (_selectedPollOption != null)
                          Text(
                            "${warriorsPercent.toStringAsFixed(0)}%",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriviaWidget() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.05),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border, width: 1.2),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppTheme.secondary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    "TRIVIA OF THE DAY",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.secondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  _showTriviaAnswer ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _showTriviaAnswer = !_showTriviaAnswer;
                  });
                },
              ),
            ],
          ),
          Text(
            "Who holds the record for the fastest century in ODI cricket history?",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: AppTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "AB de Villiers (Centurion in just 31 balls against West Indies in 2015).",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            crossFadeState: _showTriviaAnswer
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
          if (!_showTriviaAnswer)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _showTriviaAnswer = true;
                  });
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  "Reveal Answer",
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        toolbarHeight: 70,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sports_cricket, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
             Text(
              "CRIC PULSE",
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Account for floating bottom nav
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Promo Banner Slider
            SizedBox(
              height: 180,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _activePage = page;
                      });
                    },
                    itemCount: _sliderItems.length,
                    itemBuilder: (context, index) {
                      final item = _sliderItems[index];
                      return GestureDetector(
                        onTap: () {
                          if (item['type'] == 'live') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LiveScoreViewer(
                                  matchId: item['matchTitle'] == "Falcons vs Warriors" ? "1" : null,
                                  matchTitle: item['matchTitle'] ?? "Live Match",
                                ),
                              ),
                            );
                          } else if (item['type'] == 'tournament') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Explore schedules and results under the Tournaments tab!"),
                                duration: Duration(seconds: 2),
                                backgroundColor: AppTheme.primary,
                              ),
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            image: DecorationImage(
                              image: AssetImage(item['image']!),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.95),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title']!,
                                    style: GoogleFonts.spaceGrotesk(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['subtitle']!,
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Dots indicator
                  Positioned(
                    bottom: 15,
                    right: 25,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _sliderItems.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _activePage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _activePage == index
                                ? AppTheme.primary
                                : Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "LIVE MATCHES",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary,
                        blurRadius: 6,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Live Match Cards List
            // Dynamic Live Match Cards List from Firestore with Robust Offline Fallback
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('matches').snapshots(),
              builder: (context, snapshot) {
                List<ScheduledMatch> matches = [];
                bool isFallback = false;

                if (snapshot.hasError || !snapshot.hasData || (snapshot.data != null && snapshot.data!.docs.isEmpty)) {
                  // Fallback to local offline list
                  matches = List.from(matchesList);
                  isFallback = true;
                } else {
                  matches = snapshot.data!.docs.map((doc) => ScheduledMatch.fromFirestore(doc)).toList();
                }

                // Sort: Live -> Upcoming -> Finished
                matches.sort((a, b) {
                  if (a.status == 'Live' && b.status != 'Live') return -1;
                  if (a.status != 'Live' && b.status == 'Live') return 1;
                  if (a.status == 'Upcoming' && b.status == 'Finished') return -1;
                  if (a.status == 'Finished' && b.status == 'Upcoming') return 1;
                  return 0;
                });

                return Column(
                  children: matches.map((m) {
                    final isLive = m.status == 'Live';
                    
                    if (isFallback) {
                      // Offline/Mock fallback representation
                      final scoreText = m.id == "1" ? "Falcons: 156/7" : "0/0";
                      final oversText = m.id == "1" ? "20.0 Overs" : "0.0 Overs";
                      final statusMsg = m.id == "1" ? "Falcons won by 12 runs" : "Match starts at 9:30 AM";
                      
                      return liveCard(
                        matchId: m.id,
                        team1: m.teamA,
                        score: m.status == "Finished" ? "Completed" : scoreText,
                        team2: m.teamB,
                        over: m.status == "Finished" ? "Match Finished" : oversText,
                        isLive: isLive,
                        logoColor1: m.id == "1" ? Colors.blueAccent : Colors.amber,
                        logoColor2: m.id == "1" ? Colors.redAccent : Colors.purpleAccent,
                        statusMessageParam: m.status == "Finished" ? m.result : statusMsg,
                        batsman1Name: m.id == "1" ? 'Kusal Mendis *' : 'Striker',
                        batsman1Runs: m.id == "1" ? 48 : 0,
                        batsman1Balls: m.id == "1" ? 32 : 0,
                        batsman1Fours: m.id == "1" ? 5 : 0,
                        batsman1Sixes: m.id == "1" ? 2 : 0,
                        batsman2Name: m.id == "1" ? 'Sahan Arachchige' : 'Non-Striker',
                        batsman2Runs: m.id == "1" ? 12 : 0,
                        batsman2Balls: m.id == "1" ? 10 : 0,
                        batsman2Fours: m.id == "1" ? 1 : 0,
                        batsman2Sixes: m.id == "1" ? 0 : 0,
                        bowlerName: m.id == "1" ? 'Alex Mark' : 'Bowler',
                        bowlerOvers: m.id == "1" ? "2.2" : "0.0",
                        bowlerMaidens: 0,
                        bowlerRuns: m.id == "1" ? 18 : 0,
                        bowlerWickets: m.id == "1" ? 2 : 0,
                        lastWicketText: m.id == "1" ? 'Pathum Nissanka 24 (15b) - c Gunathilaka b Alex Mark' : 'None',
                        infoMessage: "Viewing in offline fallback mode.",
                      );
                    }

                    // Otherwise, stream scorecard from Firestore
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('scorecards').doc(m.id).snapshots(),
                      builder: (context, cardSnapshot) {
                        String scoreText = "0/0";
                        String oversText = "0.0 Overs";
                        String statusMsg = m.result;
                        
                        String batsman1 = 'Striker';
                        int b1Runs = 0;
                        int b1Balls = 0;
                        int b1Fours = 0;
                        int b1Sixes = 0;
                        String batsman2 = 'Non-Striker';
                        int b2Runs = 0;
                        int b2Balls = 0;
                        int b2Fours = 0;
                        int b2Sixes = 0;
                        String bowler = 'Bowler';
                        int bowlerBalls = 0;
                        int bowlerRuns = 0;
                        int bowlerWickets = 0;
                        int bowlerMaidens = 0;
                        String lastWicket = 'None';
                        
                        if (cardSnapshot.hasData && cardSnapshot.data!.exists) {
                          final cardData = cardSnapshot.data!.data() as Map<String, dynamic>;
                          int parseInt(dynamic val) {
                            if (val == null) return 0;
                            if (val is int) return val;
                            if (val is double) return val.toInt();
                            if (val is String) return int.tryParse(val) ?? 0;
                            return 0;
                          }
                          final r = parseInt(cardData['runs']);
                          final w = parseInt(cardData['wickets']);
                          final o = parseInt(cardData['overs']);
                          final b = parseInt(cardData['balls']);
                          final target = parseInt(cardData['target']);
                          final batting = cardData['battingTeam'] ?? m.teamA;
                          
                          scoreText = "$batting: $r/$w";
                          oversText = "$o.$b Overs";
                          
                          batsman1 = cardData['batsman1'] ?? 'Striker';
                          b1Runs = parseInt(cardData['batsman1Runs']);
                          b1Balls = parseInt(cardData['batsman1Balls']);
                          b1Fours = parseInt(cardData['batsman1Fours']);
                          b1Sixes = parseInt(cardData['batsman1Sixes']);
                          
                          batsman2 = cardData['batsman2'] ?? 'Non-Striker';
                          b2Runs = parseInt(cardData['batsman2Runs']);
                          b2Balls = parseInt(cardData['batsman2Balls']);
                          b2Fours = parseInt(cardData['batsman2Fours']);
                          b2Sixes = parseInt(cardData['batsman2Sixes']);
                          
                          bowler = cardData['bowler'] ?? 'Bowler';
                          bowlerBalls = parseInt(cardData['bowlerBalls']);
                          bowlerRuns = parseInt(cardData['bowlerRuns']);
                          bowlerWickets = parseInt(cardData['bowlerWickets']);
                          bowlerMaidens = parseInt(cardData['bowlerMaidens']);
                          lastWicket = cardData['lastWicketText'] ?? 'None';
                          
                          if (isLive) {
                            if (target > 0) {
                              statusMsg = "${m.teamB} need ${target - r} runs from ${(m.overs * 6) - (o * 6 + b)} balls";
                            } else {
                              statusMsg = "First innings in progress";
                            }
                          }
                        }
                        
                        return liveCard(
                          matchId: m.id,
                          team1: m.teamA,
                          score: isLive ? scoreText : "Completed",
                          team2: m.teamB,
                          over: isLive ? oversText : "Match Finished",
                          isLive: isLive,
                          logoColor1: m.id == "1" ? Colors.blueAccent : Colors.amber,
                          logoColor2: m.id == "1" ? Colors.redAccent : Colors.purpleAccent,
                          statusMessageParam: isLive ? statusMsg : m.result,
                          batsman1Name: batsman1,
                          batsman1Runs: b1Runs,
                          batsman1Balls: b1Balls,
                          batsman1Fours: b1Fours,
                          batsman1Sixes: b1Sixes,
                          batsman2Name: batsman2,
                          batsman2Runs: b2Runs,
                          batsman2Balls: b2Balls,
                          batsman2Fours: b2Fours,
                          batsman2Sixes: b2Sixes,
                          bowlerName: bowler,
                          bowlerOvers: "${bowlerBalls ~/ 6}.${bowlerBalls % 6}",
                          bowlerMaidens: bowlerMaidens,
                          bowlerRuns: bowlerRuns,
                          bowlerWickets: bowlerWickets,
                          lastWicketText: lastWicket,
                          infoMessage: isLive ? "Match updates are synced live from the ground." : "Match completed • Final standings updated.",
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTeamLogo(String teamName, Color gradientColor, String matchId) {
    return Hero(
      tag: "logo_${matchId}_$teamName",
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [gradientColor, gradientColor.withValues(alpha: 0.65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white, width: 2.2),
          boxShadow: [
            BoxShadow(
              color: gradientColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3.5),
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
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget liveCard({
    String? matchId,
    required String team1,
    required String score,
    required String team2,
    required String over,
    required bool isLive,
    required Color logoColor1,
    required Color logoColor2,
    String? statusMessageParam,
    String? batsman1Name,
    int? batsman1Runs,
    int? batsman1Balls,
    int? batsman1Fours,
    int? batsman1Sixes,
    String? batsman2Name,
    int? batsman2Runs,
    int? batsman2Balls,
    int? batsman2Fours,
    int? batsman2Sixes,
    String? bowlerName,
    String? bowlerOvers,
    int? bowlerMaidens,
    int? bowlerRuns,
    int? bowlerWickets,
    String? lastWicketText,
    String? infoMessage,
  }) {
    // Determine a dynamic status message to make the card feel alive and rich in content
    String statusMessage = statusMessageParam ?? "";
    if (statusMessage.isEmpty) {
      if (isLive) {
        if (team1 == "Falcons") {
          statusMessage = "Warriors need 32 runs in 11 balls";
        } else if (team1 == "Titans") {
          statusMessage = "Strikers need 89 runs to win";
        } else {
          statusMessage = "Match in progress • Live commentary available";
        }
      } else {
        if (team1 == "Lions") {
          statusMessage = "Match starts at 6:00 PM • Galle Stadium";
        } else {
          statusMessage = "$team1 won by 6 wickets";
        }
      }
    }

    final bool isUpcoming = over.toLowerCase().contains("upcoming") || statusMessage.toLowerCase().contains("starts at");
    Color statusColor;
    if (isLive) {
      statusColor = Colors.red.shade600;
    } else if (isUpcoming) {
      statusColor = Colors.blue.shade600;
    } else {
      statusColor = Colors.green.shade600;
    }

    final String mId = matchId ?? "";

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MatchCard3D(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LiveScoreViewer(
                matchId: matchId,
                matchTitle: "$team1 vs $team2",
                score: score,
                overs: over.replaceAll(" Overs", "").replaceAll(" Match", ""),
                isLive: isLive,
                statusMessage: statusMessage,
                batsman1Name: batsman1Name ?? "Kusal Mendis *",
                batsman1Runs: batsman1Runs ?? 48,
                batsman1Balls: batsman1Balls ?? 32,
                batsman1Fours: batsman1Fours ?? 5,
                batsman1Sixes: batsman1Sixes ?? 2,
                batsman2Name: batsman2Name ?? "Sahan Arachchige",
                batsman2Runs: batsman2Runs ?? 12,
                batsman2Balls: batsman2Balls ?? 10,
                batsman2Fours: batsman2Fours ?? 1,
                batsman2Sixes: batsman2Sixes ?? 0,
                bowlerName: bowlerName ?? "Alex Mark",
                bowlerOvers: bowlerOvers ?? "2.2",
                bowlerMaidens: bowlerMaidens ?? 0,
                bowlerRuns: bowlerRuns ?? 18,
                bowlerWickets: bowlerWickets ?? 2,
                lastWicketText: lastWicketText ?? "Pathum Nissanka 24 (15b) - c Gunathilaka b Alex Mark",
                infoMessage: infoMessage ?? "Match updates are synced live from the ground.",
              ),
            ),
          );
        },
        isLive: isLive,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isLive ? AppTheme.primary.withValues(alpha: 0.6) : AppTheme.border,
              width: isLive ? 1.8 : 1.2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Soft background ambient highlights for live matches
                if (isLive)
                  Positioned(
                    top: -60,
                    right: -60,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header band with light grey-green background for clear hierarchy
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7FAF8),
                        border: Border(
                          bottom: BorderSide(color: AppTheme.border, width: 1.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined, 
                                color: AppTheme.textSecondary.withValues(alpha: 0.8), 
                                size: 13
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isLive 
                                    ? "Super League • Live from Ground" 
                                    : (isUpcoming ? "Super League • Scheduled" : "Super League • Finished"),
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          
                          // Dynamic Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isLive ? Colors.red.shade600 : (isUpcoming ? Colors.blue.shade600 : Colors.green.shade600),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1.5),
                                )
                              ]
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isLive) ...[
                                  const LiveBadgePulse(size: 6, color: Colors.white),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  isLive ? "LIVE" : (isUpcoming ? "UPCOMING" : "FINISHED"),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Teams Row (Logo & Names)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          // Team 1
                          Expanded(
                            child: Column(
                              children: [
                                _buildHomeTeamLogo(team1, logoColor1, mId),
                                const SizedBox(height: 6),
                                Hero(
                                  tag: "team_name_${mId}_$team1",
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Text(
                                      team1,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // VS Badge
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F7F5),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.border, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Text(
                              "VS",
                              style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primary,
                                  fontSize: 9.5,
                                ),
                              ),
                            ),

                            // Team 2
                            Expanded(
                              child: Column(
                                children: [
                                  _buildHomeTeamLogo(team2, logoColor2, mId),
                                  const SizedBox(height: 6),
                                  Hero(
                                    tag: "team_name_${mId}_$team2",
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Text(
                                        team2,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Modern "Ticket" Info block at the bottom
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.background.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border, width: 1.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      score,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900,
                                        color: isLive ? AppTheme.primary : AppTheme.textPrimary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      statusMessage,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: isLive ? Colors.red.shade700 : AppTheme.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 3,
                                    )
                                  ]
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isUpcoming ? Icons.access_time_outlined : Icons.sports_cricket_outlined,
                                      size: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      over,
                                      style: GoogleFonts.spaceGrotesk(
                                        color: AppTheme.textSecondary,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}


class MatchCard3D extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isLive;

  const MatchCard3D({
    super.key,
    required this.child,
    required this.onTap,
    required this.isLive,
  });

  @override
  State<MatchCard3D> createState() => _MatchCard3DState();
}

class _MatchCard3DState extends State<MatchCard3D> {
  Offset _tilt = Offset.zero;
  bool _isHovered = false;
  bool _isPressed = false;

  void _updateTilt(PointerEvent event, Size size) {
    if (size.width == 0 || size.height == 0) return;
    
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final position = renderBox.globalToLocal(event.position);
    
    // Normalize coordinates: center is (0,0), range is -1.0 to 1.0
    final x = (position.dx / size.width) * 2 - 1;
    final y = (position.dy / size.height) * 2 - 1;
    
    setState(() {
      _tilt = Offset(x.clamp(-1.0, 1.0), y.clamp(-1.0, 1.0));
      _isHovered = true;
    });
  }

  void _resetTilt() {
    setState(() {
      _tilt = Offset.zero;
      _isHovered = false;
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth == double.infinity ? 350.0 : constraints.maxWidth;
        final height = constraints.maxHeight == double.infinity ? 140.0 : constraints.maxHeight;
        final size = Size(width, height);

        return MouseRegion(
          onHover: (event) => _updateTilt(event, size),
          onExit: (_) => _resetTilt(),
          child: Listener(
            onPointerDown: (event) {
              setState(() {
                _isPressed = true;
              });
              _updateTilt(event, size);
            },
            onPointerMove: (event) => _updateTilt(event, size),
            onPointerUp: (_) {
              setState(() {
                _isPressed = false;
              });
              _resetTilt();
            },
            onPointerCancel: (_) => _resetTilt(),
            child: GestureDetector(
              onTap: widget.onTap,
              child: TweenAnimationBuilder<Offset>(
                tween: Tween<Offset>(begin: Offset.zero, end: _tilt),
                duration: Duration(milliseconds: _isHovered ? 80 : 300),
                curve: Curves.easeOutCubic,
                builder: (context, tilt, child) {
                  // Advanced 3D rotation, perspective and translation
                  final double scale = _isPressed 
                      ? 0.97 
                      : (_isHovered ? 1.04 : 1.0);
                  final double translateY = _isPressed 
                      ? -3.0 
                      : (_isHovered ? -12.0 : 0.0);
                  final double translateZ = _isPressed 
                      ? 4.0 
                      : (_isHovered ? 24.0 : 0.0);

                  final transform = Matrix4.identity()
                    ..setEntry(3, 2, 0.0015) // perspective depth
                    // ignore: deprecated_member_use
                    ..translate(0.0, translateY, translateZ)
                    ..rotateX(-tilt.dy * 0.18) // rotate along X-axis
                    ..rotateY(tilt.dx * 0.18); // rotate along Y-axis

                  return Transform.scale(
                    scale: scale,
                    child: Transform(
                      transform: transform,
                      alignment: FractionalOffset.center,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: widget.isLive 
                                  ? AppTheme.primary.withValues(alpha: _isPressed ? 0.08 : (_isHovered ? 0.22 : 0.06)) 
                                  : Colors.black.withValues(alpha: _isPressed ? 0.08 : (_isHovered ? 0.16 : 0.03)),
                              blurRadius: _isPressed 
                                  ? 10 
                                  : (_isHovered ? 36 : 14),
                              spreadRadius: _isPressed 
                                  ? 0.5 
                                  : (_isHovered ? 2.5 : 0),
                              offset: Offset(
                                _isHovered ? tilt.dx * 12 : 0, 
                                _isPressed 
                                    ? 6 
                                    : (_isHovered ? tilt.dy * 12 + 18 : 6),
                              ),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            widget.child,
                            // Holographic dynamic light reflection/glare overlay on hover
                            if (_isHovered)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        begin: Alignment(
                                          -tilt.dx - 0.5,
                                          -tilt.dy - 0.5,
                                        ),
                                        end: Alignment(
                                          -tilt.dx + 0.5,
                                          -tilt.dy + 0.5,
                                        ),
                                        colors: [
                                          Colors.white.withValues(alpha: 0.12),
                                          Colors.white.withValues(alpha: 0.0),
                                          Colors.white.withValues(alpha: 0.08),
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

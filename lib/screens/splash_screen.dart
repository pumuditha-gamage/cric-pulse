import 'dart:async';
import 'package:flutter/material.dart';
import 'bottom.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _logoVisible = false;
  bool _titleVisible = false;
  bool _taglineVisible = false;
  bool _loaderVisible = false;
  double _logoScale = 0.8;

  @override
  void initState() {
    super.initState();

    // 1. Show logo with a pop effect
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _logoVisible = true;
          _logoScale = 1.08;
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _logoScale = 1.0;
        });
      }
    });

    // 2. Fade in title
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _titleVisible = true;
        });
      }
    });

    // 3. Fade in taglines
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _taglineVisible = true;
        });
      }
    });

    // 4. Fade in loader
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _loaderVisible = true;
        });
      }
    });

    // 5. Navigate to Home with custom fade transition
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const BottomNavBar(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081C10),
      body: Stack(
        children: [
          // Deep Green Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF050F08), // Extremely dark forest green
                  Color(0xFF0C2417), // Deep dark green
                  Color(0xFF143D28), // Forest green
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Ambient green glowing highlights for premium depth
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2C8A53).withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2C8A53).withValues(alpha: 0.12),
              ),
            ),
          ),

          // Modern Animated Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 4),

                // Animated App Logo
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: _logoVisible ? 1.0 : 0.0,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 800),
                    scale: _logoScale,
                    curve: Curves.easeOutBack,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2C8A53).withValues(alpha: 0.25),
                            blurRadius: 25,
                            spreadRadius: 3,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.asset(
                          'assets/logo.jpg',
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Animated App Title with premium style
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: _titleVisible ? 1.0 : 0.0,
                  child: const Text(
                    "CRIC PULSE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 15,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Animated Taglines
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: _taglineVisible ? 1.0 : 0.0,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C8A53).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF2C8A53).withValues(alpha: 0.25)),
                        ),
                        child: const Text(
                          "C R I C K E T",
                          style: TextStyle(
                            color: Color(0xFF2C8A53),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "LIVE SCORES • REAL TIME • REAL PASSION",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10.5,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                // Animated Loader & Text
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: _loaderVisible ? 1.0 : 0.0,
                  child: Column(
                    children: [
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2C8A53)),
                                backgroundColor: Colors.white12,
                                strokeWidth: 3.5,
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2C8A53),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF2C8A53),
                                    blurRadius: 10,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "GETTING LATEST STATS...",
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 9.5,
                          letterSpacing: 3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

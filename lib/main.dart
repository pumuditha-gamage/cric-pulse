import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase initialized successfully");
  } catch (e) {
    debugPrint("Firebase initialization failed/skipped: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {



  
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cric Pulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2C8A53)),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      ),
      home:  SplashScreen(), // ඇප් එක open වෙද්දීම Splash Screen එක පෙන්වයි
    );
  }
}

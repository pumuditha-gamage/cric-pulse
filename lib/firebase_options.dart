import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD-P040eQ-VFVtmW-rVzzsZ3SL0DwUSyQg',
    appId: '1:337516572082:web:c7738b01dbf6e57fe948ab',
    messagingSenderId: '337516572082',
    projectId: 'cricpulse-5c2de',
    authDomain: 'cricpulse-5c2de.firebaseapp.com',
    storageBucket: 'cricpulse-5c2de.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD-P040eQ-VFVtmW-rVzzsZ3SL0DwUSyQg',
    appId: '1:337516572082:android:c7738b01dbf6e57fe948ab',
    messagingSenderId: '337516572082',
    projectId: 'cricpulse-5c2de',
    storageBucket: 'cricpulse-5c2de.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD-P040eQ-VFVtmW-rVzzsZ3SL0DwUSyQg',
    appId: '1:337516572082:ios:c7738b01dbf6e57fe948ab',
    messagingSenderId: '337516572082',
    projectId: 'cricpulse-5c2de',
    storageBucket: 'cricpulse-5c2de.firebasestorage.app',
    iosBundleId: 'com.example.cricPulse',
  );
}

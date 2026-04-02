// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can re-run any of the FlutterFire configuration programs to add support for other platforms.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can re-run any of the FlutterFire configuration programs to add support for other platforms.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAA_HCaVgYIlAhVnVZ4-ocGOwdYbQm00FE',
    appId: '1:732839721535:android:2eefc171ffa371b6dc168a',
    messagingSenderId: '732839721535',
    projectId: 'facerecognition-kel2',
    storageBucket: 'facerecognition-kel2.firebasestorage.app',
  );
}

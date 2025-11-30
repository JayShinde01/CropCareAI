// lib/firebase_options.dart
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
      case TargetPlatform.macOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB_zDPZWQQWILhAvJ9gGDZN-e-U8M5nnFI',
    appId: '1:896246335749:web:bc4e05033beb810391cf6c',
    messagingSenderId: '896246335749',
    projectId: 'login-1665b',
    authDomain: 'login-1665b.firebaseapp.com',
    storageBucket: 'login-1665b.firebasestorage.app',
    measurementId: 'G-5TXPF4056R',
  );

  // ************ WEB CONFIG ************

  // ************ ANDROID ************

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAYwZxPZCRaW8Ur4QikhF6LQnl78F1BAeY',
    appId: '1:896246335749:android:d0f462c2a593145491cf6c',
    messagingSenderId: '896246335749',
    projectId: 'login-1665b',
    storageBucket: 'login-1665b.firebasestorage.app',
  );

  // If you have Android-specific appId / apiKey you should replace these values.

  // ************ iOS / macOS ************
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyB_zDPZWQQWILhAvJ9gGDZN-e-U8M5nnFI",
    appId: "1:896246335749:ios:bc4e05033beb810391cf6c", // example format, replace with your ios appId if different
    messagingSenderId: "896246335749",
    projectId: "login-1665b",
    storageBucket: "login-1665b.appspot.com",
    iosClientId: "", // fill if you use Google sign-in on iOS
    iosBundleId: "", // fill with your app's bundle id
  );
}
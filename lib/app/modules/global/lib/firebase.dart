import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:podium/firebase_options.dart';
import 'package:podium/utils/logger.dart';

class FirebaseInit {
  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      l.i('~~~~~~~~~~~~~firebase initialized~~~~~~~~~~~~~');
    } catch (e) {
      l.f("@@@@@@@@@@@@@@@@ firebase initialization error");
    }
  }
}

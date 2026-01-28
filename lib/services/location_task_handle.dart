import 'dart:async';
import 'dart:isolate';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:visaguard/services/user_registration_service.dart';

class LocationTaskHandler extends TaskHandler {

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    await Firebase.initializeApp();
    await _updateLocation();
  }
   @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) {}

  

   @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    await _updateLocation();
  }
Future<void> _updateLocation() async {
  try {
    var uid = FlutterForegroundTask.getData<String>(key: 'uid');
    if (uid == null) return;

    await UserRegistrationService().updateUserLocation(uid: uid.toString());
  } catch (e) {
    print('Background location update error: $e');
  }
}

}

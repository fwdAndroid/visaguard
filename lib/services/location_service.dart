import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:visaguard/helper/location_helper.dart';

class LocationService {
  Timer? _timer;

  void start() {
    _timer = Timer.periodic(const Duration(minutes: 5), (_) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final location = await LocationHelper.getCurrentAddress();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'latitude': location['latitude'],
        'longitude': location['longitude'],
        'address': location['address'],
        'lastLocationUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  void stop() {
    _timer?.cancel();
  }
}

import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'location_helper.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await Firebase.initializeApp();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return true;

    final location = await LocationHelper.getCurrentAddress();

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'latitude': location['latitude'],
      'longitude': location['longitude'],
      'address': location['address'],
      'lastLocationUpdated': FieldValue.serverTimestamp(),
    });

    return true;
  });
}

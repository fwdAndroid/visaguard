import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class UserRegistrationService {
  // -----------------------------------------
  // Upload Selfie
  // -----------------------------------------
  Future<String> uploadSelfie({
    required String uid,
    required XFile selfie,
  }) async {
    final ref = FirebaseStorage.instance.ref('selfies/$uid.jpg');

    UploadTask uploadTask;

    if (kIsWeb) {
      final bytes = await selfie.readAsBytes();
      uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
    } else {
      uploadTask = ref.putFile(
        File(selfie.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );
    }

    final snapshot = await uploadTask;
    return snapshot.ref.getDownloadURL();
  }

  // -----------------------------------------
  // Get Current Position + Address
  // -----------------------------------------
  Future<Map<String, dynamic>?> getLocationWithAddress() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String? address = await _getAddress(pos.latitude, pos.longitude);

      return {
        'geo': GeoPoint(pos.latitude, pos.longitude),
        'address': address,
      };
    } catch (e) {
      debugPrint('Location error: $e');
      return null;
    }
  }

  // -----------------------------------------
  // Helper: Get address from coordinates
  // -----------------------------------------
  Future<String?> _getAddress(double lat, double lon) async {
  try {
    final placemarks = await placemarkFromCoordinates(lat, lon);
    if (placemarks.isEmpty) return null;

    final p = placemarks.first;

    final parts = <String>[
      if (p.subThoroughfare != null && p.subThoroughfare!.isNotEmpty)
        p.subThoroughfare!,            // House number (245 B)
      if (p.thoroughfare != null && p.thoroughfare!.isNotEmpty)
        p.thoroughfare!,               // Street
      if (p.subLocality != null && p.subLocality!.isNotEmpty)
        p.subLocality!,                // Eden Garden
      if (p.locality != null && p.locality!.isNotEmpty)
        p.locality!,                   // Faisalabad
      if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
        p.administrativeArea!,
      if (p.country != null && p.country!.isNotEmpty)
        p.country!,
    ];

    return parts.join(', ');
  } catch (_) {
    return null;
  }
}


  // -----------------------------------------
  // Save User Profile (with optional location)
  // -----------------------------------------
  Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String phone,
    required String passportNumber,
    required String selfieUrl,
    String? email,
    Map<String, dynamic>? location,
  }) async {
    final data = <String, dynamic>{
      'uid': uid,
      'name': name,
      'phone': phone,
      'passportNumber': passportNumber,
      'selfieUrl': selfieUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (email != null && email.isNotEmpty) {
      data['email'] = email;
    }

    if (location != null && location['geo'] is GeoPoint) {
      data['location'] = {
        'geo': location['geo'],
        'address': location['address'],
      };
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  // -----------------------------------------
  // Update location in Firestore (background-safe)
  // -----------------------------------------
  Future<void> updateUserLocation({
  required String uid,
}) async {
  try {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 5),
    );

    final address = await _getAddress(pos.latitude, pos.longitude);

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'location.geo': GeoPoint(pos.latitude, pos.longitude),
      'location.address': address ?? '',
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    debugPrint('Update location error: $e');
  }
}

}

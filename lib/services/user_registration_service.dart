import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserRegistrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadSelfie({
    required String uid,
    required File selfie,
  }) async {
    final ref = _storage.ref('selfies/$uid.jpg');
    await ref.putFile(selfie);
    return await ref.getDownloadURL();
  }

  Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String passportNumber,
    required String selfieUrl,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'passportNumber': passportNumber,
      'selfieUrl': selfieUrl,
      'isApproved': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

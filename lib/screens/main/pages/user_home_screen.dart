import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('visa_documents')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      if (doc.exists) {
        setState(() {
          userData = doc.data();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  ImageProvider? _getSelfieImage(String base64String) {
    try {
      final decodedBytes = base64Decode(base64String.split(',').last);
      return MemoryImage(decodedBytes);
    } catch (_) {
      return null;
    }
  }

  Widget _buildInfoTile(
      IconData icon, String label, String value, Color color) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(value, style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  void _openVisaPdf(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Visa Document'),
            backgroundColor: Colors.deepPurple,
          ),
          body: SfPdfViewer.network(url),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'User Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? const Center(child: Text('No user data found'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Gradient Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.deepPurple, Colors.purpleAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 40, horizontal: 16),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 70,
                              backgroundColor: Colors.white,
                              backgroundImage: userData!['selfieUrl'] != null
                                  ? _getSelfieImage(userData!['selfieUrl'])
                                  : null,
                              child: userData!['selfieUrl'] == null
                                  ? const Icon(Icons.person,
                                      size: 70, color: Colors.grey)
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              userData!['name'] ?? 'N/A',
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              userData!['email'] ?? 'N/A',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Info Tiles
                      _buildInfoTile(Icons.phone, 'Phone',
                          userData!['phone'] ?? 'N/A', Colors.green),
                      _buildInfoTile(Icons.card_travel, 'Passport Number',
                          userData!['passportNumber'] ?? 'N/A', Colors.orange),
                      _buildInfoTile(
                          Icons.date_range,
                          'Uploaded At',
                          userData!['uploadedAt'] != null
                              ? (userData!['uploadedAt'] as Timestamp)
                                  .toDate()
                                  .toString()
                              : 'N/A',
                          Colors.purple),
                      const SizedBox(height: 20),

                      // Visa Document Button
                      if (userData!['visaDocUrl'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 40),
                                backgroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16))),
                            icon: const Icon(Icons.picture_as_pdf,
                                size: 28, color: Colors.white),
                            label: const Text('View Visa',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                            onPressed: () =>
                                _openVisaPdf(userData!['visaDocUrl']),
                          ),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }
}

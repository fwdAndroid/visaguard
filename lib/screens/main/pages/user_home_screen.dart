import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

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
        userData = doc.data();
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    setState(() => isLoading = false);
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
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

  Future<void> _openWhatsApp() async {
    const phoneNumber = '917718860398'; // without +
    final Uri uri = Uri.parse('https://wa.me/$phoneNumber');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp not available')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('User Profile'),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? const Center(child: Text('No user data found'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 40, horizontal: 16),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.deepPurple, Colors.purpleAccent],
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 65,
                              backgroundColor: Colors.white,
                              backgroundImage: userData!['selfieUrl'] != null
                                  ? _getSelfieImage(userData!['selfieUrl'])
                                  : null,
                              child: userData!['selfieUrl'] == null
                                  ? const Icon(Icons.person, size: 60)
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              userData!['name'] ?? 'N/A',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              userData!['phone'] ?? 'N/A',
                              style:
                                  const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildInfoTile(Icons.phone, 'Phone',
                          userData!['phone'] ?? 'N/A', Colors.green),
                      _buildInfoTile(
                          Icons.card_travel,
                          'Passport Number',
                          userData!['passportNumber'] ?? 'N/A',
                          Colors.orange),
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

                      // View Visa Button
                      if (userData!['visaDocUrl'] != null)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 32),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.picture_as_pdf,
                                color: Colors.white),
                            label: const Text('View Visa',
                                style: TextStyle(color: Colors.white)),
                            onPressed: () =>
                                _openVisaPdf(userData!['visaDocUrl']),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Two Buttons
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                ),
                                onPressed:_openWhatsApp,
                                child: const Text('Visa Extension',
                                    style:
                                        TextStyle(color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                ),
                                onPressed: _openWhatsApp,
                                child: const Text('Contact Us',
                                    style:
                                        TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }
}

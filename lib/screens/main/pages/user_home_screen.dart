import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iconsax/iconsax.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:visaguard/provider/language_provider.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? userData;
  String? visaDocUrl;
  bool isLoading = true;
  bool visaLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showQrCode = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();
    _fetchUserData();
    _fetchVisaDocument();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        userData = doc.data();
      }
    } catch (e) {
      debugPrint('User fetch error: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> _fetchVisaDocument() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('visa_documents')
          .doc(uid)
          .get();

      if (doc.exists && doc.data()?['visaDocUrl'] != null) {
        visaDocUrl = doc['visaDocUrl'];
      }
    } catch (e) {
      debugPrint('Visa fetch error: $e');
    }
    setState(() => visaLoading = false);
  }

    ImageProvider? _getSelfieImage(String? imageData) {
    if (imageData == null) return null;

    if (imageData.startsWith('http')) {
      return NetworkImage(imageData);
    }

    try {
      final bytes = base64Decode(imageData.split(',').last);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  
  }

  void _openVisaPdf(String url) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => Scaffold(
          
          appBar: AppBar(
            title: const Text('Visa Document'),
            backgroundColor: Colors.deepPurple,
          ),
          body: SfPdfViewer.network(url),
        ),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _openWhatsApp({bool isExtension = false}) async {
    const phoneNumber = '917718860398';
    final message = isExtension 
        ? 'Hello, I would like to inquire about visa extension.'
        : 'Hello, I need assistance with my visa.';
    final encodedMessage = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$phoneNumber?text=$encodedMessage');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open WhatsApp'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _toggleQrCode() {
    setState(() => _showQrCode = !_showQrCode);
  }

  Future<void> _shareQrCode() async {
    final passportNumber = userData?['passportNumber'] ?? 'N/A';
    await Share.share(
      'My Visa Guard Passport Number: $passportNumber\n\nScan the QR code for verification.',
      subject: 'Visa Guard Passport QR Code',
    );
  }

  Widget _buildQrCodeSection(BuildContext context, LanguageProvider languageProvider) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final passportNumber = userData?['passportNumber'] ?? 'N/A';
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [Colors.deepPurple.shade800, Colors.purple.shade900]
              : [Colors.deepPurple, Colors.purpleAccent],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Iconsax.scan_barcode, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                languageProvider.localizedStrings["Passport QR Code"] ?? 'Passport QR Code',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _toggleQrCode,
                icon: Icon(
                  _showQrCode ? Iconsax.eye_slash : Iconsax.eye,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: _shareQrCode,
                icon: Icon(Iconsax.share, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_showQrCode)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: 'VISAGUARD:${userData?['uid'] ?? ''}:$passportNumber',
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.deepPurple,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                   languageProvider.localizedStrings["Scan for verification"] ??   'Scan for verification',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.card, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.localizedStrings["Passport Number"] ?? 'Passport Number',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          passportNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      languageProvider.localizedStrings["Tap to reveal QR"] ??'Tap to reveal QR',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 8),
          if (!_showQrCode)
            Text(
            languageProvider.localizedStrings["Tap eye icon to show QR code for verification"] ??  'Tap eye icon to show QR code for verification',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LanguageProvider languageProvider) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [Colors.grey[900]!, Colors.grey[800]!]
              : [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // App Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.profile_circle,
                  color: Colors.deepPurple,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                    languageProvider.localizedStrings["My Profile"] ?? 'My Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDarkMode ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                   languageProvider.localizedStrings["Visa status & information"] ??   'Visa status & information',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
           
            ],
          ),
          
          // User Profile
          Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.deepPurple,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: userData!['selfieUrl'] != null
                          ? _getSelfieImage(userData!['selfieUrl'])
                          : null,
                      child: userData!['selfieUrl'] == null
                          ? Icon(Iconsax.profile_circle, 
                              size: 50, color: Colors.grey[400])
                          : null,
                    ),
                  ),
                 
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData!['name'] ?? 'No Name',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Iconsax.call, 
                          size: 16, 
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          userData!['phone'] ?? 'No Phone',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, Color color, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          subtitle: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.grey[900],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisaStatus(BuildContext context, LanguageProvider languageProvider) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final languageProvider = Provider.of<LanguageProvider>(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [Colors.blue.shade900, Colors.indigo.shade900]
              : [Colors.blue.shade50, Colors.indigo.shade50],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.document_text, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 12),
              Text(
                languageProvider.localizedStrings["Visa Status"] ?? 'Visa Status',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : Colors.grey[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (visaLoading)
            Center(child: CircularProgressIndicator(color: Colors.blue.shade700))
          else if (visaDocUrl != null)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isDarkMode ? 0.1 : 0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.tick_circle, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                            languageProvider.localizedStrings["Visa Approved"] ??  'Visa Approved',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.grey[900],
                              ),
                            ),
                            Text(
                              languageProvider.localizedStrings["Document is ready to view"] ?? 'Document is ready to view',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _openVisaPdf(visaDocUrl!),
                        icon: Icon(Iconsax.eye, color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openVisaPdf(visaDocUrl!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(Iconsax.document_download, size: 20),
                    label:  Text(
                     languageProvider.localizedStrings["View Visa Document"] ?? 'View Visa Document',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.clock, color: Colors.orange, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                             languageProvider.localizedStrings["Under Process"] ??   'Under Process',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.grey[900],
                              ),
                            ),
                            Text(
                              languageProvider.localizedStrings["Your visa is being processed"] ??  'Your visa is being processed',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  color: Colors.orange,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, LanguageProvider languageProvider) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          final languageProvider = Provider.of<LanguageProvider>(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Material(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 4,
                  child: InkWell(
                    onTap: () => _openWhatsApp(isExtension: true),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Iconsax.calendar_add, color: Colors.orange, size: 30),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            languageProvider.localizedStrings["Visa Extension"] ?? 'Visa Extension',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.grey[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            languageProvider.localizedStrings["Extend your visa period"] ?? 'Extend your visa period',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Material(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 4,
                  child: InkWell(
                    onTap: _openWhatsApp,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Iconsax.message_question, color: Colors.green, size: 30),
                          ),
                          const SizedBox(height: 12),
                          Text(
                          languageProvider.localizedStrings["Contact Support"] ??  'Contact Support',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.grey[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                           languageProvider.localizedStrings["Get help & assistance"] ?? 'Get help & assistance',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
         final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    Text(
                     languageProvider.localizedStrings["Loading your profile..."] ?? 'Loading your profile...',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            : userData == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.profile_remove, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 20),
                        Text(
                       languageProvider.localizedStrings["No user data found"] ??    'No user data found',
                          style: TextStyle(
                            fontSize: 18,
                            color: isDarkMode ? Colors.white : Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                        languageProvider.localizedStrings["Please complete your profile setup"] ??    'Please complete your profile setup',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        automaticallyImplyLeading: false,
                        expandedHeight: 200,
                        floating: false,
                        pinned: true,
                        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
                        flexibleSpace: FlexibleSpaceBar(
                          background: _buildHeader(context,languageProvider),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            // QR Code Section (replaces passport info card)
                            _buildQrCodeSection(context,languageProvider),
                            const SizedBox(height: 16),
                            // Other information
                            _buildInfoTile(
                              Iconsax.calendar,
                           languageProvider.localizedStrings["Registration Date"] ??   'Registration Date',
                              userData!['createdAt'] != null
                                  ? (userData!['createdAt'] as Timestamp)
                                      .toDate()
                                      .toString()
                                      .split(' ')[0]
                                  : 'N/A',
                              Colors.purple,
                              context,
                            ),
                            const SizedBox(height: 24),
                            _buildVisaStatus(context,languageProvider),
                            const SizedBox(height: 24),
                            _buildActionButtons(context,languageProvider),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
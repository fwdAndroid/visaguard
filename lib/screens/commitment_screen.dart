import 'package:flutter/material.dart';
import 'package:visaguard/screens/main/main_dashboard_screen.dart';

class ComplianceAgreementScreen extends StatefulWidget {
  const ComplianceAgreementScreen({Key? key}) : super(key: key);

  @override
  State<ComplianceAgreementScreen> createState() =>
      _ComplianceAgreementScreenState();
}

class _ComplianceAgreementScreenState extends State<ComplianceAgreementScreen> {
  bool agreeChecked = false;
  final ScrollController _scrollController = ScrollController();
  bool _showBottomShadow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _showBottomShadow = _scrollController.offset > 0;
      });
    });
  }

  void _onAgree() {
    if (!agreeChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please confirm your agreement to continue'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    // TODO: Save consent to Firestore / Local DB
    // TODO: Navigate to next screen

    Navigator.push(context, MaterialPageRoute(builder: (_) => MainDashboardScreen()));
  }

  void _onDisagree() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Service Cancelled'),
          ],
        ),
        content: const Text(
          'You have declined the agreement.\n\n'
          'Your visa request will be cancelled immediately and you cannot proceed with the service.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => MainDashboardScreen()));

            },
            child: const Text('UNDERSTAND', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
    Color iconColor = Colors.blue,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Compliance Agreement',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.blue[50],
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This is a legally binding agreement. Please read carefully.',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AIS VisaGuard: Traveler Compliance Agreement',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Version: 2026.1.1 • Last updated: January 1, 2026',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      Text(
                        'This is a legally binding contract between you (the Traveler) and AIS VisaGuard. '
                        'By agreeing, you accept all terms and conditions below.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      _buildSection(
                        icon: Icons.travel_explore_rounded,
                        title: 'Tourism Purpose Declaration',
                        content: 'Your entry is strictly for tourism/Umrah purposes. '
                            'You will not seek employment or attend job interviews.',
                      ),
                      
                      _buildSection(
                        icon: Icons.location_on_rounded,
                        title: '24/7 Tracking Consent',
                        content: 'You consent to real-time tracking via GPS, IP, and SIM. '
                            'The app must remain active, and you must respond to compliance pings within 4 hours.',
                        iconColor: Colors.purple,
                      ),
                      
                      _buildSection(
                        icon: Icons.gavel_rounded,
                        title: 'Legal & Baggage Compliance',
                        content: 'You confirm you are not carrying prohibited items. '
                            'AIS VisaGuard holds zero legal responsibility for your actions.',
                        iconColor: Colors.orange,
                      ),
                      
                      _buildSection(
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'Financial Liability',
                        content: 'All fines, penalties, and legal costs are your sole responsibility. '
                            'You will reimburse any payments made on your behalf.',
                        iconColor: Colors.red,
                      ),
                      
                      _buildSection(
                        icon: Icons.flight_takeoff_rounded,
                        title: 'Exit & Deportation Terms',
                        content: 'You must exit 48 hours before visa expiry. '
                            'Deportation costs are your responsibility with additional 25% penalty for emergency exits.',
                        iconColor: Colors.green,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.amber[700]),
                                const SizedBox(width: 8),
                                const Text(
                                  'Important Notice',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'By agreeing, you authorize AIS VisaGuard to file absconding reports, '
                              'share data with authorities, and contact family members if necessary. '
                              'This agreement is enforceable in Indian courts.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                
                // Shadow effect when scrolling
                if (_showBottomShadow)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.08),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Fixed bottom section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: agreeChecked,
                        onChanged: (val) => setState(() => agreeChecked = val ?? false),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => agreeChecked = !agreeChecked),
                        child: Text(
                          'I have read and understood all terms. I accept full legal and financial responsibility for my compliance.',
                          style: TextStyle(
                            fontSize: 14,
                            color: agreeChecked ? Colors.green[800] : Colors.grey[700],
                            fontWeight: agreeChecked ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _onDisagree,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                        child: const Text(
                          'DECLINE',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onAgree,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: agreeChecked ? Colors.blue[700] : Colors.grey[400],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: const Text(
                          'ACCEPT & CONTINUE',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
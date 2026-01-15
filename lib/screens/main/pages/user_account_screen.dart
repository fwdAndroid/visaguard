import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:visaguard/screens/auth/login_screen.dart';
import 'package:visaguard/screens/main/pages/profile_screen.dart';
import 'package:visaguard/services/auth_service.dart';


class UserAccountScreen extends StatelessWidget {
  const UserAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(     
      body:  SingleChildScrollView(
            child: Column(
              children: [
                // Profile Image or Logo
                
              
                const SizedBox(height: 12),
   // Logout
                  _tile(
                    context,
                    Icons.person,
                    "Profile Settings",
                    () {
                      Navigator.push(context, MaterialPageRoute(builder: (builder) => ProfileScreen()));
                    },
                  ),


                // Logout
                  _tile(
                    context,
                    Icons.logout,
                    "Log Out",
                    () => _showLogoutDialog(context),
                    color: Colors.red,
                  ),
              ],
            ),
          )
  );}
  }

  Widget _tile(BuildContext context, IconData icon, String title, VoidCallback onTap, {Color color = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

 

 

  void _showLogoutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuthService().signOut();
             
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );

  
}

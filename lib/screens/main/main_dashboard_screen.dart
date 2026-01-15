import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:visaguard/screens/main/pages/user_account_screen.dart';
import 'package:visaguard/screens/main/pages/user_home_screen.dart';


class MainDashboardScreen extends StatefulWidget {
  final int initialPageIndex;

  const MainDashboardScreen({super.key, this.initialPageIndex = 0});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const UserHomeScreen(),
    const UserAccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialPageIndex;
  }

  @override
  Widget build(BuildContext context) {

    return  Scaffold(
           
            body: _screens[_currentIndex],
            bottomNavigationBar: BottomNavigationBar(
                    selectedItemColor: Colors.blue,
                    unselectedItemColor: Colors.white,
                    type: BottomNavigationBarType.fixed,
                    currentIndex: _currentIndex,
                    onTap: (index) => setState(() => _currentIndex = index),
                    items: [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home, color: Colors.blue),
                        label:  "Home",
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person, color: Colors.blue),
                        label:  "Profile",
                      ),
                    ],
                  )
                
          
        );
    
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Do you want to exit the app?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () {
              if (Platform.isAndroid) {
                SystemNavigator.pop();
              } else if (Platform.isIOS) {
                exit(0);
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}

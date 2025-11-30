// lib/screens/home_screen.dart
import 'dart:io';
import 'package:demo/screens/diagnose_screen.dart';
import 'package:demo/screens/field_map_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
    _checkLoggedIn();
  }

  Future<void> _checkLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

List screens = [DiagnoseScreen(),FieldMapScreen(),DiagnoseScreen(),FieldMapScreen(),DiagnoseScreen(),FieldMapScreen(),];
  int bottomIndex = 0;
  final accent = const Color(0xFF74C043);
  

  File? _lastPickedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),

      drawer: _buildAppDrawer(context),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0E),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white24,
              ),
              child: const Center(child: Icon(Icons.grass, color: Colors.white)),
            ),
            const SizedBox(width: 10),
            const Text('CropCareAI', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(Icons.people, color: Colors.white),
          )
        ],
      ),

      body: screens[bottomIndex],

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF121212),
        selectedItemColor: accent,
        unselectedItemColor: Colors.white70,
        currentIndex: bottomIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => bottomIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Schedule"),
          BottomNavigationBarItem(icon: Icon(Icons.camera), label: "Diagnose"),
          BottomNavigationBarItem(icon: Icon(Icons.android), label: "Consult"),
          BottomNavigationBarItem(icon: Icon(Icons.navigation), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notifs"),
        ],
      ),
    );
  }

  

  // ---------------- Drawer ----------------
  Widget _buildAppDrawer(BuildContext context) {
    const headerBg = Color(0xFF0E5F6E);
    const drawerBg = Color(0xFF111111);

    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;

    return Drawer(
      width: 280,
      child: Container(
        color: drawerBg,
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
              child: Container(
                color: headerBg,
                width: double.infinity,
                padding: const EdgeInsets.only(top: 28, bottom: 14, left: 16),
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white24,
                      ),
                      child: ClipOval(
                        child: SizedBox(
                          child: _lastPickedImage != null
                              ? Image.file(_lastPickedImage!, fit: BoxFit.cover)
                              : (photoUrl != null
                                  ? Image.network(photoUrl, fit: BoxFit.cover)
                                  : const Icon(Icons.person, size: 36, color: Colors.white)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.displayName ?? 'ABC',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(user?.email ?? '',
                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(height: 4, color: accent),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerItem(Icons.attach_money, 'Plans and Pricing'),
                  _drawerItem(Icons.card_giftcard, 'Rewards'),
                  _drawerItem(Icons.menu_book, 'Library'),
                  _drawerItem(Icons.group, 'Teams'),
                  _drawerItem(Icons.workspaces_filled, 'Workgroup'),
                  _drawerItem(Icons.help_outline, 'Tutorials'),
                  _drawerItem(Icons.mail_outline, 'Contact Us'),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 8),
                  _drawerFooter(context),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: const [
                  Text('Privacy Policy | Terms of Use',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                  SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.white54),
      title: Text(label, style: const TextStyle(color: Colors.white70)),
      onTap: () {},
      horizontalTitleGap: 4,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _drawerFooter(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.shield, color: Colors.white30),
          title: const Text('Plans and Pricing',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
          onTap: () {},
        ),
      ],
    );
  }
  
}
// lib/screens/home_screen.dart
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
    // No user -> redirect to login and remove this page from stack
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }
}


  int bottomIndex = 2; // Diagnose tab active (green)
  final accent = const Color(0xFF74C043);
  final ImagePicker _picker = ImagePicker();

  File? _lastPickedImage; // previewed image

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),

      // Built-in hamburger icon will open this drawer
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

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tab-like header (home / people)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(Icons.home, color: Colors.white),
                        Container(
                          height: 3,
                          color: accent,
                          margin: const EdgeInsets.only(top: 6),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                    child: Icon(Icons.group, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Health Check card with camera & gallery actions
              _featureCard(
                title: "Health check",
                subtitle: "Receive instant identifications\nand treatment suggestions",
                icon: Icons.image,
                extraActions: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Use Camera',
                      icon: const Icon(Icons.camera_alt, color: Colors.white70),
                      onPressed: () => _pickAndPreview(ImageSource.camera),
                    ),
                    IconButton(
                      tooltip: 'Choose from gallery',
                      icon: const Icon(Icons.photo_library, color: Colors.white70),
                      onPressed: () => _pickAndPreview(ImageSource.gallery),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Other feature cards unchanged
              _featureCard(
                title: "No plots yet",
                subtitle: "Add a plot to activate alerts,\nforecasts, recommendations, and more",
                icon: Icons.landscape,
              ),
              const SizedBox(height: 12),
              _featureCard(
                title: "Satellite monitoring",
                subtitle: "Activate to spot problems and measure\nprogress",
                icon: Icons.satellite_alt,
              ),
              const SizedBox(height: 12),
              _featureCard(
                title: "Invite Friends",
                subtitle: "Earn credits for every friend who joins using your referral",
                icon: Icons.people_alt,
              ),
              const SizedBox(height: 20),

              const Text(
                "Personal Feed",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),

              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF171717),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('Feed item', style: TextStyle(color: Colors.white54))),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),

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
          BottomNavigationBarItem(icon: Icon(Icons.navigation), label: "Scout"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notifs"),
        ],
      ),
    );
  }

  // ---------------- Feature card widget ----------------
  Widget _featureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? extraActions,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(color: Colors.white60)),
            ]),
          ),
          Icon(icon, color: Colors.white70, size: 40),
          if (extraActions != null) ...[
            const SizedBox(width: 8),
            extraActions,
          ],
        ],
      ),
    );
  }

  // ---------------- App Drawer ----------------
  Widget _buildAppDrawer(BuildContext context) {
    const headerBg = Color(0xFF0E5F6E); // teal-ish header like screenshot
    const drawerBg = Color(0xFF111111);

    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;

    return Drawer(
      width: 280,
      child: Container(
        color: drawerBg,
        child: Column(
          children: [
            // Header (tap avatar to open profile)
            GestureDetector(
              onTap: () {
                Navigator.pop(context); // close drawer
                Navigator.pushNamed(context, '/profile'); // open profile screen
              },
              child: Container(
                color: headerBg,
                width: double.infinity,
                padding: const EdgeInsets.only(top: 28, bottom: 14, left: 16),
                child: Row(
                  children: [
                    // avatar: show picked image first (if any) else user.photoURL else icon
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
                      child: ClipOval(
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: _lastPickedImage != null
                              ? Image.file(_lastPickedImage!, fit: BoxFit.cover)
                              : (photoUrl != null
                                  ? Image.network(photoUrl, fit: BoxFit.cover)
                                  : const Icon(Icons.person, size: 36, color: Colors.white)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(user?.displayName ?? 'ABC', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ]),
                    ),
                  ],
                ),
              ),
            ),

            // thin green accent
            Container(height: 4, color: accent),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerItem(Icons.attach_money, 'Plans and Pricing', onTap: () {
                    Navigator.pop(context);
                  }),
                  _drawerItem(Icons.card_giftcard, 'Rewards', onTap: () {
                    Navigator.pop(context);
                  }),
                  _drawerItem(Icons.menu_book, 'Library', onTap: () {
                    Navigator.pop(context);
                  }),
                  _drawerItem(Icons.group, 'Teams', onTap: () {
                    Navigator.pop(context);
                  }),
                  _drawerItem(Icons.workspaces_filled, 'Workgroup', onTap: () {
                    Navigator.pop(context);
                  }),
                  _drawerItem(Icons.help_outline, 'Tutorials', onTap: () {
                    Navigator.pop(context);
                  }),
                  _drawerItem(Icons.mail_outline, 'Contact Us', onTap: () {
                    Navigator.pop(context);
                  }),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 8),
                  _drawerFooter(context),
                ],
              ),
            ),

            // small privacy / terms text
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

  Widget _drawerItem(IconData icon, String label, {VoidCallback? onTap}) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.white54),
      title: Text(label, style: const TextStyle(color: Colors.white70)),
      onTap: onTap,
      horizontalTitleGap: 4,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _drawerFooter(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.shield, color: Colors.white30),
          title: const Text('Plans and Pricing', style: TextStyle(color: Colors.white38, fontSize: 13)),
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }

  // ---------------- Image picking & preview ----------------
  Future<void> _pickAndPreview(ImageSource source) async {
    try {
      final XFile? xfile = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1200);
      if (xfile == null) return;

      // On mobile (iOS/Android), convert to File to preview & potentially upload
      final file = File(xfile.path);
      setState(() => _lastPickedImage = file);

      // Show a preview dialog with option to "Send to Diagnose" or "Cancel"
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Preview'),
          content: SizedBox(
            width: double.infinity,
            height: 300,
            child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(file, fit: BoxFit.cover)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: send `file` to your Diagnose flow / upload to backend
                // Example: Navigator.pushNamed(context, '/diagnose', arguments: file);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sent to Diagnose (TODO)')));
              },
              child: const Text('Send to Diagnose'),
            ),
          ],
        ),
      );
    } catch (e, st) {
      debugPrint('Image pick error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to pick image'), backgroundColor: Colors.redAccent));
    }
  }
}

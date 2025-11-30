// lib/screens/profile_screen.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = false;
  double _uploadProgress = 0.0;
  File? _pickedImageFile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Prefill fields from auth first
    _nameCtrl.text = user.displayName ?? '';

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _phoneCtrl.text = (data['phone'] ?? '') as String;
      }
    } catch (e) {
      // ignore errors while loading
      debugPrint('Failed to load profile doc: $e');
    }

    setState(() {});
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xfile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (xfile == null) return;
      setState(() {
        _pickedImageFile = File(xfile.path);
      });
    } catch (e) {
      debugPrint('Image pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<String?> _uploadProfileImage(File file, String uid) async {
    final ref = _storage.ref().child('profile_images').child('$uid.jpg');

    final uploadTask = ref.putFile(file);
    uploadTask.snapshotEvents.listen((event) {
      final total = event.totalBytes;
      final transferred = event.bytesTransferred;
      if (total > 0) {
        setState(() {
          _uploadProgress = transferred / total;
        });
      }
    });

    final snapshot = await uploadTask.whenComplete(() {});
    final url = await snapshot.ref.getDownloadURL();
    return url;
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    setState(() => _loading = true);

    try {
      String? photoUrl = user.photoURL;

      // If user picked a new image, upload it
      if (_pickedImageFile != null) {
        try {
          final uploadedUrl = await _uploadProfileImage(_pickedImageFile!, user.uid);
          if (uploadedUrl != null) photoUrl = uploadedUrl;
        } catch (e) {
          debugPrint('Upload failed: $e');
          throw Exception('Failed to upload image');
        }
      }

      // Update Firebase Auth profile
      await user.updateDisplayName(name);
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }
      await user.reload(); // ensure latest

      // Update Firestore user doc (merge)
      final docRef = _db.collection('users').doc(user.uid);
      await docRef.set({
        'uid': user.uid,
        'name': name,
        'email': user.email,
        'phone': phone,
        'photoURL': photoUrl,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), backgroundColor: Colors.green),
      );

      // clear picked image and reset progress
      setState(() {
        _pickedImageFile = null;
        _uploadProgress = 0;
      });
    } catch (e, st) {
      debugPrint('Save profile error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showImageSourceSheet() async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final photo = _pickedImageFile != null
        ? Image.file(_pickedImageFile!, fit: BoxFit.cover)
        : (user?.photoURL != null
            ? Image.network(user!.photoURL!, fit: BoxFit.cover)
            : const Icon(Icons.person, size: 60, color: Colors.white54));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF0E0E0E),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0E0E0E),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar + edit button
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.white12,
                  child: ClipOval(
                    child: SizedBox(
                      width: 110,
                      height: 110,
                      child: photo,
                    ),
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Material(
                    color: Colors.greenAccent.shade400,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.black),
                      onPressed: _showImageSourceSheet,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Name, email, phone fields
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              enabled: false,
              initialValue: user?.email ?? '',
              decoration: const InputDecoration(
                hintText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 18),

            // Upload progress bar
            if (_uploadProgress > 0 && _uploadProgress < 1)
              Column(
                children: [
                  LinearProgressIndicator(value: _uploadProgress),
                  const SizedBox(height: 8),
                ],
              ),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const StadiumBorder(),
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                ),
                child: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Profile'),
              ),
            ),
            const SizedBox(height: 12),

            // Sign out
            TextButton(
              onPressed: () async {
                await _auth.signOut();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Sign out', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}

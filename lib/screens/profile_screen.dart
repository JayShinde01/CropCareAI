// lib/screens/profile_screen.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
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
  // Services
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // UI state
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

  // --- PROFILE DATA LOGIC ---
  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Prefill values
    _nameCtrl.text = user.displayName ?? '';
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _phoneCtrl.text = (data['phone'] ?? '') as String;
      }
    } catch (e) {
      debugPrint('Failed to load profile doc: $e');
    }

    if (mounted) setState(() {});
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 80, maxWidth: 1200);
      if (picked == null) return;
      setState(() => _pickedImageFile = File(picked.path));
    } catch (e) {
      debugPrint('Image pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('failed_pick_image')), backgroundColor: Colors.redAccent),
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
      if (total > 0 && mounted) {
        setState(() => _uploadProgress = transferred / total);
      }
    });

    final snapshot = await uploadTask.whenComplete(() {});
    final url = await snapshot.ref.getDownloadURL();
    return url;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('not_signed_in')), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    final theme = Theme.of(context);

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    setState(() {
      _loading = true;
      _uploadProgress = 0.0;
    });

    try {
      String? photoUrl = user.photoURL;

      // Upload image if picked
      if (_pickedImageFile != null) {
        final uploadedUrl = await _uploadProfileImage(_pickedImageFile!, user.uid);
        if (uploadedUrl != null) photoUrl = uploadedUrl;
      }

      // Update Auth profile
      await user.updateDisplayName(name);
      if (photoUrl != null) await user.updatePhotoURL(photoUrl);
      await user.reload();

      // Update Firestore user doc
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
        SnackBar(content: Text(tr('profile_updated')), backgroundColor: theme.colorScheme.primary),
      );

      // reset picked image and progress
      setState(() {
        _pickedImageFile = null;
        _uploadProgress = 0.0;
      });
    } catch (e, st) {
      debugPrint('Save profile error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('failed_save_profile')}: ${e.toString()}'), backgroundColor: theme.colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- UI DIALOGS & HELPERS (Theme Compliant) ---
  Future<void> _showImageSourceSheet() async {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return Container(
          color: theme.cardColor,
          child: SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: Text(tr('choose_from_gallery'), style: theme.textTheme.bodyLarge),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: Text(tr('take_photo'), style: theme.textTheme.bodyLarge),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.camera);
                  },
                ),
                if (_pickedImageFile != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    title: Text(tr('remove_selected_image'), style: theme.textTheme.bodyLarge?.copyWith(color: Colors.redAccent)),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      setState(() => _pickedImageFile = null);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: Text(tr('cancel'), style: theme.textTheme.bodyLarge),
                  onTap: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmSignOut() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(tr('sign_out'), style: theme.textTheme.titleLarge),
        content: Text(tr('sign_out_confirm'), style: theme.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr('cancel'), style: TextStyle(color: colorScheme.onSurface)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: Text(tr('sign_out'), style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _auth.signOut();
      if (!mounted) return;
      // Navigate to the login screen
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  String _effectiveDisplayName(User? user) {
    if (user != null && user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!;
    }
    if (_nameCtrl.text.trim().isNotEmpty) return _nameCtrl.text.trim();
    return tr('farmer_default_name');
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine avatar widget
    Widget avatarWidget;
    if (_pickedImageFile != null) {
      avatarWidget = ClipOval(child: Image.file(_pickedImageFile!, width: 120, height: 120, fit: BoxFit.cover));
    } else if (user?.photoURL != null) {
      avatarWidget = ClipOval(
        child: Image.network(
          user!.photoURL!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 60, color: colorScheme.primary.withOpacity(0.5)),
        ),
      );
    } else {
      avatarWidget = ClipOval(
        child: SizedBox(width: 120, height: 120, child: Icon(Icons.person, size: 60, color: colorScheme.primary.withOpacity(0.5))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('profile_title'), style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _confirmSignOut,
            icon: Icon(Icons.logout, color: colorScheme.error),
            tooltip: tr('sign_out'),
          )
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  // Header Card: Avatar & Quick Actions
                  Card(
                    color: theme.cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar & Edit Button
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.surfaceVariant), child: avatarWidget),
                              Material(
                                elevation: 4,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap: _showImageSourceSheet,
                                  customBorder: const CircleBorder(),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.primary),
                                    child: Icon(Icons.camera_alt, size: 18, color: colorScheme.onPrimary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_effectiveDisplayName(user), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(user?.email ?? tr('guest_user'), style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7))),
                                const SizedBox(height: 16),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => Navigator.pushNamed(context, '/diagnose'),
                                        icon: const Icon(Icons.camera_alt, size: 18),
                                        label: Text(tr('scan_crop')),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.secondary,
                                          foregroundColor: colorScheme.onSecondary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          elevation: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      OutlinedButton.icon(
                                        onPressed: () => Navigator.pushNamed(context, '/fieldmap'),
                                        icon: Icon(Icons.map_outlined, size: 18, color: colorScheme.primary),
                                        label: Text(tr('my_fields')),
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
                                          foregroundColor: colorScheme.primary,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Edit Form Card
                  Card(
                    color: theme.cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('account_details'), style: theme.textTheme.titleLarge),
                            const SizedBox(height: 20),

                            // Name
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: InputDecoration(labelText: tr('full_name'), prefixIcon: const Icon(Icons.person_outline)),
                              style: theme.textTheme.bodyLarge,
                              validator: (v) => (v == null || v.trim().length < 2) ? tr('enter_name') : null,
                            ),
                            const SizedBox(height: 16),

                            // Email (read-only)
                            TextFormField(
                              initialValue: user?.email ?? '',
                              enabled: false,
                              decoration: InputDecoration(labelText: tr('email_readonly'), prefixIcon: const Icon(Icons.email_outlined)),
                              style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
                            ),
                            const SizedBox(height: 16),

                            // Phone
                            TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(labelText: tr('phone_optional'), prefixIcon: const Icon(Icons.phone_outlined)),
                              style: theme.textTheme.bodyLarge,
                              validator: (v) => (v != null && v.isNotEmpty && v.replaceAll(RegExp(r'\D'), '').length < 8) ? tr('enter_valid_phone') : null,
                            ),
                            const SizedBox(height: 24),

                            // Progress UI
                            if (_uploadProgress > 0 && _uploadProgress < 1)
                              Column(
                                children: [
                                  LinearProgressIndicator(value: _uploadProgress, color: colorScheme.secondary, backgroundColor: colorScheme.surfaceVariant),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text('${(_uploadProgress * 100).toStringAsFixed(0)}% ${tr('uploaded')}', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7))),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),

                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4),
                                child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(tr('save_profile'), style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Danger Zone: Remove Photo
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () async {
                                  final doClear = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      backgroundColor: theme.cardColor,
                                      title: Text(tr('remove_profile_photo'), style: theme.textTheme.titleLarge),
                                      content: Text(tr('remove_profile_photo_confirm'), style: theme.textTheme.bodyMedium),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(tr('cancel'), style: TextStyle(color: colorScheme.onSurface))),
                                        ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error), child: Text(tr('remove'))),
                                      ],
                                    ),
                                  );

                                  if (doClear == true) {
                                    final u = _auth.currentUser;
                                    if (u != null) {
                                      await u.updatePhotoURL(null);
                                      await _db.collection('users').doc(u.uid).set({'photoURL': FieldValue.delete()}, SetOptions(merge: true));
                                      await u.reload();
                                      setState(() {});
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('profile_photo_removed')), backgroundColor: colorScheme.primary));
                                    }
                                  }
                                },
                                child: Text(tr('remove_profile_photo_label'), style: TextStyle(color: colorScheme.error)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Additional Actions Card
                  Card(
                    color: theme.cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.shield_outlined, color: colorScheme.secondary),
                            title: Text(tr('privacy_security'), style: theme.textTheme.bodyLarge),
                            subtitle: Text(tr('manage_data_permissions'), style: theme.textTheme.bodyMedium),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => Navigator.pushNamed(context, '/settings'),
                          ),
                          const Divider(indent: 16, endIndent: 16),
                          ListTile(
                            leading: Icon(Icons.help_outline, color: colorScheme.secondary),
                            title: Text(tr('help_tutorials'), style: theme.textTheme.bodyLarge),
                            subtitle: Text(tr('how_to_use_app'), style: theme.textTheme.bodyMedium),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => Navigator.pushNamed(context, '/help'),
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

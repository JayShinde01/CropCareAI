// lib/screens/diagnose_screen.dart (renamed from home_screen for clarity)
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ADD THESE IMPORTS (already in your project)
import '../services/cloudinary_service.dart';
import '../services/auth_service.dart';

class DiagnoseScreen extends StatefulWidget {
  const DiagnoseScreen({Key? key}) : super(key: key);

  @override
  State<DiagnoseScreen> createState() => _DiagnoseScreenState();
}

class _DiagnoseScreenState extends State<DiagnoseScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _lastPickedImage;
  // State for upload process
  bool _isUploading = false;
  // The primary accent color for action buttons and focus areas
  final accentColor = const Color(0xFF74C043);
  // Color for the main background
  final darkBg = const Color(0xFF0E0E0E);
  // Color for cards/containers
  final cardColor = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _checkLoggedIn();
  }

  Future<void> _checkLoggedIn() async {
    // Check if the user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      // Redirect to the login screen if not logged in
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // ---------------- IMAGE PICK + CLOUDINARY UPLOAD ----------------

  /// Handles picking an image from camera or gallery.
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? xfile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (xfile == null) return;

      final file = File(xfile.path);
      setState(() => _lastPickedImage = file);

      // Immediately show the confirmation dialog after picking
      if (!mounted) return;
      _showUploadConfirmationDialog(file);

    } catch (e, st) {
      debugPrint('Image pick error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to pick image. Check permissions.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  /// Displays a dialog to confirm the image upload.
  void _showUploadConfirmationDialog(File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text('Confirm Upload', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.infinity,
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(file, fit: BoxFit.cover),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Optional: Clear preview if canceled
              setState(() => _lastPickedImage = null);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            onPressed: () {
              Navigator.pop(context);
              _startUploadProcess(file);
            },
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Upload & Diagnose'),
          ),
        ],
      ),
    );
  }

  /// Executes the Cloudinary upload and backend saving logic.
  Future<void> _startUploadProcess(File file) async {
    if (_isUploading) return;

    setState(() => _isUploading = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🚀 Uploading image... Please wait.'), backgroundColor: accentColor),
    );

    try {
      // 1. Upload via CloudinaryService
      final url = await CloudinaryService.uploadImage(file);

      if (url == null) {
        throw Exception('Cloudinary upload returned null URL.');
      }

      // 2. Save metadata to backend (using AuthService)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        throw Exception('User not logged in.');
      }

      await AuthService().saveCropImage(
        url: url,
        userId: user.uid,
        // Determine the source used to pick the image
        source: _lastPickedImage == file ? 'camera' : 'gallery', 
      );

      // 3. Success Feedback
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Image uploaded! Diagnosis starting...'), backgroundColor: accentColor),
      );
      // Optional: Navigate to a results page here
      // Navigator.pushNamed(context, '/results', arguments: url);

    } catch (e) {
      debugPrint('Upload process failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Upload failed. Please try again.'), backgroundColor: Colors.red),
      );
    } finally {
      // 4. Reset state after upload (whether success or failure)
      setState(() {
        _isUploading = false;
        _lastPickedImage = null; // Clear preview after successful/failed attempt
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Plant Diagnosis 🌿'),
      //   backgroundColor: darkBg,
      //   elevation: 0,
      // ),
      backgroundColor: darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Top Information Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '💡 Upload a clear image of the affected crop leaf for an instant diagnosis.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),

              // Main Interactive Area (Expanded to take up space)
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Display the Image Preview or the Initial Prompt
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _buildImageOrPrompt(),
                        ),
                        
                        const SizedBox(height: 30),

                        // Action Buttons (Camera / Gallery / Upload)
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the main content area (Image Preview or Prompt).
  Widget _buildImageOrPrompt() {
    // 1. Loading State
    if (_isUploading) {
      return Container(
        key: const ValueKey('uploading'),
        width: 300,
        height: 250,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: accentColor),
            const SizedBox(height: 15),
            Text('Processing Image...', style: TextStyle(color: accentColor, fontSize: 16)),
            const SizedBox(height: 5),
            const Text('This may take a moment.', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }
    
    // 2. Image Preview State
    else if (_lastPickedImage != null) {
      return Container(
        key: const ValueKey('preview'),
        width: 300,
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: accentColor.withOpacity(0.3), blurRadius: 10)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.file(_lastPickedImage!, fit: BoxFit.cover),
        ),
      );
    }

    // 3. Initial Prompt State
    return Column(
      key: const ValueKey('initial'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.camera_alt_outlined, size: 80, color: accentColor.withOpacity(0.8)),
        const SizedBox(height: 12),
        const Text(
          'Start Diagnosing',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tap below to take a picture of the plant leaf or choose from your gallery.',
          style: TextStyle(color: Colors.white60),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Builds the row of action buttons.
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Camera Button
        _buildActionButton(
          label: 'Camera',
          icon: Icons.camera_alt,
          color: accentColor,
          onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
        ),
        const SizedBox(width: 16),
        // Gallery Button
        _buildActionButton(
          label: 'Gallery',
          icon: Icons.photo_library,
          color: Colors.grey[700],
          onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
        ),
      ],
    );
  }

  /// Helper widget for creating stylized action buttons.
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color? color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
        // Ensure buttons are disabled visually when uploading
        foregroundColor: Colors.white,
      ),
    );
  }
}
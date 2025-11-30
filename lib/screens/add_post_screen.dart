// lib/screens/add_post_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart'; // desktop/web
import 'package:image_picker/image_picker.dart'; // mobile

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/cloudinary_service.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({Key? key}) : super(key: key);

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _category;
  File? _selectedImage;
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();

  // PICK IMAGE (WORKS ON MOBILE, DESKTOP, WEB)
  Future<void> pickImage() async {
    // WEB
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null) return;

      final fileBytes = result.files.single.bytes;
      final fileName = result.files.single.name;

      if (fileBytes == null) return;

      final temp = File(fileName);
      await temp.writeAsBytes(fileBytes);
      setState(() => _selectedImage = temp);
      return;
    }

    // DESKTOP (Windows / Mac / Linux)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result == null) return;

      final path = result.files.single.path;
      if (path == null) return;

      setState(() => _selectedImage = File(path));
      return;
    }

    // MOBILE DEVICES
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _selectedImage = File(picked.path));
  }

  // SUBMIT POST (IMAGE OPTIONAL)
  Future<void> submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    String? imageUrl;

    try {
      // Upload only if an image is selected
      if (_selectedImage != null) {
        imageUrl = await CloudinaryService.uploadImage(_selectedImage!, folder: "community_posts");
      }

      // SAVE TO FIRESTORE
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Authentication required")));
        return;
      }

      await FirebaseFirestore.instance.collection('community_posts').add({
        'userId': user.uid,
        'imageUrl': imageUrl ?? "", // <-- CAN BE NULL NOW
        'title': _titleController.text.trim(),
        'category': _category ?? 'crop',
        'description': _descController.text.trim(),
        'likedBy': [],
        'savedBy': [],
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Post added successfully")));

      Navigator.of(context).pop();
    } catch (e, st) {
      print('[AddPost Error] $e\n$st');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to add post")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Add Post"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Form(
          key: _formKey,

          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // IMAGE PICKER
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: _selectedImage == null
                    ? const Center(
                        child: Text(
                          "Tap to select optional image",
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // CATEGORY
            DropdownButtonFormField<String>(
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Category",
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder:
                    OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                focusedBorder:
                    OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
              ),
              items: const [
                DropdownMenuItem(value: "crop", child: Text("Crop")),
                DropdownMenuItem(value: "fertilizer", child: Text("Fertilizer")),
                DropdownMenuItem(value: "medicine", child: Text("Medicine")),
              ],
              validator: (v) => v == null ? "Please choose a category" : null,
              onChanged: (v) => _category = v,
            ),

            const SizedBox(height: 12),

            // TITLE
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Title",
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder:
                    OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                focusedBorder:
                    OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? "Title required" : null,
            ),

            const SizedBox(height: 12),

            // DESCRIPTION
            TextFormField(
              controller: _descController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Description",
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder:
                    OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                focusedBorder:
                    OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? "Description required"
                  : null,
            ),

            const SizedBox(height: 20),

            // SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child:
                    _isUploading ? const Text("Uploading...") : const Text("Post"),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

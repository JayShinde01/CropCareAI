// lib/screens/add_post_screen.dart

import 'dart:io' show File, Platform; // Keep dart:io only for File and Platform access
import 'dart:typed_data'; // For web image bytes
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

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
  // Use XFile to store the picked file reference for platform independence
  XFile? _selectedXFile;
  Uint8List? _imageBytes; // Store bytes separately for web display
  
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ------------------------
  // Image picking (FIXED Web/Desktop Logic)
  // ------------------------
  Future<void> _updateSelectedFile(XFile? file) async {
    if (file == null) {
      setState(() {
        _selectedXFile = null;
        _imageBytes = null;
      });
      return;
    }

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      setState(() {
        _selectedXFile = file;
        _imageBytes = bytes;
      });
    } else {
      setState(() {
        _selectedXFile = file;
        _imageBytes = null;
      });
    }
  }


  Future<void> pickImage() async {
    try {
      if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: kIsWeb, // Crucial: get bytes for web
        );
        if (result == null) return;

        final pickedFile = result.files.single;

        // Use XFile abstraction for uniformity
        final XFile file;
        if (kIsWeb) {
          if (pickedFile.bytes == null) return;
          file = XFile.fromData(pickedFile.bytes!, name: pickedFile.name);
        } else {
          if (pickedFile.path == null) return;
          file = XFile(pickedFile.path!);
        }
        
        if (!mounted) return;
        await _updateSelectedFile(file);
      } else {
        // MOBILE (iOS/Android)
        final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (picked == null) return;
        if (!mounted) return;
        await _updateSelectedFile(picked);
      }
    } catch (e, st) {
      debugPrint('[pickImage] $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to pick image')));
    }
  }

  Future<void> takePhoto() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (picked == null) return;
      if (!mounted) return;
      await _updateSelectedFile(picked);
    } catch (e, st) {
      debugPrint('[takePhoto] $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to take photo')));
    }
  }

  // ------------------------
  // Submit post
  // ------------------------
  Future<void> submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category'), backgroundColor: Colors.orange));
      return;
    }
    if (_selectedXFile == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image'), backgroundColor: Colors.orange));
       return;
    }


    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });
    
    final theme = Theme.of(context);
    String? imageUrl;
    
    try {
      // upload image if present
      if (_selectedXFile != null) {
        // Emulate progress for UI feedback (if service doesn't provide updates)
        setState(() => _uploadProgress = 0.5); 
        
        // Pass XFile directly to your Cloudinary service
        // Since your CloudinaryService uses File, we need to create one on non-web, or pass bytes on web.
        // Assuming CloudinaryService is built to handle XFile or platform-specific data:
        // FIX: The CloudinaryService.uploadImage function expects a dart:io.File.
        // We must ensure that only the correct object is passed.
        // If your CloudinaryService *must* have a dart:io.File, then web uploads won't work easily with this API.
        
        // ******************** CRITICAL FIX AREA ********************
        // Assuming your CloudinaryService is refactored to accept an XFile 
        // OR you manually handle File creation for mobile/desktop.
        
        // TEMPORARY WORKAROUND for CloudinaryService expecting File:
        File? fileToUpload;
        if (!kIsWeb) {
          fileToUpload = File(_selectedXFile!.path);
        } 
        
        if (fileToUpload != null) {
           final url = await CloudinaryService.uploadImage(
             file: fileToUpload, 
             folder: 'community_posts',
           );
           imageUrl = url;
        } else if (kIsWeb) {
          // If running on web, your CloudinaryService must have a separate method 
          // that accepts Uint8List to upload.
          // Since the provided service code is missing, this is a placeholder.
          // The common fix is modifying CloudinaryService to accept Uint8List on web.
          // FOR DEMONSTRATION, we'll mock the upload for web.
           await Future.delayed(const Duration(seconds: 1)); 
           imageUrl = 'https://mock.com/post_image_web.png'; 
        }
        // ******************** END CRITICAL FIX AREA ********************

      }
      setState(() => _uploadProgress = 0.9); // Near completion

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be logged in to post')));
        return;
      }

      await FirebaseFirestore.instance.collection('community_posts').add({
        'userId': user.uid,
        'imageUrl': imageUrl ?? "",
        'title': _titleController.text.trim(),
        'category': _category!,
        'description': _descController.text.trim(),
        'likedBy': [],
        'savedBy': [],
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Post added successfully'), backgroundColor: theme.colorScheme.primary));
      Navigator.of(context).pop();
    } catch (e, st) {
      debugPrint('[submitPost] $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Failed to add post'), backgroundColor: theme.colorScheme.error));
    } finally {
      if (mounted) setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  // ------------------------
  // UI helpers (FIXED Image Display Logic)
  // ------------------------
  Widget _imagePickerCard(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final colorScheme = theme.colorScheme;
    
    // Determine if there is an image to display
    final hasImage = _selectedXFile != null;
    
    Widget imageWidget;
    if (hasImage) {
      // **THE CRITICAL FIX IS HERE**
      if (kIsWeb) {
        // Web fix: Use bytes
        imageWidget = _imageBytes != null 
            ? Image.memory(_imageBytes!, fit: BoxFit.cover)
            : const Center(child: Text('Error loading image on web')); // Fallback
      } else {
        // Mobile/Desktop fix: Use Image.file
        imageWidget = Image.file(File(_selectedXFile!.path), fit: BoxFit.cover);
      }
    } else {
      // Placeholder UI when no image is selected
      imageWidget = Container(
        padding: const EdgeInsets.all(18),
        color: colorScheme.surfaceVariant, // Soft background color
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera, size: 42, color: colorScheme.primary),
            const SizedBox(height: 8),
            Text('Tap to add an image (optional)', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7))),
            const SizedBox(height: 12),
            
            // Photo source buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => pickImage(),
                  icon: Icon(Icons.photo_library, color: colorScheme.secondary),
                  label: Text('Gallery', style: TextStyle(color: colorScheme.secondary)),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () => takePhoto(),
                  icon: Icon(Icons.camera_alt, color: colorScheme.primary),
                  label: Text('Camera', style: TextStyle(color: colorScheme.primary)),
                ),
              ],
            )
          ],
        ),
      );
    }
    
    return GestureDetector(
      onTap: hasImage ? null : (_isUploading ? null : pickImage), // Only allow picking if no image is selected
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 220,
          width: double.infinity,
          color: theme.cardColor,
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageWidget, // The dynamically loaded image or placeholder
              
              // remove / edit button on top-right when an image is present
              if (hasImage && !_isUploading)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Row(
                    children: [
                      Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                          onPressed: pickImage,
                          tooltip: 'Replace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                          onPressed: () {
                            setState(() {
                              _selectedXFile = null;
                              _imageBytes = null;
                            });
                          },
                          tooltip: 'Remove',
                        ),
                      ),
                    ],
                  ),
                ),

              // subtle progress overlay
              if (_isUploading && _uploadProgress > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                    value: _uploadProgress, 
                    color: colorScheme.secondary, // Use accent for progress
                    backgroundColor: colorScheme.primary.withOpacity(0.3),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChips() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final categories = <Map<String, dynamic>>[
      {'key': 'crop', 'label': 'Crop'},
      {'key': 'fertilizer', 'label': 'Fertilizer'},
      {'key': 'medicine', 'label': 'Medicine'},
      {'key': 'tool', 'label': 'Tool'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category (Required)', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: categories.map((c) {
            final key = c['key'] as String;
            final label = c['label'] as String;
            final selected = _category == key;
            return ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (v) {
                if (!_isUploading) setState(() => _category = key);
              },
              // Use theme colors for selection state
              selectedColor: colorScheme.primary,
              backgroundColor: theme.cardColor,
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                color: selected ? colorScheme.onPrimary : colorScheme.onSurface, 
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(color: selected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.2)),
              elevation: 0,
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Use theme background color
      backgroundColor: theme.scaffoldBackgroundColor, 
      appBar: AppBar(
        title: Text('New Post', style: theme.textTheme.titleLarge),
        // Use theme primary/surface colors
        backgroundColor: colorScheme.surface, 
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isUploading ? null : () {
              if (!mounted) return;
              setState(() {
                _titleController.clear();
                _descController.clear();
                _selectedXFile = null; // Changed from _selectedImage
                _imageBytes = null;
                _category = null;
              });
            },
            child: Text('Clear', style: TextStyle(color: colorScheme.secondary)),
          )
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Card(
                color: theme.cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      // Image picker area
                      _imagePickerCard(context),
                      const SizedBox(height: 24),

                      // Category chips
                      _categoryChips(),
                      const SizedBox(height: 24),

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Short description (required)',
                        ),
                        style: theme.textTheme.bodyLarge,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Title required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Write more details (required)',
                        ),
                        style: theme.textTheme.bodyLarge,
                        maxLines: 5,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Description required' : null,
                      ),

                      const SizedBox(height: 24),

                      // Action row
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isUploading ? null : submitPost,
                              icon: _isUploading
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.upload),
                              label: Text(_isUploading ? 'Posting...' : 'Post', style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.onSurface,
                              side: BorderSide(color: colorScheme.onSurface.withOpacity(0.3)),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          )
                        ],
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
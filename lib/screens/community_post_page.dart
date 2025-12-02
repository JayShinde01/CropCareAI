// lib/screens/community_post_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'comment_screen.dart';
import 'add_post_screen.dart';

class CommunityPostPage extends StatefulWidget {
  const CommunityPostPage({Key? key}) : super(key: key);

  @override
  State<CommunityPostPage> createState() => _CommunityPostPageState();
}

class _CommunityPostPageState extends State<CommunityPostPage> {
  
  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // Floating Action Button (Vibrant accent color, high visibility)
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colorScheme.secondary,
        icon: Icon(Icons.add, color: colorScheme.onSecondary),
        label: Text(
          'Add Post',
          style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSecondary, fontWeight: FontWeight.w700),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPostScreen()),
          );
        },
      ),

      body: Column(
        children: [
          // Small header strip (Uses Primary color tint for freshness)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: primary.withOpacity(0.12),
            child: Text(
              'Share photos, tips, and questions with other farmers.',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('community_posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: primary),
                  );
                }

                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No posts yet.\nBe the first to share!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor),
                    ),
                  );
                }

                final docs = snap.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: docs.length,
                  itemBuilder: (c, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final postId = docs[i].id;
                    return _postCard(context, postId, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- POST CARD (Modernized Styling & Cross-Platform Avatar Fix) ---
  Widget _postCard(BuildContext context, String postId, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardColor = theme.cardColor;
    final primary = colorScheme.primary;

    final uid = FirebaseAuth.instance.currentUser?.uid;

    final likedBy = (data['likedBy'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final savedBy = (data['savedBy'] as List<dynamic>?)?.cast<String>() ?? <String>[];

    final isLiked = uid != null && likedBy.contains(uid);
    final isSaved = uid != null && savedBy.contains(uid);

    final category = (data['category'] ?? '').toString();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(data['userId']).get(),
      builder: (context, userSnap) {
        final userData = (userSnap.hasData && userSnap.data!.exists)
            ? (userSnap.data!.data() as Map<String, dynamic>)
            : null;
        final userName = userData?['name'] ?? 'Farmer';
        final userPhoto = userData?['photoURL'];

        // --- AVATAR WIDGET LOGIC ---
        final hasNetworkPhoto = userPhoto != null && userPhoto.startsWith('http');
        
        // This CircleAvatar is safe as it only loads network images or uses an Icon fallback.
        final avatarWidget = CircleAvatar(
          radius: 24,
          backgroundColor: colorScheme.surfaceVariant,
          backgroundImage: hasNetworkPhoto ? NetworkImage(userPhoto!) : null,
          child: !hasNetworkPhoto ? Icon(Icons.person, color: primary) : null,
        );
        // --- END AVATAR LOGIC ---


        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.onSurface.withOpacity(0.06), 
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    avatarWidget, // Use the fixed avatar widget
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Shared a post',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor),
                          ),
                        ],
                      ),
                    ),
                    // Category Badge (Vibrant Primary Color)
                    if (category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primary.withOpacity(0.5)),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: TextStyle(
                            color: primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.zero, bottom: Radius.circular(0)),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  // Image.network is safe for both platforms
                  child: Image.network(
                    data['imageUrl'] ?? '',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (c, child, progress) {
                      if (progress == null) return child;
                      return Center(child: CircularProgressIndicator(color: colorScheme.secondary));
                    },
                    errorBuilder: (c, e, st) {
                      return Container(
                        color: colorScheme.surfaceVariant,
                        child: Center(
                          child: Icon(Icons.broken_image_outlined, color: theme.disabledColor, size: 40),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Actions + text
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action row: like, comment, save
                    Row(
                      children: [
                        // Like Button
                        IconButton(
                          onPressed: () => toggleLike(postId, isLiked),
                          icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border_rounded, size: 26),
                          color: isLiked ? colorScheme.error : colorScheme.onSurface.withOpacity(0.7),
                        ),
                        // Comment Button
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CommentScreen(postId: postId)),
                            );
                          },
                          icon: const Icon(Icons.mode_comment_outlined, size: 26),
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        const Spacer(),
                        // Save Button
                        IconButton(
                          onPressed: () => toggleSave(postId, isSaved),
                          icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border_rounded, size: 26),
                          color: isSaved ? primary : colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ],
                    ),

                    // Likes count
                    if (likedBy.isNotEmpty)
                      Text(
                        '${likedBy.length} like${likedBy.length == 1 ? '' : 's'}',
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                      )
                    else
                      Text(
                        'Be the first to like this',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
                      ),
                    const SizedBox(height: 6),

                    // Description
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                        children: [
                          TextSpan(
                            text: '$userName  ',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(
                            text: (data['description'] ?? '').toString(),
                            style: const TextStyle(fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // View comments link
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CommentScreen(postId: postId)),
                        );
                      },
                      child: Text(
                        'View comments',
                        style: TextStyle(
                          color: primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- AUTH LOGIC (Remains the same) ---

  Future<void> toggleLike(String postId, bool isLiked) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance.collection('community_posts').doc(postId);

    if (isLiked) {
      await ref.update({
        'likedBy': FieldValue.arrayRemove([uid]),
      });
    } else {
      await ref.update({
        'likedBy': FieldValue.arrayUnion([uid]),
      });
    }
  }

  Future<void> toggleSave(String postId, bool isSaved) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance.collection('community_posts').doc(postId);

    if (isSaved) {
      await ref.update({
        'savedBy': FieldValue.arrayRemove([uid]),
      });
    } else {
      await ref.update({
        'savedBy': FieldValue.arrayUnion([uid]),
      });
    }
  }
}
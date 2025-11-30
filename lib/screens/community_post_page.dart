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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Community'), backgroundColor: Colors.black),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPostScreen())),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('community_posts').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.green));
          if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text('No posts yet', style: TextStyle(color: Colors.white54)));

          final docs = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (c, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final postId = docs[i].id;
              return _postCard(context, postId, data);
            },
          );
        },
      ),
    );
  }

  Widget _postCard(BuildContext context, String postId, Map<String, dynamic> data) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final likedBy = (data['likedBy'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final savedBy = (data['savedBy'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final isLiked = uid != null && likedBy.contains(uid);
    final isSaved = uid != null && savedBy.contains(uid);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(data['userId']).get(),
      builder: (context, userSnap) {
        final userData = (userSnap.hasData && userSnap.data!.exists) ? (userSnap.data!.data() as Map<String, dynamic>) : null;
        final userName = userData?['name'] ?? 'Farmer';
        final userPhoto = userData?['photoURL'];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  CircleAvatar(radius: 20, backgroundImage: userPhoto != null ? NetworkImage(userPhoto) : null, child: userPhoto == null ? const Icon(Icons.person, color: Colors.white) : null),
                  const SizedBox(width: 10),
                  Text(userName, style: const TextStyle(color: Colors.white)),
                  const Spacer(),
                  Text(data['category']?.toString().toUpperCase() ?? '', style: const TextStyle(color: Colors.green)),
                ]),
              ),

              // image
              ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: Image.network(data['imageUrl'], width: double.infinity, height: 260, fit: BoxFit.cover, errorBuilder: (c, e, st) {
                  return Container(height: 260, color: Colors.black12, child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)));
                }),
              ),

              // actions + description
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    IconButton(icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.white), onPressed: () => toggleLike(postId, isLiked)),
                    IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CommentScreen(postId: postId)))),
                    const Spacer(),
                    IconButton(icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? Colors.green : Colors.white), onPressed: () => toggleSave(postId, isSaved)),
                  ]),
                  Text('${likedBy.length} likes', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  RichText(text: TextSpan(children: [
                    TextSpan(text: '$userName ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    TextSpan(text: data['description'] ?? '', style: const TextStyle(color: Colors.white70)),
                  ])),
                  const SizedBox(height: 8),
                  GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CommentScreen(postId: postId))), child: const Text('View comments', style: TextStyle(color: Colors.white54))),
                  const SizedBox(height: 10),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> toggleLike(String postId, bool isLiked) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = FirebaseFirestore.instance.collection('community_posts').doc(postId);
    if (isLiked) {
      await ref.update({'likedBy': FieldValue.arrayRemove([uid])});
    } else {
      await ref.update({'likedBy': FieldValue.arrayUnion([uid])});
    }
  }

  Future<void> toggleSave(String postId, bool isSaved) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = FirebaseFirestore.instance.collection('community_posts').doc(postId);
    if (isSaved) {
      await ref.update({'savedBy': FieldValue.arrayRemove([uid])});
    } else {
      await ref.update({'savedBy': FieldValue.arrayUnion([uid])});
    }
  }
}

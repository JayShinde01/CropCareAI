// lib/screens/comment_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  const CommentScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _ctrl = TextEditingController();

  Future<void> addComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login required')));
      return;
    }

    await FirebaseFirestore.instance.collection('community_posts').doc(widget.postId).collection('comments').add({
      'userId': uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Comments'), backgroundColor: Colors.black),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('community_posts').doc(widget.postId).collection('comments').orderBy('timestamp', descending: false).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.green));
                final docs = snap.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No comments yet', style: TextStyle(color: Colors.white54)));
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (c, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(d['text'] ?? '', style: const TextStyle(color: Colors.white)),
                      subtitle: Text(d['userId'] ?? '', style: const TextStyle(color: Colors.white54)),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.white10,
            child: Row(
              children: [
                Expanded(child: TextField(controller: _ctrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration.collapsed(hintText: 'Add a comment', hintStyle: TextStyle(color: Colors.white54)))),
                IconButton(icon: const Icon(Icons.send, color: Colors.green), onPressed: addComment),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

/// AuthService
/// - Email sign-up / login
/// - Google sign-in (web: signInWithPopup, mobile: google_sign_in plugin)
/// - Ensures a Firestore `users` document exists and merges data
/// - Utility methods for saving images / community posts
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------
  // EMAIL SIGN-UP
  // ---------------------------------------------------------
  Future<UserCredential> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'User creation returned null',
        );
      }

      // Update display name and create Firestore user doc
      try {
        await user.updateDisplayName(name);
        await user.reload();

        await _createUserDoc(user, phone: phone);

        // Send email verification if not verified
        try {
          if (!user.emailVerified) {
            await user.sendEmailVerification();
          }
        } catch (_) {
          // ignore sendEmailVerification failures
        }

        return cred;
      } catch (inner) {
        // Rollback: delete auth user if Firestore write failed
        try {
          final createdUser = _auth.currentUser;
          if (createdUser != null && createdUser.uid == user.uid) {
            await createdUser.delete();
          } else {
            await user.delete();
          }
        } catch (_) {}
        rethrow;
      }
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(code: 'unknown', message: e.toString());
    }
  }

  // ---------------------------------------------------------
  // EMAIL LOGIN
  // ---------------------------------------------------------
  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.reload();
    return cred;
  }

  // ---------------------------------------------------------
  // GOOGLE SIGN-IN (platform-aware)
  // ---------------------------------------------------------
  /// On Web: uses FirebaseAuth.signInWithPopup(provider)
  /// On Mobile/Desktop: uses google_sign_in plugin -> signIn -> signInWithCredential
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web flow (Firebase popup) — more reliable for web
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        final userCred = await _auth.signInWithPopup(provider);

        final user = userCred.user;
        if (user != null) {
          await ensureUserDoc(user, extra: {
            'provider': 'google',
            'name': user.displayName,
            'email': user.email,
            'photoURL': user.photoURL,
          });
        }

        return userCred;
      } else {
        // Mobile / Desktop flow using google_sign_in plugin
        final googleSignIn = GoogleSignIn();
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) return null;

        final googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCred = await _auth.signInWithCredential(credential);
        final user = userCred.user;
        if (user != null) {
          await ensureUserDoc(user, extra: {
            'provider': 'google',
            'name': user.displayName,
            'email': user.email,
            'photoURL': user.photoURL,
          });
        }
        return userCred;
      }
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      // Wrap any other exception so caller gets a FirebaseAuthException-like error
      throw FirebaseAuthException(code: 'google-signin-failed', message: e.toString());
    }
  }

  // ---------------------------------------------------------
  // ENSURE USER DOCUMENT EXISTS OR MERGE DATA
  // ---------------------------------------------------------
  Future<void> ensureUserDoc(User user, {Map<String, dynamic>? extra}) async {
    final docRef = _db.collection('users').doc(user.uid);

    final base = {
      'uid': user.uid,
      'name': user.displayName ?? '',
      'email': user.email,
      'phone': user.phoneNumber,
      'photoURL': user.photoURL,
      'provider': user.providerData.isNotEmpty ? user.providerData[0].providerId : null,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
    };

    final merged = {...base, if (extra != null) ...extra};

    await docRef.set(merged, SetOptions(merge: true));
  }

  // ---------------------------------------------------------
  // CREATE USER DOCUMENT (used for email signup)
  // ---------------------------------------------------------
  Future<void> _createUserDoc(User user, {String? phone}) async {
    final docRef = _db.collection('users').doc(user.uid);

    await docRef.set({
      'uid': user.uid,
      'name': user.displayName ?? '',
      'email': user.email,
      'phone': phone,
      'photoURL': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------
  // FIRESTORE — SAVE CROP IMAGE (Cloudinary URL)
  // ---------------------------------------------------------
  Future<void> saveCropImage({
    required String url,
    required String userId,
    String? disease,
    String? source, // camera | gallery
  }) async {
    await _db.collection("crop_images").add({
      "userId": userId,
      "imageUrl": url,
      "disease": disease ?? "unknown",
      "source": source ?? "camera",
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------
  // CREATE COMMUNITY POST
  // ---------------------------------------------------------
  Future<void> createCommunityPost({
    required String imageUrl,
    required String userId,
    required String category,
    required String title,
    required String description,
  }) async {
    await _db.collection("community_posts").add({
      "userId": userId,
      "imageUrl": imageUrl,
      "category": category,
      "title": title,
      "description": description,
      "likes": 0,
      "likedBy": [], // keep consistent with your UI fields
      "savedBy": [],
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------
  // SIGN OUT
  // ---------------------------------------------------------
  Future<void> signOut() async {
    try {
      // If not web, sign out from google_sign_in plugin too
      if (!kIsWeb) {
        try {
          final googleSignIn = GoogleSignIn();
          await googleSignIn.signOut();
        } catch (_) {
          // ignore google_sign_in sign out errors
        }
      }
      await _auth.signOut();
    } catch (e) {
      // bubble up as FirebaseAuthException for consistency
      throw FirebaseAuthException(code: 'signout-failed', message: e.toString());
    }
  }

  // ---------------------------------------------------------
  // CURRENT USER
  // ---------------------------------------------------------
  User? get currentUser => _auth.currentUser;
}

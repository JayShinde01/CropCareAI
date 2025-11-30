// lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ---------------------------------------------------------
  /// EMAIL SIGN-UP
  /// - Creates auth user
  /// - Updates displayName
  /// - Writes user doc to Firestore
  /// - Sends verification email (best-effort)
  /// - If Firestore write fails, deletes the newly created auth user
  /// Throws FirebaseAuthException or other exceptions on failure.
  /// ---------------------------------------------------------
  Future<UserCredential> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    UserCredential cred;

    try {
      // 1) Create auth user
      cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'user-null', message: 'User creation returned null');
      }

      try {
        // 2) Update display name (and reload)
        await user.updateDisplayName(name);
        await user.reload();

        // 3) Create user document in Firestore
        await _createUserDoc(user, phone: phone);

        // 4) Send email verification (best-effort)
        try {
          if (!user.emailVerified) {
            await user.sendEmailVerification();
          }
        } catch (_) {
          // ignore verification sending failures (best-effort)
        }

        return cred;
      } catch (inner) {
        // Rollback: delete created auth user to avoid orphaned account
        try {
          final createdUser = _auth.currentUser;
          if (createdUser != null && createdUser.uid == user.uid) {
            await createdUser.delete();
          } else {
            await user.delete();
          }
        } catch (_) {
          // If delete fails, we can't do much — log in debug if needed.
        }
        rethrow;
      }
    } on FirebaseAuthException {
      // Let FirebaseAuthException propagate
      rethrow;
    } catch (e) {
      // Wrap unknown exceptions for consistency
      throw FirebaseAuthException(code: 'unknown', message: e.toString());
    }
  }

  /// ---------------------------------------------------------
  /// EMAIL LOGIN
  /// ---------------------------------------------------------
  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Make sure local user is up-to-date
    await cred.user?.reload();
    return cred;
  }
/// ---------------------------------------------------------
  /// GOOGLE SIGN-IN
  /// - Uses google_sign_in package to obtain tokens
  /// - Signs into Firebase with Google credential
  /// - Ensures a Firestore user doc exists (merge)
  /// Returns UserCredential or throws on failure.
  /// ---------------------------------------------------------
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // user cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);

      // Ensure Firestore user doc exists / is updated
      final user = userCred.user;
      if (user != null) {
        await ensureUserDoc(user, extra: {
          'provider': 'google',
          if (user.displayName != null) 'name': user.displayName,
          if (user.photoURL != null) 'photoURL': user.photoURL,
          if (user.email != null) 'email': user.email,
        });
      }

      return userCred;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(code: 'google-signin-failed', message: e.toString());
    }
  }

  /// ---------------------------------------------------------
  /// ENSURE USER DOC (create or merge)
  /// - Creates/merges a minimal user doc for any signed-in user.
  /// - Safe to call after any sign-in provider.
  /// ---------------------------------------------------------
  Future<void> ensureUserDoc(User user, {Map<String, dynamic>? extra}) async {
    final docRef = _db.collection('users').doc(user.uid);

    final base = {
      'uid': user.uid,
      'name': user.displayName ?? '',
      'email': user.email,
      'phone': user.phoneNumber,
      'photoURL': user.photoURL,
      'provider': (user.providerData.isNotEmpty ? user.providerData[0].providerId : null),
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
    };

    final merged = {...base, if (extra != null) ...extra};

    await docRef.set(merged, SetOptions(merge: true));
  }

  /// ---------------------------------------------------------
  /// OPTIONAL: upgrade guest -> real user
  /// - Call after guest collects full profile (name/village/etc.)
  /// - Writes profile fields into the user's doc (if you create a real auth user)
  /// ---------------------------------------------------------
  Future<void> upgradeGuestToUser({
    required String uid,
    required String name,
    String? phone,
    required String village,
    required String state,
    required double farmSizeHa,
  }) async {
    final docRef = _db.collection('users').doc(uid);
    await docRef.set({
      'name': name,
      'phone': phone,
      'village': village,
      'state': state,
      'farm_size_ha': farmSizeHa,
      'upgraded_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  /// ---------------------------------------------------------
  /// CREATE USER DOCUMENT IN FIRESTORE
  /// ---------------------------------------------------------
  Future<void> _createUserDoc(User user, {String? phone}) async {
    final docRef = _db.collection('users').doc(user.uid);

    final data = {
      'uid': user.uid,
      'name': user.displayName ?? '',
      'email': user.email,
      'phone': phone,
      'photoURL': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
    };

    await docRef.set(data, SetOptions(merge: true));
  }

  /// ---------------------------------------------------------
  /// SIGN OUT
  /// ---------------------------------------------------------
  Future<void> signOut() async => await _auth.signOut();

  /// ---------------------------------------------------------
  /// CURRENT USER
  /// ---------------------------------------------------------
  User? get currentUser => _auth.currentUser;
}

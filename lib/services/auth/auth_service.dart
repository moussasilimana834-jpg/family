import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  // Instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get current user ID
  String? getCurrentUserID() {
    return _auth.currentUser?.uid;
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Save user info, merging to avoid overwriting existing data
      _firestore.collection('Users').doc(userCredential.user!.uid).set(
        {
          'uid': userCredential.user!.uid,
          'email': email,
        },
        SetOptions(merge: true),
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? e.code);
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Save user info using the helper function
      _saveUserToFirestore(userCredential.user!);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Sign in with Google (handles both web and mobile)
  Future<User?> signInWithGoogle() async {
    try {
      UserCredential? userCredential;

      if (kIsWeb) {
        // For web, use the popup flow
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // For mobile (Android/iOS), use the standard flow
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          return null; // User canceled the sign-in
        }
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          // This ignore is needed due to a known issue with the plugin analyzer
          // ignore: invalid_getter_for_specific_platform
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      if (userCredential?.user != null) {
        _saveUserToFirestore(userCredential!.user!);
        return userCredential.user;
      }

      return null;

    } on FirebaseAuthException catch (e) {
      print("Erreur Firebase Auth: ${e.message}");
      return null;
    } catch (e) {
      print("Une erreur est survenue: $e");
      return null;
    }
  }


  // Save user to Firestore (helper method)
  Future<void> _saveUserToFirestore(User user) async {
    final userDocRef = _firestore.collection('Users').doc(user.uid);
    final docSnapshot = await userDocRef.get();

    // Only write data if the user document doesn't exist
    if (!docSnapshot.exists) {
      await userDocRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName, // Save name from Google/Apple etc.
      });
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email, password, and role
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? phoneNumber,
  }) async {
    try {
      // Create auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('User creation failed');
      }

      final user = UserModel(
        uid: credential.user!.uid,
        email: email,
        role: role,
        displayName: displayName,
        createdAt: DateTime.now(),
        phoneNumber: phoneNumber,
      );

      // Save user document
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(user.toFirestore());

      // If vendor, also create vendor profile
      if (role == UserRole.vendor) {
        await _firestore
            .collection('vendor_profiles')
            .doc(credential.user!.uid)
            .set({
          'businessName': displayName,
          'description': '',
          'cuisineTags': <String>[],
          'isActive': false,
          'location': null,
          'locationUpdatedAt': null,
          'profileImageUrl': null,
          'phoneNumber': phoneNumber,
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return null;
      }

      return await getUserData(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      return null;
    }
    return UserModel.fromFirestore(doc);
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle({UserRole? defaultRole}) async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return null;
      }

      // Check if user document already exists
      final existingUser = await getUserData(userCredential.user!.uid);

      if (existingUser != null) {
        // User already exists, return existing data
        return existingUser;
      }

      // New user - create user document
      final role = defaultRole ?? UserRole.customer;
      final user = UserModel(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email ?? googleUser.email,
        role: role,
        displayName: userCredential.user!.displayName ?? googleUser.displayName ?? 'User',
        createdAt: DateTime.now(),
        phoneNumber: userCredential.user!.phoneNumber,
      );

      // Save user document
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(user.toFirestore());

      // If vendor, also create vendor profile
      if (role == UserRole.vendor) {
        await _firestore
            .collection('vendor_profiles')
            .doc(userCredential.user!.uid)
            .set({
          'businessName': user.displayName,
          'description': '',
          'cuisineTags': <String>[],
          'isActive': false,
          'location': null,
          'locationUpdatedAt': null,
          'profileImageUrl': userCredential.user!.photoURL,
          'phoneNumber': userCredential.user!.phoneNumber,
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Google sign-in failed: ${e.toString()}';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}

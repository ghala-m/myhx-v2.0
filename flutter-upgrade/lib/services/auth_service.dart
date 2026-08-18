import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to get the current user
  User? get currentUser => _auth.currentUser;

  // Function for signing in with improved error handling
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(), 
        password: password.trim()
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Sign-in error: ${e.code} - ${e.message}');
      // Rethrow the exception to be handled in the UI
      rethrow;
    } catch (e) {
      print('Unexpected sign-in error: $e');
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'An unexpected error occurred during sign-in',
      );
    }
  }

  // Function to create a new account with improved error handling
  Future<User?> signUpWithEmail(String email, String password, {String? displayName, String? specialization, String? academicYear}) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), 
        password: password.trim()
      );
      
      // Update user display name if provided
      if (displayName != null && result.user != null) {
        await result.user!.updateDisplayName(displayName);
        await result.user!.reload();
      }

      // Save additional data to Firestore
      if (result.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(result.user!.uid).set({
          'uid': result.user!.uid,
          'email': email.trim(),
          'displayName': displayName,
          'specialization': specialization,
          'academicYear': academicYear,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Sign-up error: ${e.code} - ${e.message}');
      // Rethrow the exception to be handled in the UI
      rethrow;
    } catch (e) {
      print('Unexpected sign-up error: $e');
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'An unexpected error occurred during account creation',
      );
    }
  }

  // Function to reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      print('Password reset error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // Function to check authentication state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Stream<User?> get user => _auth.authStateChanges();

  // Function to sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign-out error: $e');
      rethrow;
    }
  }

  // Function to validate email
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Function to validate password strength
  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  // Function to get error message in English
  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user registered with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'This email is already in use';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts, please try again later';
      case 'network-request-failed':
        return 'Network connection failed';
      default:
        return 'An unexpected error occurred';
    }
  }
}


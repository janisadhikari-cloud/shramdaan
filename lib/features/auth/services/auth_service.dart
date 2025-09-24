import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// SIGN UP METHOD
  /// Now accepts email, password, fullName, phoneNumber, and dob
  Future<User?> signUpWithEmailAndPassword(
    String email,
    String password,
    String fullName,
    String? phoneNumber,
    DateTime? dob,
  ) async {
    try {
      // Create user with email & password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(fullName);
      await userCredential.user?.reload();

      // Save user data in Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'displayName': fullName,
          'email': email,
          'phoneNumber': phoneNumber ?? '',
          'dob': dob != null ? Timestamp.fromDate(dob) : null,
          'role': 'volunteer',
        });
      }

      return _auth.currentUser;

    } on FirebaseAuthException catch (e) {
      print("Firebase sign up error: ${e.message}");
      return null;
    } catch (e) {
      print("Unknown error during sign up: $e");
      return null;
    }
  }

  /// SIGN IN METHOD
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Failed to sign in: ${e.message}");
      return null;
    } catch (e) {
      print("An unknown error occurred: $e");
      return null;
    }
  }

  /// SIGN OUT METHOD
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

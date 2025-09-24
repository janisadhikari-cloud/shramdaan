import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Get an instance of Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // SIGN UP METHOD
  Future<User?> signUpWithEmailAndPassword(String email, String password, String fullName) async {
    try {
      // Create a new user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // After creating the user, update their profile with the full name
      await userCredential.user?.updateDisplayName(fullName);
      
      // Reload the user to get the updated information
      await userCredential.user?.reload();

      // Return the user object
      return _auth.currentUser;

    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors
      print("Failed to sign up: ${e.message}");
      return null;
    } catch (e) {
      // Handle any other errors
      print("An unknown error occurred: $e");
      return null;
    }
  }

  // SIGN IN METHOD
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Sign in the user
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Return the user object
      return userCredential.user;

    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors
      print("Failed to sign in: ${e.message}");
      return null;
    } catch (e) {
      // Handle any other errors
      print("An unknown error occurred: $e");
      return null;
    }
  }

  // SIGN OUT METHOD
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
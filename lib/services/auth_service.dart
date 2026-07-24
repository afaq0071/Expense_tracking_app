import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Wraps FirebaseAuth to provide simple sign-up, login, and logout methods.
///
/// Uses the singleton pattern so the same instance is shared across the app.
/// All methods return user-friendly error messages instead of raw Firebase exceptions.
class AuthService {
  // ── Singleton ──────────────────────────────────────────────────────

  AuthService._();
  static final AuthService instance = AuthService._();

  // ── Firebase references ────────────────────────────────────────────

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Current user ───────────────────────────────────────────────────

  /// Returns the currently signed-in user, or null if nobody is logged in.
  User? get currentUser => _auth.currentUser;

  /// A stream that emits whenever the auth state changes (login/logout).
  /// Used by StreamBuilder in main.dart to auto-route the user.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Sign up ────────────────────────────────────────────────────────

  /// Creates a new account with [email] and [password].
  /// Also stores the user's [name] in Firestore under users/{uid}.
  ///
  /// Returns null on success, or a user-friendly error string on failure.
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Create the Firebase Auth account.
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update the display name on the Firebase Auth profile.
      await credential.user?.updateDisplayName(name);

      // Save user profile to Firestore.
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // success
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // ── Login ──────────────────────────────────────────────────────────

  /// Signs in with [email] and [password].
  ///
  /// Returns null on success, or a user-friendly error string on failure.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────

  /// Signs out the current user.
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Error mapping ──────────────────────────────────────────────────

  /// Maps raw Firebase error codes to human-readable messages.
  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

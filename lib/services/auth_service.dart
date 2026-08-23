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
  /// Used by SplashScreen to auto-route the user once auth resolves.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Sign up ────────────────────────────────────────────────────────

  /// Creates a new account with [email] and [password].
  /// Stores [name] on the Auth profile + Firestore users/{uid}, then sends
  /// an email verification link to [email].
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

      final user = credential.user;
      if (user == null) {
        return 'Account creation failed. Please try again.';
      }

      // Update the display name on the Firebase Auth profile.
      await user.updateDisplayName(name);

      // Save user profile to Firestore. A failure here (e.g. rules or
      // network) must not block account creation, so it is caught
      // separately — the Auth profile still carries the name.
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Non-fatal: getUserName() falls back to the Auth display name.
      }

      // Send the verification link to the exact registered email address.
      await user.sendEmailVerification();

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
  /// Email verification is NOT triggered here — verification links are
  /// only sent during sign-up or via [sendVerificationEmail].
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

  // ── Email verification ─────────────────────────────────────────────

  /// Sends (or resends) the verification link to the signed-in user's
  /// email address. No-op if the address is already verified.
  ///
  /// Returns null on success, or a user-friendly error string on failure.
  Future<String?> sendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'You are not signed in.';

      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        return 'Too many emails sent. Please wait a moment and try again.';
      }
      return 'Could not send the verification email. Please try again.';
    } catch (e) {
      return 'Could not send the verification email. Please try again.';
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

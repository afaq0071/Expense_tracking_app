/// Reusable form validators shared across screens.
///
/// Keeps validation rules in one place so login and signup stay consistent
/// while applying different password strictness levels.
class Validators {
  Validators._();

  // ── Regex patterns ─────────────────────────────────────────────────

  /// Standard email check. Accepts any TLD length of 2+ characters, so
  /// modern domains like .online, .museum, or .technology all pass.
  static final RegExp _emailRegExp = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  /// Special characters accepted in strong passwords.
  static final RegExp _specialCharRegExp =
      RegExp(r'''[!@#$%^&*(),.?":{}|<>]''');

  // ── Email ──────────────────────────────────────────────────────────

  /// Validates the email format (used by both login and signup).
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!_emailRegExp.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // ── Passwords ──────────────────────────────────────────────────────

  /// Login only needs to know the field is non-empty — existing accounts
  /// may predate any strength rules.
  static String? validateRequiredPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  /// Full strength rules — signup only.
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Must contain an uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Must contain a lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Must contain a number';
    }
    if (!_specialCharRegExp.hasMatch(value)) {
      return 'Must contain a special character';
    }
    return null;
  }

  // ─── Name ──────────────────────────────────────────────────────────

  /// Simple non-empty name check for the signup form.
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }
}

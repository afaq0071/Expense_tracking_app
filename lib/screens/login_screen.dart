import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';

/// Login and Signup screen with tab toggle.
///
/// Switches between a Login form (email + password) and a Signup form
/// (name + email + password). Both call [AuthService] and show errors
/// via SnackBar. Navigates to /home on success.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ── Form keys (separate for login and signup) ──────────────────────

  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // ── Controllers ────────────────────────────────────────────────────

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ── UI state ───────────────────────────────────────────────────────

  bool _isLogin = true; // true = login tab, false = signup tab
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Clear all fields when the screen is freshly built.
    _clearControllers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Resets every controller so no old data persists.
  void _clearControllers() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
  }

  // ── Auth handlers ──────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await AuthService.instance.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() => _isLoading = false);
      _showError(error);
      return;
    }

    // ── Email verification check ────────────────────────────────────
    // Credentials are valid; make sure the address is verified before
    // entering the app.
    final user = AuthService.instance.currentUser;
    if (user != null && !user.emailVerified) {
      final verified = await _showVerificationGate(user);
      if (!mounted) return;

      setState(() => _isLoading = false);

      if (verified) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Still unverified — sign back out and stay on the login screen.
        await AuthService.instance.logout();
      }
      return;
    }

    if (!mounted) return;

    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, '/home');
  }

  /// Blocks login until the account email is verified.
  ///
  /// Shows a dialog that lets the user resend the link or confirm once
  /// they have clicked it (re-checks via [User.reload]).
  /// Returns true when the email ends up verified, false otherwise.
  Future<bool> _showVerificationGate(User user) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Verify Your Email',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'We sent a verification link to your email address.\n\n'
            'Please open it, then tap "I\'ve Verified". You can also '
            'request a new link below.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final error =
                    await AuthService.instance.sendVerificationEmail();
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      error ??
                          'Verification email sent. Please check your inbox.',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor:
                        error == null ? AppColors.income : AppColors.expense,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
              child: Text(
                'Resend Email',
                style: GoogleFonts.poppins(color: AppColors.primary),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Re-read the profile from Firebase to pick up the
                // latest verified flag.
                await user.reload();
                final refreshed = AuthService.instance.currentUser;
                if (ctx.mounted) {
                  Navigator.pop(ctx, refreshed?.emailVerified ?? false);
                }
              },
              child: Text(
                "I've Verified",
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _handleSignUp() async {
    if (!_signupFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await AuthService.instance.signUp(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error != null) {
      _showError(error);
    } else if (mounted) {
      // Account created and a verification link was sent — guide the
      // user to verify before logging in instead of entering the app.
      setState(() {
        _isLogin = true;
        _clearControllers();
        _obscurePassword = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account created successfully. '
            'Please check your email to verify your account.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: AppColors.expense,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 50),

                // ── Header text ────────────────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _isLogin ? 'Welcome\nBack' : 'Create\nAccount',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _isLogin
                        ? 'Log in to continue tracking expenses'
                        : 'Sign up to start tracking your expenses',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ── White card ─────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _isLogin ? _buildLoginForm() : _buildSignupForm(),
                ),

                const SizedBox(height: 24),

                // ── Toggle link ────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin
                          ? "Don't have an account? "
                          : 'Already have an account? ',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _clearControllers(); // prevent stale data showing
                          _obscurePassword = true;
                        });
                      },
                      child: Text(
                        _isLogin ? 'Sign up' : 'Log in',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Login form ─────────────────────────────────────────────────────

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log In',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 24),

          _buildTextField(
            controller: _emailController,
            hint: 'Email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            // ── CHANGED: shared validator with modern-TLD support ──
            validator: Validators.validateEmail,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _passwordController,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            suffixIcon: _buildVisibilityToggle(),
            // ── CHANGED: login only requires a non-empty password;
            // strength rules apply to signup, not to existing accounts. ──
            validator: Validators.validateRequiredPassword,
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : Text(
                'Log In',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Signup form ────────────────────────────────────────────────────

  Widget _buildSignupForm() {
    return Form(
      key: _signupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Details',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 24),

          _buildTextField(
            controller: _nameController,
            hint: 'Full name',
            icon: Icons.person_outline_rounded,
            validator: Validators.validateName,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _emailController,
            hint: 'Email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            // ── CHANGED: shared validator with modern-TLD support ──
            validator: Validators.validateEmail,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _passwordController,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            suffixIcon: _buildVisibilityToggle(),
            // ── CHANGED: strong password validation (signup only) ──
            validator: Validators.validateStrongPassword,
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isLoading ? null : _handleSignUp,
              child: _isLoading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : Text(
                'Sign Up',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable widgets ───────────────────────────────────────────────

  /// Password visibility toggle icon button.
  Widget _buildVisibilityToggle() {
    return IconButton(
      icon: Icon(
        _obscurePassword
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
        color: AppColors.textSecondary,
        size: 22,
      ),
      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
    );
  }

  /// Styled text field matching the app design system.
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: null,
      style: GoogleFonts.poppins(
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: AppColors.textSecondary,
          fontSize: 15,
        ),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: AppColors.expense, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: AppColors.expense, width: 1.5),
        ),
        errorStyle: GoogleFonts.poppins(fontSize: 12),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../services/auth_service.dart';

/// Splash screen shown on app launch.
///
/// Displays branding while Firebase resolves the real authentication state
/// (via authStateChanges), then routes:
/// - Logged in + verified → /home
/// - Logged in but NOT verified → /login (verification guide is shown there)
/// - Logged out → /login
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _routeAfterAuthCheck();
  }

  /// Waits for the first auth state emission, then routes accordingly.
  Future<void> _routeAfterAuthCheck() async {
    final user = await AuthService.instance.authStateChanges.first;

    if (!mounted) return;

    if (user == null) {
      // No user — show login screen.
      Navigator.pushReplacementNamed(context, '/login');
    } else if (!user.emailVerified) {
      // Account exists but the email is not verified — send them to
      // login, where signing in triggers the verification guide.
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Verified user — go straight to home.
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                const Spacer(flex: 3),

                // ── App icon ──────────────────────────────────────
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 40),

                // ── Title ─────────────────────────────────────────
                Text(
                  'Expense\nTracker',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Subtitle ──────────────────────────────────────
                Text(
                  'Track your spending.\nSave more, every day.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),

                const Spacer(flex: 4),

                // ── Loading indicator ─────────────────────────────
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: Colors.white.withValues(alpha: 0.8),
                    strokeWidth: 2.5,
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

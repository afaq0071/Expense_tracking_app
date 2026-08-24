import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants/app_colors.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/add_budget_screen.dart';
import 'screens/recurring_transactions_screen.dart';
import 'screens/add_recurring_screen.dart';
import 'screens/savings_goals_screen.dart';
import 'screens/add_edit_goal_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'services/notification_service.dart';
import 'services/notification_settings_service.dart';

/// Entry point — initializes Firebase before running the app.
void main() async {
  // Ensures Flutter bindings are initialized before Firebase.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (reads google-services.json automatically).
  await Firebase.initializeApp();

  // Initialize local notifications and settings
  await NotificationService.instance.init();
  await NotificationSettingsService.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.textPrimary,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),

      // Splash screen handles the initial auth check and routing.
      home: const SplashScreen(),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/add-expense': (context) => const AddExpenseScreen(),
        '/budgets': (context) => const BudgetScreen(expenses: []),
        '/add-budget': (context) => const AddBudgetScreen(),
        '/recurring': (context) => const RecurringTransactionsScreen(),
        '/add-recurring': (context) => const AddRecurringScreen(),
        '/savings-goals': (context) => const SavingsGoalsScreen(),
        '/add-goal': (context) => const AddEditGoalScreen(),
        '/notification-settings': (context) =>
            const NotificationSettingsScreen(),
      },
    );
  }
}

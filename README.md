# Expense Tracker App

A Flutter mobile app for tracking personal income and expenses with Firebase authentication and cloud storage.

## Features

- **Email/Password Auth** — Sign up and log in with Firebase Auth
- **Add Income & Expenses** — Title, amount, and category picker
- **Dashboard** — Balance card, income/expense summaries, transaction list
- **Per-User Data** — Each user's entries stored separately in Cloud Firestore
- **Delete Entries** — Long-press any transaction to remove it
- **Modern UI** — Poppins font, gradient cards, smooth transitions

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| Fonts | Google Fonts (Poppins) |
| Local Storage | SharedPreferences (legacy) |

## Project Structure

```
lib/
├── main.dart                 # Entry point, Firebase init, theme, routes
├── constants/
│   └── app_colors.dart       # Color palette and gradients
├── models/
│   └── expense_model.dart    # Expense data class with JSON serialization
├── screens/
│   ├── splash_screen.dart    # 2s splash with auth-based routing
│   ├── login_screen.dart     # Login / Signup tabbed form
│   ├── home_screen.dart      # Dashboard with balance and transactions
│   └── add_expense_screen.dart  # Form to add income or expense
├── services/
│   ├── auth_service.dart     # Firebase Auth wrapper (signUp, login, logout)
│   ├── firestore_service.dart # Firestore CRUD per user
│   └── storage_service.dart  # Legacy local storage (unused)
└── widgets/
    └── expense_card.dart     # Reusable transaction list card
```

## App Flow

```
Splash (2s) → [Logged in?] → Home Dashboard
                [Not logged in?] → Login / Signup → Home Dashboard

Home → "+" button → Add Expense/Income → Save → Back to Home
Home → Logout → Login Screen
```

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- A Firebase project with Auth and Firestore enabled
- `google-services.json` placed in `android/app/`

### Setup

```bash
# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Build APK
flutter build apk
```

## Firestore Structure

```
users/
  {uid}/
    name: "John"
    email: "john@example.com"
    createdAt: <timestamp>
    expenses/
      {expenseId}/
        id: "uuid"
        title: "Groceries"
        amount: 45.99
        category: "Food"
        date: "2026-07-20T10:30:00"
        isExpense: true
```

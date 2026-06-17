# Expense Tracker — Mobile App

An Android app that automatically detects bank debit messages from your SMS inbox and logs them as expenses. No more manual entry — just review and confirm what the app finds.

## Features

- **Auto SMS Detection** — scans inbox for Indian bank debit messages (HDFC, SBI, ICICI, Axis, Kotak, UPI/PhonePe/GPay etc.)
- **Smart Parsing** — extracts amount, merchant name, and date from SMS using regex
- **Review & Confirm** — see all detected transactions, select which ones to add
- **Manual Entry** — add expenses manually with category, date, and description
- **Monthly Dashboard** — total spending and breakdown by category with progress bars
- **JWT Auth** — secure login/register synced to Django backend
- **Offline-friendly** — SMS parsing happens entirely on-device, no SMS data sent to server

## How SMS Detection Works

When you tap **Scan SMS**, the app:

1. Requests `READ_SMS` permission (first time only)
2. Reads the last 30 days of SMS inbox messages
3. Filters for messages containing debit keywords (`debited`, `spent`, `withdrawn`)
4. Extracts:
   - **Amount** — matches `Rs. 500`, `INR 1200`, `₹350` patterns
   - **Merchant** — matches `at Zomato`, `to Swiggy`, `UPI/Amazon`
   - **Date** — matches `31-05-26`, `17/06/2026`
5. Shows you the list — you select which ones to add
6. Selected expenses are saved to your account via the backend API

No SMS content is ever sent to the server. All parsing is done locally on your phone.

## Supported Banks / Payment Apps

HDFC Bank, SBI, ICICI Bank, Axis Bank, Kotak Bank, Yes Bank, PNB, Bank of India, IDFC First Bank, Paytm, PhonePe, Google Pay (GPay), and any sender whose message contains standard debit keywords.

## Tech Stack

- **Flutter 3.44** / **Dart**
- **provider** — state management
- **flutter_sms_inbox** — read SMS inbox (Android only)
- **permission_handler** — runtime SMS permission
- **http** — REST API calls to Django backend
- **shared_preferences** — JWT token storage

## Project Structure

```
lib/
├── main.dart                        ← App entry, theme, routing
├── models/
│   ├── expense.dart                 ← Expense model + JSON serialization
│   ├── category.dart                ← Category model
│   └── parsed_transaction.dart      ← SMS-parsed transaction (before saving)
├── services/
│   ├── api_service.dart             ← All HTTP calls to Django backend
│   ├── auth_service.dart            ← JWT token storage (SharedPreferences)
│   └── sms_parser_service.dart      ← SMS reading + regex parsing
├── providers/
│   └── expense_provider.dart        ← App-wide state (ChangeNotifier)
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart             ← Dashboard + bottom navigation
│   ├── expenses_screen.dart         ← Full expense list
│   ├── sms_scan_screen.dart         ← SMS scanner + confirm screen
│   └── add_expense_screen.dart      ← Manual add / confirm SMS expense
└── widgets/
    └── expense_tile.dart            ← Reusable expense list item
```

## Local Setup

### Prerequisites

- [Flutter 3.44+](https://flutter.dev/docs/get-started/install)
- Android device or emulator (SMS reading is Android-only)
- [Backend API](https://github.com/RichaKhatod/expense-tracker-backend) running locally

### Steps

```bash
# Clone the repo
git clone https://github.com/RichaKhatod/expense-tracker-mobile.git
cd expense-tracker-mobile

# Install dependencies
flutter pub get
```

Open `lib/services/api_service.dart` and set `baseUrl` to your backend server's address:

```dart
// Android emulator → localhost
static const String baseUrl = 'http://10.0.2.2:8000/api';

// Real Android device (same WiFi as your PC)
static const String baseUrl = 'http://192.168.X.X:8000/api';

// Production server
static const String baseUrl = 'https://yourdomain.com/api';
```

Then run:

```bash
flutter run
```

## Android Permissions

Already configured in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_SMS" />
<uses-permission android:name="android.permission.INTERNET" />
```

The app requests SMS permission at runtime when you tap **Scan SMS**.

## Publishing to Play Store

```bash
# Generate a keystore (do this once and keep the file safe)
keytool -genkey -v -keystore release-keystore.jks \
        -keyalg RSA -keysize 2048 -validity 10000 \
        -alias expense_tracker

# Build release App Bundle
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` to Google Play Console.

> **Play Store SMS Policy:** In your store listing, justify the READ_SMS permission:
> *"This app reads the SMS inbox to detect bank debit messages and automatically log them as expenses. All SMS parsing is done locally on-device. No SMS content is transmitted to any server."*

## Related

- [Backend API (Django)](https://github.com/RichaKhatod/expense-tracker-backend) — REST API with JWT auth and expense storage

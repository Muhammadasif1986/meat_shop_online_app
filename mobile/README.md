# Abdul Ghaffar Meat Shop - Mobile App

Customer Android application for Abdul Ghaffar Meat Shop, Naval Colony, Karachi.

## Features

- Authentication (Phone + OTP)
- Browse Categories (Beef, Chicken, Mutton)
- Product Listing with Images, Prices, Urdu Names
- Product Details with Weight & Cut Selection
- Cart Management
- Checkout (COD with JazzCash/EasyPaisa architecture)
- Order Tracking with Real-time Status
- Product Reviews & Ratings
- Notifications (Firebase Cloud Messaging)
- Multi-language (English / Urdu) with RTL Support
- Offline Caching
- Secure JWT Storage

## Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **API Client**: Dio (with JWT interceptor)
- **Local Storage**: Hive, SharedPreferences, FlutterSecureStorage
- **Backend**: FastAPI (existing AGMS API)

## Prerequisites

- Flutter SDK >=3.2.0 <4.0.0
- Android Studio with Android SDK (API 34)
- Java JDK 17
- Git

## Setup

### 1. Clone & Install Dependencies

```bash
cd mobile
flutter pub get
```

### 2. Firebase Setup

1. Create a Firebase project at https://console.firebase.google.com
2. Add an Android app with package name: `com.abdulghaffar.meatshop`
3. Download `google-services.json` and place it in `android/app/`
4. Enable Phone Auth and Cloud Messaging in Firebase Console

### 3. Configure API Endpoint

Edit `lib/core/constants/api_constants.dart`:

```dart
// For Android emulator (localhost):
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

// For physical device (use your machine's IP):
static const String baseUrl = 'http://192.168.1.x:8000/api/v1';

// For production:
static const String baseUrl = 'https://api.agms.com/api/v1';
```

### 4. Run

```bash
# Run on emulator
flutter run

# Run on physical device
flutter run -d <device_id>

# Run in debug mode
flutter run --debug
```

## Build APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APK per architecture
flutter build apk --release --split-per-abi
```

APK output: `build/app/outputs/flutter-apk/`

## Project Structure

```
mobile/
├── lib/
│   ├── main.dart                    # App entry point with Riverpod
│   ├── core/
│   │   ├── constants/               # API URLs, colors, strings
│   │   ├── i18n/                    # AppLocalization delegate
│   │   ├── network/                 # Dio client, response models
│   │   ├── routes/                  # GoRouter configuration
│   │   ├── theme/                   # App theme (red/white/dark gray)
│   │   ├── utils/                   # Validators, helpers
│   │   └── widgets/                 # Shared widgets
│   └── features/
│       ├── auth/                    # Login, OTP, JWT
│       ├── home/                    # Home screen, promotions
│       ├── products/                # Categories, products, details
│       ├── cart/                    # Cart management
│       ├── checkout/                # Checkout flow
│       ├── orders/                  # Orders list, tracking
│       ├── reviews/                 # Product reviews
│       ├── profile/                 # User profile, settings
│       └── notifications/           # Push notifications
├── assets/
│   ├── i18n/                        # en.json, ur.json
│   └── images/                      # App images
├── android/                         # Android native project
└── test/                            # Unit tests
```

## API Integration

The app connects to the existing AGMS FastAPI backend:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/auth/send-otp` | POST | Send verification code |
| `/auth/verify-otp` | POST | Verify OTP, get JWT |
| `/auth/me` | GET | Current user profile |
| `/categories` | GET | All categories |
| `/products` | GET | All products |
| `/products/featured` | GET | Featured products |
| `/cart` | GET/POST | Cart operations |
| `/orders` | GET/POST | Order operations |
| `/reviews` | POST | Submit review |
| `/notifications` | GET | User notifications |

## Localization

- English: `assets/i18n/en.json` (116 keys)
- Urdu: `assets/i18n/ur.json` (116 keys, RTL)
- Runtime language switching in Profile screen
- Language preference saved via SharedPreferences

## Troubleshooting

### Connection refused to API
- Ensure backend is running: `curl http://localhost:8000/health`
- For emulator use `10.0.2.2` instead of `localhost`
- For physical device, use computer's LAN IP

### Firebase not configured
- The app will work without Firebase (OTP auth uses backend)
- Add `google-services.json` for push notifications

### Build errors
- Run `flutter clean && flutter pub get`
- Update Gradle: `flutter build apk --no-shrink`

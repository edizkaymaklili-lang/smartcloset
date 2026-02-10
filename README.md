# Stil Asist 👗

**Weather-based style assistant for women** - A Flutter mobile application that provides personalized outfit recommendations based on weather conditions, personal style preferences, and wardrobe items.

## 🌟 Features

### ✅ Completed Features

- **🌤️ Weather-Based Recommendations**: Get daily outfit suggestions based on current weather
- **👔 Virtual Wardrobe**: Manage your clothing items with photos and categories
- **🎨 Style Preferences**: Customize recommendations based on your personal style
- **📱 Style Feed**: Share your outfits and discover inspiration from others
- **💬 Comments & Likes**: Engage with the community through comments and likes
- **📍 Location Services**: Find nearby style posts with geohashing optimization
- **⚙️ Settings**: Comprehensive settings for account, preferences, and privacy
- **🔐 Authentication**: Secure login with Firebase Auth (Email/Password + Google Sign-In)
- **📊 Firebase Crashlytics**: Automatic crash reporting for better app stability
- **🌐 Web Support**: Full web compatibility with Firebase Hosting
- **✨ Auto Background Removal**: Automatic background removal for wardrobe photos using remove.bg API

## 🛠️ Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Backend**: Firebase (Firestore, Auth, Storage, Crashlytics)
- **Navigation**: GoRouter
- **Geolocation**: Geolocator + GeoFlutterFire Plus

## 🚀 Getting Started

1. Clone the repository
2. Run `flutter pub get`
3. Configure Firebase with `flutterfire configure`
4. Run `flutter run`

### Optional: Background Removal Setup

To enable automatic background removal for wardrobe photos:

1. Sign up for a free account at [remove.bg](https://www.remove.bg/users/sign_up)
2. Get your API key from [remove.bg/api](https://www.remove.bg/api)
3. In the app, go to Settings → Auto Background Removal
4. Enable the feature and enter your API key
5. Now all wardrobe photos will automatically have their backgrounds removed!

**Note**: The free tier includes 50 API calls per month.

## 📄 License

This project is licensed under the MIT License.

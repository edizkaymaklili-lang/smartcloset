import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/error/error_handler.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

// Firebase availability flag — false until flutterfire configure is run
final firebaseAvailableProvider = Provider<bool>((ref) => false);

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize global error handling
    AppErrorHandler.initialize();

    final prefs = await SharedPreferences.getInstance();

    // Initialize notification service
    await NotificationService().initialize();

    // Try Firebase init — silently skip if not yet configured
    bool firebaseReady = false;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseReady = true;

      // Initialize Crashlytics if Firebase is available (mobile/desktop only, not web)
      if (firebaseReady && !kIsWeb) {
        // Pass all uncaught Flutter errors to Crashlytics
        FlutterError.onError = (errorDetails) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        };

        // Pass all uncaught asynchronous errors to Crashlytics
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };

        // Enable Crashlytics collection (can be disabled in debug mode if needed)
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
      }
    } catch (_) {
      // Firebase not configured yet — app works with local rule matrix
    }

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          firebaseAvailableProvider.overrideWithValue(firebaseReady),
        ],
        child: const StilAsistApp(),
      ),
    );
  }, (error, stack) {
    // Catch errors that occur outside of Flutter
    // Only use Crashlytics on non-web platforms
    if (!kIsWeb) {
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (_) {
        // Crashlytics not available, error already logged by AppErrorHandler
      }
    }
  });
}

class StilAsistApp extends StatelessWidget {
  const StilAsistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Stil Asist',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/error/error_handler.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

// Firebase availability flag — starts false, updated when Firebase is ready
final firebaseAvailableProvider = NotifierProvider<FirebaseAvailableNotifier, bool>(
  FirebaseAvailableNotifier.new,
);

class FirebaseAvailableNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setReady() => state = true;
}

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize global error handling
    AppErrorHandler.initialize();

    final prefs = await SharedPreferences.getInstance();

    // Don't block startup on notification service (not supported on web)
    if (!kIsWeb) {
      NotificationService().initialize();
      NotificationService.router = appRouter;
    }

    // Start app IMMEDIATELY - don't wait for Firebase
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const SmartClosetApp(),
      ),
    );

    // Initialize Firebase in background AFTER app is visible
    _initFirebaseInBackground(container);
  }, (error, stack) {
    if (!kIsWeb) {
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (_) {
        // Crashlytics not available
      }
    }
  });
}

/// Firebase init runs AFTER the app is already on screen
Future<void> _initFirebaseInBackground(ProviderContainer container) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Update firebase flag so providers know Firebase is ready
    container.read(firebaseAvailableProvider.notifier).setReady();

    // Setup Crashlytics (non-web only)
    if (!kIsWeb) {
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);
    }
  } catch (_) {
    // Firebase not configured — app works with local data
  }
}

class SmartClosetApp extends ConsumerWidget {
  const SmartClosetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider).asData?.value ?? ThemeMode.system;
    return MaterialApp.router(
      title: 'Smart Closet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}

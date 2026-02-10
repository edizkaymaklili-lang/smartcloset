import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/wardrobe/domain/entities/clothing_item.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/splash_screen.dart';
import '../../features/recommendation/presentation/screens/daily_recommendations_screen.dart';
import '../../features/wardrobe/presentation/screens/wardrobe_screen.dart';
import '../../features/wardrobe/presentation/screens/add_item_screen.dart';
import '../../features/wardrobe/presentation/screens/collections_screen.dart';
import '../../features/wardrobe/presentation/screens/collection_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/contest/presentation/screens/contest_screen.dart';
import '../../features/contest/presentation/screens/submit_entry_screen.dart';
import '../../features/try_on/presentation/screens/try_on_screen.dart';
import '../../features/style_board/presentation/screens/style_board_screen.dart';
import '../../features/style_feed/presentation/screens/style_feed_screen.dart';
import '../../features/style_feed/presentation/screens/create_post_screen.dart';
import '../../features/style_feed/presentation/screens/map_view_screen.dart';
import '../../features/style_feed/presentation/screens/saved_posts_screen.dart';
import '../../features/style_feed/presentation/screens/post_detail_screen.dart';
import '../../features/style_feed/domain/entities/style_post.dart';
import '../../screens/upload_mock_data_screen.dart';
import '../../test_firebase_connection.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNavigator');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shellNavigator');


final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => HomeScreen(child: child),
      routes: [
        GoRoute(
          path: '/recommendations',
          builder: (context, state) => const DailyRecommendationsScreen(),
        ),
        GoRoute(
          path: '/wardrobe',
          builder: (context, state) => const WardrobeScreen(),
        ),
        GoRoute(
          path: '/wardrobe/add',
          builder: (context, state) => AddItemScreen(
            itemToEdit: state.extra as ClothingItem?,
          ),
        ),
        GoRoute(
          path: '/wardrobe/try-on',
          builder: (context, state) => const TryOnScreen(),
        ),
        GoRoute(
          path: '/wardrobe/style-board',
          builder: (context, state) => const StyleBoardScreen(),
        ),
        GoRoute(
          path: '/wardrobe/collections',
          builder: (context, state) => const CollectionsScreen(),
        ),
        GoRoute(
          path: '/wardrobe/collections/:id',
          builder: (context, state) => CollectionDetailScreen(
            collectionId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/profile/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/contest',
          builder: (context, state) => const ContestScreen(),
        ),
        GoRoute(
          path: '/contest/submit',
          builder: (context, state) => const SubmitEntryScreen(),
        ),
        GoRoute(
          path: '/style-feed',
          builder: (context, state) => const StyleFeedScreen(),
        ),
        GoRoute(
          path: '/style-feed/create',
          builder: (context, state) => const CreatePostScreen(),
        ),
        GoRoute(
          path: '/style-feed/map',
          builder: (context, state) => const MapViewScreen(),
        ),
        GoRoute(
          path: '/style-feed/saved',
          builder: (context, state) => const SavedPostsScreen(),
        ),
        GoRoute(
          path: '/style-feed/post',
          builder: (context, state) => PostDetailScreen(
            post: state.extra as StylePost,
          ),
        ),
        // Debug routes - only available in debug mode
        if (kDebugMode) ...[
          GoRoute(
            path: '/upload-mock-data',
            builder: (context, state) => const UploadMockDataScreen(),
          ),
          GoRoute(
            path: '/test-firebase',
            builder: (context, state) => const FirebaseConnectionTest(),
          ),
        ],
      ],
    ),
  ],
);

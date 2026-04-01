import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../main.dart' show firebaseAvailableProvider;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../weather/presentation/providers/weather_provider.dart';
import '../../../../services/subscription_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
    _waitForAuthAndNavigate();
  }

  Future<void> _waitForAuthAndNavigate() async {
    // Wait minimum 800ms for animation
    await Future.delayed(const Duration(milliseconds: 800));

    // Wait up to 2 seconds for Firebase to be ready (web initializes fast)
    for (int i = 0; i < 10; i++) {
      if (!mounted) return;
      final firebaseReady = ref.read(firebaseAvailableProvider);
      if (firebaseReady) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Pre-warm weather provider so the API call starts during the splash
    // instead of after navigation. Profile is sync (SharedPreferences),
    // so the city is already available here.
    if (mounted) ref.read(weatherProvider);

    // Reduced from 300ms — auth state is typically settled by now
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted || _navigated) return;
    _navigated = true;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      if (!authState.emailVerified && authState.email != null) {
        context.go('/verify-email');
      } else {
        // Check subscription status
        final subService = SubscriptionService();
        await subService.initialize();
        if (!mounted) return;
        if (subService.isSubscribed) {
          context.go('/recommendations');
        } else {
          context.go('/paywall');
        }
      }
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryLight, Colors.white, AppColors.secondaryLight],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Smart Closet',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your personal style companion',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

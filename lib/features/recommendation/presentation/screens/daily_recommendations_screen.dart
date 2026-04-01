import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/outfit_occasion.dart';
import '../../../../core/enums/style_preference.dart';
import '../../../../services/location_service.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../weather/presentation/providers/weather_provider.dart';
import '../providers/recommendation_provider.dart';
import '../widgets/weather_card.dart';
import '../widgets/smart_tip_banner.dart';
import '../widgets/occasion_outfit_tab.dart';
import '../../../../services/tips_service.dart';

class DailyRecommendationsScreen extends ConsumerStatefulWidget {
  const DailyRecommendationsScreen({super.key});

  @override
  ConsumerState<DailyRecommendationsScreen> createState() =>
      _DailyRecommendationsScreenState();
}

class _DailyRecommendationsScreenState
    extends ConsumerState<DailyRecommendationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: OutfitOccasion.values.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (await TipsService.shouldShow('today_style_icon')) {
        await TipsService.markShown('today_style_icon');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tap the style icon (top-right) to switch between Casual, Formal, Sporty and more'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _todayDate() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final recAsync = ref.watch(recommendationProvider);
    final weatherAsync = ref.watch(weatherProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Today\'s Style'),
            Text(
              _todayDate(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<StylePreference>(
            icon: Text(profile.stylePreference.icon,
                style: const TextStyle(fontSize: 22)),
            tooltip: 'Change style',
            onSelected: (style) {
              ref.read(profileProvider.notifier).updateStylePreference(style);
            },
            itemBuilder: (_) => StylePreference.values.map((s) {
              final isSelected = s == profile.stylePreference;
              return PopupMenuItem<StylePreference>(
                value: s,
                child: Row(
                  children: [
                    Text(s.icon),
                    const SizedBox(width: 10),
                    Text(s.displayName),
                    if (isSelected) ...[
                      const Spacer(),
                      const Icon(Icons.check,
                          color: AppColors.primary, size: 16),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Detecting location...'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              await ref.read(weatherProvider.notifier).refresh(detectLocation: true);
              if (context.mounted) {
                final city = ref.read(profileProvider).city;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Weather updated for $city'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            tooltip: 'Refresh & Detect Location',
          ),
        ],
      ),
      body: recAsync.when(
        loading: () => const _RecommendationsSkeleton(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 8),
              Text('Could not load recommendations',
                  style: Theme.of(context).textTheme.bodyLarge),
              TextButton(
                onPressed: () async {
                  await ref.read(weatherProvider.notifier).refresh(detectLocation: true);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (rec) => Column(
          children: [
            // Location banner - tappable to detect/change city
            _LocationBanner(
              city: profile.city,
              onDetectLocation: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Detecting your location...'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                try {
                  final locationService = LocationService();
                  final city = await locationService.getCurrentCity();
                  if (city != null && city.isNotEmpty) {
                    ref.read(profileProvider.notifier).updateCity(city);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Location: $city'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not detect location. Go to Settings > City.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Location error: $e'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
            if (weatherAsync is AsyncData)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: WeatherCard(weather: (weatherAsync as AsyncData).value),
              ),
            if (rec.smartTips.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SmartTipBanner(tips: rec.smartTips),
              ),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: OutfitOccasion.values
                  .map((o) => Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(o.icon),
                            const SizedBox(width: 4),
                            Text(o.displayName),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: OutfitOccasion.values
                    .map((occasion) => OccasionOutfitTab(
                          outfit: rec.occasions[occasion]!,
                          onRegenerate: () {
                            ref.read(recommendationProvider.notifier).regenerateOccasion(occasion);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Generating new ${occasion.displayName} outfit...'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationsSkeleton extends StatelessWidget {
  const _RecommendationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location banner skeleton
            _SkeletonBox(height: 40, borderRadius: 10),
            const SizedBox(height: 12),
            // Weather card skeleton
            _SkeletonBox(height: 100, borderRadius: 16),
            const SizedBox(height: 12),
            // Tip banner skeleton
            _SkeletonBox(height: 60, borderRadius: 12),
            const SizedBox(height: 16),
            // Tab bar skeleton
            Row(
              children: List.generate(
                3,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    child: const _SkeletonBox(height: 36, borderRadius: 8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Outfit cards skeleton
            _SkeletonBox(height: 200, borderRadius: 16),
            const SizedBox(height: 12),
            _SkeletonBox(height: 160, borderRadius: 16),
            const SizedBox(height: 12),
            _SkeletonBox(height: 160, borderRadius: 16),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  final double height;
  final double borderRadius;

  const _SkeletonBox({required this.height, required this.borderRadius});

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: _animation.value),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class _LocationBanner extends StatelessWidget {
  final String city;
  final VoidCallback onDetectLocation;

  const _LocationBanner({
    required this.city,
    required this.onDetectLocation,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDetectLocation,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              city,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const Spacer(),
            const Icon(Icons.my_location, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            const Text(
              'Detect',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

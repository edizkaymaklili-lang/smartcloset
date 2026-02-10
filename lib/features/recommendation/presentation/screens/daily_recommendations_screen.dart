import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/outfit_occasion.dart';
import '../../../../core/enums/style_preference.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../weather/presentation/providers/weather_provider.dart';
import '../providers/recommendation_provider.dart';
import '../widgets/weather_card.dart';
import '../widgets/smart_tip_banner.dart';
import '../widgets/occasion_outfit_tab.dart';

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
            onPressed: () => ref.read(weatherProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: recAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
                onPressed: () =>
                    ref.read(weatherProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (rec) => Column(
          children: [
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

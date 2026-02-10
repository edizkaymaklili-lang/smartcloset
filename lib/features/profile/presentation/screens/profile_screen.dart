import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/world_cities.dart';
import '../../../../core/enums/style_preference.dart';
import '../providers/profile_provider.dart';
import '../../../wardrobe/data/wardrobe_demo_data.dart';
import '../../../../services/location_service.dart';
import '../../../../services/notification_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _useMyLocation(BuildContext context, WidgetRef ref) async {
    final locationService = LocationService();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Getting your location...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final city = await locationService.getCurrentCity();

      if (!context.mounted) return;
      // Use post-frame callback to safely close dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context); // Close loading dialog
        }
      });

      if (city != null) {
        ref.read(profileProvider.notifier).updateCity(city);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location updated to $city'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not get your location. Please check permissions.'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => locationService.openAppSettings(),
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      // Use post-frame callback to safely close dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context); // Close loading dialog
        }
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get location. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCityPicker(BuildContext context, WidgetRef ref, String currentCity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CityPickerSheet(currentCity: currentCity),
    );
  }

  Future<void> _testNotification(BuildContext context) async {
    final notificationService = NotificationService();
    await notificationService.showImmediateNotification(
      title: '☀️ Good Morning!',
      body: 'Your daily outfit recommendation is ready! Check the app for today\'s perfect look.',
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final wardrobeCount = WardrobeDemoData.items.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/profile/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar & name
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        profile.stylePreference.icon,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  profile.displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${profile.stylePreference.displayName} Style · ${profile.city}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatChip(label: 'Items', value: '$wardrobeCount'),
                    const SizedBox(width: 16),
                    _StatChip(label: 'Outfits', value: '0'),
                    const SizedBox(width: 16),
                    _StatChip(label: 'Worn', value: '0'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Style preference
          _SectionTitle('My Style'),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.8,
            children: StylePreference.values.map((style) {
              final isSelected = style == profile.stylePreference;
              return GestureDetector(
                onTap: () =>
                    ref.read(profileProvider.notifier).updateStylePreference(style),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${style.icon}  ${style.displayName}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Settings
          _SectionTitle('Settings'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined,
                      color: AppColors.primary),
                  title: const Text('Morning Notifications'),
                  subtitle: const Text('Daily style alerts at 7:00 AM'),
                  value: profile.notificationEnabled,
                  onChanged: (value) {
                    ref.read(profileProvider.notifier).toggleNotifications(value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value
                            ? 'Notifications enabled'
                            : 'Notifications disabled'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  activeThumbColor: AppColors.primary,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined,
                      color: AppColors.primary),
                  title: const Text('Location'),
                  subtitle: Text(profile.city),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.my_location, size: 20),
                        onPressed: () => _useMyLocation(context, ref),
                        tooltip: 'Use my location',
                        color: AppColors.secondary,
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _showCityPicker(context, ref, profile.city),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline,
                      color: AppColors.textSecondary),
                  title: const Text('About Stil Asist'),
                  subtitle: const Text('Version 1.0.0'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                if (profile.notificationEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_active,
                        color: AppColors.secondary),
                    title: const Text('Test Notification'),
                    subtitle: const Text('Send a test notification now'),
                    trailing: const Icon(Icons.send),
                    onTap: () => _testNotification(context),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _CityPickerSheet extends ConsumerStatefulWidget {
  final String currentCity;

  const _CityPickerSheet({required this.currentCity});

  @override
  ConsumerState<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends ConsumerState<_CityPickerSheet> {
  String _searchQuery = '';
  String _selectedRegion = 'Popular';

  @override
  Widget build(BuildContext context) {
    // Filter cities based on search and region
    List<String> cities;
    if (_selectedRegion == 'Popular') {
      cities = WorldCities.popularCities;
    } else if (_selectedRegion == 'All') {
      cities = WorldCities.allCities;
    } else {
      cities = WorldCities.citiesByRegion[_selectedRegion] ?? [];
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      cities = cities
          .where((city) =>
              city.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Select Your City',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Use My Location button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        final locationService = LocationService();
                        _useMyLocation(context, ref, locationService);
                      },
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use My Location'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Search bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search city...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ],
              ),
            ),

            // Region tabs
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _RegionChip(
                    label: 'Popular',
                    isSelected: _selectedRegion == 'Popular',
                    onTap: () => setState(() => _selectedRegion = 'Popular'),
                  ),
                  const SizedBox(width: 8),
                  _RegionChip(
                    label: 'All',
                    isSelected: _selectedRegion == 'All',
                    onTap: () => setState(() => _selectedRegion = 'All'),
                  ),
                  const SizedBox(width: 8),
                  ...WorldCities.citiesByRegion.keys.map((region) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _RegionChip(
                        label: region,
                        isSelected: _selectedRegion == region,
                        onTap: () => setState(() => _selectedRegion = region),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const Divider(height: 1),

            // Cities list
            Expanded(
              child: cities.isEmpty
                  ? Center(
                      child: Text(
                        'No cities found',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: cities.length,
                      itemBuilder: (_, i) {
                        final city = cities[i];
                        final isSelected = city == widget.currentCity;
                        return ListTile(
                          leading: Icon(
                            Icons.location_city,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          title: Text(
                            city,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: AppColors.primary)
                              : null,
                          onTap: () {
                            ref.read(profileProvider.notifier).updateCity(city);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Location updated to $city'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _useMyLocation(
      BuildContext context, WidgetRef ref, LocationService locationService) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Getting your location...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final city = await locationService.getCurrentCity();

      if (!context.mounted) return;
      // Use post-frame callback to safely close dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context); // Close loading dialog
        }
      });

      if (city != null) {
        ref.read(profileProvider.notifier).updateCity(city);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location updated to $city'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Could not get your location. Please check permissions.'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => locationService.openAppSettings(),
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      // Use post-frame callback to safely close dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context); // Close loading dialog
        }
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get location. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _RegionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RegionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

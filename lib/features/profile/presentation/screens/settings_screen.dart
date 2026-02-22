import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../../../services/settings_service.dart';
import '../../../../services/background_removal_service.dart';
import '../../../../core/constants/world_cities.dart';
import '../../../../core/legal/legal_texts.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../services/location_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _settingsService = SettingsService();
  final _backgroundRemovalService = BackgroundRemovalService();

  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _backgroundRemovalEnabled = false;
  String _removeBgApiKey = '';
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadSettings();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    }
  }

  Future<void> _loadSettings() async {
    final notifications = await _settingsService.getNotificationsEnabled();
    final location = await _settingsService.getLocationEnabled();
    final bgRemoval = await _settingsService.getBackgroundRemovalEnabled();
    final apiKey = await _settingsService.getRemoveBgApiKey();

    if (mounted) {
      setState(() {
        _notificationsEnabled = notifications;
        _locationEnabled = location;
        _backgroundRemovalEnabled = bgRemoval;
        _removeBgApiKey = apiKey;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await _settingsService.setNotificationsEnabled(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value
              ? 'Notifications enabled'
              : 'Notifications disabled'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleLocation(bool value) async {
    setState(() => _locationEnabled = value);
    await _settingsService.setLocationEnabled(value);
  }

  Future<void> _toggleDarkMode(bool value) async {
    await ref.read(themeModeProvider.notifier).toggle();
  }

  Future<void> _toggleBackgroundRemoval(bool value) async {
    setState(() => _backgroundRemovalEnabled = value);
    await _settingsService.setBackgroundRemovalEnabled(value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value
              ? 'Background removal enabled'
              : 'Background removal disabled'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showApiKeyDialog() async {
    final controller = TextEditingController(text: _removeBgApiKey);
    bool isValidating = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Remove.bg API Key'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To enable automatic background removal, you need a remove.bg API key.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                'Get your free API key (50 images/month):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '1. Visit remove.bg/users/sign_up\n2. Sign up for free\n3. Get API key from remove.bg/api',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                  hintText: 'Paste your API key here',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isValidating
                  ? null
                  : () async {
                      final apiKey = controller.text.trim();
                      if (apiKey.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter an API key'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      // Validate API key
                      setDialogState(() => isValidating = true);
                      final isValid = await _backgroundRemovalService.validateApiKey(apiKey);
                      setDialogState(() => isValidating = false);

                      if (!context.mounted) return;

                      if (isValid) {
                        await _settingsService.setRemoveBgApiKey(apiKey);
                        setState(() {
                          _removeBgApiKey = apiKey;
                          _backgroundRemovalEnabled = true;
                        });
                        await _settingsService.setBackgroundRemovalEnabled(true);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('API key validated successfully!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invalid API key. Please check and try again.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              child: isValidating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
            'This will clear all cached images and data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // 1. Clear Flutter painting image memory cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // 2. Clear CachedNetworkImage disk cache
      await DefaultCacheManager().emptyCache();

      // 3. Clear app temp directory (mobile/desktop only)
      try {
        final tempDir = await getTemporaryDirectory();
        final entities = tempDir.listSync();
        for (final entity in entities) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      } catch (_) {
        // Temp directory not available on web or permissions denied
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showCityPicker(BuildContext context, WidgetRef ref, String currentCity) {
    String searchQuery = '';
    bool isDetecting = false;
    String? detectError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          final allCities = WorldCities.allCities;
          final filteredCities = searchQuery.isEmpty
              ? allCities
              : allCities
                  .where((city) =>
                      city.toLowerCase().contains(searchQuery.toLowerCase()))
                  .toList();

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
                    child: Text(
                      'Select Your City',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  // Use My Location button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isDetecting
                            ? null
                            : () async {
                                setModalState(() {
                                  isDetecting = true;
                                  detectError = null;
                                });
                                try {
                                  final locationService = LocationService();
                                  final city =
                                      await locationService.getCurrentCity();
                                  if (city != null && city.isNotEmpty) {
                                    ref
                                        .read(profileProvider.notifier)
                                        .updateCity(city);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Location detected: $city'),
                                        ),
                                      );
                                    }
                                  } else {
                                    setModalState(() {
                                      isDetecting = false;
                                      detectError =
                                          'Could not detect city. Please select manually.';
                                    });
                                  }
                                } catch (e) {
                                  setModalState(() {
                                    isDetecting = false;
                                    detectError =
                                        'Location error: ${e.toString()}';
                                  });
                                }
                              },
                        icon: isDetecting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(
                            isDetecting ? 'Detecting...' : 'Use My Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (detectError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Text(
                        detectError!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search city...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  // Cities list
                  Expanded(
                    child: filteredCities.isEmpty
                        ? const Center(
                            child: Text('No cities found'),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: filteredCities.length,
                            itemBuilder: (context, index) {
                              final city = filteredCities[index];
                              final isSelected = city == currentCity;
                              return ListTile(
                                leading: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.location_city,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                title: Text(city),
                                selected: isSelected,
                                selectedTileColor:
                                    AppColors.primaryLight.withValues(alpha: 0.1),
                                onTap: () {
                                  ref
                                      .read(profileProvider.notifier)
                                      .updateCity(city);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('City updated to $city')),
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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Account Section
          _SectionHeader(title: 'Account'),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Display Name',
            subtitle: profile.displayName,
            onTap: () => _showEditDisplayName(),
          ),
          _SettingsTile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: authState.email ?? 'Not set',
            trailing: authState.email != null
                ? const Icon(Icons.verified, size: 20, color: AppColors.success)
                : null,
          ),
          _SettingsTile(
            icon: Icons.location_city_outlined,
            title: 'City',
            subtitle: profile.city,
            onTap: () => _showCityPicker(context, ref, profile.city),
          ),

          const Divider(height: 32),

          // Preferences Section
          _SectionHeader(title: 'Preferences'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('Daily outfit recommendations'),
            value: _notificationsEnabled,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            activeThumbColor: AppColors.primary,
            onChanged: _toggleNotifications,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.location_on_outlined),
            title: const Text('Location Services'),
            subtitle: const Text('For weather and nearby features'),
            value: _locationEnabled,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            activeThumbColor: AppColors.primary,
            onChanged: _toggleLocation,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: ref.watch(themeModeProvider).asData?.value == ThemeMode.dark,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            activeThumbColor: AppColors.primary,
            onChanged: _toggleDarkMode,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.auto_fix_high_outlined),
            title: const Text('Auto Background Removal'),
            subtitle: Text(_removeBgApiKey.isEmpty
                ? 'Remove backgrounds automatically (free local)'
                : 'Using remove.bg API for higher quality'),
            value: _backgroundRemovalEnabled,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            activeThumbColor: AppColors.primary,
            onChanged: _toggleBackgroundRemoval,
          ),
          if (_removeBgApiKey.isNotEmpty)
            _SettingsTile(
              icon: Icons.key_outlined,
              title: 'Remove.bg API Key',
              subtitle: '${_removeBgApiKey.substring(0, 8)}...',
              onTap: _showApiKeyDialog,
            ),

          const Divider(height: 32),

          // Privacy & Data Section
          _SectionHeader(title: 'Privacy & Data'),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _showLegalDoc(
              LegalTexts.privacyPolicyTitle,
              LegalTexts.privacyPolicy,
            ),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => _showLegalDoc(
              LegalTexts.termsOfServiceTitle,
              LegalTexts.termsOfService,
            ),
          ),
          _SettingsTile(
            icon: Icons.shield_outlined,
            title: 'Data Processing Notice',
            subtitle: 'KVKK / GDPR',
            onTap: () => _showLegalDoc(
              LegalTexts.dataProcessingTitle,
              LegalTexts.dataProcessingNotice,
            ),
          ),
          _SettingsTile(
            icon: Icons.storage_outlined,
            title: 'Storage Notice',
            subtitle: 'Web cookies & local storage',
            onTap: () => _showLegalDoc(
              LegalTexts.storageNoticeTitle,
              LegalTexts.storageNotice,
            ),
          ),
          _SettingsTile(
            icon: Icons.delete_outline,
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            onTap: _clearCache,
          ),

          const Divider(height: 32),

          // About Section
          _SectionHeader(title: 'About'),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: _appVersion.isEmpty ? 'Loading...' : _appVersion,
          ),
          _SettingsTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () => _showHelpSupport(),
          ),
          _SettingsTile(
            icon: Icons.star_outline,
            title: 'Rate Us',
            onTap: () => _rateApp(),
          ),

          const Divider(height: 32),

          // Security Section
          _SectionHeader(title: 'Security'),
          _SettingsTile(
            icon: Icons.lock_reset_outlined,
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: _showChangePassword,
          ),
          _SettingsTile(
            icon: Icons.person_remove_outlined,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account and data',
            onTap: _showDeleteAccount,
          ),

          const Divider(height: 32),

          // Logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _showLogoutConfirmation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showEditDisplayName() {
    final controller = TextEditingController(
      text: ref.read(profileProvider).displayName,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref.read(profileProvider.notifier).updateDisplayName(newName);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Name updated to $newName')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePassword() {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();
    bool saving = false;
    String? errorMsg;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPwController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setDialogState(
                          () => obscureCurrent = !obscureCurrent),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPwController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setDialogState(() => obscureNew = !obscureNew),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPwController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setDialogState(
                          () => obscureConfirm = !obscureConfirm),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMsg!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      final current = currentPwController.text;
                      final newPw = newPwController.text;
                      final confirm = confirmPwController.text;

                      if (current.isEmpty || newPw.isEmpty) {
                        setDialogState(
                            () => errorMsg = 'All fields are required.');
                        return;
                      }
                      if (newPw.length < 6) {
                        setDialogState(() =>
                            errorMsg = 'New password must be at least 6 characters.');
                        return;
                      }
                      if (newPw != confirm) {
                        setDialogState(
                            () => errorMsg = 'Passwords do not match.');
                        return;
                      }

                      setDialogState(() {
                        saving = true;
                        errorMsg = null;
                      });

                      final error = await ref
                          .read(authProvider.notifier)
                          .changePassword(
                            currentPassword: current,
                            newPassword: newPw,
                          );

                      if (!ctx.mounted) return;

                      if (error == null) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password changed successfully.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } else {
                        setDialogState(() {
                          saving = false;
                          errorMsg = error;
                        });
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccount() {
    final passwordController = TextEditingController();
    bool deleting = false;
    String? errorMsg;
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will permanently delete your account and all associated data. This action cannot be undone.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Enter your password to confirm',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () =>
                        setDialogState(() => obscure = !obscure),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMsg!,
                  style: const TextStyle(
                      color: AppColors.error, fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: deleting
                  ? null
                  : () async {
                      final password = passwordController.text;
                      if (password.isEmpty) {
                        setDialogState(() =>
                            errorMsg = 'Please enter your password.');
                        return;
                      }

                      setDialogState(() {
                        deleting = true;
                        errorMsg = null;
                      });

                      final error = await ref
                          .read(authProvider.notifier)
                          .deleteAccount(password);

                      if (!ctx.mounted) return;

                      if (error == null) {
                        Navigator.pop(ctx);
                        if (mounted) context.go('/login');
                      } else {
                        setDialogState(() {
                          deleting = false;
                          errorMsg = error;
                        });
                      }
                    },
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.error),
              child: deleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLegalDoc(String title, String body) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  body,
                  style: const TextStyle(fontSize: 13, height: 1.6),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Need help? Contact us:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _HelpItem(icon: Icons.email, text: 'support@stilasist.com'),
            const SizedBox(height: 8),
            _HelpItem(icon: Icons.language, text: 'www.stilasist.com'),
            const SizedBox(height: 8),
            _HelpItem(icon: Icons.help_outline, text: 'FAQ & Documentation'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _rateApp() async {
    final InAppReview inAppReview = InAppReview.instance;

    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    } else {
      // Fallback: Open app store page
      await inAppReview.openStoreListing(
        appStoreId: 'your-app-store-id', // Replace with actual App Store ID
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HelpItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

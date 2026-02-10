import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/settings_service.dart';
import '../../../../services/background_removal_service.dart';

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
  bool _darkMode = false;
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
    final darkMode = await _settingsService.getDarkMode();
    final bgRemoval = await _settingsService.getBackgroundRemovalEnabled();
    final apiKey = await _settingsService.getRemoveBgApiKey();

    if (mounted) {
      setState(() {
        _notificationsEnabled = notifications;
        _locationEnabled = location;
        _darkMode = darkMode;
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
    setState(() => _darkMode = value);
    await _settingsService.setDarkMode(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dark mode coming soon!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleBackgroundRemoval(bool value) async {
    // If enabling, check if API key is set
    if (value && _removeBgApiKey.isEmpty) {
      _showApiKeyDialog();
      return;
    }

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
      // TODO: Implement cache clearing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
            onTap: () {
              // Navigate back to profile to edit city
              Navigator.pop(context);
            },
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
            value: _darkMode,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            activeThumbColor: AppColors.primary,
            onChanged: _toggleDarkMode,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.auto_fix_high_outlined),
            title: const Text('Auto Background Removal'),
            subtitle: Text(_removeBgApiKey.isEmpty
                ? 'Tap to set API key'
                : 'Remove backgrounds from wardrobe photos'),
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
            onTap: () => _showPrivacyPolicy(),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => _showTermsOfService(),
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

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Your privacy is important to us. This app collects minimal data:\n\n'
            '• Account information (email, display name)\n'
            '• Wardrobe items you add\n'
            '• Location data (only when you grant permission)\n'
            '• Usage analytics to improve the app\n\n'
            'We never share your personal data with third parties without your consent.',
            style: TextStyle(fontSize: 14),
          ),
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

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using Stil Asist, you agree to:\n\n'
            '• Use the app for personal, non-commercial purposes\n'
            '• Provide accurate information\n'
            '• Not misuse or abuse the service\n'
            '• Respect other users\' content and privacy\n\n'
            'We reserve the right to terminate accounts that violate these terms.',
            style: TextStyle(fontSize: 14),
          ),
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

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you for your support! Rating feature coming soon.'),
        duration: Duration(seconds: 2),
      ),
    );
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

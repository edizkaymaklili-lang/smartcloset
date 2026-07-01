import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/legal/legal_texts.dart';
import '../../../../services/subscription_service.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final service = SubscriptionService();
  ref.onDispose(service.dispose);
  return service;
});

final subscriptionStatusProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(subscriptionServiceProvider);
  await service.initialize();
  return service.isSubscribed;
});

class PaywallScreen extends ConsumerStatefulWidget {
  final VoidCallback onSubscribed;

  const PaywallScreen({super.key, required this.onSubscribed});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _loading = false;

  // Localized price string from the store, defaults until loaded.
  String _price = '€10';

  // Whether the free trial has already been used (and thus expired by the
  // time this screen is shown). When true, the trial can no longer be started.
  bool _trialUsed = false;

  @override
  void initState() {
    super.initState();
    _loadPrice();
    _loadTrialState();
  }

  Future<void> _loadPrice() async {
    final service = ref.read(subscriptionServiceProvider);
    final price = await service.getPriceString();
    if (mounted) setState(() => _price = price);
  }

  Future<void> _loadTrialState() async {
    final service = ref.read(subscriptionServiceProvider);
    final used = await service.hasTrialStarted();
    if (mounted) setState(() => _trialUsed = used);
  }

  Future<void> _startTrial() async {
    setState(() => _loading = true);
    final service = ref.read(subscriptionServiceProvider);
    await service.startTrial();
    if (!mounted) return;
    setState(() => _loading = false);
    // Only enter the app if the trial was actually granted. If it was already
    // used, startTrial() is a no-op and access must not be granted for free.
    if (service.isSubscribed) {
      widget.onSubscribed();
    } else {
      setState(() => _trialUsed = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your free trial has ended. Please subscribe to continue.')),
      );
    }
  }

  Future<void> _subscribe() async {
    setState(() => _loading = true);
    final service = ref.read(subscriptionServiceProvider);
    final success = await service.subscribe();
    if (!mounted) return;
    setState(() => _loading = false);
    if (success) widget.onSubscribed();
  }

  Future<void> _restore() async {
    setState(() => _loading = true);
    final service = ref.read(subscriptionServiceProvider);
    final restored = await service.restorePurchases();
    if (!mounted) return;
    setState(() => _loading = false);
    if (restored) {
      widget.onSubscribed();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active subscription found to restore.')),
      );
    }
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE91E8C), Color(0xFF7B1FA2)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Close button — only shown when the paywall was pushed (e.g.
                // opened from Settings), so it can be dismissed. When it is the
                // root screen (trial expired) there is nothing to pop.
                if (Navigator.of(context).canPop())
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                const SizedBox(height: 16),
                const Icon(Icons.checkroom, size: 72, color: Colors.white),
                const SizedBox(height: 20),
                // Title of the subscription
                const Text(
                  'Smart Closet Premium',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your AI-powered personal stylist',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _FeatureRow(icon: Icons.wb_sunny, text: 'Daily weather-based outfit recommendations'),
                const SizedBox(height: 16),
                _FeatureRow(icon: Icons.checkroom, text: 'Unlimited wardrobe items'),
                const SizedBox(height: 16),
                _FeatureRow(icon: Icons.auto_awesome, text: 'AI clothing analysis & virtual try-on'),
                const SizedBox(height: 16),
                _FeatureRow(icon: Icons.people, text: 'Style Feed community access'),
                const SizedBox(height: 32),
                // Subscription details: title, length, price and price per unit
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$_price / month',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Smart Closet Premium — auto-renewable subscription',
                        style: TextStyle(fontSize: 13, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Length: 1 month · Billed at $_price per month',
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _trialUsed
                            ? 'Your 7-day free trial has ended. Subscribe to continue.'
                            : '7 days free, then renews monthly. Cancel anytime.',
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Primary action: start the free trial (first-time users) or
                // subscribe (once the trial has been used up).
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading
                        ? null
                        : (_trialUsed ? _subscribe : _startTrial),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFE91E8C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator()
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _trialUsed
                                  ? 'Subscribe — $_price/month'
                                  : 'Start 7-Day Free Trial',
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                // Secondary subscribe link (hidden once trial is used, since the
                // primary button already subscribes in that state).
                if (!_trialUsed)
                  TextButton(
                    onPressed: _loading ? null : _subscribe,
                    child: Text(
                      'Subscribe now — $_price/month',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                // Restore purchases
                TextButton(
                  onPressed: _loading ? null : _restore,
                  child: const Text(
                    'Restore Purchases',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
                // Required auto-renewable subscription disclosure
                const Text(
                  'Payment will be charged to your Apple Account at confirmation '
                  'of purchase. The subscription automatically renews unless it is '
                  'canceled at least 24 hours before the end of the current period. '
                  'Your account will be charged for renewal within 24 hours prior to '
                  'the end of the current period. You can manage and cancel your '
                  'subscriptions in your App Store account settings.',
                  style: TextStyle(fontSize: 11, color: Colors.white60, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Functional links to Terms of Use (EULA) and Privacy Policy
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _LegalLink(
                      label: 'Terms of Use (EULA)',
                      onTap: () => _showLegalDoc(
                        LegalTexts.termsOfServiceTitle,
                        LegalTexts.termsOfService,
                      ),
                    ),
                    const Text(
                      '  ·  ',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    _LegalLink(
                      label: 'Privacy Policy',
                      onTap: () => _showLegalDoc(
                        LegalTexts.privacyPolicyTitle,
                        LegalTexts.privacyPolicy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LegalLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white,
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, color: Colors.white),
          ),
        ),
        const Icon(Icons.check_circle, color: Colors.white70, size: 20),
      ],
    );
  }
}

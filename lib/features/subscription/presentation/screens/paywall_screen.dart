import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> _startTrial() async {
    setState(() => _loading = true);
    final service = ref.read(subscriptionServiceProvider);
    await service.startTrial();
    setState(() => _loading = false);
    widget.onSubscribed();
  }

  Future<void> _subscribe() async {
    setState(() => _loading = true);
    final service = ref.read(subscriptionServiceProvider);
    final success = await service.subscribe();
    setState(() => _loading = false);
    if (success) widget.onSubscribed();
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                const Icon(Icons.checkroom, size: 80, color: Colors.white),
                const SizedBox(height: 24),
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
                const SizedBox(height: 40),
                _FeatureRow(icon: Icons.wb_sunny, text: 'Daily weather-based outfit recommendations'),
                const SizedBox(height: 16),
                _FeatureRow(icon: Icons.checkroom, text: 'Unlimited wardrobe items'),
                const SizedBox(height: 16),
                _FeatureRow(icon: Icons.auto_awesome, text: 'AI clothing analysis & virtual try-on'),
                const SizedBox(height: 16),
                _FeatureRow(icon: Icons.people, text: 'Style Feed community access'),
                const Spacer(),
                // Price info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '7 days free, then €10/month',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Cancel anytime · No commitment',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Start trial button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _startTrial,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFE91E8C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Start 7-Day Free Trial',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                // Subscribe directly
                TextButton(
                  onPressed: _loading ? null : _subscribe,
                  child: const Text(
                    'Subscribe now — €10/month',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy.',
                  style: TextStyle(fontSize: 11, color: Colors.white54),
                  textAlign: TextAlign.center,
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

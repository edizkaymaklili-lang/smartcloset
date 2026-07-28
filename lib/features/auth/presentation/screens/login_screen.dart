import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/legal/legal_texts.dart';
import '../../domain/entities/auth_state.dart';
import '../providers/auth_provider.dart';
import '../widgets/animated_fashion_avatar.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                    child: Text(title,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
                child: Text(body, style: const TextStyle(fontSize: 13, height: 1.6)),
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

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  void _handleGoogleLogin() {
    ref.read(authProvider.notifier).signInWithGoogle();
  }

  void _handleAppleLogin() {
    ref.read(authProvider.notifier).signInWithApple();
  }

  void _showForgotPassword() {
    final controller = TextEditingController(text: _emailController.text.trim());
    bool sending = false;
    String? message;
    bool success = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your email and we\'ll send a reset link.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 12),
                Text(
                  message!,
                  style: TextStyle(
                    color: success ? AppColors.success : AppColors.error,
                    fontSize: 13,
                  ),
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
              onPressed: sending || success
                  ? null
                  : () async {
                      final email = controller.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        setDialogState(() {
                          message = 'Please enter a valid email.';
                          success = false;
                        });
                        return;
                      }
                      setDialogState(() => sending = true);
                      final error = await ref
                          .read(authProvider.notifier)
                          .sendPasswordResetEmail(email);
                      setDialogState(() {
                        sending = false;
                        message = error ?? 'Reset link sent! Check your inbox.';
                        success = error == null;
                      });
                    },
              child: sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send Link'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Navigate on success (handles both direct login and redirect return)
    if (authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          if (!authState.emailVerified &&
              authState.email != null &&
              authState.email != kReviewAccountEmail) {
            context.go('/verify-email');
          } else {
            context.go('/recommendations');
          }
        }
      });
    }
    ref.listen(authProvider, (prev, next) {
      if (next.isAuthenticated) {
        if (!next.emailVerified &&
            next.email != null &&
            next.email != kReviewAccountEmail) {
          context.go('/verify-email');
        } else {
          context.go('/recommendations');
        }
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFFCE4EC),
              Color(0xFFF8BBD0),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ─── Scrollable top: avatar + form ───
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const AnimatedFashionAvatar(height: 130),
                      const SizedBox(height: 8),
                      Text(
                        'Smart Closet',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 1.5,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your personal style companion',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Email is required';
                                if (!val.contains('@')) return 'Enter valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Password is required';
                                if (val.length < 6) return 'At least 6 characters';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPassword,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      if (authState.status == AuthStatus.error &&
                          authState.errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authState.errorMessage!,
                                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // ─── Fixed bottom: buttons always visible ───
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: authState.status == AuthStatus.loading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: authState.status == AuthStatus.loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.textHint.withValues(alpha: 0.5))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('or', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ),
                        Expanded(child: Divider(color: AppColors.textHint.withValues(alpha: 0.5))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: authState.status == AuthStatus.loading ? null : _handleGoogleLogin,
                      icon: Image.network(
                        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                        width: 20,
                        height: 20,
                        errorBuilder: (_, _, _) => const Icon(Icons.g_mobiledata, size: 24),
                      ),
                      label: const Text('Sign in with Google', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.textPrimary,
                        minimumSize: const Size(double.infinity, 50),
                        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: SignInWithAppleButton(
                        onPressed: authState.status == AuthStatus.loading ? () {} : _handleAppleLogin,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(fontSize: 11, color: AppColors.textHint, height: 1.5),
                          children: [
                            const TextSpan(text: 'By signing in you agree to our '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: const TextStyle(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _showLegalDoc(
                                      LegalTexts.termsOfServiceTitle,
                                      LegalTexts.termsOfService,
                                    ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _showLegalDoc(
                                      LegalTexts.privacyPolicyTitle,
                                      LegalTexts.privacyPolicy,
                                    ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text('Don\'t have an account? ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        GestureDetector(
                          onTap: () => context.go('/register'),
                          child: Text('Sign Up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

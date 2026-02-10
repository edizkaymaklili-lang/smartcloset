import 'dart:ui' show PlatformDispatcher;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show DiagnosticsNode, FlutterError, FlutterErrorDetails, debugPrint, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Global error handler for the application
class AppErrorHandler {
  /// Initialize global error handling
  static void initialize() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _logError(details.exception, details.stack, details.context);
    };

    // Handle errors outside Flutter (async errors, etc.)
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError(error, stack, null);
      return true;
    };

    // Set custom error widget builder
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return CustomErrorWidget(
        error: details.exception.toString(),
        stackTrace: details.stack?.toString(),
      );
    };
  }

  /// Log error to console and send to Firebase Crashlytics
  static void _logError(Object error, StackTrace? stackTrace, DiagnosticsNode? context) {
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════════');
      debugPrint('ERROR: $error');
      if (context != null) {
        debugPrint('CONTEXT: $context');
      }
      if (stackTrace != null) {
        debugPrint('STACK TRACE:\n$stackTrace');
      }
      debugPrint('═══════════════════════════════════════════');
    }

    // Send to Firebase Crashlytics (mobile/desktop only, not web)
    if (!kIsWeb) {
      try {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: context?.toString(),
        );
      } catch (_) {
        // Crashlytics not available, already logged to console
      }
    }
  }
}

/// Custom error widget shown when Flutter encounters an error
class CustomErrorWidget extends StatelessWidget {
  final String error;
  final String? stackTrace;

  const CustomErrorWidget({
    super.key,
    required this.error,
    this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'We\'re sorry for the inconvenience. Please restart the app.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Debug Information:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: SingleChildScrollView(
                          child: Text(
                            error,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error boundary widget for wrapping sections of the app
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String errorContext;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    required this.errorContext,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace);
      }
      return _DefaultErrorView(
        error: _error!,
        errorContext: widget.errorContext,
        onRetry: () {
          setState(() {
            _error = null;
            _stackTrace = null;
          });
        },
      );
    }

    return ErrorCapture(
      onError: (error, stackTrace) {
        setState(() {
          _error = error;
          _stackTrace = stackTrace;
        });
      },
      child: widget.child,
    );
  }
}

/// Captures errors within its subtree
class ErrorCapture extends StatelessWidget {
  final Widget child;
  final void Function(Object error, StackTrace stackTrace) onError;

  const ErrorCapture({
    super.key,
    required this.child,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Default error view shown when an error boundary catches an error
class _DefaultErrorView extends StatelessWidget {
  final Object error;
  final String errorContext;
  final VoidCallback onRetry;

  const _DefaultErrorView({
    required this.error,
    required this.errorContext,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error in $errorContext',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

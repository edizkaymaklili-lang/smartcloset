import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/try_on_state.dart';
import 'model_photo_selector.dart';

class TryOnResultView extends StatelessWidget {
  final TryOnState state;
  final VoidCallback onPickPhoto;
  final VoidCallback? onClearResult;

  const TryOnResultView({
    super.key,
    required this.state,
    required this.onPickPhoto,
    this.onClearResult,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background: Model photo or placeholder
        if (state.modelImagePath == null)
          ModelPhotoSelector(onTap: onPickPhoto)
        else if (state.resultImageUrl != null)
          _buildResultImage()
        else
          _buildModelPhoto(),

        // Loading/Processing overlay
        if (state.status == TryOnStatus.uploading || state.status == TryOnStatus.processing)
          _buildLoadingOverlay(),

        // Error overlay
        if (state.status == TryOnStatus.error && state.errorMessage != null)
          _buildErrorOverlay(context),

        // Clear button (when result is shown)
        if (state.resultImageUrl != null && onClearResult != null)
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              onPressed: onClearResult,
              icon: const Icon(Icons.refresh, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.9),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModelPhoto() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: kIsWeb
            ? Image.network(
                state.modelImagePath!,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(Icons.error, size: 48, color: AppColors.error),
                ),
              )
            : Image.file(
                File(state.modelImagePath!),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
      ),
    );
  }

  Widget _buildResultImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: state.resultImageUrl!,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 8),
                Text(
                  'Failed to load result image',
                  style: TextStyle(color: AppColors.error),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withValues(alpha: 0.7),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              state.status == TryOnStatus.uploading
                  ? 'Preparing images...'
                  : 'Generating try-on... (10-30s)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.error.withValues(alpha: 0.9),
      ),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              state.errorMessage!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

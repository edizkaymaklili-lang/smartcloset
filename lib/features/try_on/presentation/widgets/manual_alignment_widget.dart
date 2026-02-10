import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/pose_detection_service.dart';

class ManualAlignmentWidget extends StatefulWidget {
  final File bodyPhoto;
  final File garmentPhoto;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const ManualAlignmentWidget({
    super.key,
    required this.bodyPhoto,
    required this.garmentPhoto,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<ManualAlignmentWidget> createState() => _ManualAlignmentWidgetState();
}

class _ManualAlignmentWidgetState extends State<ManualAlignmentWidget> {
  TransformData? _transform;
  bool _isLoading = true;
  final PoseDetectionService _poseService = PoseDetectionService();

  // Manual adjustment values
  double _manualScale = 1.0;
  double _manualRotation = 0.0;
  Offset _manualOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _autoAlign();
  }

  @override
  void dispose() {
    _poseService.dispose();
    super.dispose();
  }

  Future<void> _autoAlign() async {
    setState(() => _isLoading = true);

    // Detect pose from body photo
    final alignmentData = await _poseService.detectBodyPose(widget.bodyPhoto);

    if (alignmentData != null && mounted) {
      // Calculate initial transform
      final transform = alignmentData.calculateGarmentTransform(
        garmentSize: const Size(300, 400), // Estimated garment size
        bodyImageSize: const Size(400, 600), // Estimated body image size
      );

      setState(() {
        _transform = transform;
        _manualScale = transform.scale;
        _manualRotation = transform.rotation;
        _manualOffset = transform.offset;
        _isLoading = false;
      });
    } else {
      // Fallback to center alignment
      setState(() {
        _transform = TransformData(
          offset: const Offset(50, 100),
          scale: 0.8,
          rotation: 0,
        );
        _manualScale = 0.8;
        _manualRotation = 0;
        _manualOffset = const Offset(50, 100);
        _isLoading = false;
      });
    }
  }

  void _resetAlignment() {
    _autoAlign();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Detecting pose...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Preview area
        Expanded(
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _manualOffset += details.delta;
              });
            },
            onScaleUpdate: (details) {
              setState(() {
                _manualScale *= details.scale;
                _manualRotation += details.rotation;
              });
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Body photo
                _buildBodyImage(),

                // Garment overlay with transform
                if (_transform != null)
                  Positioned.fill(
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setTranslationRaw(_manualOffset.dx, _manualOffset.dy, 0)
                        ..multiply(Matrix4.diagonal3Values(_manualScale, _manualScale, 1))
                        ..rotateZ(_manualRotation),
                      child: Opacity(
                        opacity: 0.85,
                        child: _buildGarmentImage(),
                      ),
                    ),
                  ),

                // Help text
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.black54,
                    child: const Text(
                      '👆 Drag to move • 👌 Pinch to scale • 🔄 Two fingers to rotate',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Control panel
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Scale slider
              Row(
                children: [
                  const Icon(Icons.zoom_in, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: _manualScale.clamp(0.3, 2.0),
                      min: 0.3,
                      max: 2.0,
                      divisions: 34,
                      label: '${(_manualScale * 100).toInt()}%',
                      onChanged: (value) {
                        setState(() => _manualScale = value);
                      },
                    ),
                  ),
                  Text(
                    '${(_manualScale * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),

              // Rotation slider
              Row(
                children: [
                  const Icon(Icons.rotate_right, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: _manualRotation.clamp(-0.5, 0.5),
                      min: -0.5,
                      max: 0.5,
                      divisions: 20,
                      label: '${(_manualRotation * 57.3).toInt()}°',
                      onChanged: (value) {
                        setState(() => _manualRotation = value);
                      },
                    ),
                  ),
                  Text(
                    '${(_manualRotation * 57.3).toInt()}°',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onCancel,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetAlignment,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.onSave,
                      icon: const Icon(Icons.check),
                      label: const Text('Save'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBodyImage() {
    return kIsWeb
        ? Image.network(
            widget.bodyPhoto.path,
            fit: BoxFit.contain,
          )
        : Image.file(
            widget.bodyPhoto,
            fit: BoxFit.contain,
          );
  }

  Widget _buildGarmentImage() {
    return kIsWeb
        ? Image.network(
            widget.garmentPhoto.path,
            fit: BoxFit.contain,
          )
        : Image.file(
            widget.garmentPhoto,
            fit: BoxFit.contain,
          );
  }
}

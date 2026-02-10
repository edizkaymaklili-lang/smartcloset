import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/material.dart';

class PoseDetectionService {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.single,
    ),
  );

  /// Detect pose landmarks from body photo
  Future<AlignmentData?> detectBodyPose(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isEmpty) return null;

      final pose = poses.first;
      return _calculateAlignmentData(pose);
    } catch (e) {
      // Log error silently in production
      return null;
    }
  }

  AlignmentData _calculateAlignmentData(Pose pose) {
    // Get key landmarks
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final nose = pose.landmarks[PoseLandmarkType.nose];

    if (leftShoulder == null || rightShoulder == null ||
        leftHip == null || rightHip == null || nose == null) {
      return AlignmentData.defaultAlignment();
    }

    // Calculate shoulder center
    final shoulderCenterX = (leftShoulder.x + rightShoulder.x) / 2;
    final shoulderCenterY = (leftShoulder.y + rightShoulder.y) / 2;

    // Calculate shoulder width
    final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();

    // Calculate body rotation (angle of shoulders)
    final shoulderAngle = _calculateAngle(
      Point(leftShoulder.x, leftShoulder.y),
      Point(rightShoulder.x, rightShoulder.y),
    );

    // Calculate torso length (shoulder to hip)
    final torsoLength = shoulderCenterY - ((leftHip.y + rightHip.y) / 2);

    return AlignmentData(
      shoulderCenter: Offset(shoulderCenterX, shoulderCenterY),
      shoulderWidth: shoulderWidth,
      torsoLength: torsoLength.abs(),
      bodyAngle: shoulderAngle,
      nosePosition: Offset(nose.x, nose.y),
    );
  }

  double _calculateAngle(Point p1, Point p2) {
    return (p2.y - p1.y) / (p2.x - p1.x);
  }

  void dispose() {
    _poseDetector.close();
  }
}

class Point {
  final double x;
  final double y;
  Point(this.x, this.y);
}

class AlignmentData {
  final Offset shoulderCenter;
  final double shoulderWidth;
  final double torsoLength;
  final double bodyAngle;
  final Offset nosePosition;

  AlignmentData({
    required this.shoulderCenter,
    required this.shoulderWidth,
    required this.torsoLength,
    required this.bodyAngle,
    required this.nosePosition,
  });

  factory AlignmentData.defaultAlignment() {
    return AlignmentData(
      shoulderCenter: const Offset(0, 0),
      shoulderWidth: 100,
      torsoLength: 200,
      bodyAngle: 0,
      nosePosition: const Offset(0, 0),
    );
  }

  /// Calculate transform for garment overlay
  TransformData calculateGarmentTransform({
    required Size garmentSize,
    required Size bodyImageSize,
  }) {
    // Scale based on shoulder width
    // Assuming garment shoulder width is ~40% of garment width
    final garmentShoulderWidth = garmentSize.width * 0.4;
    final scale = shoulderWidth / garmentShoulderWidth;

    // Position: align garment top with body shoulders
    // Garment collar should be slightly above shoulder center
    final offsetX = shoulderCenter.dx - (garmentSize.width * scale / 2);
    final offsetY = shoulderCenter.dy - (garmentSize.height * scale * 0.15); // 15% from top

    return TransformData(
      offset: Offset(offsetX, offsetY),
      scale: scale,
      rotation: bodyAngle * 0.1, // Gentle rotation matching body angle
    );
  }
}

class TransformData {
  final Offset offset;
  final double scale;
  final double rotation;

  TransformData({
    required this.offset,
    required this.scale,
    required this.rotation,
  });

  TransformData copyWith({
    Offset? offset,
    double? scale,
    double? rotation,
  }) {
    return TransformData(
      offset: offset ?? this.offset,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }
}

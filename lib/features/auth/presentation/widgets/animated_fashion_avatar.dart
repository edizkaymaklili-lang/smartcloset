import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Outfit definition: colors + label + accessory icon
class _OutfitSet {
  final Color topColor;
  final Color bottomColor;
  final Color shoeColor;
  final String label;
  final IconData accessoryIcon;
  final bool isDress; // true = single piece (dress), false = top + bottom

  const _OutfitSet({
    required this.topColor,
    required this.bottomColor,
    required this.shoeColor,
    required this.label,
    required this.accessoryIcon,
    this.isDress = false,
  });
}

class AnimatedFashionAvatar extends StatefulWidget {
  final double height;

  const AnimatedFashionAvatar({super.key, this.height = 280});

  @override
  State<AnimatedFashionAvatar> createState() => _AnimatedFashionAvatarState();
}

class _AnimatedFashionAvatarState extends State<AnimatedFashionAvatar>
    with TickerProviderStateMixin {
  static const _outfits = [
    _OutfitSet(
      topColor: Color(0xFFE53935),
      bottomColor: Color(0xFFE53935),
      shoeColor: Color(0xFF5D4037),
      label: 'Night Elegance',
      accessoryIcon: Icons.diamond_outlined,
      isDress: true,
    ),
    _OutfitSet(
      topColor: Colors.white,
      bottomColor: Color(0xFF1565C0),
      shoeColor: Color(0xFFEEEEEE),
      label: 'Casual Style',
      accessoryIcon: Icons.shopping_bag_outlined,
    ),
    _OutfitSet(
      topColor: Color(0xFF212121),
      bottomColor: Color(0xFF424242),
      shoeColor: Color(0xFF212121),
      label: 'Office Chic',
      accessoryIcon: Icons.watch_outlined,
    ),
    _OutfitSet(
      topColor: Color(0xFF43A047),
      bottomColor: Color(0xFF43A047),
      shoeColor: Color(0xFFD7CCC8),
      label: 'Summer Breeze',
      accessoryIcon: Icons.wb_sunny_outlined,
      isDress: true,
    ),
    _OutfitSet(
      topColor: Color(0xFF7B1FA2),
      bottomColor: Color(0xFF37474F),
      shoeColor: Color(0xFF5D4037),
      label: 'Autumn Vibes',
      accessoryIcon: Icons.eco_outlined,
    ),
    _OutfitSet(
      topColor: Color(0xFFF48FB1),
      bottomColor: Colors.white,
      shoeColor: Color(0xFFFFCDD2),
      label: 'Romantic Look',
      accessoryIcon: Icons.favorite_outline,
    ),
  ];

  late AnimationController _outfitController;
  late AnimationController _sparkleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  int _currentOutfit = 0;

  final _random = Random();
  List<_Sparkle> _sparkles = [];

  @override
  void initState() {
    super.initState();

    // Outfit change animation
    _outfitController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _outfitController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _outfitController, curve: Curves.easeOut),
    );

    _outfitController.forward();

    // Sparkle animation
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _sparkleController.addListener(() {
      if (mounted) setState(() => _updateSparkles());
    });

    // Timer for outfit changes
    _startOutfitCycle();
  }

  void _startOutfitCycle() {
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      _outfitController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _currentOutfit = (_currentOutfit + 1) % _outfits.length;
        });
        _outfitController.forward();
        _startOutfitCycle();
      });
    });
  }

  void _updateSparkles() {
    // Add new sparkle randomly
    if (_random.nextDouble() < 0.15) {
      _sparkles.add(_Sparkle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 3 + 1,
        opacity: 1.0,
      ));
    }
    // Fade existing sparkles
    _sparkles = _sparkles
        .map((s) => s.copyWith(opacity: s.opacity - 0.03))
        .where((s) => s.opacity > 0)
        .toList();
  }

  @override
  void dispose() {
    _outfitController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outfit = _outfits[_currentOutfit];

    return SizedBox(
      height: widget.height,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sparkle effects
          ..._sparkles.map((s) => Positioned(
                left: s.x * 200,
                top: s.y * widget.height,
                child: Opacity(
                  opacity: s.opacity.clamp(0.0, 1.0),
                  child: Icon(
                    Icons.auto_awesome,
                    size: s.size * 4,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                ),
              )),

          // Glow behind avatar
          Positioned(
            top: 30,
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Container(
                  width: 120,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(60),
                    gradient: RadialGradient(
                      colors: [
                        outfit.topColor.withValues(alpha: 0.15 * _fadeAnimation.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // The avatar figure
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, _) {
              return CustomPaint(
                size: Size(200, widget.height),
                painter: _AvatarPainter(
                  outfit: outfit,
                  animProgress: _fadeAnimation.value,
                ),
              );
            },
          ),

          // Outfit label
          Positioned(
            bottom: 8,
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, _) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(outfit.accessoryIcon,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            outfit.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter that draws a stylized female figure
class _AvatarPainter extends CustomPainter {
  final _OutfitSet outfit;
  final double animProgress;

  _AvatarPainter({required this.outfit, required this.animProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    // Scale for the figure
    final scale = size.height / 280;

    // ─── HAIR ───
    final hairPaint = Paint()
      ..color = const Color(0xFF4E342E)
      ..style = PaintingStyle.fill;

    // Hair back (wider, behind head)
    final hairBack = Path()
      ..moveTo(centerX - 22 * scale, 30 * scale)
      ..quadraticBezierTo(centerX - 30 * scale, 60 * scale, centerX - 18 * scale, 95 * scale)
      ..quadraticBezierTo(centerX - 25 * scale, 110 * scale, centerX - 15 * scale, 120 * scale)
      ..lineTo(centerX + 15 * scale, 120 * scale)
      ..quadraticBezierTo(centerX + 25 * scale, 110 * scale, centerX + 18 * scale, 95 * scale)
      ..quadraticBezierTo(centerX + 30 * scale, 60 * scale, centerX + 22 * scale, 30 * scale)
      ..close();
    canvas.drawPath(hairBack, hairPaint);

    // ─── HEAD ───
    final skinPaint = Paint()
      ..color = const Color(0xFFFBE9E7)
      ..style = PaintingStyle.fill;

    // Face oval
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, 50 * scale),
        width: 34 * scale,
        height: 42 * scale,
      ),
      skinPaint,
    );

    // ─── HAIR FRONT (bangs) ───
    final bangsPath = Path()
      ..moveTo(centerX - 18 * scale, 34 * scale)
      ..quadraticBezierTo(centerX - 12 * scale, 22 * scale, centerX, 26 * scale)
      ..quadraticBezierTo(centerX + 12 * scale, 22 * scale, centerX + 18 * scale, 34 * scale)
      ..quadraticBezierTo(centerX + 20 * scale, 28 * scale, centerX + 17 * scale, 24 * scale)
      ..quadraticBezierTo(centerX, 16 * scale, centerX - 17 * scale, 24 * scale)
      ..quadraticBezierTo(centerX - 20 * scale, 28 * scale, centerX - 18 * scale, 34 * scale)
      ..close();
    canvas.drawPath(bangsPath, hairPaint);

    // ─── EYES ───
    final eyePaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 7 * scale, 48 * scale),
        width: 4 * scale,
        height: 5 * scale,
      ),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 7 * scale, 48 * scale),
        width: 4 * scale,
        height: 5 * scale,
      ),
      eyePaint,
    );

    // Eyelashes
    final lashPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..strokeWidth = 1.2 * scale
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX - 7 * scale, 47 * scale),
        width: 6 * scale,
        height: 3 * scale,
      ),
      3.14, 3.14, false, lashPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX + 7 * scale, 47 * scale),
        width: 6 * scale,
        height: 3 * scale,
      ),
      3.14, 3.14, false, lashPaint,
    );

    // ─── SMILE ───
    final smilePaint = Paint()
      ..color = const Color(0xFFE57373)
      ..strokeWidth = 1.5 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX, 57 * scale),
        width: 10 * scale,
        height: 6 * scale,
      ),
      0.2, 2.7, false, smilePaint,
    );

    // ─── NECK ───
    canvas.drawRect(
      Rect.fromLTWH(centerX - 5 * scale, 70 * scale, 10 * scale, 12 * scale),
      skinPaint,
    );

    // ─── CLOTHING (animated) ───
    final clothingOpacity = animProgress.clamp(0.0, 1.0);

    if (outfit.isDress) {
      _drawDress(canvas, centerX, scale, clothingOpacity);
    } else {
      _drawTopAndBottom(canvas, centerX, scale, clothingOpacity);
    }

    // ─── ARMS ───
    final armPaint = Paint()
      ..color = const Color(0xFFFBE9E7)
      ..strokeWidth = 5 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Left arm
    final leftArm = Path()
      ..moveTo(centerX - 24 * scale, 88 * scale)
      ..quadraticBezierTo(
          centerX - 35 * scale, 120 * scale, centerX - 28 * scale, 145 * scale);
    canvas.drawPath(leftArm, armPaint);

    // Right arm
    final rightArm = Path()
      ..moveTo(centerX + 24 * scale, 88 * scale)
      ..quadraticBezierTo(
          centerX + 35 * scale, 120 * scale, centerX + 28 * scale, 145 * scale);
    canvas.drawPath(rightArm, armPaint);

    // ─── LEGS ───
    final legPaint = Paint()
      ..color = const Color(0xFFFBE9E7)
      ..strokeWidth = 5.5 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Left leg
    canvas.drawLine(
      Offset(centerX - 10 * scale, 195 * scale),
      Offset(centerX - 12 * scale, 240 * scale),
      legPaint,
    );
    // Right leg
    canvas.drawLine(
      Offset(centerX + 10 * scale, 195 * scale),
      Offset(centerX + 12 * scale, 240 * scale),
      legPaint,
    );

    // ─── SHOES ───
    final shoePaint = Paint()
      ..color = Color.lerp(Colors.transparent, outfit.shoeColor, clothingOpacity)!
      ..style = PaintingStyle.fill;

    // Left shoe
    final leftShoe = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        centerX - 20 * scale, 238 * scale, 16 * scale, 8 * scale,
      ),
      Radius.circular(4 * scale),
    );
    canvas.drawRRect(leftShoe, shoePaint);

    // Right shoe
    final rightShoe = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        centerX + 4 * scale, 238 * scale, 16 * scale, 8 * scale,
      ),
      Radius.circular(4 * scale),
    );
    canvas.drawRRect(rightShoe, shoePaint);
  }

  void _drawDress(Canvas canvas, double cx, double s, double opacity) {
    final dressPaint = Paint()
      ..color = Color.lerp(Colors.transparent, outfit.topColor, opacity)!
      ..style = PaintingStyle.fill;

    final dressPath = Path()
      ..moveTo(cx - 20 * s, 80 * s)
      ..lineTo(cx + 20 * s, 80 * s)
      ..quadraticBezierTo(cx + 24 * s, 85 * s, cx + 24 * s, 90 * s)
      ..lineTo(cx + 20 * s, 130 * s)
      ..quadraticBezierTo(cx + 28 * s, 160 * s, cx + 35 * s, 195 * s)
      ..lineTo(cx - 35 * s, 195 * s)
      ..quadraticBezierTo(cx - 28 * s, 160 * s, cx - 20 * s, 130 * s)
      ..lineTo(cx - 24 * s, 90 * s)
      ..quadraticBezierTo(cx - 24 * s, 85 * s, cx - 20 * s, 80 * s)
      ..close();
    canvas.drawPath(dressPath, dressPaint);

    // Dress detail: belt/waist line
    final beltPaint = Paint()
      ..color = Color.lerp(Colors.transparent,
          outfit.topColor.withValues(alpha: 0.3), opacity)!
      ..strokeWidth = 2 * s
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - 18 * s, 130 * s),
      Offset(cx + 18 * s, 130 * s),
      beltPaint,
    );
  }

  void _drawTopAndBottom(Canvas canvas, double cx, double s, double opacity) {
    // TOP
    final topPaint = Paint()
      ..color = Color.lerp(Colors.transparent, outfit.topColor, opacity)!
      ..style = PaintingStyle.fill;

    final topPath = Path()
      ..moveTo(cx - 20 * s, 80 * s)
      ..lineTo(cx + 20 * s, 80 * s)
      ..quadraticBezierTo(cx + 24 * s, 85 * s, cx + 24 * s, 90 * s)
      ..lineTo(cx + 22 * s, 135 * s)
      ..lineTo(cx - 22 * s, 135 * s)
      ..lineTo(cx - 24 * s, 90 * s)
      ..quadraticBezierTo(cx - 24 * s, 85 * s, cx - 20 * s, 80 * s)
      ..close();
    canvas.drawPath(topPath, topPaint);

    // BOTTOM (pants/skirt)
    final bottomPaint = Paint()
      ..color = Color.lerp(Colors.transparent, outfit.bottomColor, opacity)!
      ..style = PaintingStyle.fill;

    final bottomPath = Path()
      ..moveTo(cx - 22 * s, 135 * s)
      ..lineTo(cx + 22 * s, 135 * s)
      ..lineTo(cx + 15 * s, 195 * s)
      ..lineTo(cx + 5 * s, 195 * s)
      ..lineTo(cx, 170 * s)
      ..lineTo(cx - 5 * s, 195 * s)
      ..lineTo(cx - 15 * s, 195 * s)
      ..close();
    canvas.drawPath(bottomPath, bottomPaint);
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) {
    return oldDelegate.outfit != outfit ||
        oldDelegate.animProgress != animProgress;
  }
}

class _Sparkle {
  final double x;
  final double y;
  final double size;
  final double opacity;

  const _Sparkle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
  });

  _Sparkle copyWith({double? opacity}) {
    return _Sparkle(
      x: x,
      y: y,
      size: size,
      opacity: opacity ?? this.opacity,
    );
  }
}

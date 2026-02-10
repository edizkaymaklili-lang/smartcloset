/// Body type enum - for personalized clothing recommendations
enum BodyType {
  hourglass,
  pear,
  apple,
  rectangle,
  invertedTriangle;

  String get displayName => switch (this) {
        hourglass => 'Hourglass',
        pear => 'Pear',
        apple => 'Apple',
        rectangle => 'Rectangle',
        invertedTriangle => 'Inverted Triangle',
      };

  String get description => switch (this) {
        hourglass => 'Balanced shoulders & hips, defined waist',
        pear => 'Hips wider than shoulders, slim waist',
        apple => 'Broad torso, slim legs',
        rectangle => 'Shoulders, waist & hips similar width',
        invertedTriangle => 'Broad shoulders, narrow hips',
      };

  String get icon => switch (this) {
        hourglass => '⏳',
        pear => '🍐',
        apple => '🍎',
        rectangle => '▬',
        invertedTriangle => '🔻',
      };

  /// Recommended clothing styles for this body type
  List<String> get recommendedStyles => switch (this) {
        hourglass => [
          'Waist-defining dresses',
          'Wrap dresses',
          'High-waist pants',
          'Fit & flare cuts',
        ],
        pear => [
          'A-line skirts',
          'Wide necklines',
          'Dark bottoms, light tops',
          'Shoulder-detail tops',
        ],
        apple => [
          'Empire waist dresses',
          'V-neck tops',
          'Straight-cut pants',
          'Long sleeve blouses',
        ],
        rectangle => [
          'Belted outfits',
          'Peplum tops',
          'Layered clothing',
          'Ruffled/flared pieces',
        ],
        invertedTriangle => [
          'A-line skirts & dresses',
          'Wide-leg pants',
          'V-neck tops',
          'Dark tops, light bottoms',
        ],
      };
}

/// Height range enum - for clothing proportions and sizing
enum HeightRange {
  petite,
  average,
  tall;

  String get displayName => switch (this) {
        petite => 'Petite (under 5\'1")',
        average => 'Average (5\'1" - 5\'7")',
        tall => 'Tall (over 5\'7")',
      };

  /// Style tips for this height
  List<String> get styleTips => switch (this) {
        petite => [
          'Choose high-waist styles',
          'Vertical lines elongate',
          'Monochrome outfits ideal',
          'Cropped jackets balance proportions',
        ],
        average => [
          'Most cuts suit you well',
          'Play with proportions freely',
          'Any heel height works comfortably',
        ],
        tall => [
          'Wide-leg pants look great',
          'Maxi dresses & skirts flatter',
          'Horizontal lines add balance',
          'Oversized pieces look chic',
        ],
      };
}

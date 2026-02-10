/// Color season analysis - best color palette for your skin tone
enum ColorSeason {
  spring,
  summer,
  autumn,
  winter;

  String get displayName => switch (this) {
        spring => 'Spring',
        summer => 'Summer',
        autumn => 'Autumn',
        winter => 'Winter',
      };

  String get description => switch (this) {
        spring => 'Warm, bright and light tones',
        summer => 'Cool, soft and pastel tones',
        autumn => 'Warm, deep and earthy tones',
        winter => 'Cool, intense and contrasting tones',
      };

  String get icon => switch (this) {
        spring => '🌸',
        summer => '🌊',
        autumn => '🍂',
        winter => '❄️',
      };

  /// Best colors for this season
  List<String> get bestColors => switch (this) {
        spring => [
          'Coral',
          'Peach',
          'Warm red',
          'Golden yellow',
          'Turquoise',
          'Light green',
          'Cream',
          'Salmon',
        ],
        summer => [
          'Lavender',
          'Powder pink',
          'Ice blue',
          'Rose',
          'Lilac',
          'Mint green',
          'Silver gray',
          'Mauve',
        ],
        autumn => [
          'Mustard',
          'Orange',
          'Burgundy',
          'Olive green',
          'Earth brown',
          'Copper',
          'Cinnamon',
          'Terracotta',
        ],
        winter => [
          'Black',
          'White',
          'Deep red',
          'Royal blue',
          'Emerald green',
          'Fuchsia',
          'Deep purple',
          'Silver',
        ],
      };

  /// Colors to avoid
  List<String> get avoidColors => switch (this) {
        spring => ['Black', 'Gray', 'Cool tones'],
        summer => ['Orange', 'Mustard', 'Warm brown'],
        autumn => ['Pastel tones', 'Ice blue', 'Pink'],
        winter => ['Earth tones', 'Beige', 'Cream'],
      };

  /// Skin tone hints for color season test
  String get skinToneHint => switch (this) {
        spring => 'Golden/peach undertones, warm skin',
        summer => 'Pink/blue undertones, cool skin',
        autumn => 'Golden/bronze undertones, warm deep skin',
        winter => 'Blue/pink undertones, high contrast skin',
      };
}

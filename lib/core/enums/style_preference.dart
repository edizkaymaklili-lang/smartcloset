enum StylePreference {
  classic,
  sporty,
  bohemian,
  elegant;

  String get displayName {
    return switch (this) {
      StylePreference.classic => 'Classic',
      StylePreference.sporty => 'Sporty',
      StylePreference.bohemian => 'Bohemian',
      StylePreference.elegant => 'Elegant',
    };
  }

  String get description {
    return switch (this) {
      StylePreference.classic => 'Timeless pieces, clean lines, neutral tones',
      StylePreference.sporty => 'Comfortable, athletic-inspired, casual chic',
      StylePreference.bohemian => 'Free-spirited, layered, earthy textures',
      StylePreference.elegant => 'Sophisticated, refined, statement pieces',
    };
  }

  String get icon {
    return switch (this) {
      StylePreference.classic => '👔',
      StylePreference.sporty => '🏃‍♀️',
      StylePreference.bohemian => '🌸',
      StylePreference.elegant => '✨',
    };
  }
}

enum OutfitOccasion {
  office,
  casual,
  night;

  String get displayName {
    return switch (this) {
      OutfitOccasion.office => 'Work Week',
      OutfitOccasion.casual => 'Daily',
      OutfitOccasion.night => 'Special Night',
    };
  }

  String get icon {
    return switch (this) {
      OutfitOccasion.office => '💼',
      OutfitOccasion.casual => '☀️',
      OutfitOccasion.night => '✨',
    };
  }
}

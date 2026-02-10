/// User hobby/activity enum - for lifestyle-based clothing recommendations
enum UserHobby {
  yoga,
  running,
  gym,
  swimming,
  cycling,
  hiking,
  dancing,
  shopping,
  cafe,
  photography,
  travel,
  cooking,
  reading,
  gardening,
  painting;

  String get displayName => switch (this) {
        yoga => 'Yoga / Pilates',
        running => 'Running',
        gym => 'Gym',
        swimming => 'Swimming',
        cycling => 'Cycling',
        hiking => 'Hiking',
        dancing => 'Dancing',
        shopping => 'Shopping',
        cafe => 'Cafe / Dining',
        photography => 'Photography',
        travel => 'Travel',
        cooking => 'Cooking',
        reading => 'Reading',
        gardening => 'Gardening',
        painting => 'Art / Painting',
      };

  String get icon => switch (this) {
        yoga => '🧘',
        running => '🏃',
        gym => '💪',
        swimming => '🏊',
        cycling => '🚴',
        hiking => '🥾',
        dancing => '💃',
        shopping => '🛍️',
        cafe => '☕',
        photography => '📸',
        travel => '✈️',
        cooking => '👩‍🍳',
        reading => '📖',
        gardening => '🌱',
        painting => '🎨',
      };

  /// Recommended outfit style for this hobby
  String get outfitHint => switch (this) {
        yoga => 'Flexible leggings, sports bra, light top',
        running => 'Running tights, breathable tee, running shoes',
        gym => 'Sport leggings, tank top, cross-training shoes',
        swimming => 'Swimsuit, pareo, beach dress',
        cycling => 'Bike shorts, windbreaker, sport sunglasses',
        hiking => 'Outdoor pants, layered tops, boots',
        dancing => 'Freedom-of-movement dress or skirt',
        shopping => 'Comfy but chic: dress, sneakers, crossbody bag',
        cafe => 'Casual chic: blouse, jeans, loafers',
        photography => 'Practical: multi-pocket jacket, comfy pants',
        travel => 'Wrinkle-free fabrics, layers, comfortable shoes',
        cooking => 'Comfortable, stain-resistant fabrics, apron',
        reading => 'Soft sweater, comfy pants, slippers',
        gardening => 'Old/comfy clothes, sun hat, gloves',
        painting => 'Old t-shirt, apron, comfy pants',
      };

  /// Is this an active sport?
  bool get isActiveSport => switch (this) {
        yoga || running || gym || swimming || cycling || hiking || dancing => true,
        _ => false,
      };
}

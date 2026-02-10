/// Work type enum - determines daily clothing needs
enum WorkType {
  officeFormel,
  officeCasual,
  remote,
  student,
  freelance,
  homemaker,
  retired;

  String get displayName => switch (this) {
        officeFormel => 'Office (Formal)',
        officeCasual => 'Office (Casual)',
        remote => 'Remote Work',
        student => 'Student',
        freelance => 'Freelancer',
        homemaker => 'Homemaker',
        retired => 'Retired',
      };

  String get icon => switch (this) {
        officeFormel => '👔',
        officeCasual => '💼',
        remote => '🏠',
        student => '📚',
        freelance => '💻',
        homemaker => '🏡',
        retired => '🌸',
      };

  /// Daily style hints
  String get styleHint => switch (this) {
        officeFormel => 'Blazer, shirt, pencil skirt, heels',
        officeCasual => 'Chinos, blouse, loafers, light jacket',
        remote => 'Comfy but chic: joggers, oversized sweater, sneakers',
        student => 'Practical & dynamic: jeans, t-shirt, backpack',
        freelance => 'Flexible style: mix & match, creative combos',
        homemaker => 'Comfortable & easy: jogger top, flat shoes',
        retired => 'Elegant comfort: fabric pants, knitwear, scarf',
      };
}

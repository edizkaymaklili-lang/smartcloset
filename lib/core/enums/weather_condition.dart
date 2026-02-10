enum WeatherCondition {
  sunny,
  cloudy,
  rainy,
  snowy,
  windy,
  stormy;

  String get displayName {
    return switch (this) {
      WeatherCondition.sunny => 'Sunny',
      WeatherCondition.cloudy => 'Cloudy',
      WeatherCondition.rainy => 'Rainy',
      WeatherCondition.snowy => 'Snowy',
      WeatherCondition.windy => 'Windy',
      WeatherCondition.stormy => 'Stormy',
    };
  }

  String get icon {
    return switch (this) {
      WeatherCondition.sunny => '☀️',
      WeatherCondition.cloudy => '☁️',
      WeatherCondition.rainy => '🌧️',
      WeatherCondition.snowy => '❄️',
      WeatherCondition.windy => '💨',
      WeatherCondition.stormy => '⛈️',
    };
  }
}

enum WeatherClass {
  hotSunny,
  mildWarm,
  cool,
  windyCool,
  rainy,
  snowyCold;

  String get displayName {
    return switch (this) {
      WeatherClass.hotSunny => 'Hot & Sunny',
      WeatherClass.mildWarm => 'Mild & Warm',
      WeatherClass.cool => 'Cool',
      WeatherClass.windyCool => 'Windy & Cool',
      WeatherClass.rainy => 'Rainy',
      WeatherClass.snowyCold => 'Snowy & Cold',
    };
  }
}

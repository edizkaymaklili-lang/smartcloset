import '../../../core/enums/weather_condition.dart';
import '../../weather/domain/entities/weather_data.dart';

class WeatherClassifier {
  WeatherClass classify(WeatherData data) {
    if (data.condition == WeatherCondition.snowy || data.temperature <= 5) {
      return WeatherClass.snowyCold;
    }

    if (data.condition == WeatherCondition.rainy || data.precipitation >= 5) {
      return WeatherClass.rainy;
    }

    if (data.windSpeed >= 8 && data.temperature < 18) {
      return WeatherClass.windyCool;
    }

    if (data.temperature >= 25 && data.precipitation < 1) {
      return WeatherClass.hotSunny;
    }

    if (data.temperature >= 18 && data.temperature < 25) {
      return WeatherClass.mildWarm;
    }

    return WeatherClass.cool;
  }
}

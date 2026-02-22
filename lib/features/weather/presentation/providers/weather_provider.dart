import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/weather_api_datasource.dart';
import '../../domain/entities/weather_data.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../services/location_service.dart';

final weatherApiProvider = Provider<WeatherApiDatasource>((ref) {
  return WeatherApiDatasource();
});

final weatherProvider =
    AsyncNotifierProvider<WeatherNotifier, WeatherData>(WeatherNotifier.new);

class WeatherNotifier extends AsyncNotifier<WeatherData> {
  @override
  Future<WeatherData> build() async {
    // Keep weather data cached - don't dispose when navigating away
    ref.keepAlive();

    final profile = ref.watch(profileProvider);
    final api = ref.read(weatherApiProvider);

    // Don't auto-detect location on page load to improve performance
    // Users can manually trigger location detection via refresh button
    debugPrint('Fetching weather for: ${profile.city}');
    return api.getCurrentWeather(city: profile.city);
  }

  Future<void> refresh({String? city, bool detectLocation = false}) async {
    state = const AsyncValue.loading();
    final targetCity = city ?? ref.read(profileProvider).city;

    if (detectLocation) {
      try {
        final locationService = LocationService();
        final detectedCity = await locationService.getCurrentCity();

        if (detectedCity != null && detectedCity.isNotEmpty) {
          ref.read(profileProvider.notifier).updateCity(detectedCity);
          state = await AsyncValue.guard(() =>
              ref.read(weatherApiProvider).getCurrentWeather(city: detectedCity));
          return;
        }
      } catch (_) {
        // Failed to detect location
      }
    }

    state = await AsyncValue.guard(
        () => ref.read(weatherApiProvider).getCurrentWeather(city: targetCity));
  }
}

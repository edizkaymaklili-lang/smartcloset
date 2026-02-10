import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/weather_mock_datasource.dart';
import '../../domain/entities/weather_data.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

final weatherMockProvider = Provider<WeatherMockDatasource>((ref) {
  return WeatherMockDatasource();
});

final weatherProvider = NotifierProvider<WeatherNotifier, AsyncValue<WeatherData>>(() {
  return WeatherNotifier();
});

class WeatherNotifier extends Notifier<AsyncValue<WeatherData>> {
  @override
  AsyncValue<WeatherData> build() {
    // Watch user profile to get their city
    final profile = ref.watch(profileProvider);
    _load(city: profile.city);
    return const AsyncValue.loading();
  }

  void _load({String city = 'Istanbul'}) {
    final datasource = ref.read(weatherMockProvider);
    try {
      final data = datasource.getCurrentWeather(city: city);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void refresh({String? city}) {
    final profile = ref.read(profileProvider);
    _load(city: city ?? profile.city);
  }
}

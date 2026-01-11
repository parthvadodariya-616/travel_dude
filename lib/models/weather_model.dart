// lib/models/weather_model.dart

class WeatherModel {
  final String cityName;
  final double temperature;
  final String description;
  final String weatherCondition;
  final int humidity;
  final double windSpeed;
  final String icon; // Icon code like '01d' or '01n'
  final DateTime timestamp;

  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.weatherCondition,
    required this.humidity,
    required this.windSpeed,
    required this.icon,
    required this.timestamp,
  });

  factory WeatherModel.fromOpenWeatherJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'] ?? '',
      temperature: (json['main']?['temp'] ?? 0).toDouble(),
      description: json['weather']?[0]?['description'] ?? '',
      weatherCondition: json['weather']?[0]?['main'] ?? 'Clear',
      humidity: json['main']?['humidity'] ?? 0,
      windSpeed: (json['wind']?['speed'] ?? 0).toDouble(),
      icon: json['weather']?[0]?['icon'] ?? '01d',
      timestamp: DateTime.now(),
    );
  }

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['cityName'] ?? '',
      temperature: json['temperature'] ?? 0.0,
      description: json['description'] ?? '',
      weatherCondition: json['weatherCondition'] ?? '',
      humidity: json['humidity'] ?? 0,
      windSpeed: json['windSpeed'] ?? 0.0,
      icon: json['icon'] ?? '01d',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cityName': cityName,
      'temperature': temperature,
      'description': description,
      'weatherCondition': weatherCondition,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'icon': icon,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  int get temperatureCelsius => temperature.round();

  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';

  // Dynamic emoji based on OpenWeather icon code
  // d = day, n = night
  String get weatherEmoji {
    if (icon == '01d') return '☀️'; // Clear sky day
    if (icon == '01n') return '🌙'; // Clear sky night
    if (icon == '02d') return 'zk🌤️'; // Few clouds day
    if (icon == '02n') return '☁️'; // Few clouds night
    if (icon == '03d' || icon == '03n') return '☁️'; // Scattered clouds
    if (icon == '04d' || icon == '04n') return '☁️'; // Broken clouds
    if (icon == '09d' || icon == '09n') return '🌧️'; // Shower rain
    if (icon == '10d') return '🌦️'; // Rain day
    if (icon == '10n') return '🌧️'; // Rain night
    if (icon == '11d' || icon == '11n') return '⛈️'; // Thunderstorm
    if (icon == '13d' || icon == '13n') return '❄️'; // Snow
    if (icon == '50d' || icon == '50n') return '🌫️'; // Mist
    return '🌈'; // Default
  }

  String get formattedDescription {
    return '${description[0].toUpperCase()}${description.substring(1)}';
  }
}